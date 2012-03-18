----------------------------------------------------------------------------------
--
--    af65k ALU
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
-- 	entity: 		af65002alu
--		purpose:		Provides the arithmetic and logical (integer) operations for the CPU
--		features:	
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all; 
use ieee.std_logic_signed.all; 
library af65002;
use af65002.af65k.all;


entity af65002alu is
	Generic (
		W : integer
	);
   Port ( 
		ina : in  STD_LOGIC_VECTOR (W-1 downto 0);
      inb : in  STD_LOGIC_VECTOR (W-1 downto 0);
      aout : out  STD_LOGIC_VECTOR (W-1 downto 0);
      in_c : in  STD_LOGIC;
      out_c : out  STD_LOGIC;
      op : in  alu_operation;
		rsw : in rs_width;
		is_decimal : in std_logic
	);
end af65002alu;

architecture Behavioral of af65002alu is

	-- inputs extended by one bit for carry
	signal ina_ext : std_logic_vector (W downto 0);
	signal inb_ext : std_logic_vector (W downto 0);
	
	signal result 	: std_logic_vector (W downto 0);
	signal resultout : std_logic_vector (W-1 downto 0);
	
	signal tmp_c : std_logic;

	-- type of carry generation
	type c_type is (
		WBIT, INA0, NONE
	);

	signal carry_def : c_type;
	signal inaw1 : std_logic;
	
begin

	input_p : process (rsw, ina, inb)
	begin
		-- default
		ina_ext <= (others => '0');
		inb_ext <= (others => '0');
		-- paste in input data
		case rsw is
		when wBYTE =>
			ina_ext(7 downto 0) <= ina(7 downto 0);
			inb_ext(7 downto 0) <= inb(7 downto 0);
			inaw1 <= ina(7);
		when wWORD =>
			ina_ext(15 downto 0) <= ina(15 downto 0);
			inb_ext(15 downto 0) <= inb(15 downto 0);
			inaw1 <= ina(15);
		when wLONG =>
			ina_ext(minimum(W-1,31) downto 0) <= ina(minimum(W-1,31) downto 0);
			inb_ext(minimum(W-1,31) downto 0) <= inb(minimum(W-1,31) downto 0);
			inaw1 <= ina(minimum(W-1,31));
		when wQUAD =>
			ina_ext(minimum(W-1,63) downto 0) <= ina(minimum(W-1,63) downto 0);
			inb_ext(minimum(W-1,63) downto 0) <= inb(minimum(W-1,63) downto 0);
			inaw1 <= ina(minimum(W-1,63));
		end case;
	end process;

	-- I am pretty sure that this can be further optimized a lot...
	alu : process (in_c, ina_ext, inb_ext, op, rsw, inaw1)
	begin
		-- prepare input
		carry_def <= NONE;		
	
		result <= (others => '0');
		case op is
		when aADC =>
			-- TODO: decimal flag
			result <= ina_ext + inb_ext + in_c;
			carry_def <= WBIT;
		when aADD =>
			result <= ina_ext + inb_ext;
		when aSBC =>
			-- TODO: decimal flag
			result <= not(ina_ext) + inb_ext + in_c;
			carry_def <= WBIT;
		when aSUB =>
			result <= not(ina_ext) + inb_ext + 1;
		-------------------------
		when aROL =>
			result(0) <= in_c;
			result(W downto 1) <= ina_ext (W-1 downto 0) ;
			carry_def <= WBIT;
		when aROR =>
			result(W-2 downto 0) <= ina_ext (W-1 downto 1) ;
			case rsw is
			when wBYTE => result(7) <= in_c;
			when wWORD => result(15) <= in_c;
			when wLONG => result(minimum(W-1,31)) <= in_c;
			when wQUAD => result(minimum(W-1,63)) <= in_c;
			end case;
			carry_def <= INA0;
		when aRDL =>
			result(0) <= inaw1;
			result(W downto 1) <= ina_ext (W-1 downto 0) ;
		when aRDR =>
			result(W-2 downto 0) <= ina_ext (W-1 downto 1) ;
			case rsw is
			when wBYTE => result(7) <= ina_ext(0);
			when wWORD => result(15) <= ina_ext(0);
			when wLONG => result(minimum(W-1,31)) <= ina_ext(0);
			when wQUAD => result(minimum(W-1,63)) <= ina_ext(0);
			end case;
		when aASR =>
			result(W-2 downto 0) <= ina_ext (W-1 downto 1) ;
			result(W-1) <= inaw1;	-- sign
		when aASL =>
			result(0) <= '0';
			result(W downto 1) <= ina_ext (W-1 downto 0) ;
			carry_def <= WBIT;
		when aLSR =>
			result(W-1 downto 0) <= ina_ext (W downto 1) ;
			result(W) <= '0';
			carry_def <= INA0;
		-------------------------
		when aOR =>
			result(W downto 0) <= ina_ext or inb_ext;
		when aAND =>
			result(W downto 0) <= ina_ext and inb_ext;
		when aXOR =>
			result(W downto 0) <= ina_ext xor inb_ext;
		-------------------------
		when aINC =>
			result(W downto 0) <= ina_ext(W downto 0) + 1;
		when aDEC =>
			result(W downto 0) <= ina_ext(W downto 0) - 1;
		-------------------------
		when aINV =>
			result <= not(ina_ext) + 1;
		-------------------------
		when others => 
			-- missing are:
			--
			-- aBCN, aSWP
			--
		end case;
	end process;
	
	output_p : process(rsw, result, ina)
	begin
		-- note: TXS, TYS rely on only incrementing the lower 8 bits
		-- and passing through the upper bits for the restricted stack
		-- feature
		--
		-- default
		resultout <= ina;
		-- now paste in actual result
		case rsw is
		when wBYTE =>
			resultout(7 downto 0) <= result (7 downto 0);
		when wWORD =>
			resultout(15 downto 0) <= result (15 downto 0);
		when wLONG =>
			resultout(minimum(W-1,31) downto 0) <= result (minimum(W-1,31) downto 0);
		when wQUAD =>
			resultout(minimum(W-1,63) downto 0) <= result (minimum(W-1,63) downto 0);
		end case;
		
	end process;

	carry: process(rsw, result, ina, carry_def, in_c)
	begin
		case carry_def is
		when WBIT =>
			case rsw is
			when wBYTE => tmp_c <= result(8);
			when wWORD => tmp_c <= result(minimum(W,16));
			when wLONG => tmp_c <= result(minimum(W,32));
			when wQUAD => tmp_c <= result(minimum(W,64));
			when others => tmp_c <= '0';
			end case;
		when INA0 =>
			tmp_c <= ina(0);
		when NONE =>
			tmp_c <= in_c;
		end case;
	end process;
	out_c <= tmp_c;
	
	aout <= resultout;
	
end Behavioral;

