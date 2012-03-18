----------------------------------------------------------------------------------
--
--    Register file for the af65k CPU
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
-- 	entity: 		af65002regs
--		purpose:		Stores the register values
--		features:	
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		todo:			- Check how this can be done into block memory(?)
--						- separate out USP/SSP, as they have special rollback handling
--						- currently read address is taken one cycle before data is available
--						  (to enable move into block memory)
--						  this produces overhead in the controller and delays, Check if this
--						  is necessary for block memory, or if taking value on rising phi2 
--						  suffices, or we just use normal latches instead of block memory
--
--		Changes:		
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65k.all;


entity af65002regs is
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
end af65002regs;

architecture Behavioral of af65002regs is

	subtype reg is std_logic_vector(W-1 downto 0);
	type regfile is array (0 to NumReg-1) of reg;
	
	signal ram : regfile;
	
	signal usp : reg;
	signal ssp : reg;
	signal usp_int : reg;
	signal ssp_int : reg;
	signal usp_backup : reg;
	signal ssp_backup : reg;
	
begin


	usp_p : process(reset, phi2, usp_int, usp_backup, commit, rollback, wr_regno, wrvalid)
	begin
		-- determine next usp reg value
		if (reset = '1') then
			usp <= (others => '0');
		elsif (falling_edge(phi2)) then
			if (rollback = '1') then
				usp <= usp_backup;
			elsif (reset = '0' and wrvalid = '1' and wr_regno = rUSP) then
				usp <= usp_int;
				if (commit = '1') then
					usp_backup <= usp_int;
				end if;
			elsif (commit = '1') then
				usp_backup <= usp;
			end if;
		end if;
	end process;

	ssp_p : process(reset, phi2, ssp_int, ssp_backup, commit, rollback, wr_regno, wrvalid)
	begin
		-- determine next usp reg value
		-- determine next usp reg value
		if (reset = '1') then
			ssp <= (others => '0');
		elsif (falling_edge(phi2)) then
			if (rollback = '1') then
				ssp <= ssp_backup;
			elsif ((reset = '0') and (wrvalid = '1') and (wr_regno = rSSP)) then
				ssp <= ssp_int;
				if (commit = '1') then
					ssp_backup <= ssp_int;
				end if;
			elsif (commit = '1') then
				ssp_backup <= ssp;
			end if;
		end if;
	end process;

	
	usp_int_p : process(phi2, wr_data, wrvalid, wr_width, usp)
	begin
		-- determine what would be the next usp reg value
		case wr_width is
		when wBYTE =>
			usp_int(7 downto 0) <= wr_data(7 downto 0);
			usp_int(W-1 downto 8) <= usp(W-1 downto 8);
		when wWORD =>
			usp_int(15 downto 0) <= wr_data(15 downto 0);
			usp_int(W-1 downto minimum(W-1,16)) <= usp(W-1 downto minimum(W-1,16));
		when wLONG =>
			usp_int(minimum(W-1,31) downto 0) <= wr_data(minimum(W-1,31) downto 0);
			usp_int(W-1 downto minimum(W-1,32)) <= usp(W-1 downto minimum(W-1,32));
		when wQUAD =>
			usp_int(W-1 downto 0) <= wr_data(W-1 downto 0);
		end case;
	end process;
	
	ssp_int_p : process(phi2, wr_data, wrvalid, wr_width, ssp)
	begin
		-- determine what would be the next usp reg value
		case wr_width is
		when wBYTE =>
			ssp_int(7 downto 0) <= wr_data(7 downto 0);
			ssp_int(W-1 downto 8) <= ssp(W-1 downto 8);
		when wWORD =>
			ssp_int(15 downto 0) <= wr_data(15 downto 0);
			ssp_int(W-1 downto minimum(W-1,16)) <= ssp(W-1 downto minimum(W-1,16));
		when wLONG =>
			ssp_int(minimum(W-1,31) downto 0) <= wr_data(minimum(W-1,31) downto 0);
			ssp_int(W-1 downto minimum(W-1,32)) <= ssp(W-1 downto minimum(W-1,32));
		when wQUAD =>
			ssp_int(W-1 downto 0) <= wr_data(W-1 downto 0);
		end case;
	end process;	
	
	writereg : process(phi2, wr_regno, wr_data, wrvalid, wr_width)
	begin
		if (falling_edge(phi2)) then
			if (reset = '0' and wrvalid = '1' and wr_regno < rNONE) then
				case wr_width is
				when wBYTE =>
					ram(wr_regno)(7 downto 0) <= wr_data(7 downto 0);
				when wWORD =>
					ram(wr_regno)(15 downto 0) <= wr_data(15 downto 0);
				when wLONG =>
					ram(wr_regno)(minimum(W-1,31) downto 0) <= wr_data(minimum(W-1,31) downto 0);
				when wQUAD =>
					ram(wr_regno)(W-1 downto 0) <= wr_data(W-1 downto 0);
				end case;
			end if;
		end if;
	end process;

	readreg : process(phi2, rd_regno, reset, wrvalid, wr_regno, ssp_backup, usp_backup)
	begin
	
		if (reset = '1') then
			rd_data <= (others => '0');
		elsif (falling_edge(phi2)) then
			if (rd_regno < rNONE or rd_regno = rUSP or rd_regno = rSSP) then
				-- only overwrite the output value when 
				-- explicit register is set
				-- (control can only set it once, then leave as 
				-- rNONE during read wait states for example)
				if (rd_regno = rUSP) then
					rd_data <= usp;
					if (rollback = '1') then
						rd_data <= usp_backup;
					end if;
				elsif (rd_regno = rSSP) then
					rd_data <= ssp;
					if (rollback = '1') then
						rd_data <= ssp_backup;
					end if;
				else
					rd_data <= ram(rd_regno);
				end if;
				if (wrvalid = '1' and wr_regno = rd_regno) then
					case wr_width is
					when wBYTE =>
						rd_data(7 downto 0) <= wr_data(7 downto 0);
					when wWORD =>
						rd_data(15 downto 0) <= wr_data(15 downto 0);
					when wLONG =>
						rd_data(minimum(W-1,31) downto 0) <= wr_data(minimum(W-1,31) downto 0);
					when wQUAD =>
						rd_data(W-1 downto 0) <= wr_data(W-1 downto 0);
					end case;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

