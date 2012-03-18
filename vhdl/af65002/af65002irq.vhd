----------------------------------------------------------------------------------
--
--    Interrupt controller for the af65k CPU
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
-- 	entity: 		af65002irq
--		purpose:		Takes interrupts from the bus and distributes them to the cores
--		features:	- currently all interrupts go to core 0
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65k.all;


entity af65002irq is
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
			irqeffmask_in : in irqlevels_t; --array(0 to CORES-1) of irqlevel_t;
			
			-- current values
			-- mask
			irqmask : out irqlevel_t;
			-- current inputs
			irqlevel : out irqlevel_t;
			
			-- target level for each core
			-- here the actual interrupts are controlled
			coreirqlevel : out irqlevels_t --array(0 to CORES-1) of irqlevel_t;
	 );
end af65002irq;

architecture Behavioral of af65002irq is

	-- internal mirror; taken on phi2 transition before
	-- priority encoding - to avoid glitches in prio encoding
	signal irqin_int : std_logic_vector(6 downto 0);
	
	-- internal signal so we can reuse it
	signal irqlevel_int : irqlevel_t;
	-- stored value from irqmask_in
	signal irqmask_int : irqlevel_t;
	
begin

	-- well this is currently very (too) simple...
	-- interrupts are always only pointed to the first core
	target_p : process(irqlevel_int, irqmask_int)
	begin
		for i in 1 to CORES-1 loop
			coreirqlevel(i) <= "111";
		end loop;
		if (irqlevel_int <= irqmask_int) then
			coreirqlevel(0) <= irqlevel_int;
		else
			coreirqlevel(0) <= "111";
		end if;
	end process;
	
	irqin_p : process(phi2, irqin)
	begin
		if (falling_edge(phi2)) then
			irqin_int <= irqin;
		end if;
	end process;
	
	-- note: this only works for single-core
	-- any multi-core should distribute multiple concurrent interrupts
	-- to multiple cores if possible
	irqlevel_p : process(irqin_int) --, phi2)
	begin
	
		irqlevel_int <= "111";
		if (irqin_int(0) = '1') then
			irqlevel_int <= "000";
		elsif (irqin_int(1) = '1') then
			irqlevel_int <= "001";
		elsif (irqin_int(2) = '1') then
			irqlevel_int <= "010";
		elsif (irqin_int(3) = '1') then
			irqlevel_int <= "011";
		elsif (irqin_int(4) = '1') then
			irqlevel_int <= "100";
		elsif (irqin_int(5) = '1') then
			irqlevel_int <= "101";
		elsif (irqin_int(6) = '1') then
			irqlevel_int <= "110";
		end if;
	end process;
	irqlevel <= irqlevel_int;

	-- store irq mask
	irqmask_p : process(reset, phi2, irqmask_in, irqmask_valid) 
	begin
		if (reset = '1') then
			irqmask_int <= "111";	-- test; "000"; --only allow NMI
		elsif (falling_edge(phi2)) then
			if (irqmask_valid = '1') then
				irqmask_int <= irqmask_in;
			end if;
		end if;
	end process;
	irqmask <= irqmask_int;
	
end Behavioral;

