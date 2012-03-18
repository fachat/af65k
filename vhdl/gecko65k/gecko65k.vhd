----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:47:21 03/19/2011 
-- Design Name: 
-- Module Name:    gecko65k - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library af65002;
use af65002.af65002cpu;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gecko65k is
	
   Port ( 
--			  RAM_A : out  STD_LOGIC_VECTOR (0 downto 31);
--			  RAM_D : inout  STD_LOGIC_VECTOR (0 downto 7);
--			  RAM_RNW : out  STD_LOGIC;
--			  RAM_NSEL : out STD_LOGIC;

			  BUS_A : out STD_LOGIC_VECTOR (15 downto 0);
			  BUS_D : inout STD_LOGIC_VECTOR (15 downto 0);
			  BUS_RNW : out STD_LOGIC;
			  BUS_PHI2 : in STD_LOGIC;
			  BUS_NSEL : out STD_LOGIC;
			  
			  BUS_ERR : in std_logic_vector (1 downto 0);
			  
           NIRQIN : in STD_LOGIC_VECTOR (3 downto 0);
			  NRESET : in STD_LOGIC
	);
end;

architecture Behavioral of gecko65k is

	-- core width, i.e. also width of registers
	constant W : integer := 32;
	-- (max) memory width. Only single width supported right now
	constant MW : integer := 16;
	
   component af65002cpu is
		Generic (
			W : integer;
			MW : integer
		);
		Port ( 
			A : out  STD_LOGIC_VECTOR (W-1 downto 0);
			ISVALID : out STD_LOGIC;							-- true when address valid
			ISFETCH : out STD_LOGIC;							-- true when program fetch (i.e. opcode plus param)
			DOUT : out  STD_LOGIC_VECTOR (MW-1 downto 0);
			DIN : in  STD_LOGIC_VECTOR (MW-1 downto 0);
			DWIDTH_OUT : out STD_LOGIC_VECTOR (1 downto 0);
			DWIDTH_IN : in STD_LOGIC_VECTOR (1 downto 0);
			RDY : in STD_LOGIC;									-- true when data transferred (sampled at falling phi2)
			BUSERR : in STD_LOGIC_VECTOR(1 downto 0);		-- true when data transfer trapped on error
			PHI2 : in  STD_LOGIC;
			RNW : out  STD_LOGIC;
			IRQIN : in  STD_LOGIC_VECTOR (6 downto 0);
			RESET : in STD_LOGIC;			-- active high input(!)
			SO : in std_logic
		);
	end component;

	signal phi2			:std_logic;

	signal cpu_dout		: std_logic_vector (MW-1 downto 0) := (others => '0');
	signal cpu_din		: std_logic_vector (MW-1 downto 0) := (others => '0');
	signal cpu_aout		: std_logic_vector (W-1 downto 0) := (others => '0');
	signal cpu_rnw		: std_logic;
	signal cpu_irqmap	: std_logic_vector (6 downto 0);
	signal cpu_reset	: std_logic;

	signal cpu_is_valid	: std_logic;
	signal cpu_is_fetch	: std_logic;
	signal cpu_width_in	: std_logic_vector (1 downto 0);
	signal cpu_width_out	: std_logic_vector (1 downto 0);
	
	signal cpu_so : std_logic := '0';
begin

	cpu_so <= '0';
	
	cpu_width_in <= cpu_width_out;
	
	----------------------------------------
	-- clock
	phi2 <= BUS_PHI2;
	
	----------------------------------------
	-- busses
	
	BUS_D <= cpu_dout when (cpu_rnw='0') else (others => 'X');
	cpu_din <= bus_d;
	BUS_A <= cpu_aout(15 downto 0) when cpu_is_valid = '1' else (others => '0');
	BUS_RNW <= cpu_rnw when cpu_is_valid = '1' else '1';
	BUS_NSEL <= not(cpu_is_valid);
	
	cpu_irqmap(3 downto 0) <= not(NIRQIN);
	cpu_irqmap(6 downto 4) <= (others => '0');
	
	cpu_reset <= not(NRESET);
	
	----------------------------------------
	-- core integration

	cpu: af65002cpu 
	generic map (
		W, MW
	)
	port map (
		cpu_aout,
		cpu_is_valid,
		cpu_is_fetch,
		cpu_dout,
		cpu_din,
		cpu_width_out,
		cpu_width_in,
		'1',
		BUS_ERR,
		phi2,
		cpu_rnw,
		cpu_irqmap,
		cpu_reset,
		cpu_so
	);
	
end Behavioral;

