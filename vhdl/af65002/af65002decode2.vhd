----------------------------------------------------------------------------------
--
--    Opcode decoder for the af65k CPU
--
--    Copyright (C) 2011,2012 André Fachat
--
--    This library is free software; you can redistribute it and/or
--    modify it under the terms of the GNU Lesser General Public
--    License as published by the Free Software Foundation; either
--    version 2.1 of the License, or (at your option) any later version.
--
--    This library is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--    Lesser General Public License for more details.
--
--    You should have received a copy of the GNU Lesser General Public
--    License along with this library; if not, write to the Free Software
--    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--
----------------------------------------------------------------------------------
--
-- 	entity: 		af65002decode
--		purpose:		Decodes program code into operation, addressing mode, parameter
--		features:	- uses prefetch to allow reading program code "in the background"
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		todo:			- stop prefetch when a "known" jump operation is detected, e.g. JMP, RTS, ...
--						- after a new PC, store data till next opcode in "branch prefetch buffer",
--						  so branch penalty is reduced for second and later branches/jumps
--
--		Changes:		
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use ieee.std_logic_arith.all; 
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;
library af65002;
use af65002.af65k.all;

--
-- Note that the decode algorithm assumes that multi-byte fetches/reads
-- are always aligned, i.e. a QUAD read will always occur at an 8-byte address
-- boundary, as much as WORD reads will always occur at a 2-byte address
-- boundary and so on.
--
-- Note: current implementation only works up to MW=32, but NOT for MW=64!
-- This also implies that the condition term "dwidth=wQUAD" is not implemented as well
--

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity af65002decode2 is
	Generic (
		W : integer;
		MW : integer
	);
	Port ( 
		-- master clock
		phi2 : in  STD_LOGIC;
		reset : in STD_LOGIC;
		
		-- interrupt handling
		-- when set, start interrupt sequence...
		start_interrupt : in std_logic;
		-- ...using this interrupt level
		irqlevel_in : in irqlevel_t;
		-- signal with this when irq sequence is piped into execution queue
		started_interrupt : out std_logic;
		-- input if in hypervisor mode
		is_hypervisor : in std_logic;
		-- rollback info from control
		is_rollback : in std_logic;
		-- abort vector for rollback
		rollback_abort_vec : in abort_t;
		-- pc for abort
		rollback_pc : in std_logic_vector(W-1 downto 0);
		
		---- fetch interface
		pcin : in STD_LOGIC_VECTOR (W-1 downto 0);
		-- true when PC should be set, sampled at falling phi2
		pcin_set : in std_logic;
		-- address to read from memory
		-- the sequencer start address is taken from pcin/pcin_set
		--rdaddr : out STD_LOGIC_VECTOR (W-1 downto 0);
		-- true when incoming data is accepted
		rdvalid : out std_logic;
		-- data read from memory and its width
		din_in : in  STD_LOGIC_VECTOR (MW-1 downto 0);
      dwidth_bytes : in natural range 0 to 4;
		-- true when data read is done on din_in
      dvalid : in  STD_LOGIC;
		-- set when the read accessed illegal memory (not mapped, no execute)
		dvalid_err : in buserr_t;
		
		
		---- output params
		-- when true, the upper layer will take the output at falling phi2
		outrdy : in std_logic;
		-- the PC where the opcode is fetched from
		pc_out : out std_logic_vector (W-1 downto 0);
		-- address of the last byte of the opcode
		pc_op_end : out std_logic_vector (W-1 downto 0);
		-- address of the first byte of the next (unbranched/jumped) opcode
		pc_op_next : out std_logic_vector (W-1 downto 0);
		-- is decoded operation valid (changes at falling phi2)
      ovalid : out  STD_LOGIC;
		-----------------------------------------------------
		-- decoded operation
      operation : out  cpu_operation;
		-- decoded addressing mode
      admode : out  cpu_syntax;
		idxreg : out idx_register;
		-- decoded addressing width (parameter width)
		parwidth : out par_width;
		-- indirect address width
		indwidth : out rs_width;
		-----------------------------------------------------
		-- the actual parameter
		parameter : out std_logic_vector(W-1 downto 0);
		-- the decoded prefix bits
		-- load extension
      prefix_le : out  ext_type;
		-- width
      prefix_rs : out  rs_width;
		-- user mode bit
      prefix_um : out  STD_LOGIC;
		-- no flags bit
      prefix_nf : out  STD_LOGIC;
		-- address offset prefix
      prefix_of : out  of_type
	);
end af65002decode2;

architecture Behavioral of af65002decode2 is

	component af65002opmap is
		Port ( 
			opcode : in  STD_LOGIC_VECTOR (7 downto 0);
			opmap : in  STD_LOGIC_VECTOR (7 downto 0);
			prefix_rs : in rs_width;
			prefix_am : in std_logic;
			-- true when valid
			is_valid : out std_logic;
			operation : out cpu_operation;
			-- parameter length and syntax together define the addressing mode
			-- e.g. syntax=ABSOLUTE and parlen=wBYTE is zeropage addressing
			parwidth : out par_width;
			indwidth : out rs_width;
			admode : out cpu_syntax;
			idxreg : out idx_register;
			default_le : out ext_type
		);
	end component;

	-- current read address, initialized with PC, then incremented as opcode bytes are read
--	signal next_addr 			: std_logic_vector (W-1 downto 0);
--	signal current_addr 		: std_logic_vector (W-1 downto 0);
	-- the PC for the current opcode
	signal current_pc 		: std_logic_vector (W-1 downto 0);
	signal next_pc 			: std_logic_vector(W-1 downto 0);
	signal next_pc_m1 		: std_logic_vector(W-1 downto 0);
	
	-- maximum input width (LONG; MW=32)
	signal din				: std_logic_vector (31 downto 0);
	-- aligned when data read is not aligned with read address
	signal din_aligned			: std_logic_vector (31 downto 0);
	-- number of aligned bytes to take (for addition to write pointer)
	-- 0 means no valid bytes
	signal din_width			: natural range 0 to 4 := 0;
	-- buffered version
	signal din_width_l		: natural range 0 to 4 := 0;
	-- bit map to OR into op_valid (MW=32)
	signal din_valid_map			: std_logic_vector (3 downto 0);
	
	-- the input buffer for the opcode and parameter; needs to be 4 bytes opcode 
	-- plus 2/4/8 bytes parameters for W=16/32/64 
	-- plus 0/1/3/7 byte alignment buffer for 1/2/4/8 byte memory access width (MW=8/16/32/64)
	-- plus place for one MW prefetch
	-- rounded to multiples of MW
	-- TODO: needs more conditional coding, therefore constant for max MW=32 and W=64
	--
	constant LEN : integer := 20; -- 4 + 64/8 + 32/8-1 + 4, rounded to multiples of MW
	constant BUFLEN : integer := LEN * 8;
	-- the actual input buffer
	signal op_buffer : std_logic_vector (BUFLEN-1 downto 0) := (others => '0');
	-- bit field which byte is valid in op_buffer
	signal op_valid : std_logic_vector (LEN-1 downto 0) := (others => '0');
	
	-- async computed from op_buffer/op_valid and oplength
	--
	-- the selected data for the next cycle's input buffer (either same, or shift after finishing an opcode)
	signal next_op_buffer : std_logic_vector (BUFLEN-1 downto 0) := (others => '0');
	-- selected data fo next cycle's bit field which byte is valid in op_buffer
	signal next_op_valid : std_logic_vector (LEN-1 downto 0) := (others => '0');
	
	-- use the appropriate bytes only, where the value can appear
	-- with up to 3 byte alignment (MW=32) and 4 byte opcode
	--
	-- for the first byte in op_buffer, defines whether the byte is a prefix1
	-- (as fetch is aligned, only first byte can be prefix1)
	signal op_prefix1 : std_logic_vector(0 downto 0) := "0";
	-- for the first 2 bytes in op_buffer, defines whether the byte is a prefix2
	-- (as fetch is aligned, only first two bytes can be prefix2)
	signal op_prefix2 : std_logic_vector(1 downto 0) := (others => '0');
	-- for the first 3 bytes in op_buffer, defines whether the byte is a page prefix
	-- (as fetch is aligned, only first three bytes can be prefixp)
	signal op_prefixp : std_logic_vector(2 downto 0) := (others => '0');
	-- for the first 4 bytes in  in op_buffer, defines whether the byte is a possible opcode
	-- (as fetch is aligned, only first four bytes can be operation)
	signal op_op : std_logic_vector(3 downto 0) := (others => '0');

	-- where to write data that has been read from the bus
	-- valid between phi2 falling edges, transfers happen during phi2 falling
	signal prev_write_ptr : integer range -4 to LEN-5 := 0;
	-- where to write data in this cycle
	signal shift_write_ptr : integer range -4 to LEN-5 := 0;
		
	-- intermediate logic signals
	signal prefix1		: std_logic_vector (7 downto 0);
	signal prefix2		: std_logic_vector (7 downto 0);
	signal prefixp		: std_logic_vector (7 downto 0);
	signal opcode		: std_logic_vector (7 downto 0);
	
	-- TODO rework for MW=64
--	type parampos_t is range 0 to 7;
--   constant parampos_len : integer := 3;
	-- opcode is aligned, so parampos is same as oplength
	signal parampos : natural range 0 to 4 := 0;
	signal oplength : natural range 0 to 4 := 0;
	
	signal omapvalid : std_logic;
	
	signal parameter_int : std_logic_vector(W-1 downto 0);
	signal prefix_rs_int : rs_width;
	signal prefix_am_int : STD_LOGIC;
	signal prefix_um_int : STD_LOGIC;
	signal prefix_nf_int : STD_LOGIC;
	signal prefix_of_int : of_type;
	signal prefix_le_int : ext_type;		-- from prefix
	signal default_le_int : ext_type;	-- taken if no prefix given
	
   signal operation_int : cpu_operation;
   signal admode_int : cpu_syntax;
	signal parwidth_int : par_width;
	signal indwidth_int : rs_width;
	signal idxreg_int : idx_register;

	-- index of last byte of current opcode in buffer
	signal next_op_byte_ptr : natural range 0 to LEN-1 := 0;
	-- local
	signal next_op_byte_ptr_l : natural range 0 to LEN-1 := 0;

	-- internal signal if opcode is valid
	signal ovalid_int : std_logic;
	
	type decode_mode_t is (
		DECODE_INIT,			-- init
		DECODE_RESET,			-- doing a reset sequence
		DECODE_PC,				-- setting a new fetch address (PC)
		DECODE_FETCH,			-- fetching (standard)
		DECODE_WAIT,			-- wait after reset or error until new PC is set
		DECODE_INT,				-- doing an interrupt sequence
		DECODE_DRAIN			-- drain the buffer after abort detection,until empty
	);

	-- runtime states
	signal decode_mode : decode_mode_t := DECODE_INIT;
	signal last_decode_mode : decode_mode_t := DECODE_INIT;

	-- 
	--signal addr_align_vec : std_logic_vector(1 downto 0);
	
	--
	signal started_interrupt_int : std_logic;

	signal buf_lasterr : buserr_t;
		
begin

	-- determine what to do at the next falling phi2
	--
	-- The following actions are available:
	-- 1) we are not done yet decoding -> loop and read a new word
	-- 2) we are done decoding with an opcode, release the decoded information
	--    and prepare to decode the next opcode (which we may have already read)
	-- 3) initialize the fetch address counter with a new PC (from external module)
	-- 4) initialize the fetch logic with a new state like RESET, IRQ, ... (from external input)
	-- 5) find that the fetched opcode is illegal and start exception sequence
	--
	-- TODO: opmap should note when an opcode is a jmp/jsr/bra/bsr/rts/rti/brk/trp to stop prefetch
	--
	nextphi2 : process(decode_mode, reset, pcin_set, phi2, last_decode_mode,
						start_interrupt, started_interrupt_int, buf_lasterr, is_rollback) 
	begin
		decode_mode <= last_decode_mode;
		if (reset = '1') then 
			decode_mode <= DECODE_INIT;
		elsif (pcin_set = '1') then
			decode_mode <= DECODE_PC;
		elsif ((last_decode_mode = DECODE_FETCH or last_decode_mode = DECODE_DRAIN) 
			and (start_interrupt = '1' or is_rollback = '1')) then
			decode_mode <= DECODE_INT;
		elsif (last_decode_mode = DECODE_INIT) then
			decode_mode <= DECODE_RESET;
		elsif (last_decode_mode = DECODE_RESET) then
			decode_mode <= DECODE_WAIT;
		elsif (last_decode_mode = DECODE_INT) then
			if (started_interrupt_int = '1') then 
				decode_mode <= DECODE_WAIT;
			end if;
		elsif (not(buf_lasterr = beOK)) then
			decode_mode <= DECODE_DRAIN;
		elsif (not(last_decode_mode = DECODE_WAIT)) then
			decode_mode <= DECODE_FETCH;
		end if;
		
		if (falling_edge(phi2)) then
			last_decode_mode <= decode_mode;
		end if;
	end process;

	started_int_p : process(decode_mode, outrdy, phi2) 
	begin
		if (falling_edge(phi2)) then
			if (decode_mode = DECODE_INT and outrdy = '1') then
				started_interrupt_int <= '1';
			else
				started_interrupt_int <= '0';
			end if;
		end if;
	end process;
	started_interrupt <= started_interrupt_int;
	
	-- increment PC
	incpc : process(decode_mode, pcin, current_pc, phi2)
	begin
		if (falling_edge(phi2)) then
			if (decode_mode = DECODE_RESET) then
				current_pc <= (others => '0');
			elsif (decode_mode = DECODE_PC) then
				current_pc <= pcin;
			elsif (decode_mode = DECODE_FETCH or decode_mode = DECODE_DRAIN) then
				if (ovalid_int = '1' and outrdy = '1') then
					current_pc <= next_pc;
				end if;
			end if;
		end if;
	end process;
	
	-- count the read address
	-- The next read address is always aligned to the last read, so the next read
	-- address of a LONG fetch is at a 4-byte border for example
--	readcnt : process(phi2, current_addr, dvalid, decode_mode, dwidth, pcin)
--	begin
--		if (decode_mode = DECODE_RESET) then
--			next_addr <= (others => '0');
--		elsif (decode_mode = DECODE_PC) then
--			next_addr <= pcin;
--		elsif (dvalid = '1') then
--			case dwidth is 
--			when wBYTE =>
--				next_addr <= current_addr + 1;
--			when wWORD =>
--				next_addr (W-1 downto 1) <= current_addr (W-1 downto 1) + 1;
--				next_addr (0) <= '0';
--			when wLONG =>
--				next_addr (W-1 downto 2) <= current_addr (W-1 downto 2) + 1;
--				next_addr (1 downto 0) <= "00";
--			when wQUAD =>
--				next_addr (W-1 downto 4) <= current_addr (W-1 downto 4) + 1;
--				next_addr (3 downto 0) <= "0000";
--			end case;
--		else
--			next_addr <= current_addr;
--		end if;
--		if (falling_edge(phi2)) then
--			current_addr <= next_addr;
--		end if;
--	end process;
--
--	rdaddr <= next_addr;

	----------------------------------------------------------------------------------------------
	-- input data handling

	-- set up full width (restricting that would need a lot of conditional coding below)
	--
	din(31 downto MW) <= (others => '0');
	din(MW-1 downto 0) <= din_in;	

	din_width_valid_p : process(din, dwidth_bytes, dvalid_err)
	begin
		if (not(dvalid_err = beOK)) then
			din_valid_map <= "0000";
		else
			case dwidth_bytes is
			when 0 =>
				din_valid_map <= "0000";
			when 1 =>
				din_valid_map <= "0001";
			when 2 =>
				din_valid_map <= "0011";
			when 3 =>
				din_valid_map <= "0111";
			when 4 =>
				din_valid_map <= "1111";
			end case;
		end if;
	end process;

	-- align the data read such that the lowest byte in din_aligned holds the
	-- the byte from rdaddr; din holds byte from rdaddr but din is aligned to
	-- dwidth. I.e. if wBYTE is read, the address is exact; if wWORD is read,
	-- if rdaddr is odd (bit 0 is 1), the byte from rdaddr is in byte 1, not byte 0,
	-- and so on. Therefore the number of bytes read can have any value from 1 to 4 (MW=32).
	--
--	din_aligned_p : process(din, dwidth, dvalid, current_addr, dvalid_err)
--	begin
--		addr_align_vec <= current_addr(1 downto 0);
--
--		if (not(dvalid_err = beOK)) then
--			din_aligned <= din;
--			din_width_l <= 1;
--			din_valid_map <= "0000";
--		else
--			case dwidth is
--			when wBYTE =>
--				din_aligned <= din;
--				din_width_l <= 1;
--				din_valid_map <= "0001";
--			when wWORD =>
--				case current_addr(0) is
--				when '0' =>
--					din_aligned <= din;
--					din_width_l <= 2;
--					din_valid_map <= "0011";
--				when '1' =>
--					din_aligned(31 downto 24) <= (others => '0');
--					din_aligned(23 downto 0) <= din(31 downto 8);
--					din_width_l <= 1;
--					din_valid_map <= "0001";
--				when others =>
--				end case;
--			when wLONG =>
--				case addr_align_vec is 
--				when "00" =>
--					din_aligned <= din;
--					din_width_l <= 4;
--					din_valid_map <= "1111";
--				when "01" =>
--					din_aligned(31 downto 24) <= (others => '0');
--					din_aligned(23 downto 0) <= din(31 downto 8);
--					din_width_l <= 3;
--					din_valid_map <= "0111";
--				when "10" =>
--					din_aligned(31 downto 16) <= (others => '0');
--					din_aligned(15 downto 0) <= din(31 downto 16);
--					din_width_l <= 2;
--					din_valid_map <= "0011";
--				when "11" =>
--					din_aligned(31 downto 8) <= (others => '0');
--					din_aligned(7 downto 0) <= din(31 downto 24);
--					din_width_l <= 1;
--					din_valid_map <= "0001";
--				when others =>
--				end case;
--			when wQUAD =>
--				-- should not happen (MW=32)
--				din_aligned <= din;
--				din_width_l <= 1;
--				din_valid_map <= "0000";
--			end case;
--		end if;
--	end process;

	-- the sequencer automatically aligns it
	din_aligned <= din;
	din_width_l <= dwidth_bytes;
	
	din_width_p : process(din_width_l, phi2, reset)
	begin
		if (reset = '1') then
			din_width <= 0;
		elsif (falling_edge(phi2)) then
			if (dvalid = '1') then
				din_width <= din_width_l;
			else
				din_width <= 0;
			end if;
		end if;
	end process;
	
	-- prepare shifting op_buffer when current opcode is being removed
	-- by calculating next_op_buffer, next_op_valid
	--	
	next_op_buffer_p : process(op_buffer, op_valid, ovalid_int, prev_write_ptr, next_op_byte_ptr,
			din_width, outrdy, decode_mode, last_decode_mode)
	begin

		report "next_op_buffer_p";
		report integer'image(prev_write_ptr);
		report integer'image(next_op_byte_ptr);
		report integer'image(din_width);

		-- default
		next_op_buffer <= op_buffer;
		next_op_valid <= op_valid;

		-- TODO: this will most likely break if we experience wait states in the cycle
		-- after decode_mode...
		if (decode_mode = DECODE_PC or last_decode_mode = DECODE_PC) then
			shift_write_ptr <= 0;
		else
			shift_write_ptr <= prev_write_ptr + din_width;
		end if;
		
--		if (decode_mode = DECODE_PC) then
--			next_op_buffer <= (others => '0');
--			next_op_valid <= (others => '0');
		if (ovalid_int = '0' or outrdy = '0' or next_op_byte_ptr = 0) then
			next_op_buffer <= op_buffer;
			next_op_valid <= op_valid;
		else
				
			-- may become negative in case next_op_byte_ptr already includes 
			-- the read from the previous cycle
			shift_write_ptr <= prev_write_ptr - next_op_byte_ptr + din_width;
			
			case next_op_byte_ptr is
			when 0 =>
				next_op_buffer <= op_buffer;
				next_op_valid <= op_valid;
			when 1 =>
				-- shift buffer one byte
				next_op_buffer(BUFLEN-1 downto BUFLEN-8) <= (others => '0');
				next_op_buffer(BUFLEN-9 downto 0) <= op_buffer(BUFLEN-1 downto 8);
				next_op_valid(LEN-1) <= '0';
				next_op_valid(LEN-2 downto 0) <= op_valid(LEN-1 downto 1);
			when 2 =>
				-- shift buffer two bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-16) <= (others => '0');
				next_op_buffer(BUFLEN-17 downto 0) <= op_buffer(BUFLEN-1 downto 16);
				next_op_valid(LEN-1 downto LEN-2) <= (others => '0');
				next_op_valid(LEN-3 downto 0) <= op_valid(LEN-1 downto 2);
			when 3 =>
				-- shift buffer three bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-24) <= (others => '0');
				next_op_buffer(BUFLEN-25 downto 0) <= op_buffer(BUFLEN-1 downto 24);
				next_op_valid(LEN-1 downto LEN-3) <= (others => '0');
				next_op_valid(LEN-4 downto 0) <= op_valid(LEN-1 downto 3);
			when 4 =>
				-- shift buffer four bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-32) <= (others => '0');
				next_op_buffer(BUFLEN-33 downto 0) <= op_buffer(BUFLEN-1 downto 32);
				next_op_valid(LEN-1 downto LEN-4) <= (others => '0');
				next_op_valid(LEN-5 downto 0) <= op_valid(LEN-1 downto 4);
			when 5 =>
				-- shift buffer five bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-40) <= (others => '0');
				next_op_buffer(BUFLEN-41 downto 0) <= op_buffer(BUFLEN-1 downto 40);
				next_op_valid(LEN-1 downto LEN-5) <= (others => '0');
				next_op_valid(LEN-6 downto 0) <= op_valid(LEN-1 downto 5);
			when 6 =>
				-- shift buffer six bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-48) <= (others => '0');
				next_op_buffer(BUFLEN-49 downto 0) <= op_buffer(BUFLEN-1 downto 48);
				next_op_valid(LEN-1 downto LEN-6) <= (others => '0');
				next_op_valid(LEN-7 downto 0) <= op_valid(LEN-1 downto 6);
			when 7 =>
				-- shift buffer seven bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-56) <= (others => '0');
				next_op_buffer(BUFLEN-57 downto 0) <= op_buffer(BUFLEN-1 downto 56);
				next_op_valid(LEN-1 downto LEN-7) <= (others => '0');
				next_op_valid(LEN-8 downto 0) <= op_valid(LEN-1 downto 7);
			when 8 =>
				-- shift buffer eight bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-64) <= (others => '0');
				next_op_buffer(BUFLEN-65 downto 0) <= op_buffer(BUFLEN-1 downto 64);
				next_op_valid(LEN-1 downto LEN-8) <= (others => '0');
				next_op_valid(LEN-9 downto 0) <= op_valid(LEN-1 downto 8);
			when 9 =>
				-- shift buffer nine bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-72) <= (others => '0');
				next_op_buffer(BUFLEN-73 downto 0) <= op_buffer(BUFLEN-1 downto 72);
				next_op_valid(LEN-1 downto LEN-9) <= (others => '0');
				next_op_valid(LEN-10 downto 0) <= op_valid(LEN-1 downto 9);
			when 10 =>
				-- shift buffer ten bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-80) <= (others => '0');
				next_op_buffer(BUFLEN-81 downto 0) <= op_buffer(BUFLEN-1 downto 80);
				next_op_valid(LEN-1 downto LEN-10) <= (others => '0');
				next_op_valid(LEN-11 downto 0) <= op_valid(LEN-1 downto 10);
			when 11 =>
				-- shift buffer eleven bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-88) <= (others => '0');
				next_op_buffer(BUFLEN-89 downto 0) <= op_buffer(BUFLEN-1 downto 88);
				next_op_valid(LEN-1 downto LEN-11) <= (others => '0');
				next_op_valid(LEN-12 downto 0) <= op_valid(LEN-1 downto 11);
			when 12 =>
				-- shift buffer twelve bytes
				next_op_buffer(BUFLEN-1 downto BUFLEN-96) <= (others => '0');
				next_op_buffer(BUFLEN-97 downto 0) <= op_buffer(BUFLEN-1 downto 96);
				next_op_valid(LEN-1 downto LEN-12) <= (others => '0');
				next_op_valid(LEN-13 downto 0) <= op_valid(LEN-1 downto 12);
			when others =>
				-- should not happen
				--shift_write_ptr <= prev_write_ptr;
				next_op_buffer <= op_buffer;
				next_op_valid <= op_valid;
			end case;	
		end if;
	end process;


	prev_write_ptr_p : process (phi2, reset, shift_write_ptr,
				decode_mode)
	begin

--		report "op_buffer_p";
--		report integer'image(shift_write_ptr);
		
		if (reset = '1' or decode_mode = DECODE_PC) then
			prev_write_ptr <= 0;
		elsif (falling_edge(phi2)) then
			-- for each byte, decide where to get the new data from
			-- be it the shifted buffer, or the read data
			
			-- calculate write pointer
			prev_write_ptr <= shift_write_ptr after 5 ns;

		end if;
	end process;

	op_buffer_p : process (op_buffer, next_op_buffer, op_valid, next_op_valid, 
				din_aligned, dvalid, phi2, reset, ovalid_int, outrdy,
				decode_mode)
	begin

--		report "op_buffer_p";
--		report integer'image(shift_write_ptr);
		
		if (reset = '1' or decode_mode = DECODE_PC) then
			op_buffer <= (others => '0');
			op_valid <= (others => '0');
			buf_lasterr <= beOK;
						
		elsif (falling_edge(phi2)) then
			-- for each byte, decide where to get the new data from
			-- be it the shifted buffer, or the read data

			-- here's some stuff about VHDL that I do not understand.
			-- I was unable to define a signal that defines the value for 
			-- the case statement with the correct timing, to unify both branches.
			-- So I had to repeat the case statement in both branches 
			if (ovalid_int = '1' and outrdy = '1') then
				-- fill in shifted buffer
				op_buffer <= next_op_buffer;
				op_valid <= next_op_valid;
				
			end if;

			if (dvalid = '1' and not(decode_mode = DECODE_DRAIN)) then
				buf_lasterr <= dvalid_err;
				case shift_write_ptr is
				when 0 => 
					op_buffer(31 downto 0) <= din_aligned;
					op_valid(3 downto 0) <= din_valid_map;
				when 1 =>
					op_buffer(39 downto 8) <= din_aligned;
					op_valid(4 downto 1) <= din_valid_map;
				when 2 => 
					op_buffer(47 downto 16) <= din_aligned;
					op_valid(5 downto 2) <= din_valid_map;
				when 3 =>
					op_buffer(55 downto 24) <= din_aligned;
					op_valid(6 downto 3) <= din_valid_map;
				when 4 => 
					op_buffer(63 downto 32) <= din_aligned;
					op_valid(7 downto 4) <= din_valid_map;
				when 5 =>
					op_buffer(71 downto 40) <= din_aligned;
					op_valid(8 downto 5) <= din_valid_map;
				when 6 => 
					op_buffer(79 downto 48) <= din_aligned;
					op_valid(9 downto 6) <= din_valid_map;
				when 7 =>
					op_buffer(87 downto 56) <= din_aligned;
					op_valid(10 downto 7) <= din_valid_map;
				when 8 => 
					op_buffer(95 downto 64) <= din_aligned;
					op_valid(11 downto 8) <= din_valid_map;
				when 9 =>
					op_buffer(103 downto 72) <= din_aligned;
					op_valid(12 downto 9) <= din_valid_map;
				when 10 => 
					op_buffer(111 downto 80) <= din_aligned;
					op_valid(13 downto 10) <= din_valid_map;
				when 11 =>
					op_buffer(119 downto 88) <= din_aligned;
					op_valid(14 downto 11) <= din_valid_map;
				when 12 => 
					op_buffer(127 downto 96) <= din_aligned;
					op_valid(15 downto 12) <= din_valid_map;
				when 13 => 
					op_buffer(135 downto 104) <= din_aligned;
					op_valid(16 downto 13) <= din_valid_map;
				when 14 => 
					op_buffer(143 downto 112) <= din_aligned;
					op_valid(17 downto 14) <= din_valid_map;
				when 15 => 
					op_buffer(151 downto 120) <= din_aligned;
					op_valid(18 downto 15) <= din_valid_map;
				when others =>
				end case;

			end if;
			
			-- now write data that has been read
			if (not(din_width = 0)) then
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------------------------
	-- op_buffer analysis
	
	
	-- find whether a buffer value actually is a prefix, or opcode
	decgen_prefix1 : for i in 0 to 0 generate
	begin
			op_prefix1(i) <= '1' when (op_valid(i)='1') 
											and (op_buffer(i*8)='1') 
											and (op_buffer(i*8+1)='1') 
											and (op_buffer(i*8+3)='0')
											and not(
												op_buffer(i*8+2)='0' and op_buffer(i*8+4)='0'
												and op_buffer(i*8+5)='0' and op_buffer(i*8+6)='0'
												and op_buffer(i*8+7)='0')
									else '0';
	end generate;
	
	decgen_prefix2 : for i in 0 to 1 generate
	begin
			op_prefix2(i) <= '1' when (op_valid(i)='1') 
											and (op_buffer(i*8)='1') 
											and (op_buffer(i*8+1)='1') 
											and (op_buffer(i*8+2)='0') 
											and (op_buffer(i*8+3)='1') 
											and not(
												op_buffer(i*8+4)='0'
												and op_buffer(i*8+5)='0' and op_buffer(i*8+6)='0'
												and op_buffer(i*8+7)='0')
									else '0';
	end generate;
	
	decgen_prefixp : for i in 0 to 2 generate
	begin
			op_prefixp(i) <= '1' when (op_valid(i)='1') 
											and (op_buffer(i*8)='1') 
											and (op_buffer(i*8+1)='1') 
											and (op_buffer(i*8+2)='1') 
											and (op_buffer(i*8+3)='1') 
											and (op_buffer(i*8+4)='0') 
									else '0';
	end generate;
	
	op_op(0) <= '1' when (op_valid(0) = '1')
									and op_prefix1(0) = '0'
									and op_prefix2(0) = '0'
									and op_prefixp(0) = '0'
							else '0';
	op_op(1) <= '1' when (op_valid(1) = '1')
									and op_prefix2(1) = '0'
									and op_prefixp(1) = '0'
							else '0';
	op_op(2) <= '1' when (op_valid(2) = '1')
									and op_prefixp(2) = '0'
							else '0';
	op_op(3) <= '1' when (op_valid(3) = '1')
							else '0';
	
	-- now that we have the valid opcode bytes in op_buffer (with appropriate flags in op_*),
	-- we can go on with finding the actual opcode and prefix bits
	-- finding the actual opcode and parameter index depends on which prefixes are used
	-- it is independent from the memory widths, as op_buffer is aligned
	--
	-- find the actual prefix and opcode values. Kind of crossbar
	-- prefix one is simple, as it can only be the very first byte
	-- For the other values we have to take into account if previous prefixes (e.g. prefix1) exist
	
	-- prefix 1
	prefix1 <= op_buffer(7 downto 0) when op_prefix1(0) = '1' else (others => '0');
	
	getpref : process(op_buffer, op_prefix1, op_prefix2, op_prefixp, op_op, reset)
	begin
		-- prefix 2
		if ((op_prefix1(0) = '0') and op_prefix2(0) = '1') then
			prefix2 <= op_buffer(7 downto 0);
		elsif ((op_prefix1(0) = '1') and op_prefix2(1) = '1') then
			prefix2 <= op_buffer(15 downto 8);
		else
			prefix2 <= (others => '0');
		end if;
		
		-- prefix p
		if (op_prefix1(0) = '0' and op_prefix2(0) = '0' and op_prefixp(0) = '1') then
			prefixp <= op_buffer(7 downto 0);
		elsif (op_prefix1(0) = '0' and op_prefix2(0) = '1' and op_prefixp(1) = '1') then
			prefixp <= op_buffer(15 downto 8);
		elsif (op_prefix1(0) = '1' and op_prefix2(0) = '0' and op_prefixp(1) = '1') then
			prefixp <= op_buffer(15 downto 8);
		elsif (op_prefix1(0) = '1' and op_prefix2(1) = '1' and op_prefixp(2) = '1') then
			prefixp <= op_buffer(23 downto 16);
		else
			prefixp <= (others => '0');
		end if;
		
		-- opcode
		if (reset = '1') then
			parampos <= 0;
			oplength <= 0;
			opcode <= (others => '0');
		elsif (op_prefix1(0) = '0' and op_prefix2(0) = '0' and op_prefixp(0) = '0' and op_op(0) = '1') then
			opcode <= op_buffer(7 downto 0);
			parampos <= 1;
			oplength <= 1;
		elsif (( (op_prefix1(0) = '1' and op_prefix2(1) = '0' and op_prefixp(1) = '0')
				or (op_prefix1(0) = '0' and op_prefix2(0) = '1' and op_prefixp(1) = '0')
				or (op_prefix1(0) = '0' and op_prefix2(0) = '0' and op_prefixp(0) = '1') )
				and op_op(1) = '1') then
			opcode <= op_buffer(15 downto 8);
			parampos <= 2;
			oplength <= 2;
		elsif (( (op_prefix1(0) = '1' and op_prefix2(1) = '1' and op_prefixp(2) = '0')
				or (op_prefix1(0) = '1' and op_prefix2(1) = '0' and op_prefixp(1) = '1')
				or (op_prefix1(0) = '0' and op_prefix2(0) = '1' and op_prefixp(1) = '1') )
				and op_op(2) = '1') then
			opcode <= op_buffer(23 downto 16);
			parampos <= 3;
			oplength <= 3;
		elsif (op_prefix1(0) = '1' and op_prefix2(1) = '1' and op_prefixp(2) = '1' and op_op(3) = '1') then
			opcode <= op_buffer(31 downto 24);
			parampos <= 4;
			oplength <= 4;
		else
			opcode <= (others => '0');
			parampos <= 0;
			oplength <= 0;
		end if;
		
	end process;
	
	--------------------------------------------------------------------------
	-- now finally set some of the output signals
	--
	
	prefix_um_int <= prefix2(7);
	prefix_nf_int <= prefix2(4);
	prefix_am_int <= prefix1(2);
	
	doprefrs : process(prefix1(4), prefix1(5))
	begin
		if (prefix1(4) = '1' and prefix1(5) = '0') then
			prefix_rs_int <= wWORD;
		elsif (prefix1(4) = '0' and prefix1(5) = '1') then
			prefix_rs_int <= wLONG;
		elsif (prefix1(4) = '1' and prefix1(5) = '1') then
			prefix_rs_int <= wQUAD;
		else
			prefix_rs_int <= wBYTE;
		end if;
	end process;
	
	doprefle : process(prefix2, default_le_int)
	begin
		if (prefix2(0) = '0') then
			-- prefix has not been set, as all prefix2 have odd values
			prefix_le_int <= default_le_int;
		else
			if (prefix2(5) = '1' and prefix2(6) = '0') then
				prefix_le_int <= eSIGN;
			elsif (prefix2(5) = '0' and prefix2(6) = '1') then
				prefix_le_int <= eZERO;
			elsif (prefix2(5) = '1' and prefix2(6) = '1') then
				prefix_le_int <= eONE;
			else
				prefix_le_int <= eNONE;
			end if;
		end if;
	end process;

	doprefof : process(prefix1)
	begin
		if (prefix1(6) = '1' and prefix1(7) = '0') then
			prefix_of_int <= oPC;
		elsif (prefix1(6) = '0' and prefix1(7) = '1') then
			prefix_of_int <= oSP;
		elsif (prefix1(6) = '1' and prefix1(7) = '1') then
			prefix_of_int <= oBASE;
		else
			prefix_of_int <= oNONE;
		end if;
	end process;
	
	param : process(op_buffer, parampos)
	begin
		case parampos is
			when 1 =>
				parameter_int(W-1 downto 0) <= op_buffer(W+7 downto 8);
			when 2 =>
				parameter_int(W-1 downto 0) <= op_buffer(W+15 downto 16);
			when 3 =>
				parameter_int(W-1 downto 0) <= op_buffer(W+23 downto 24);
			when 4 =>
				parameter_int(W-1 downto 0) <= op_buffer(W+31 downto 32);
			-- opcode is aligned in op_buffer, so param starts max at 4 or earlier
--			when 5 =>
--				parameter_int(W-1 downto 0) <= op_buffer(W+39 downto 40);
--			when 6 =>
--				parameter_int(W-1 downto 0) <= op_buffer(W+47 downto 48);
--			when 7 =>
--				parameter_int(W-1 downto 0) <= op_buffer(W+55 downto 56);
			when others =>
				parameter_int <= (others => '0');
		end case;
	end process;
	
	-- find the actual operation, syntax mode, and parameter width
	-- for the opcode. Use the opcode map component for this. Note: no
	-- generics dependency :-)
	opmap : af65002opmap 
	port map (
			opcode,
			prefixp,
			prefix_rs_int,
			prefix_am_int,
			-- true when valid
			omapvalid,
			operation_int,
			-- parameter length and syntax together define the addressing mode
			-- e.g. syntax=ABSOLUTE and parlen=wBYTE is zeropage addressing
			parwidth_int,
			indwidth_int,
			admode_int,
			idxreg_int,
			default_le_int
	);

	donextpc : process(parwidth_int, parampos, omapvalid, current_pc, oplength)
	begin
		if (omapvalid = '0') then
			next_pc <= current_pc;
			next_pc_m1 <= current_pc;
		else
			case parwidth_int is
			when pNONE =>
				--next_pc_m1 <= current_pc + std_logic_vector(to_unsigned(parampos, parampos_len)) - 1;
				next_pc_m1 <= current_pc + oplength - 1;
				next_pc    <= current_pc + oplength;
			when pBYTE =>
				--next_pc_m1 <= current_pc + std_logic_vector(to_unsigned(parampos, parampos_len));
				next_pc_m1 <= current_pc + oplength;
				next_pc    <= current_pc + oplength + 1;
			when pWORD =>
				--next_pc_m1 <= current_pc + std_logic_vector(to_unsigned(parampos, parampos_len)) + 1;
				next_pc_m1 <= current_pc + oplength + 1;
				next_pc    <= current_pc + oplength + 2;
			when pLONG =>
				--next_pc_m1 <= current_pc + std_logic_vector(to_unsigned(parampos, parampos_len)) + 3;
				next_pc_m1 <= current_pc + oplength + 3;
				next_pc    <= current_pc + oplength + 4;
			when pQUAD =>
				--next_pc_m1 <= current_pc + std_logic_vector(to_unsigned(parampos, parampos_len)) + 7;
				next_pc_m1 <= current_pc + oplength + 7;
				next_pc    <= current_pc + oplength + 8;
			end case;
		end if;
	end process;
		
	-- find out if we're done. We need to check if we've got all of our parameter
	-- bytes read already; iterate over all values of parampos
	donegen : process(op_valid, parwidth_int, parampos, omapvalid, current_pc, reset, decode_mode)
	begin
		if (omapvalid = '0' or (not(decode_mode = DECODE_FETCH) and not(decode_mode = DECODE_DRAIN))) then
			ovalid_int <= '0';
			next_op_byte_ptr_l <= 0;
		else
			case parampos is
			when 1 =>
				case parwidth_int is
				when pNONE => -- we use 0
					ovalid_int <= '1';
					next_op_byte_ptr_l <= 1;
				when pBYTE => -- we use 0,1
					ovalid_int <= op_valid(1);
					next_op_byte_ptr_l <= 2;
				when pWORD => -- we use 0,1,2
					ovalid_int <= op_valid(2);
					next_op_byte_ptr_l <= 3;
				when pLONG => -- we use 0,1,2,3,4
					ovalid_int <= op_valid(4);
					next_op_byte_ptr_l <= 5;
				when pQUAD => -- we use 0,1,2,3,4,5,6,7,8
					ovalid_int <= op_valid(8);
					next_op_byte_ptr_l <= 9;
				end case;
			when 2 =>
				case parwidth_int is
				when pNONE => -- uses 1
					ovalid_int <= '1';
					next_op_byte_ptr_l <= 2;
				when pBYTE => -- uses 1,2
					ovalid_int <= op_valid(2);
					next_op_byte_ptr_l <= 3;
				when pWORD => -- uses 1,2,3
					ovalid_int <= op_valid(3);
					next_op_byte_ptr_l <= 4;
				when pLONG => -- uses 1,2,3,4,5
					ovalid_int <= op_valid(5);
					next_op_byte_ptr_l <= 6;
				when pQUAD => -- uses 1,2,3,4,5,6,7,8,9
					ovalid_int <= op_valid(9);
					next_op_byte_ptr_l <= 10;
				end case;
			when 3 =>
				case parwidth_int is
				when pNONE => -- uses 2
					ovalid_int <= '1';
					next_op_byte_ptr_l <= 3;
				when pBYTE => -- uses 2,3
					ovalid_int <= op_valid(3);
					next_op_byte_ptr_l <= 4;
				when pWORD => -- uses 2,3,4
					ovalid_int <= op_valid(4);
					next_op_byte_ptr_l <= 5;
				when pLONG => -- uses 2,3,4,5,6
					ovalid_int <= op_valid(6);
					next_op_byte_ptr_l <= 7;
				when pQUAD => -- uses 2,3,4,5,6,7,8,9,10
					ovalid_int <= op_valid(10);
					next_op_byte_ptr_l <= 11;
				end case;
			when 4 =>
				case parwidth_int is
				when pNONE => -- uses 3
					ovalid_int <= '1';
					next_op_byte_ptr_l <= 4;
				when pBYTE => -- uses 3,4
					ovalid_int <= op_valid(4);
					next_op_byte_ptr_l <= 5;
				when pWORD => -- uses 3,4,5
					ovalid_int <= op_valid(5);
					next_op_byte_ptr_l <= 6;
				when pLONG => -- uses 3,4,5,6,7
					ovalid_int <= op_valid(7);
					next_op_byte_ptr_l <= 8;
				when pQUAD => -- uses 3,4,5,6,7,8,9,10,11
					ovalid_int <= op_valid(11);
					next_op_byte_ptr_l <= 12;
				end case;
			-----------------------
			-- note that any parampos of >=5 is can only happen when the opcode
			-- is not aligned with the start of the buffer!
		  when others =>
				ovalid_int <= '0';
				next_op_byte_ptr_l <= 0;
		  end case;
		end if;
	end process;
	
	next_op_byte_ptr <= next_op_byte_ptr_l when ovalid_int = '1' else 0;
	
	-- set when trying to fetch next input into buffer;
	-- length restricted, so it does not overflow and does not do too much overhead on jmp:
	-- MW=32 hard stop: substract 8 from end of buffer, which means last cycle fetch has consumed max 4,
	-- and this cycle's fetch finally fills the buffer (with MW=32, i.e. max length = 4 byte)
	rdvalid <= '0' when not(decode_mode = DECODE_FETCH 
								or decode_mode = DECODE_PC
								or decode_mode = DECODE_DRAIN) else
					-- hard stop at end of buffer
					'0' when (prev_write_ptr > (LEN-8)) else 
					-- stop after two(?) prefetch ops
					'0' when (ovalid_int = '1' --and outrdy = '0'
								and (prev_write_ptr > (next_op_byte_ptr + 7))) else
					'1';
	
	-- generate the output
	output : process(phi2, parameter_int, ovalid_int, operation_int, parwidth_int, admode_int,
			prefix_rs_int, prefix_am_int, prefix_of_int, prefix_le_int, prefix_nf_int, prefix_um_int,
			next_pc, next_pc_m1, decode_mode, idxreg_int, indwidth_int, current_pc, irqlevel_in,
			is_hypervisor, buf_lasterr, is_rollback, rollback_abort_vec, rollback_pc)
	begin
		if (decode_mode = DECODE_RESET) then
			parameter <= parameter_int;
			prefix_rs <= wWORD;
			prefix_of <= oNONE;
			prefix_nf <= '0';
			prefix_um <= '0';
			prefix_le <= eNONE;
			parwidth <= pNONE;
			indwidth <= wBYTE;
			idxreg <= iXR;
			admode <= sIMPLIED;
			operation <= xRESET;
			parameter <= (others => '0');
			pc_out <= (others => '0');
			pc_op_end <= (others => '0');
			pc_op_next <= (others => '0');
			ovalid <= '1';
		elsif (decode_mode = DECODE_INT and is_rollback = '0') then
			parameter(W-1 downto 3) <= (others => '0');
			parameter(2 downto 0) <= irqlevel_in;
			prefix_rs <= max_width(W);		-- width of the interrupt return address (unused)
			prefix_of <= oNONE;
			prefix_nf <= '0';
			prefix_um <= '0';
			prefix_le <= eNONE;
			parwidth <= pNONE;
			indwidth <= wBYTE;
			idxreg <= iXR;
			admode <= sIMPLIED;
			if (irqlevel_in = "000") then
				operation <= xNMI;
			else
				operation <= xIRQ;
			end if;
			pc_out <= current_pc;
			pc_op_end <= (others => '0');
			pc_op_next <= (others => '0');
			ovalid <= '1';			
		elsif (is_rollback = '1' or (is_hypervisor = '0' and prefix_um_int = '1')) then
			-- user mode prefix bit is set in user mode (virtualization req.)
			parameter(W-1 downto 4) <= (others => '0');
			if (is_rollback = '1') then
				parameter(3 downto 0) <= rollback_abort_vec;
				pc_out <= rollback_pc;
			else
				parameter(3 downto 0) <= abUMODE;
				pc_out <= current_pc;
			end if;
			prefix_rs <= max_width(W);		-- width of the interrupt return address (unused)
			prefix_of <= oNONE;
			prefix_nf <= '0';
			prefix_um <= '0';
			prefix_le <= eNONE;
			parwidth <= pNONE;
			indwidth <= wBYTE;
			idxreg <= iXR;
			admode <= sIMPLIED;
			operation <= xABORT;
			pc_op_end <= (others => '0');
			pc_op_next <= (others => '0');
			ovalid <= '1';
		elsif (ovalid_int ='0' and not(buf_lasterr = beOK)) then
			-- user mode prefix bit is set in user mode (virtualization req.)
			parameter(W-1 downto 4) <= (others => '0');
			parameter(3 downto 0) <= fetch_buserr_abort_vec(buf_lasterr);
			prefix_rs <= max_width(W);		-- width of the interrupt return address (unused)
			prefix_of <= oNONE;
			prefix_nf <= '0';
			prefix_um <= '0';
			prefix_le <= eNONE;
			parwidth <= pNONE;
			indwidth <= wBYTE;
			idxreg <= iXR;
			admode <= sIMPLIED;
			operation <= xABORT;
			pc_out <= current_pc;
			pc_op_end <= (others => '0');
			pc_op_next <= (others => '0');
			ovalid <= '1';			
		else
			parameter <= parameter_int;
			prefix_rs <= prefix_rs_int;
			prefix_of <= prefix_of_int;
			prefix_le <= prefix_le_int; -- TODO use default when no explicit prefix given
			prefix_nf <= prefix_nf_int;
			prefix_um <= prefix_um_int;
			
			parwidth <= parwidth_int;
			indwidth <= indwidth_int;
			idxreg <= idxreg_int;
			admode <= admode_int;
			operation <= operation_int;
			pc_out <= current_pc;
			pc_op_end <= next_pc_m1;
			pc_op_next <= next_pc;
			ovalid <= ovalid_int;
		end if;
	end process;
	
end Behavioral;

