----------------------------------------------------------------------------------
--
--    Read/write sequencer for a af65k CPU. 
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
-- 	entity: 		af65002sequencer
--		purpose:		sequences wide memory accesses into smaller ones,
--						e.g. a LONG read into four BYTE reads etc.
--		features:	up to 32bit memory interface.
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all; 
use ieee.std_logic_signed.all; 
library af65002;
use af65002.af65k.all;


entity af65002sequencer is

	-- TODO: memory lock
	
	Generic (
		W : integer;
		MW : integer
	);
	Port (
	  -- clock
	  reset : in std_logic;
	  phi2  : in std_logic;
	  
	  -- this signal can be used by an interrupt controller
	  -- to schedule interrupts to a "free" CPU
	  -- signals to the outside if we're running in hypervisor mode
	  is_hypervisor : out std_logic;
	  
	  -- interrupt level coming in from the interrupt controller
	  -- if this level is lower than the current level (irqlevel_out)
	  -- then a new interrupt sequence will be started
	  irqlevel_in : in irqlevel_t;
	  -- internal interrupt level; will be set when an interrupt sequence
	  -- is being started, or SEI/CLI are executed
	  irqlevel_out : out irqlevel_t;

		-- bus interface
		A : out  STD_LOGIC_VECTOR (W-1 downto 0);
		ISVALID : out STD_LOGIC;							-- true when address valid
      RNW : out  STD_LOGIC;
		DWIDTH_OUT : out std_logic_vector(1 downto 0);	-- which width should the data transfer have?
		RW_TYPE : out memrw_t;						-- what type of transfer is intended
		RW_HYPER : out std_logic;
		
		RDY : in STD_LOGIC;									-- true when data transferred (sampled at falling phi2)
		BUSERR : in buserr_t;								-- when RDY is set, signals error condition to core
		-- actual data transfer width
		-- async signal, must be valid before the data-transfer falling edge of phi2,
		-- used to determine address offset, which will be sampled at falling phi2
		DWIDTH_IN : in std_logic_vector(1 downto 0);	
		
		-- data transfer; DIN is valid after falling phi2; 
		-- DIN is aligned on DIN_WIDTH boundaries
      DIN : in  STD_LOGIC_VECTOR (MW-1 downto 0);
		-- data transfer; DOUT should be sampled on falling phi2
		-- DOUT is created such that any external width works:
		-- 	- on long-aligned addresses, no extra is done, DWIDTH_OUT can have LONG,
		--			but DWIDTH_IN returns the actual amount of tranferred data
		--		- on +1 addresses, the low 8 bits mirror the bits 8-15
		--		- on +2 addresses, the low 16 bits mirror the bits 16-31
		--		- on +3 addresses, the low 8 bits mirror 24-31, but also
		--			bits 8-15 mirror the bits 24-31.
		-- this allows valid transfers on byte, word and long widths no matter the alignment
		-- callers need to determine valid bytes by comparing lowest address bits with 
		-- DWIDTH_OUT
      DOUT : out  STD_LOGIC_VECTOR (MW-1 downto 0);

	  -- external SO input
	  ext_so_in : in std_logic;
	  
	  -- (runtime) configuration settings
	  -- interrupts affected by SEI in user mode
	  user_irqlevel : in irqlevel_t;
	  -- width for user mode
	  user_width : in rs_width;
	  -- stack restricted to 256 byte
	  is_restricted_stack : in std_logic
	);
	
end af65002sequencer;

architecture Behavioral of af65002sequencer is

	-- NOTE: width values are taken for M max. 64 and MW max 32
	-- It is assumed that the compiled optimizes the unused bits away.
	constant Wmax : integer := 64;
	constant MWmax : integer := 32;

	component af65002core is

		Generic (
			W : integer;
			MW : integer
		);
		Port ( 
			  -- clock
			  reset : in std_logic;
			  phi2  : in std_logic;
			  
			  -- those two signals can be used by an interrupt controller
			  -- to schedule interrupts to a "free" CPU
			  -- signals to the outside if we're running in hypervisor mode
			  is_hypervisor : out std_logic;
			  
			  -- interrupt level coming in from the interrupt controller
			  -- if this level is lower than the current level (irqlevel_out)
			  -- then a new interrupt sequence will be started
			  irqlevel_in : in irqlevel_t;
			  -- internal interrupt level; will be set when an interrupt sequence
			  -- is being started, or SEI/CLI are executed
			  irqlevel_out : out irqlevel_t;
			  
			  -- operation interface
			  -- Each memory operation has two cycles. On cycle one, take_addr is set and
			  -- addr_out (plus memrw_type) contain a memory address to be put to the 
			  -- address lines. On the second cycle, is_memrw signals a memory access,
			  -- and when is_memrw_done is set, the core takes the data read from data_in_outbus
			  -- Both cycles can interleave, i.e. cycle 2 for the first memory operation
			  -- can be cycle 1 for the second operation etc.
			  -- cycle 1 and cycle need not follow directly. address can be taken and the actual
			  -- cycle only follows two or even more cycles later. There can be even two
			  -- cycle 2 operations for a single cycle 1 - think read/modify/write opcodes.
			  --
			  -- cycle 1
			  take_addr : out std_logic;		-- set when addr_out has address to store
			  addr_out : out std_logic_vector(W-1 downto 0);
			  memrw_type : out memrw_t;		-- type of access (taken when take_addr is set, like addr_out)
			  memrw_hyper : out std_logic;	-- set when access to hypervisor memory
			  -- cycle 2
			  is_memrw : out std_logic;		-- do the memory access (usually one cycle after take_addr)
			  memrw_width : out rs_width;		-- what width to read
			  mem_rnw : out std_logic;			-- 1 on read, 0 on write
			  -- result
			  is_memrw_done : in std_logic;	-- set when data transfer is done
			  is_memrw_err : in buserr_t;		-- set when data transfer is trapped on an error
  			  -- buffered data from DIN
			  memrw_data_in : in std_logic_vector(W-1 downto 0);
			  -- data out to write
			  memrw_data_out : out std_logic_vector(W-1 downto 0);

			  -- fetch interface
			  -- fetched data in fetch_data_in is always expected to be aligned to the fetch address
			  fetch_addr : out std_logic_vector(W-1 downto 0);
			  fetch_addr_valid : out std_logic;		-- when set, a new address to start fetch stream is valid in fetch_addr
			  fetch_is_active : out std_logic;		-- when active is set, decode takes more input
			  is_fetch_data_valid : in std_logic; 	-- set when the fetch data is done
			  is_fetch_data_err : in buserr_t;		-- set when .._data_valid is set and error has occurred
			  fetch_hyper : out std_logic;			-- set when fetch from hypervisor mode
			  -- buffered data from DIN
			  fetch_data_in : in std_logic_vector(MW-1 downto 0);
			  -- width of data read
			  fetch_data_in_bytes : natural range 0 to 4;	-- (MW=32)
			  			  
			  -- external SO input
			  ext_so_in : in std_logic;
			  
			  -- (runtime) configuration settings
			  -- interrupts affected by SEI in user mode
			  user_irqlevel : in irqlevel_t;
			  -- width for user mode
			  user_width : in rs_width;
			  -- stack restricted to 256 byte
			  is_restricted_stack : in std_logic
		);

	end component;

	
	-- din width latched at raising edge of phi2
	signal dwidth_in_br : rs_width;
	signal dwidth_in_b : rs_width;
	
	-- sequencer state
	signal is_fetch : std_logic;
	signal is_memrw : std_logic;
	
	-- fetch signals
	--
	-- signal to take address
	signal fetch_take_addr : std_logic;
	-- fetch address input from core
	signal fetch_addr : std_logic_vector(W-1 downto 0);
	-- temporary fetch address counter
	signal fetch_addr_cnt : std_logic_vector(W-1 downto 0);	
	signal fetch_addr_cnt01 : std_logic_vector(1 downto 0);	-- slice with lowest two bits
	-- fetch data
	signal fetch_data_in : std_logic_vector(MWmax-1 downto 0);
	-- fetch data width
	signal fetch_data_in_bytes : natural range 0 to 4;
	-- is fetch active?
	signal fetch_is_active : std_logic;
	-- is fetch hypervisor
	signal fetch_hyper : std_logic;
	-- 
	signal is_fetch_data_valid : std_logic;
	
	-- memrw signals
	--
	-- signel to take addr
	signal memrw_take_addr : std_logic;
	-- memrw address input from core
	signal memrw_addr : std_logic_vector(W-1 downto 0);
	-- memrw address input from core, buffered for R/M/W cycles
	signal memrw_addr_b : std_logic_vector(W-1 downto 0);
	-- temporary fetch address counter
	signal memrw_addr_cnt : std_logic_vector(W-1 downto 0);	
	signal memrw_addr_cnt01 : std_logic_vector(1 downto 0);	-- slice with lowest two bits
	-- memrw data on read
	signal memrw_data_in : std_logic_vector(Wmax-1 downto 0);
	-- memrw data on read, aligned
	signal memrw_data_in_aligned : std_logic_vector(MWmax-1 downto 0);
	-- buffered input data to combine multi-reads
	signal memrw_data_in_b : std_logic_vector(Wmax-1 downto 0);

	-- memrw width on core side
	signal memrw_width : rs_width;
	-- memrw data width on bus side (when core tx is split)
	signal memrw_bus_width : rs_width;
	
	-- number of valid bytes on transfer
	signal memrw_byte_num : natural range 0 to 4;	--	(MW=32)
	-- set on last cycle of memrw cycle
	signal memrw_tx_done : std_logic;
	-- set on last cycle of memrw cycle, buffered by one cycle
	signal memrw_tx_done_b : std_logic;
	-- total byte counter for memrw transfer tx
	signal memrw_bytes_transferred : natural range 0 to 8;	-- (MW=32)
	signal memrw_next_bytes_transferred : natural range 0 to 8;	-- (MW=32)
	
	-- data output from core (full width to reduce generate logic)
	signal memrw_data_out : std_logic_vector(Wmax-1 downto 0);
	-- data output from core (full width to reduce generate logic) - buffered during write seqs
	signal memrw_data_out_b : std_logic_vector(Wmax-1 downto 0);
	-- aligned to number of bytes already transferred
	signal memrw_data_out_aligned : std_logic_vector(Wmax-1 downto 0);
	
	signal memrw_type : memrw_t;
	signal memrw_hyper : std_logic;
	signal memrw_rnw : std_logic;
	
	-- error handling
	signal is_memrw_err : buserr_t;
	signal is_fetch_data_err : buserr_t;
	
	--------------------------
	-- signal extension to handle W/MW mismatches
	signal DIN_X : std_logic_vector(MWmax-1 downto 0);
	
begin

	DIN_X(MWmax-1 downto MW) <= (others => '0');
	DIN_X(MW-1 downto 0) <= DIN;
	
	memrw_tx_done_b_p : process(reset, phi2, memrw_tx_done)
	begin
		if (reset = '1') then
			memrw_tx_done_b <= '0';
		elsif (falling_edge(phi2)) then
			memrw_tx_done_b <= memrw_tx_done;
		end if;
	end process;
	
	din_width_br_p : process(reset, phi2, DWIDTH_IN)
	begin
		if (reset = '1') then
			dwidth_in_br <= wBYTE;
		elsif (rising_edge(phi2)) then
			dwidth_in_br <= rs_width_slv(DWIDTH_IN);
		end if;
	end process;

	errors_t : process(reset, phi2, RDY, BUSERR, is_fetch, is_memrw)
	begin
		if (reset = '1') then
			is_memrw_err <= beOK;
			is_fetch_data_err <= beOK;
		elsif (falling_edge(phi2)) then
			if (is_fetch = '1' and RDY = '1') then
				is_fetch_data_err <= BUSERR;
			end if;
			if (is_memrw = '1' and RDY = '1') then
				is_memrw_err <= BUSERR;
			end if;
		end if;
	end process;
	
	-----------------------------------------------------------------------
	-- memrw handling
	
	-- calculate the number of valid bytes (may be more than requested)
	-- calculated asynchronously during data transfer from DIN_WIDTH
	-- and memrw_addr_cnt.
	memrw_byte_num_p : process(dwidth_in_br, memrw_addr_cnt, memrw_addr_cnt01)
	begin
		memrw_byte_num <= 1;
		case dwidth_in_br is
		when wBYTE => 
			memrw_byte_num <= 1;
		when wWORD =>
			case memrw_addr_cnt(0) is
			when '0' =>
				memrw_byte_num <= 2;
			when '1' =>
				memrw_byte_num <= 1;
			when others =>
				memrw_byte_num <= 1;		-- 0 is not in range
			end case;
		when wLONG =>
			case memrw_addr_cnt01 is
			when "00" =>
				memrw_byte_num <= 4;
			when "01" =>
				memrw_byte_num <= 3;
			when "10" =>
				memrw_byte_num <= 2;
			when "11" =>
				memrw_byte_num <= 1;
			when others =>
				memrw_byte_num <= 0;		
			end case;
		when wQUAD =>
			-- should not happen (MW=32)
		end case;
	end process;
	
	-- needs to be valid before falling phi2
	memrw_next_bytes_transferred <= memrw_bytes_transferred + memrw_byte_num;
	memrw_tx_done <= '1' when 
				(RDY = '1' and not(BUSERR = beOK))
				or (memrw_next_bytes_transferred >= rs_width_bytes(memrw_width))
				else '0' after 2 ns;
	
	-- calculate fetch_addr_cnt for the next fetch
	-- evaluated at falling phi2
	memrw_addr_p : process(reset, phi2, is_memrw, memrw_addr, memrw_take_addr, 
			memrw_addr_cnt, RDY)
	begin
		if (reset = '1') then
			memrw_addr_b <= (others => '0');
			memrw_addr_cnt <= (others => '0');
			memrw_bytes_transferred <= 0;
		elsif (falling_edge(phi2)) then
			if (memrw_take_addr = '1') then
				memrw_addr_b <= memrw_addr;
			end if;
			
			if (memrw_take_addr = '1' or memrw_tx_done = '1') then
				if (memrw_take_addr = '1') then
					memrw_addr_cnt <= memrw_addr;
				else
					-- reset address for R/M/W cycles
					memrw_addr_cnt <= memrw_addr_b;
				end if;
				memrw_bytes_transferred <= 0;
			elsif (is_memrw = '1' and RDY = '1') then
				-- calculate next fetch address such that it is aligned
				memrw_addr_cnt <= memrw_addr_cnt + memrw_byte_num;
				memrw_bytes_transferred <= memrw_next_bytes_transferred;
			end if;
		end if;
	end process;
	memrw_addr_cnt01 <= memrw_addr_cnt(1 downto 0);
	
	-- the data that is written from the core is latched in the first write cycle
	-- this way the core could actually continue doing other stuff...
	-- in fact this is to avoid the problem (with PHA.W) that during the write cycle
	-- the control section already prepares to read from another register, so 
	-- during the second write cycle, the data from the core is already invalid!
	memrw_data_out_b_p : process(reset, phi2, memrw_tx_done, memrw_tx_done_b, memrw_data_out)
	begin
		if (reset = '1') then
			memrw_data_out_b <= (others => '0');
		elsif (falling_edge(phi2) and memrw_tx_done = '0' and memrw_tx_done_b = '1') then
			memrw_data_out_b <= memrw_data_out;
		end if;
	end process;
	
	-- MW=32
	-- map outgoing (write) bytes from memrw to DOUT
	-- mapping depends on memrw_width, memrw_bytes_transferred
	memrw_data_out_p : process(memrw_data_out, memrw_bytes_transferred, 
										memrw_tx_done, memrw_tx_done_b, memrw_data_out_b)
	begin
		memrw_data_out_aligned <= (others => '0');
		if (memrw_tx_done_b = '1') then
			case memrw_bytes_transferred is
			when 0 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out(31 downto 0);
			when 1 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out(39 downto 8);
			when 2 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out(47 downto 16);
			when 3 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out(55 downto 24);
			when 4 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out(63 downto 32);
			when 5 =>
				memrw_data_out_aligned(23 downto 0) <= memrw_data_out(63 downto 40);
			when 6 =>
				memrw_data_out_aligned(15 downto 0) <= memrw_data_out(63 downto 48);
			when 7 =>
				memrw_data_out_aligned(7 downto 0) <= memrw_data_out(63 downto 56);
			when 8 =>
			end case;
		else
			case memrw_bytes_transferred is
			when 0 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out_b(31 downto 0);
			when 1 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out_b(39 downto 8);
			when 2 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out_b(47 downto 16);
			when 3 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out_b(55 downto 24);
			when 4 =>
				memrw_data_out_aligned(31 downto 0) <= memrw_data_out_b(63 downto 32);
			when 5 =>
				memrw_data_out_aligned(23 downto 0) <= memrw_data_out_b(63 downto 40);
			when 6 =>
				memrw_data_out_aligned(15 downto 0) <= memrw_data_out_b(63 downto 48);
			when 7 =>
				memrw_data_out_aligned(7 downto 0) <= memrw_data_out_b(63 downto 56);
			when 8 =>
			end case;
		end if;
	end process;
	
	-- align DOUT
	dout_p : process(memrw_addr_cnt, memrw_data_out_aligned, memrw_width, memrw_addr_cnt01)
	begin
		DOUT <= memrw_data_out_aligned(MW-1 downto 0);
		case memrw_width is
		when wBYTE =>
		when wWORD =>
			case memrw_addr_cnt(0) is
			when '0' =>
			when '1' =>
				DOUT(MW-1 downto 8) <= memrw_data_out_aligned(MW-9 downto 0);
				DOUT(7 downto 0) <= memrw_data_out_aligned(7 downto 0);
			when others =>
			end case;
		when wLONG | wQUAD =>
			case memrw_addr_cnt01 is
			when "00" =>
			when "01" =>
				-- covers LONG and WORD interfaces
				DOUT(MW-1 downto 8) <= memrw_data_out_aligned(MW-9 downto 0);
				-- for BYTE interfaces
				DOUT(7 downto 0) <= memrw_data_out_aligned(7 downto 0);
			when "10" =>
				-- covers LONG interfaces
				DOUT(MW-1 downto 16) <= memrw_data_out_aligned(MW-17 downto 0);
				-- for WORD and BYTE interfaces
				DOUT(15 downto 0) <= memrw_data_out_aligned(15 downto 0);
			when "11" =>
				-- covers LONG interfaces
				DOUT(MW-1 downto 24) <= memrw_data_out_aligned(MW-25 downto 0);
				DOUT(minimum(MW-1,23) downto 16) <= (others => '0');
				-- WORD interfaces
				DOUT(15 downto 8) <= memrw_data_out_aligned(7 downto 0);
				-- for BYTE interfaces
				DOUT(7 downto 0) <= memrw_data_out_aligned(7 downto 0);
			when others =>
			end case;
		end case;
	end process;

	-- generate memrw_data_in_aligned by aligning the input data and
	-- calculating the number of data bytes fetched
	-- async, takes DIN/din_width_b after the data transfer at falling phi2, aligns
	-- the data and passes it to the core
	memrw_align_p : process(memrw_addr_cnt, DIN_X, dwidth_in_b, memrw_addr_cnt01, dwidth_in_br)
	begin
		memrw_data_in_aligned <= (others => '0');
		case dwidth_in_br is
		when wBYTE =>
			memrw_data_in_aligned <= DIN_X;
		when wWORD =>
			case memrw_addr_cnt(0) is
			when '0' =>
				memrw_data_in_aligned <= DIN_X;
			when '1' =>
				memrw_data_in_aligned(7 downto 0) <= DIN_X(15 downto 8);
			when others =>
			end case;
		when wLONG =>
			case memrw_addr_cnt01 is
			when "00" =>
				memrw_data_in_aligned <= DIN_X;
			when "01" =>
				memrw_data_in_aligned(23 downto 0) <= DIN_X(31 downto 8);
			when "10" =>
				memrw_data_in_aligned(15 downto 0) <= DIN_X(31 downto 16);
			when "11" =>
				memrw_data_in_aligned(7 downto 0) <= DIN_X(31 downto 24);
			when others =>
			end case;
		when wQUAD =>
			-- should not happen (MW=32)
		end case;
	end process;

	-- calculate the data to be sent to the core from the last input
	-- and the saved input from previous reads
	memrw_data_in_p : process(memrw_data_in_aligned, memrw_data_in_b, memrw_bytes_transferred)
	begin
		memrw_data_in <= memrw_data_in_b;
		case memrw_bytes_transferred is
		when 0 =>
			memrw_data_in(31 downto 0) <= memrw_data_in_aligned(31 downto 0) after 1 ns;
		when 1 =>
			memrw_data_in(39 downto 8) <= memrw_data_in_aligned(31 downto 0);
		when 2 =>
			memrw_data_in(47 downto 16) <= memrw_data_in_aligned(31 downto 0);
		when 3 =>
			memrw_data_in(55 downto 24) <= memrw_data_in_aligned(31 downto 0);
		when 4 =>
			memrw_data_in(63 downto 32) <= memrw_data_in_aligned(31 downto 0);
		when 5 =>
			memrw_data_in(63 downto 40) <= memrw_data_in_aligned(23 downto 0);
		when 6 =>
			memrw_data_in(63 downto 48) <= memrw_data_in_aligned(15 downto 0);
		when 7 =>
			memrw_data_in(63 downto 56) <= memrw_data_in_aligned(7 downto 0);
		when 8 =>
		end case;
	end process;

	-- store currently read data to be combined with later reads
	memrw_data_in_b_p : process(reset, phi2, memrw_bytes_transferred, memrw_data_in_b, memrw_data_in_aligned)
	begin
		if (reset = '1') then
			memrw_data_in_b <= (others => '0');
		elsif (falling_edge(phi2)) then
			memrw_data_in_b <= memrw_data_in after 2 ns;
		end if;
	end process;
	
	-- determine width of next read/write cycle depending on number of bytes
	-- already transferred and wanted width
	-- Note: this is the requested width, real width is what comes in from the bus
	memrw_bus_width_p : process(reset, phi2, memrw_next_bytes_transferred, memrw_width)
	begin
		if (reset = '1') then
			memrw_bus_width <= wBYTE;
		elsif (falling_edge(phi2)) then
			case memrw_bytes_transferred is
			when 0 =>
				memrw_bus_width <= rs_width_bytes(memrw_width);
			when 1 =>
				case memrw_width is
				when wBYTE => -- not happening (already finished)
				when wWORD => memrw_bus_width <= wBYTE;
				when wLONG => memrw_bus_width <= wWORD;
				when wQUAD => memrw_bus_width <= wLONG;
				end case;
			when 2 =>
				case memrw_width is
				when wBYTE | wWORD => -- not happening (already finished)
				when wLONG => memrw_bus_width <= wWORD;
				when wQUAD => memrw_bus_width <= wLONG;
				end case;
			when 3 =>
				case memrw_width is
				when wBYTE | wWORD => -- not happening (already finished)
				when wLONG => memrw_bus_width <= wBYTE;
				when wQUAD => memrw_bus_width <= wLONG;
				end case;
			when 4 =>
				case memrw_width is
				when wBYTE | wWORD | wLONG => -- not happening (already finished)
				when wQUAD => memrw_bus_width <= wLONG;
				end case;
			when 5 | 6 =>
				case memrw_width is
				when wBYTE | wWORD | wLONG => -- not happening (already finished)
				when wQUAD => memrw_bus_width <= wWORD;
				end case;
			when 7 =>
				case memrw_width is
				when wBYTE | wWORD | wLONG => -- not happening (already finished)
				when wQUAD => memrw_bus_width <= wBYTE;
				end case;
			when 8 =>
			end case;
		end if;
	end process;
	
	-----------------------------------------------------------------------
	-- fetch handling

	is_fetch_data_valid <= '1' when is_fetch = '1' and RDY = '1' else '0';

	-- calculate fetch_addr_cnt for the next fetch
	-- evaluated at falling phi2
	fetch_data_bytes_p : process(reset, phi2, is_fetch, fetch_addr, fetch_take_addr, 
			fetch_addr_cnt, RDY, dwidth_in_br, fetch_addr_cnt01)
	begin
		fetch_data_in_bytes <= 0;
		if (reset = '1') then
			fetch_data_in_bytes <= 0;
		else
			if (fetch_take_addr = '1') then
				fetch_data_in_bytes <= 0;
			elsif (is_fetch = '1' and RDY = '1') then
				-- calculate next fetch address such that it is aligned
				case dwidth_in_br is
				when wBYTE => 
					fetch_data_in_bytes <= 1;
				when wWORD =>
					case fetch_addr_cnt(0) is
					when '0' =>
						fetch_data_in_bytes <= 2;
					when '1' =>
						fetch_data_in_bytes <= 1;
					when others =>
					end case;
				when wLONG =>
					case fetch_addr_cnt01 is
					when "00" =>
						fetch_data_in_bytes <= 4;
					when "01" =>
						fetch_data_in_bytes <= 3;
					when "10" =>
						fetch_data_in_bytes <= 2;
					when "11" =>
						fetch_data_in_bytes <= 1;
					when others =>
					end case;
				when wQUAD =>
					-- should not happen (MW=32)
				end case;
			else 
				fetch_data_in_bytes <= 0;
			end if;
		end if;
	end process;
	
	-- calculate fetch_addr_cnt for the next fetch
	-- evaluated at falling phi2
	fetch_addr_p : process(reset, phi2, is_fetch, fetch_addr, fetch_take_addr, 
			fetch_addr_cnt, RDY, dwidth_in_br)
	begin
		if (reset = '1') then
			fetch_addr_cnt <= (others => '0');
			--fetch_data_in_bytes <= 0;
		elsif (falling_edge(phi2)) then
			if (fetch_take_addr = '1') then
				fetch_addr_cnt <= fetch_addr;
				--fetch_data_in_bytes <= 0;
			elsif (is_fetch = '1' and RDY = '1') then
				-- calculate next fetch address such that it is aligned
				case dwidth_in_br is
				when wBYTE => 
					fetch_addr_cnt <= fetch_addr_cnt + 1;
					--fetch_data_in_bytes <= 1;
				when wWORD =>
					case fetch_addr_cnt(0) is
					when '0' =>
						fetch_addr_cnt <= fetch_addr_cnt + 2;
						--fetch_data_in_bytes <= 2;
					when '1' =>
						fetch_addr_cnt <= fetch_addr_cnt + 1;
						--fetch_data_in_bytes <= 1;
					when others =>
					end case;
				when wLONG =>
					case fetch_addr_cnt01 is
					when "00" =>
						fetch_addr_cnt <= fetch_addr_cnt + 4;
						--fetch_data_in_bytes <= 4;
					when "01" =>
						fetch_addr_cnt <= fetch_addr_cnt + 3;
						--fetch_data_in_bytes <= 3;
					when "10" =>
						fetch_addr_cnt <= fetch_addr_cnt + 2;
						--fetch_data_in_bytes <= 2;
					when "11" =>
						fetch_addr_cnt <= fetch_addr_cnt + 1;
						--fetch_data_in_bytes <= 1;
					when others =>
					end case;
				when wQUAD =>
					-- should not happen (MW=32)
				end case;
			end if;
		end if;
	end process;
	fetch_addr_cnt01 <= fetch_addr_cnt(1 downto 0);
	
	-- generate fetch_data_in by aligning the input data and
	-- calculating the number of data bytes fetched
	-- async, takes DIN/din_width_b after the data transfer at falling phi2, aligns
	-- the data and passes it to the core
	fetch_align_p : process(fetch_addr_cnt, DIN_X, dwidth_in_b, fetch_addr_cnt01)
	begin
		fetch_data_in <= (others => '0');
		case dwidth_in_b is
		when wBYTE =>
			fetch_data_in <= DIN_X;
		when wWORD =>
			case fetch_addr_cnt(0) is
			when '0' =>
				fetch_data_in <= DIN_X;
			when '1' =>
				fetch_data_in(7 downto 0) <= DIN_X(15 downto 8);
			when others =>
			end case;
		when wLONG =>
			case fetch_addr_cnt01 is
			when "00" =>
				fetch_data_in <= DIN_X;
			when "01" =>
				fetch_data_in(23 downto 0) <= DIN_X(31 downto 8);
			when "10" =>
				fetch_data_in(15 downto 0) <= DIN_X(31 downto 16);
			when "11" =>
				fetch_data_in(7 downto 0) <= DIN_X(31 downto 24);
			when others =>
			end case;
		when wQUAD =>
			-- should not happen (MW=32)
		end case;
	end process;

	----------------------------------------------------------------
	-- buffer DIN_WIDTH
	din_width_b_p : process(reset, phi2, DWIDTH_IN)
	begin
		if (reset = '1') then
			dwidth_in_b <= wBYTE;
		elsif (falling_edge(phi2)) then
			dwidth_in_b <= rs_width_slv(DWIDTH_IN);
		end if;
	end process;

	
	----------------------------------------------------------------
	-- bus arbiter
	
	-- set output address and r/-w
	bus_arb : process (reset, phi2, fetch_addr, fetch_is_active, phi2,
							is_memrw, memrw_rnw, memrw_width,
							memrw_addr_cnt, fetch_addr_cnt, memrw_bus_width,
							memrw_type, memrw_hyper, fetch_hyper)
	begin
		
		if (reset = '1') then
			A <= (others => '0');
			RNW <= '1'; -- read
			ISVALID <= '0';
			DWIDTH_OUT <= slv_rs_width(wBYTE);
			is_fetch <= '0';
			RW_TYPE <= rwNONE;
			RW_HYPER <= '0';
		else
			
			-- fetch has prio over normal load/store
			if (is_memrw = '1') then
				A <= memrw_addr_cnt;
				RNW <= memrw_rnw;
				ISVALID <= '1';
				DWIDTH_OUT <= slv_rs_width(memrw_bus_width);
				is_fetch <= '0';
				RW_TYPE <= memrw_type;
				RW_HYPER <= memrw_hyper;
			elsif (fetch_is_active = '1') then
				A <= fetch_addr_cnt;
				RNW <= '1';
				ISVALID <= '1';
				RW_TYPE <= rwFETCH;
				RW_HYPER <= fetch_hyper;
				-- TODO rework for MW=64
				if (fetch_addr(1 downto 0) = "00") then
					DWIDTH_OUT <= slv_rs_width(wLONG);
				elsif (fetch_addr(0) = '0') then
					DWIDTH_OUT <= slv_rs_width(wWORD);
				else
					DWIDTH_OUT <= slv_rs_width(wBYTE);
				end if;
				is_fetch <= '1';
			else
				A <= (others => '0');
				RNW <= '1'; -- read
				ISVALID <= '0';
				DWIDTH_OUT <= slv_rs_width(wBYTE);
				is_fetch <= '0';
				RW_TYPE <= rwNONE;
				RW_HYPER <= '0';
			end if;
		end if;
	end process;

	-----------------------------------------------------------------------
	
	core : af65002core 

		Generic map (
			W,
			MW
		)
		Port map ( 
			  -- clock
			  reset,
			  phi2,
			  
			  -- those two signals can be used by an interrupt controller
			  -- to schedule interrupts to a "free" CPU
			  -- signals to the outside if we're running in hypervisor mode
			  is_hypervisor,
			  
			  -- interrupt level coming in from the interrupt controller
			  -- if this level is lower than the current level (irqlevel_out)
			  -- then a new interrupt sequence will be started
			  irqlevel_in,
			  -- internal interrupt level; will be set when an interrupt sequence
			  -- is being started, or SEI/CLI are executed
			  irqlevel_out,
			  
			  -- operation interface
			  
			  -- Each memory operation has two cycles. On cycle one, take_addr is set and
			  -- addr_out (plus memrw_type) contain a memory address to be put to the 
			  -- address lines. On the second cycle, is_memrw signals a memory access,
			  -- and when is_memrw_done is set, the core takes the data read from data_in_outbus
			  -- Both cycles can interleave, i.e. cycle 2 for the first memory operation
			  -- can be cycle 1 for the second operation etc.
			  -- cycle 1 and cycle need not follow directly. address can be taken and the actual
			  -- cycle only follows two or even more cycles later. There can be even two
			  -- cycle 2 operations for a single cycle 1 - think read/modify/write opcodes.
			  --
			  -- cycle 1
			  memrw_take_addr, 		-- : out std_logic;		-- set when addr_out has address to store
			  memrw_addr,				-- : out std_logic_vector(W-1 downto 0);
			  memrw_type,				-- : out memrw_t;		-- type of access (taken when take_addr is set, like addr_out)
			  memrw_hyper,				-- : out std_logic;	-- set when access to hypervisor memory
			  -- cycle 2
			  is_memrw,					-- : out std_logic;		-- do the memory access (usually one cycle after take_addr)
			  memrw_width,				-- : out rs_width;		-- what width to read
			  memrw_rnw,				-- : out std_logic;			-- 1 on read, 0 on write
			  -- result
			  memrw_tx_done,			-- : in std_logic;	-- set when data transfer is done
			  is_memrw_err,			-- : in buserr_t;		-- set when data transfer is trapped on an error
			  -- buffered data from DIN, aligned to address (fetch, memrw, depending on is_*_valid
			  memrw_data_in_b(W-1 downto 0),			-- _outbus : in std_logic_vector(W-1 downto 0);
			  -- data out to write
			  memrw_data_out(W-1 downto 0),			-- : out std_logic_vector(W-1 downto 0);
			  
			  -- fetch interface
			  -- fetched data in data_in_outbus is always expected to be aligned to data_in_width
			  -- (i.e. word reads are aligned to even addresses and so on). 
			  -- Even if an odd address is requested to being fetched, wide reads are accepted.
			  -- e.g.: $ff03 is being fetched (fetch_addr). The read can then be a wBYTE read
			  -- from $ff03, but the read can also be a wWORD read from $ff02 - the core detects this and aligns
			  -- automatically.
			  fetch_addr,				-- : out std_logic_vector(W-1 downto 0);
			  fetch_take_addr,		-- : out std_logic;		-- when set, a new address to start fetch stream is valid in fetch_addr
			  fetch_is_active,		-- : out std_logic;		-- when active is set, decode takes more input
			  is_fetch_data_valid, 	-- : in std_logic; 	-- set when the fetch data is done
			  is_fetch_data_err,		-- : in buserr_t;		-- set when .._data_valid is set and error has occurred
			  fetch_hyper,				-- : out std_logic;			-- set when fetch from hypervisor mode			  
			  -- buffered data from DIN, aligned to address (fetch, memrw, depending on is_*_valid
			  fetch_data_in(MW-1 downto 0),			-- _outbus : in std_logic_vector(W-1 downto 0);
			  -- width of data read
			  fetch_data_in_bytes,	-- : natural;
			  			  
			  -- passthrough pins
			  
			  -- external SO input
			  ext_so_in,				-- : in std_logic;
			  
			  -- (runtime) configuration settings
			  -- interrupts affected by SEI in user mode
			  user_irqlevel,			-- : in irqlevel_t;
			  -- width for user mode
			  user_width,				-- : in rs_width;
			  -- stack restricted to 256 byte
			  is_restricted_stack	-- : in std_logic
		);

		memrw_data_out(Wmax-1 downto W) <= (others => '0');

end Behavioral;

