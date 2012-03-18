----------------------------------------------------------------------------------
--
--    Bus extender to extend values to a wider bus width
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
-- 	entity: 		af65002ext
--		purpose:		Extends a bus to a wider bus width using the given extension type
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



entity af65002ext is
	Generic (
		W : integer
	);
   Port ( 
		extmode : in ext_type;
      insize : in rs_width;
      indata : in  STD_LOGIC_VECTOR (W-1 downto 0);
		altdata : in STD_LOGIC_VECTOR (W-1 downto 8);
      outdata : out  STD_LOGIC_VECTOR (W-1 downto 0)
	);
end af65002ext;

architecture Behavioral of af65002ext is

begin

	word_g : if (W=16) generate
		extend_p : process(extmode, insize, indata, altdata)
		begin
			outdata <= indata;
			case extmode is
			when eZERO =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '0');
				when wWORD =>
				when wLONG =>
				when wQUAD =>
				end case;
			when eONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '1');
				when wWORD =>
				when wLONG =>
				when wQUAD =>
				end case;
			when eSIGN =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => indata(7));
				when wWORD =>
				when wLONG =>
				when wQUAD =>
				end case;
			when eNONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= altdata(W-1 downto 8);
				when wWORD =>
				when wLONG =>
				when wQUAD =>
				end case;
			end case;
		end process;
	end generate;
	
	long_g : if (W=32) generate
		extend_p : process(extmode, insize, indata, altdata)
		begin
			outdata <= indata;
			case extmode is
			when eZERO =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '0');
				when wWORD =>
					outdata(W-1 downto 16) <= (others => '0');
				when wLONG =>
				when wQUAD =>
				end case;
			when eONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '1');
				when wWORD =>
					outdata(W-1 downto 16) <= (others => '1');
				when wLONG =>
				when wQUAD =>
				end case;
			when eSIGN =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => indata(7));
				when wWORD =>
					outdata(W-1 downto 16) <= (others => indata(15));
				when wLONG =>
				when wQUAD =>
				end case;
			when eNONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= altdata(W-1 downto 8);
				when wWORD =>
					outdata(W-1 downto 16) <= altdata(W-1 downto 16);
				when wLONG =>
				when wQUAD =>
				end case;
			end case;
		end process;
	end generate;
	
	quad_g : if (W=64) generate
		extend_p : process(extmode, insize, indata, altdata)
		begin
			outdata <= indata;
			case extmode is
			when eZERO =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '0');
				when wWORD =>
					outdata(W-1 downto 16) <= (others => '0');
				when wLONG =>
					outdata(W-1 downto 32) <= (others => '0');
				when wQUAD =>
				end case;
			when eONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => '1');
				when wWORD =>
					outdata(W-1 downto 16) <= (others => '1');
				when wLONG =>
					outdata(W-1 downto 32) <= (others => '1');
				when wQUAD =>
				end case;
			when eSIGN =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= (others => indata(7));
				when wWORD =>
					outdata(W-1 downto 16) <= (others => indata(15));
				when wLONG =>
					outdata(W-1 downto 32) <= (others => indata(31));
				when wQUAD =>
				end case;
			when eNONE =>
				case insize is
				when wBYTE =>
					outdata(W-1 downto 8) <= altdata(W-1 downto 8);
				when wWORD =>
					outdata(W-1 downto 16) <= altdata(W-1 downto 16);
				when wLONG =>
					outdata(W-1 downto 32) <= altdata(W-1 downto 32);
				when wQUAD =>
				end case;
			end case;
		end process;
	end generate;
	
end Behavioral;

	