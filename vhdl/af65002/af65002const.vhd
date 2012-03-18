----------------------------------------------------------------------------------
--
--    Constants for the af65k CPU
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
-- 	entity: 		af65002const
--		purpose:		Constants that can be fed into the CPU busses
--		features:	
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65k.all;


entity af65002const is
	Generic (
		W : in integer
	);
   Port ( 
		constname : in const_type;
      value : out STD_LOGIC_VECTOR (W-1 downto 0)
	);
end af65002const;

architecture Behavioral of af65002const is

begin

	value_p : process(constname)
	begin
		case constname is
		when cRESET =>
			value(7 downto 0) <= X"fc";
			value(W-1 downto 8) <= (others => '1');
		when cIRQ =>
			value(7 downto 0) <= X"fe";
			value(W-1 downto 8) <= (others => '1');
		when cNMI =>
			value(7 downto 0) <= X"fa";
			value(W-1 downto 8) <= (others => '1');
		when cABORT =>
			value(7 downto 0) <= X"f8";
			value(W-1 downto 8) <= (others => '1');
		when cZERO | c1m1 =>
			value(W-1 downto 0) <= (others => '0');
		when c2 =>
			value(7 downto 0) <= X"02";
			value(W-1 downto 8) <= (others => '0');
		when c4 =>
			value(7 downto 0) <= X"04";
			value(W-1 downto 8) <= (others => '0');
		when c8 =>
			value(7 downto 0) <= X"08";
			value(W-1 downto 8) <= (others => '0');
		when c2m1 | c1 =>
			value(7 downto 0) <= X"01";
			value(W-1 downto 8) <= (others => '0');
		when c4m1 =>
			value(7 downto 0) <= X"03";
			value(W-1 downto 8) <= (others => '0');
		when c8m1 =>
			value(7 downto 0) <= X"07";
			value(W-1 downto 8) <= (others => '0');
		when cSTACK_INIT =>
			-- internal stack representation is programming model value plus one
			value(11 downto 0) <= X"100";	
			value(W-1 downto 12) <= (others => '0');
		end case;
	end process;

end Behavioral;

