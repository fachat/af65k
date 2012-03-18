----------------------------------------------------------------------------------
--
--    CPU shell for a af65k CPU. 
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
-- 	entity: 		af65002cpu
--		purpose:		CPU shell for one af65k core
--		features:	one core, with up to 32bit memory interface.
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65k.all;


entity af65002cpu is

	Generic (
		W, MW : integer
	);
	
   Port ( 
		A : out  STD_LOGIC_VECTOR (W-1 downto 0) := (others => '0');
		ISVALID : out STD_LOGIC;							-- true when address valid
		ISFETCH : out STD_LOGIC;							-- true when program fetch (i.e. opcode plus param)
      DOUT : out  STD_LOGIC_VECTOR (MW-1 downto 0);
      DIN : in  STD_LOGIC_VECTOR (MW-1 downto 0);
		DWIDTH_OUT : out std_logic_vector(1 downto 0);	-- which width should the data transfer have?
		DWIDTH_IN : in std_logic_vector(1 downto 0);	-- actual data transfer width
		RDY : in STD_LOGIC;									-- true when data transferred (sampled at falling phi2)
		BUSERR : in std_logic_vector (1 downto 0);	-- when true, current access is trapped on error
      PHI2 : in  STD_LOGIC;
      RNW : out  STD_LOGIC;
      IRQIN : in  STD_LOGIC_VECTOR (6 downto 0);	-- interrupt level input (high active)
		RESET : in STD_LOGIC;								-- active high input(!)
		SO : in STD_LOGIC									-- active in sets Overflow CPU status bit
	);
	
end;

architecture Behavioral of af65002cpu is

	component af65002sequencer is

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
		
	end component;

	component af65002irq is
	Generic (
		CORES : integer
	);
   Port ( 
			reset : in std_logic;
			phi2 : in std_logic;
			
			-- current interrupt pins
			irqin : in  STD_LOGIC_VECTOR (6 downto 0);
				
			-- interrupt levels are: 0=NMI, 1-6 are normal ints in decending prio
			
			-- global interrupt mask.
			-- note: may be too simple... but works for single-core
			
			-- set current interrupt sensitivity level mask
			-- interrupts that are equal or lower than irqmask are allowed
			irqmask_in : in irqlevel_t;
			-- if set on falling phi2 set irq prio level
			irqmask_valid : in std_logic;

			-- effective interrupt sensitivity level mask
			-- This is changed on SEI, or RTI to restore previous level
			-- interrupts that are equal or lower than irqmask are allowed
			irqeffmask_in : in irqlevels_t; -- array(0 to CORES-1) of irqlevel_t;
			
			-- current values (to be read via control registers)
			-- mask
			irqmask : out irqlevel_t;
			-- current inputs
			irqlevel : out irqlevel_t;
			
			-- target level for each core
			-- here the actual interrupts are controlled
			coreirqlevel : out irqlevels_t --array(0 to CORES-1) of irqlevel_t
	 );
	end component;

	-------------------
	-- core signals
	signal rw_type 				: memrw_t;
	signal rw_hyper				: std_logic;
	
--	-------------------
--	-- control
--	signal is_memrw				: std_logic;
--	signal is_memrw_done			: std_logic;
--	signal is_memrw_hyper		: std_logic;
--	signal memrw_type				: memrw_t;
--	signal is_memrw_err			: buserr_t;
--	
--	-- r/-w for memory access
--	signal mem_rnw					: std_logic;
--	signal memrw_width			: rs_width;
--	
--	-- fetch address from decode logic
--	signal fetch_addr					: std_logic_vector (W-1 downto 0);
--	-- is fetch address valid
--	signal fetch_addr_valid			: std_logic;
--	-- fetch from hypervisor more
--	signal is_fetch_hyper			: std_logic;
--	-- true when a fetch read has valid data on the input
--	signal is_fetch_data_valid		: std_logic;
--	-- same signal in sync with data_in_outbus
--	signal is_fetch_data_valid_b		: std_logic;
--	-- true when a fetch read has valid data on the input
--	signal is_fetch_data_err		: buserr_t;
--	-- same signal in sync with data_in_outbus
--	signal is_fetch_data_err_b		: buserr_t;
--	
--	-- internal mirror of ISFETCH
--	-- decide whether opcode fetch or data tansfer
--	signal is_fetch_int			: std_logic;
--
--	-- address out bus
--	signal addr_out					: std_logic_vector (W-1 downto 0);
--	-- buffer for addr out control
--	-- buffer the data transfer address
--	signal aout_buf					: std_logic_vector (W-1 downto 0);
--	signal take_addr					: std_logic;
--	
--	-- data to write
--	signal data_out					: std_logic_vector (W-1 downto 0);
--	
--	-- databus input register output (into Inbus input multiplexer)
--	signal data_in_outbus 			: std_logic_vector (W-1 downto 0);
--	signal data_in_width				: rs_width;

	-- interrupt 
	
	signal irqmask_in : irqlevel_t;
	signal irqmask_valid : std_logic;

	signal irqeffmask_in : irqlevel_t;

	signal irqlevel : irqlevel_t;
	signal irqmask : irqlevel_t;
	signal irqeffmask : irqlevels_t;	--array(0 to 0) of irqlevel_t;
	signal coreirqlevel : irqlevels_t; --array(0 to 0) of irqlevel_t;

	signal is_hypervisor : std_logic;
	
begin


	seq: af65002sequencer 
		Generic map (
			W,
			MW
		)
		Port map ( 
			  -- clock
			  reset,
			  phi2,
			  
			  -- output to denote if running as hypervisor
			  is_hypervisor,
			  
			  -- interrupt handling
			  -- target interrupt
			  coreirqlevel(0),
			  -- core internal mask (effective level)
			  irqeffmask(0),
			  
				-- bus interface
				A,					-- : out  STD_LOGIC_VECTOR (W-1 downto 0);
				ISVALID,			-- : out STD_LOGIC;							-- true when address valid
				RNW,				-- : out  STD_LOGIC;
				DWIDTH_OUT,		-- : out std_logic_vector(1 downto 0);	-- which width should the data transfer have?
				rw_type,			-- : out memrw_type;						-- what type of transfer is intended
				rw_hyper,		-- : out std_logic;
			
				RDY,				-- : in STD_LOGIC;									-- true when data transferred (sampled at falling phi2)
				errpins_buserr(BUSERR),			-- : in buserr_t;								-- when RDY is set, signals error condition to core
				-- actual data transfer width
				-- async signal, must be valid before the data-transfer falling edge of phi2,
				-- used to determine address offset, which will be sampled at falling phi2
				DWIDTH_IN,		-- : in std_logic_vector(1 downto 0);				
				-- data transfer; DIN is valid after falling phi2; 
				-- DIN is aligned on DIN_WIDTH boundaries
				DIN,				-- : in  STD_LOGIC_VECTOR (MW-1 downto 0);
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
				DOUT,				-- : out  STD_LOGIC_VECTOR (MW-1 downto 0);

				-- external SO input
				SO,
				-- runtime configuration
				"011",				-- user irq level
				max_width(W),		-- user mode address width (for stack ops)
				'0'					-- is stack restricted to 256 byte?
			  );

	irq : af65002irq 
	 Generic map (
		1
	 )
    Port map ( 
			reset,
			phi2,
			
			-- current interrupt pins
			IRQIN,
				
			-- interrupt levels are: 0=NMI, 1-7 are normal ints in decending prio
			
			-- global irq mask
			-- set current interrupt sensitivity level mask
			-- interrupts that are equal or lower than irqmask are allowed
			irqmask_in,
			-- if set on falling phi2 set irq prio level
			irqmask_valid,

			-- Effective interrupt sensitivity level mask per core (input)
			-- This is set by the CPU on interrupt entry and cleared
			-- on RTI and CLEIM
			-- interrupts that are equal or lower than irqeffmask are allowed
			irqeffmask,
			
			-- current values
			-- mask
			irqmask,
			-- current inputs
			irqlevel,
			
			-- output interrupt level for each core
			coreirqlevel
	 );

	-- interface to write global mask into irq controller
	irqmask_in <= "111";			-- all irqs allowed
	irqmask_valid <= '0';		-- not valid
	
end Behavioral;

