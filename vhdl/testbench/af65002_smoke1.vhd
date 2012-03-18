--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:55:42 06/11/2011
-- Design Name:   
-- Module Name:   /home/fachat/XILINX/work/GK65002/gecko65k_testbench.vhd
-- Project Name:  GK65002
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gecko65k
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.all; 
use ieee.std_logic_signed.all; 

library af65002;
use af65002.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY af65002_smoke1 IS
END af65002_smoke1;
 
ARCHITECTURE behavior OF af65002_smoke1 IS 

	component smoke1rom IS

        	Port (
                	BUS_PHI2 : in std_logic;
                	BUS_A : in std_logic_vector(15 downto 0);
                	BUS_RNW : in std_logic;
                	BUS_ROMSEL : in std_logic;
                	BUSERR1 : in std_logic;

                	ROM_WIDTH : out std_logic_vector(1 downto 0);
                	ROM_D : out std_logic_vector(15 downto 0);
                	ROM_VALID : out std_logic
        	);

	END component;


        -- core width, i.e. also width of registers
        constant W : integer := 16;
        -- (max) memory width. Only single width supported right now
        constant MW : integer := 16;

        -- Component Declaration for the Unit Under Test (UUT)
	component af65002cpu is
                Generic (
                        W : integer;
                        MW : integer
                );
                Port (
                        A : out  STD_LOGIC_VECTOR (W-1 downto 0);
                        ISVALID : out STD_LOGIC;                            -- true when address valid
                        ISFETCH : out STD_LOGIC;                            -- true when program fetch (i.e. opcode plus param)
                        DOUT : out  STD_LOGIC_VECTOR (MW-1 downto 0);
                        DIN : in  STD_LOGIC_VECTOR (MW-1 downto 0);
                        DWIDTH_OUT : out STD_LOGIC_VECTOR (1 downto 0);
                        DWIDTH_IN : in STD_LOGIC_VECTOR (1 downto 0);
                        RDY : in STD_LOGIC;                                 -- true when data transferred (sampled at falling phi2)
                        BUSERR : in STD_LOGIC_VECTOR (1 downto 0);          -- true when data transfer trapped on error
                        PHI2 : in  STD_LOGIC;
                        RNW : out  STD_LOGIC;
                        IRQIN : in  STD_LOGIC_VECTOR (6 downto 0);
                        RESET : in STD_LOGIC;                               -- active high input(!)
			SO : in STD_LOGIC				    -- active sets overflow status bit
                );
        end component;
 
 
   --Inputs
   signal BUS_PHI2 : std_logic := '0';
   signal IRQIN : std_logic_vector(6 downto 0) := (others => '1');
   signal RDY : std_logic := '1';
   signal BUSERR : std_logic_vector(1 downto 0) := "00";

	--BiDirs
   signal BUS_DIN : std_logic_vector(15 downto 0) := (Others => '0');
   signal BUS_DOUT : std_logic_vector(15 downto 0) := (Others => '0');

 	--Outputs
   signal BUS_A : std_logic_vector(15 downto 0) := (Others => '0');
   signal BUS_RNW : std_logic := '0';
   signal BUS_ROMSEL : std_logic := '0';
   signal BUS_RAMSEL : std_logic := '0';

   signal BUS_ISVALID : std_logic := '0';
   signal BUS_ISFETCH : std_logic := '0';
   signal BUS_DWIDTH_IN : std_logic_vector(1 downto 0) := "00";
   signal BUS_DWIDTH_OUT : std_logic_vector(1 downto 0) := "00";
	
   constant BUS_PHI2_period : time := 100 ns;
 
	-- helpers
   signal RAM_D : std_logic_vector(15 downto 0) := (Others => '0');
   signal RAM_A : integer;
   signal RAM_A1 : integer;

   signal ROM_VALID : std_logic;

   signal ROM_D : std_logic_vector(15 downto 0) := (Others => '0');
   signal ROM_A : std_logic_vector(15 downto 0) := (Others => '0');

   signal ROM_WIDTH : std_logic_vector(1 downto 0);
   signal RAM_WIDTH : std_logic_vector(1 downto 0);

   signal RESET : std_logic := '1';

   signal SO    : std_logic;

   type ram_t is array (0 to 1023) of std_logic_vector(7 downto 0);
   signal ram : ram_t;

   signal BUSERR1 : std_logic;
   signal BUSERR2 : std_logic;
   signal BUSERR3 : std_logic;

BEGIN
 
   -- Instantiate the Unit Under Test (UUT)

   -- Instantiate the Unit Under Test (UUT)
   uut: af65002cpu
	GENERIC MAP (
	  W,
	  MW
	)
	PORT MAP (
	  BUS_A,
	  BUS_ISVALID,
	  BUS_ISFETCH,
	  BUS_DOUT,
	  BUS_DIN,
	  BUS_DWIDTH_OUT,
	  BUS_DWIDTH_IN,
	  RDY,
	  BUSERR,
	  BUS_PHI2,
	  BUS_RNW,
	  IRQIN,
	  RESET,
	  SO
        );

	BUS_ROMSEL <= BUS_A(15);
	BUS_RAMSEL <= '1' when BUS_A(15 downto 9) = "0000000" else '0';

	--BUS_DIN <= ROM_D when BUS_RNW = '1' else (others => 'Z');
	BUS_DIN <= ROM_D when BUS_ROMSEL = '1' else RAM_D;

	BUS_DWIDTH_IN <= ROM_WIDTH when BUS_ROMSEL = '1' else RAM_WIDTH;

	buserr_p : process(BUS_ROMSEL, ROM_VALID, BUS_RAMSEL, BUSERR2, BUSERR3)
	begin
		BUSERR <= "00";
		if (BUS_ROMSEL = '1' and ROM_VALID = '0') then
			BUSERR <= "01";
		end if;
		-- no memory selected
		if (BUS_RAMSEL = '0' and BUS_ROMSEL = '0') then
			BUSERR(0) <= BUSERR2;
		end if;
		-- RAM selected
		if (BUS_RAMSEL = '1') then
			BUSERR(0) <= BUSERR3;
		end if;
	end process;
	--BUSERR <= '1' when (BUS_ROMSEL = '1' and ROM_VALID = '0') else '0';

	-----------------------------------------------------

	RAM_A <= conv_integer(BUS_A);
	RAM_A1 <= RAM_A + 1;

	RAM_WIDTH <= "00";

	ram_write_p : process(BUS_PHI2, BUS_DOUT, BUS_A, BUS_RNW, BUS_RAMSEL, BUS_DWIDTH_OUT)
	begin
		if (falling_edge(BUS_PHI2) and BUS_RAMSEL = '1' and BUS_RNW = '0') then
			ram(RAM_A) <= BUS_DOUT(7 downto 0);	-- low byte
--			if (BUS_DWIDTH_OUT = "01" and BUS_A(0) = '0') then
--				report "ram write high byte ";
--				report integer'image(RAM_A1);
--				ram(RAM_A1) <= BUS_DOUT(15 downto 8);	-- high byte
--			end if;
		end if;
	end process;		

	ram_read_p : process(BUS_PHI2, BUS_A, BUS_RNW, BUS_RAMSEL, BUS_DWIDTH_OUT)
	begin 
		if (rising_edge(BUS_PHI2) and BUS_RAMSEL = '1' and BUS_RNW = '1') then
			RAM_D(7 downto 0) <= ram(RAM_A)(7 downto 0);	-- low byte
--			if (BUS_DWIDTH_OUT= "01") then
--				RAM_D(15 downto 8) <= ram(RAM_A1)(7 downto 0) ;	-- high byte
--			end if;
		end if;
	end process;

	-----------------------------------------------------

       	rom : smoke1rom 
		Port map (
                	BUS_PHI2,
                	BUS_A,
                	BUS_RNW,
                	BUS_ROMSEL,
                	BUSERR1,

                	ROM_WIDTH,
                	ROM_D,
                	ROM_VALID
        	);


   -- Clock process definitions
   BUS_PHI2_process :process
   begin
		BUS_PHI2 <= '0';
		wait for BUS_PHI2_period/2;
		BUS_PHI2 <= '1';
		wait for BUS_PHI2_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		RESET <= '1';
		
      -- hold reset state for 100 ns.
      wait for 200 ns;	

		RESET <= '0';

      wait for 1000000 ns;	

		RESET <= '1';
      wait;
   end process;

   irq_p : process
   begin
	IRQIN <= "0000000";

	wait for 13733 ns;
		IRQIN(2) <= '1';

	wait for 4500 ns;
		IRQIN(1) <= '1';		

	wait for 1300 ns;
		IRQIN(1) <= '0';
		IRQIN(2) <= '0';

	wait;
   end process;

   buserr3_p : process
   begin
	BUSERR3 <= '0';
	wait for 27250 ns;
		BUSERR3 <= '1';		-- asl $01 abort check
	wait for 200 ns;
		BUSERR3 <= '0';
	wait for 3600 ns;
		BUSERR3 <= '1';		-- PHA.W abort check
	wait for 200 ns;
		BUSERR3 <= '0';
	wait;
   end process;

   buserr2_p : process
   begin
	BUSERR2 <= '1';
	wait for 26700 ns;
		BUSERR2 <= '0';
	wait;
   end process;

   buserr1_p : process
   begin
	BUSERR1 <= '1';
	wait for 23300 ns;
		BUSERR1 <= '0';
	wait;
   end process;

END;
