--------------------------------------------------------------------------------
-- test ROM for smoketest 1
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
 
ENTITY smoke1rom IS

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

END;
 
ARCHITECTURE behavior OF smoke1rom IS 

	signal ROM_A : std_logic_vector(15 downto 0);

BEGIN
 
	ROM_WIDTH <= "01";

	rom_p : process(BUS_PHI2, BUS_A, BUS_RNW, BUS_ROMSEL, BUSERR1)
	begin
		ROM_A (15 downto 1) <= BUS_A (15 downto 1);
		ROM_A (0) <= '0';
		ROM_VALID <= '1';
		if (rising_edge(BUS_PHI2)) then
			if (BUS_RNW = '1' and BUS_A(15) = '1' and BUS_ROMSEL = '1') then
				case ROM_A is
				when X"f000" => ROM_D <= X"00a9";	-- LDA #$00
				when X"f002" => ROM_D <= X"55a0";	-- LDY #$55
				when X"f004" => ROM_D <= X"2284";	-- STY $22
				when X"f006" => ROM_D <= X"a913";	-- LDA.W #$aa99
				when X"f008" => ROM_D <= X"99aa";	-- /
				when X"f00a" => ROM_D <= X"c8c8";	-- INY:INY
				when X"f00c" => ROM_D <= X"8888";	-- DEY:DEY
				when X"f00e" => ROM_D <= X"c8c8";	-- INY:INY
				when X"f010" => ROM_D <= X"a013";	-- LDY.W #$0
				when X"f012" => ROM_D <= X"0000";	-- /
				when X"f014" => ROM_D <= X"8813";	-- DEY.W
				when X"f016" => ROM_D <= X"a02b";	-- LDY.S #$80
				when X"f018" => ROM_D <= X"1380";	-- INY.W
				when X"f01a" => ROM_D <= X"02c8";	-- LDA $01,Y
				when X"f01c" => ROM_D <= X"ea01";	-- NOP
				when X"f01e" => ROM_D <= X"ea98";	-- TYA; NOP
				when X"f020" => ROM_D <= X"9813";	-- TYA.W
				when X"f022" => ROM_D <= X"eaaa";	-- TAX; NOP
				when X"f024" => ROM_D <= X"0194";	-- STY $01,X
				when X"f026" => ROM_D <= X"01b1";	-- LDA ($01),Y
				when X"f028" => ROM_D <= X"0913";	-- ORA.W #1213
				when X"f02a" => ROM_D <= X"1213";	-- /
				when X"f02c" => ROM_D <= X"a22b";	-- LDX.S #$FF
				when X"f02e" => ROM_D <= X"eaff";	-- /
				when X"f030" => ROM_D <= X"ea9a";	-- TXS
				when X"f032" => ROM_D <= X"9a2b";	-- TXS.S
				when X"f034" => ROM_D <= X"a213";	-- LDX #$01FF
				when X"f036" => ROM_D <= X"01ff";	-- /
				when X"f038" => ROM_D <= X"9a13";	-- TXS.W
				when X"f03a" => ROM_D <= X"48ea";	-- NOP:PHA
				when X"f03c" => ROM_D <= X"4813";	-- PHA.W
				when X"f03e" => ROM_D <= X"7aea";	-- NOP:PLY

				when X"f042" => ROM_D <= X"804c";	-- JMP $f080
				when X"f044" => ROM_D <= X"eaf0";	-- /

				when X"f080" => ROM_D <= X"55a9";	-- LDA #$55
				when X"f082" => ROM_D <= X"0020";	-- JSR $ff00
				when X"f084" => ROM_D <= X"eaff";

				when X"f086" => ROM_D <= X"10D0";	-- BNE +$10
				when X"f098" => ROM_D <= X"00a9";	-- LDA #$00
				when X"f09a" => ROM_D <= X"10d0";	-- BNE +$10

				when X"f0a0" => ROM_D <= X"7082";	-- BSR +$70

				when X"f0a4" => ROM_D <= X"55a9";	-- LDA #$55
				when X"f0a6" => ROM_D <= X"0a0a";	-- ASL: ASL
				when X"f0a8" => ROM_D <= X"ea4a";	-- LSR: NOP
				when X"f0aa" => ROM_D <= X"55e9";	-- SBC #$55
				
				when X"f0b0" => ROM_D <= X"ff6e";	-- ROR $01ff
				when X"f0b2" => ROM_D <= X"ea01"; 	-- /

				when X"f0b8" => ROM_D <= X"7858";	-- CLI:SEI
				when X"f0ba" => ROM_D <= X"01b1";	-- LDA ($01),Y
				when X"f0bc" => ROM_D <= X"0194";	-- STY $01,X
				when X"f0be" => ROM_D <= X"0100";	-- BRK $01

				when X"f0c2" => ROM_D <= X"eaea";	-- BRK $00
					ROM_VALID <= not(BUSERR1);	-- switches off after time, to avoid endless loop
			
				-- trigger abort on normal memory access
				when X"f0c8" => ROM_D <= X"11ad";	-- LDA $1111
				when X"f0ca" => ROM_D <= X"ea11";
				
				-- abort check on r/m/w op
				when X"f0cc" => ROM_D <= X"0106";	-- ASL $01  (c:1 -> 0)

				when X"f0d0" => ROM_D <= X"4813";	-- PHA.W	(to be aborted and check for SSP rollback)
	
				---------------------
				when X"f112" => ROM_D <= X"0060";	-- BSR target
				---------------------
				when X"fe08" => ROM_D <= X"0040";	-- RTI (IRQ target)
				---------------------
				when X"ff00" => ROM_D <= X"01a2";	-- LDX #$01
				when X"ff02" => ROM_D <= X"0060";	-- RTS

				when X"ffe0" => ROM_D <= X"a92b";	-- LDA.S #$00
				when X"ffe2" => ROM_D <= X"1300";
				when X"ffe4" => ROM_D <= X"0185";	-- STA.W $01
				when X"ffe6" => ROM_D <= X"004c";	-- JMP $F000
				when X"ffe8" => ROM_D <= X"00f0";	-- /

				when X"fff8" => ROM_D <= X"fe00";	-- $fe00 ABORT
				when X"fffa" => ROM_D <= X"fe00";	-- $fe00 NMI
				when X"fffc" => ROM_D <= X"ffe0";	-- $ffe0 RESET
				when X"fffe" => ROM_D <= X"fe00";	-- $fe00 IRQ/BRK
				when others => ROM_D <= X"eaea"; --ROM_A;
				end case;
			end if;
		end if;
	end process;
	
END;
