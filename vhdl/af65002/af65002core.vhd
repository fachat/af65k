----------------------------------------------------------------------------------
--
--    Single core for a af65k CPU. 
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
-- 	entity: 		af65002core
--		purpose:		af65k CPU core
--		features:	- user/hypervisor more
--						- generatable for 16, 32 or 64 bit register widths
--						- 6502 compatible
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--

--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library af65002;
use af65002.af65k.all;


entity af65002core is

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
			  fetch_addr_valid : out std_logic;
			  fetch_is_active : out std_logic;		-- when active is set, decode takes more input
			  is_fetch_data_valid : in std_logic; -- set when the fetch data is done
			  is_fetch_data_err : in buserr_t;		-- set when .._data_valid is set and error has occurred
			  fetch_hyper : out std_logic;			-- set when fetch from hypervisor mode
			  
			  -- buffered data from DIN
			  fetch_data_in : in std_logic_vector(MW-1 downto 0);
			  -- width of data read
			  fetch_data_in_bytes : natural range 0 to 4;
			  			  
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

end;

architecture Behavioral of af65002core is

	
	component af65002status is
		Generic (
			W : integer
		);
		Port ( 
			  -- clock
			  reset : in std_logic;
			  phi2_in  : in std_logic;
			  -- control
			  commit : in std_logic;
			  rollback : in std_logic;
			  -- status value
			  is_hypervisor : out std_logic;
			  status_n : out  STD_LOGIC;
           status_v : out  STD_LOGIC;
           status_z : out  STD_LOGIC;
           status_c : out  STD_LOGIC;
           status_d : out  STD_LOGIC;
           status_i : out  STD_LOGIC;
           status_x : out  STD_LOGIC;
			  status_byte : out std_logic_vector(7 downto 0);
			  ext_status_byte : out std_logic_vector(7 downto 0);
			  -- input selectors
           status_n_in : in  st_in_type;
           status_v_in : in  st_in_type;
           status_z_in : in  st_in_type;
           status_c_in : in  st_in_type;
           status_d_in : in  st_in_type;
           status_i_in : in  st_in_type;
           status_u_in : in  st_in_type;
           status_x_in : in  st_in_type;
			  -- input data to select
			  -- alu result
			  alu_c_in : in  std_logic;
			  -- value to investigate
           value_in : in  STD_LOGIC_VECTOR(W-1 downto 0);
           value_width_in : in  rs_width;
           pull_in : in  STD_LOGIC_VECTOR(W-1 downto 0);
			  -- external SO (set overflow flag)
			  ext_so_in : in std_logic;
			  -- set '1' bit
			  stat_brk_bit : in std_logic
			  );
	end component;

	component af65002ext is
		Generic (
			W : integer
		);
		Port ( 
			extmode : in ext_type;
			insize : in rs_width;
			indata : in  STD_LOGIC_VECTOR (W-1 downto 0);
			altdata : in  STD_LOGIC_VECTOR (W-1 downto 8);
			outdata : out  STD_LOGIC_VECTOR (W-1 downto 0)
		);
	end component;

	component af65002const is
		Generic (
			W : integer
		);
		Port ( 
			constname : in const_type;
			value : out STD_LOGIC_VECTOR (W-1 downto 0)
		);
	end component;

	component af65002alu is 
		generic (
			W : integer
		);
		port (
			ina	: in std_logic_vector (W-1 downto 0);
			inb	: in std_logic_vector (W-1 downto 0);
			aout 	: out std_logic_vector (W-1 downto 0);
			in_c	: in std_logic;
			out_c	: out std_logic;
			op		: in alu_operation;
			rsw	: in rs_width;
			is_decimal : in std_logic
		);
	end component;

	component af65002decode2 is
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
			-- signal whether we are in hypervisor mode
			is_hypervisor : in std_logic;
			-- rollback info from control
			is_rollback : in std_logic;
			-- abort vector for rollback
			rollback_abort_vec : in abort_t;
			-- pc for rollback
			rollback_pc : in std_logic_vector (W-1 downto 0);
			
			-- input params
			pcin 			: in STD_LOGIC_VECTOR (W-1 downto 0);
			pcin_set		: in std_logic;
			--rdaddr 		: out STD_LOGIC_VECTOR (W-1 downto 0);
			rdvalid		: out std_logic;
			din_in 		: in  STD_LOGIC_VECTOR (MW-1 downto 0);
			dwidth_bytes: in natural range 0 to 4;
			dvalid 		: in  STD_LOGIC;
			dvalid_err	: in buserr_t;
			
			-- output params
			outrdy		: in std_logic;
			pc_out		: out STD_LOGIC_VECTOR (W-1 downto 0);
			pc_op_end	: out std_logic_vector (W-1 downto 0);
			pc_op_next	: out std_logic_vector (W-1 downto 0);
			ovalid 		: out STD_LOGIC;
			operation 	: out cpu_operation;
			admode 		: out cpu_syntax;
			idxreg		: out idx_register;
			parwidth		: out par_width;
			indwidth		: out rs_width;
			parameter	: out STD_LOGIC_VECTOR (W-1 downto 0);
			prefix_le 	: out ext_type;
			prefix_rs 	: out rs_width;
			prefix_um 	: out STD_LOGIC;
			prefix_nf 	: out STD_LOGIC;
			prefix_of 	: out of_type
		);
	end component;

	component af65002regs is
		Generic (
			W : integer;
			NumReg : integer
		);
		Port ( 
			reset : in std_logic;
			phi2 : in  STD_LOGIC;
			-- control
			commit : in std_logic;
			rollback : in std_logic;
			-- in/out
			rd_regno : in  integer range 0 to rMAX;
			rd_data : out  STD_LOGIC_VECTOR(W-1 downto 0);
			wr_regno : in  integer range 0 to rMAX;
			wr_width : in rs_width;
			wrvalid : in  STD_LOGIC;
			wr_data : in  STD_LOGIC_VECTOR(W-1 downto 0)
		);
	end component;
	
	component af65002ctrl is
		Generic (
			full_width : rs_width
		);
		Port ( 
			reset : in std_logic;
			phi2 : in std_logic;
			is_hypervisor : in std_logic;
			ovalid : in  STD_LOGIC;
			outrdy : out  STD_LOGIC;
			operation : in cpu_operation;
			admode : in cpu_syntax;
			idxreg : in idx_register;
			parwidth : in par_width;
			indwidth : in rs_width;
			prefix_le : in ext_type;
			prefix_rs : in rs_width;
			prefix_um : in  STD_LOGIC;
			prefix_nf : in  STD_LOGIC;
			prefix_of : in of_type;
			-- control outputs
			-- output when memory access is requested
			is_memrw : out std_logic;
			memrw_width : out rs_width;
			memrw_type : out memrw_t;		-- defines type of memory access
			memrw_hyper : out std_logic;		-- set when memory access is in hypervisor space
			-- returns when memory access is done
			is_memrw_done : in std_logic;
			is_memrw_err : in buserr_t;
			-- is memory access read or write?
			mem_rnw : out std_logic;
			-- bus configuration
			sel_inbus : out inbus_source;
			sel_regbus : out regbus_source;
			sel_outbus : out outbus_source;
			sel_addrout : out out_source;
			sel_dataout : out out_source;
			take_addr : out std_logic;
			take_pc : out std_logic;
			inbus_ext_type : out ext_type;
			inbus_ext_width : out rs_width;
			outbus_ext_type : out ext_type;
			outbus_ext_width : out rs_width;
			constname : out const_type;
			-- register config
			tempreg_latch : out std_logic;
			sel_store_to_reg : out cpu_register;
			store_to_reg_width : out rs_width;
			sel_read_from_reg : out cpu_register;
			-- ALU configuration
			alu_op : out  alu_operation;
			alu_op_width : out rs_width;
			-- hypervisor control
			st_u : out st_in_type;		-- set usermode bit
			st_x : out st_in_type;		-- is extended stack frame
			-- status control
			st_n : out st_in_type;
			st_v : out st_in_type;
			st_z : out st_in_type;
			st_c : out st_in_type;
			st_i : out st_in_type;
			st_d : out st_in_type;
			st_value_width : out rs_width;
			stat_brk_bit : out std_logic;
			-- status values for branching
			st_n_in : in std_logic;
			st_v_in : in std_logic;
			st_z_in : in std_logic;
			st_c_in : in std_logic;
			st_x_in : in std_logic;
			-- interrupt handling
			release_irqlevel : out std_logic;	-- when set, clear interrupt level
			-- (runtime) configuration section
			is_restricted_stack : in std_logic;
			user_width : in rs_width;
			-- commit/rollback handling
			-- when commit is _not_ set, any changes are temporary until commit is set again
			-- when rollback is set, temporary changes are rolled back 
			commit : out std_logic;
			rollback : out std_logic;
			abort_vec : out abort_t
		);
	end component;
	
	------------------------------------------------------
	-- input interface busses
	
	-- temp register output (into Inbus input multiplexer)
	signal temp_register_outbus	: std_logic_vector (W-1 downto 0);
	
	-- opcode parameter (input into Inbus input multiplexer)
	signal opcode_param_outbus		: std_logic_vector (W-1 downto 0);
	
	-- constants
	signal const_outbus				: std_logic_vector (W-1 downto 0);
	
	-- register file output (into Regbus input multiplexer)
	signal register_file_outbus	: std_logic_vector (W-1 downto 0);
	-- PC output (into Regbus input multiplexer, decoder)
	signal pc_reg						: std_logic_vector (W-1 downto 0);
	-- the address of the last byte of the opcode (sync)
	signal op_end_pc					: std_logic_vector (W-1 downto 0);
	-- the address of the first byte of the next opcode (sync, not branched/jumped)
	signal op_next_pc					: std_logic_vector (W-1 downto 0);

	-- the PC from which the current opcode has been loaded (async, from decode)
	signal decode_pc					: std_logic_vector (W-1 downto 0);
	-- the address of the last byte of the opcode (async, from decode)
	signal decode_op_end				: std_logic_vector (W-1 downto 0);
	-- the address of the first byte of the next opcode (async, from decode)
	signal decode_op_next			: std_logic_vector (W-1 downto 0);
	
	------------------------------------------------------
	-- output interface busses

	signal data_out_sel : out_source;
	
	signal addr_out_sel : out_source;	
		
	
	------------------------------------------------------
	-- internal busses
	
	-------------------
	-- input bus, set from Din, opcode parameter or temp register
	-- input to ALU A
	signal Inbus 				: std_logic_vector (W-1 downto 0);
	signal Inbus_preext 		: std_logic_vector (W-1 downto 0);
	
	signal inbus_sel : Inbus_source;
	
	-------------------
	-- register file output, input into ALU B
	signal Regbus		: std_logic_vector (W-1 downto 0);
	
	signal regbus_sel : Regbus_source;

	-- output from register file
--	signal regfile_out 	: std_logic_vector (W-1 downto 0);
	
	-------------------
	-- output bus, output from ALU or from DIN, input into registers, address output
	signal Outbus 				: std_logic_vector (W-1 downto 0);
	signal Outbus_preext 	: std_logic_vector (W-1 downto 0);

	-- ALU output
	signal outbus_alu	: std_logic_vector (W-1 downto 0);
	
	signal outbus_sel : outbus_source;

	-------------------
	
	signal tempreg_latch : std_logic;

	-------------------
	-- alu interface signals
	--signal alu_c_in 		: std_logic;
	signal alu_c_out		: std_logic;
	
	signal alu_op			: alu_operation;
	signal alu_op_width	: rs_width;

	-------------------
	-- status register interface signals
	signal status_n		: std_logic;
	signal status_v		: std_logic;
	signal status_z		: std_logic;
	signal status_c		: std_logic;
	signal status_i		: std_logic;
	signal status_d		: std_logic;
	signal status_x		: std_logic;
	
	signal status_byte   : std_logic_vector(7 downto 0);
	signal ext_status_byte  : std_logic_vector(7 downto 0);
	
	signal status_n_in	: st_in_type;
	signal status_v_in	: st_in_type;
	signal status_z_in	: st_in_type;
	signal status_c_in	: st_in_type;
	signal status_i_in	: st_in_type;
	signal status_d_in	: st_in_type;
	signal status_u_in	: st_in_type;
	signal status_x_in	: st_in_type;

	signal status_value_width_in : rs_width;
	signal stat_brk_bit : std_logic;
	
	--signal ext_so_in 		: std_logic := '0';
	
	signal is_hypervisor_int : std_logic := '1';
	--signal is_restricted_stack : std_logic := '0';
	
	-------------------
	---- decoding signals
	-- flow control
	signal outrdy					: std_logic;
	signal decode_is_valid		: std_logic;
	
	-- interface
	-- to set a new PC to decode
	signal new_pc					: std_logic_vector(W-1 downto 0);
	signal new_pc_set				: std_logic;
	
	-- the opcode parameter
	signal decode_par				: std_logic_vector(W-1 downto 0);
	
	signal prefix_rs				: rs_width;
	signal prefix_nf				: std_logic;
	signal prefix_um				: std_logic;
	signal prefix_of				: of_type;
	signal prefix_le				: ext_type;
	
	signal decode_op				: cpu_operation;
	signal decode_am				: cpu_syntax;
	signal decode_pw				: par_width;
	signal decode_iw				: rs_width;
	signal decode_ir				: idx_register;
	-------------------
	-- register file signals
	signal rd_regno 				: cpu_register;
	signal wr_regno				: cpu_register;
	signal wr_width				: rs_width;
	signal wrvalid					: std_logic;

	signal inbus_ext_type		: ext_type;
	signal inbus_ext_width		: rs_width;
	
	signal outbus_ext_type		: ext_type;
	signal outbus_ext_width		: rs_width;

	signal constname				: const_type;
	
	---------------------
	-- interrupt handling
	
	signal start_interrupt		: std_logic;
	signal started_interrupt	: std_logic;
	-- what interrupts are in principle allowed depending on I-bit and hypervisor mode
	signal irqeffmask				: irqlevel_t;	
	
	signal irqlevel_int			: irqlevel_t;
	
	signal release_irqlevel		: std_logic;
	
	signal commit					: std_logic;
	signal rollback				: std_logic;
	signal abort_vec				: abort_t;
	
begin

	fetch_hyper <= is_hypervisor_int;
	is_hypervisor <= is_hypervisor_int;
	
	----------------------------------------------------------------
	-- control
	control : af65002ctrl
		Generic map (
			max_width(W)
		)
		Port map ( 
			reset,
			phi2,
			is_hypervisor_int,
			decode_is_valid,
			outrdy,
			decode_op,
			decode_am,
			decode_ir,
			decode_pw,
			decode_iw,
			
			prefix_le,
			prefix_rs,
			prefix_um,
			prefix_nf,
			prefix_of,
			-- control outputs
			-- output when memory access is requested
			is_memrw,
			memrw_width,
			memrw_type,
			memrw_hyper,
			-- returns when memory access is done
			is_memrw_done,
			is_memrw_err,
			-- is memory access read or write?
			mem_rnw,
			-- bus config
			inbus_sel,
			regbus_sel,
			outbus_sel,
			addr_out_sel,
			data_out_sel,
			take_addr, 
			new_pc_set,
			inbus_ext_type,
			inbus_ext_width,
			outbus_ext_type,
			outbus_ext_width,
			constname,
			-- register config
			tempreg_latch,
			wr_regno,
			wr_width,
			rd_regno,
			-- ALU config
			alu_op,
			alu_op_width,
			-- hypervisor control
			status_u_in,
			status_x_in,
			-- status config
			status_n_in,
			status_v_in,
			status_z_in,
			status_c_in,
			status_i_in,
			status_d_in,
			status_value_width_in,
			stat_brk_bit,
			-- status values
			status_n,
			status_v,
			status_z,
			status_c,		
			status_x,	-- extended stack frame		
			-- interrupt handling
			release_irqlevel,	-- when set, clear interrupt level
			-- (runtime) configuration section
			is_restricted_stack,
			user_width,
			--
			commit,
			rollback,
			abort_vec
		);

	----------------------------------------------------------------
	-- decode 

	new_pc <= outbus;

	decode : af65002decode2
		generic map (
			W,
			MW
		)
		port map ( 
			phi2,
			reset,
			
			start_interrupt,
			irqlevel_in,
			started_interrupt,
			is_hypervisor_int,
			rollback,
			abort_vec,
			pc_reg,
			
			-- input params
			new_pc,
			new_pc_set,
			--fetch_addr,
			-- fetch_addr_valid,
			fetch_is_active,
			fetch_data_in(MW-1 downto 0),
			fetch_data_in_bytes,
			is_fetch_data_valid,
			is_fetch_data_err,
			
			-- output params
			outrdy,
			decode_pc,
			decode_op_end,
			decode_op_next,
			decode_is_valid,
			decode_op,
			decode_am,
			decode_ir,
			decode_pw,
			decode_iw,
			decode_par,
			
			prefix_le,
			prefix_rs,
			prefix_um,
			prefix_nf,
			prefix_of
		);

	-- output to sequencer, to start new fetch stream
	fetch_addr <= new_pc;
	fetch_addr_valid <= new_pc_set;
	
	pcreg_p : process(phi2, decode_is_valid, decode_pc)
	begin
		if (falling_edge(phi2)) then
			if (decode_is_valid = '1' and outrdy = '1') then
				pc_reg <= decode_pc;
				op_end_pc <= decode_op_end;
				op_next_pc <= decode_op_next;
			end if;
		end if;
	end process;

	----------------------------------------------------------------
	-- ALU 

	alu : af65002alu
		generic map (
			W
		)
		port map (
			inbus,
			regbus,
			outbus_alu,
			status_c,
			alu_c_out,
			alu_op,
			alu_op_width,
			status_d
		);

	----------------------------------------------------------------
	-- register file
	
	wrvalid <= '0' when wr_regno = rNONE else '1';
	
	regfile : af65002regs
		generic map (
			W,
			5
		)
		port map (
			reset,
			phi2,
			commit,
			rollback,
			rd_regno,
			register_file_outbus,
			wr_regno,
			wr_width,
			wrvalid,
			outbus
		);

	----------------------------------------------------------------
	-- status register

	status: af65002status 
		generic map (
			W
		)
		port map ( 
			  -- clock
			  reset,
			  phi2,
			  -- control
			  commit,
			  rollback,
			  -- status value
			  is_hypervisor_int,
			  status_n,
           status_v,
           status_z,
           status_c,
           status_d,
           status_i,
           status_x,
			  status_byte,
			  ext_status_byte,
			  -- input selectors
           status_n_in,
           status_v_in,
           status_z_in,
           status_c_in,
           status_d_in,
           status_i_in,
			  status_u_in,
           status_x_in,
			  -- input data to select
			  -- alu result
			  alu_c_out,
			  -- value to investigate
           Outbus,
           status_value_width_in,
			  -- pull value
			  memrw_data_in,
			  -- external SO (set overflow flag)
			  ext_so_in,
			  -- set '1' bit value
			  stat_brk_bit
		);
	
	
	----------------------------------------------------------------
	-- temporary register
	temp_register : process (
		tempreg_latch, RESET, outbus, phi2)
	begin
		if (RESET = '1') then
			temp_register_outbus <= (others => '0');
		elsif (falling_edge(phi2)) then
			if (tempreg_latch = '1') then
				temp_register_outbus <= outbus;
			end if;
		end if;
	end process;

	----------------------------------------------------------------
	-- opcode parameter save register
	save_register : process (
		decode_is_valid, RESET, decode_par, phi2)
	begin
		if (RESET = '1') then
			opcode_param_outbus <= (others => '0');
		elsif (falling_edge(phi2)) then
			if (decode_is_valid = '1' and outrdy = '1') then
				opcode_param_outbus <= decode_par;
			end if;
		end if;
	end process;

	----------------------------------------------------------------
	-- bus multiplexers

	aoutbus_multiplexer : process (
		addr_out_sel,
		Inbus, Outbus, Regbus)
	begin 
		case addr_out_sel is
		when IN_BUS =>	
			addr_out <= Inbus;
		when REG_BUS =>
			addr_out <= Regbus;
		when OUT_BUS =>
			addr_out <= Outbus;
		when NO_BUS =>
			addr_out <= (others => '0');
		end case;
	end process;
	
	doutbus_multiplexer : process (
		data_out_sel,
		Inbus, Outbus, Regbus)
	begin 
		case data_out_sel is
		when IN_BUS =>	
			memrw_data_out <= Inbus;
		when REG_BUS =>
			memrw_data_out <= Regbus;
		when OUT_BUS =>
			memrw_data_out <= Outbus;
		when NO_BUS =>
			memrw_data_out <= (others => '0');
		end case;
	end process;
	
	inbus_multiplexer : process (
		inbus_sel,
		temp_register_outbus, 
		memrw_data_in,
		opcode_param_outbus,
		const_outbus, 
		register_file_outbus
	)
	begin 
		case inbus_sel is
		when IB_DIN =>	
			Inbus_preext <= memrw_data_in;
		when IB_PARAM =>
			Inbus_preext <= opcode_param_outbus;
		when IB_TEMP =>
			Inbus_preext <= temp_register_outbus;
		when IB_CONST =>
			Inbus_preext <= const_outbus;
		when IB_REGFILE =>
			Inbus_preext <= register_file_outbus;
		when IB_NONE =>
			Inbus_preext <= (others => '0');
		end case;
	end process;

	inbus_ext_c : af65002ext 
		Generic map (
			W
		)
		Port map ( 
			inbus_ext_type,
			inbus_ext_width,
			inbus_preext,
			regbus(W-1 downto 8),
			inbus
		);
		
	regbus_multiplexer : process (
		regbus_sel,
		pc_reg,
		register_file_outbus,
		op_next_pc,
		op_end_pc,
		status_byte, ext_status_byte
		)
	begin 
		case regbus_sel is
		when RB_REGFILE =>	
			Regbus <= register_file_outbus;
		when RB_PC =>
			Regbus <= pc_reg;
		when RB_NEXT_PC =>
			Regbus <= op_next_pc;
		when RB_NEXT_PC_MINUS_1 =>
			Regbus <= op_end_pc;
		when RB_NONE =>
			Regbus <= (others => '0');
		when RB_STATUS =>
			-- TODO: bits 8-15 as extended status?
			Regbus(7 downto 0) <= status_byte;
			Regbus(15 downto 8) <= ext_status_byte;
			Regbus(W-1 downto 16) <= (others => '0');
		end case;
	end process;
	
	outbus_multiplexer : process (
		outbus_sel,
		outbus_alu,
		memrw_data_in,
		opcode_param_outbus,
		register_file_outbus,
		temp_register_outbus,
		op_next_pc,
		const_outbus
		)
	begin 
		case outbus_sel is
		when OB_ALU =>	
			outbus_preext <= outbus_alu;
		when OB_DIN =>
			outbus_preext <= memrw_data_in;
		when OB_PARAM =>
			outbus_preext <= opcode_param_outbus;
		when OB_REGFILE =>
			outbus_preext <= register_file_outbus;
		when OB_TEMP =>
			outbus_preext <= temp_register_outbus;
		when OB_NEXT_PC =>
			outbus_preext <= op_next_pc;
		when OB_CONST =>
			outbus_preext <= const_outbus;
		end case;
	end process;
	
	outbus_ext_c : af65002ext 
		Generic map (
			W
		)
		Port map ( 
			outbus_ext_type,
			outbus_ext_width,
			outbus_preext,
			regbus(W-1 downto 8),
			outbus
		);

	const_c : af65002const 
		Generic map (
			W
		)
		Port map ( 
			constname,
			const_outbus
		);
	
	-----------------------------------------------------------------------------------
	-- interrupt handling
	
	-- detect that we need to start an interrupt (input to decode)
	interrupt_p : process(irqlevel_in, irqlevel_int, phi2, reset, is_hypervisor_int, status_i)
	begin
		if (reset = '1') then 
			start_interrupt <= '0';
		elsif (falling_edge(phi2)) then
			if ((irqlevel_in < irqlevel_int)
				and (irqlevel_in < irqeffmask)
				) then
				start_interrupt <= '1';
			else
				start_interrupt <= '0';
			end if;
		end if;
	end process;

	irqlevel_p : process(start_interrupt, started_interrupt, irqlevel_in, phi2, reset, release_irqlevel)
	begin
		if (reset = '1') then
			irqlevel_int <= "111";
		elsif (falling_edge(phi2)) then
			if (start_interrupt = '1' and started_interrupt = '1') then
				irqlevel_int <= irqlevel_in;
			elsif (release_irqlevel = '1') then
				irqlevel_int <= "111";
			end if;
		end if;
	end process;
	irqlevel_out <= irqlevel_int;
	
	irqeffmask_p : process(status_i, user_irqlevel, is_hypervisor_int, status_i_in)
	begin
		-- using status_i_in is a feeble attempt to make interrupt handling
		-- react on SEI/CLI one cycle earlier
		if ((status_i = '0' and not(status_i_in = stSET)) or status_i_in = stCLR) then
			irqeffmask <= (others => '1'); -- any interrupt (000-110)
		else
			if (is_hypervisor_int = '0') then
				irqeffmask <= user_irqlevel;
			else
				irqeffmask <= "001";	-- only NMI (000) allowed
			end if;
		end if;
	end process;
	
end Behavioral;

