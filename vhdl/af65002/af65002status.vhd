----------------------------------------------------------------------------------
--
--    af65k CPU status register
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
-- 	entity: 		af65002status
--		purpose:		provides the status register for the af65k CPU
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


entity af65002status is
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
			  -- pull value
           pull_in : in  STD_LOGIC_VECTOR(W-1 downto 0);
			  -- external SO (set overflow flag)
			  ext_so_in : in std_logic;
			  -- set '1' bit
			  stat_brk_bit : in std_logic
			  );
end af65002status;

architecture Behavioral of af65002status is

	signal status_n_int : std_logic;
	signal status_v_int : std_logic;
	signal status_z_int : std_logic;
	signal status_c_int : std_logic;
	signal status_i_int : std_logic;
	signal status_d_int : std_logic;
	
	signal status_x_int : std_logic;
	signal status_u_int : std_logic;

	signal status_n_int_backup : std_logic;
	signal status_v_int_backup : std_logic;
	signal status_z_int_backup : std_logic;
	signal status_c_int_backup : std_logic;
	signal status_i_int_backup : std_logic;
	signal status_d_int_backup : std_logic;

	signal status_n_out : std_logic;
	signal status_v_out : std_logic;
	signal status_z_out : std_logic;
	signal status_c_out : std_logic;
	signal status_i_out : std_logic;
	signal status_d_out : std_logic;

	signal status_x_out : std_logic;
	signal status_u_out : std_logic;

begin

	status_n <= status_n_out;
	status_v <= status_v_out;
	status_z <= status_z_out;
	status_c <= status_c_out;
	status_i <= status_i_out;
	status_d <= status_d_out;
	status_x <= status_x_out;
	is_hypervisor <= not(status_u_out);
	
	status_byte(7) <= status_n_out;
	status_byte(6) <= status_v_out;
	status_byte(5) <= status_x_out;
	status_byte(4) <= stat_brk_bit;
	status_byte(3) <= status_d_out;
	status_byte(2) <= status_i_out;
	status_byte(1) <= status_z_out;
	status_byte(0) <= status_c_out;
	
	ext_status_byte(7 downto 1) <= (others => '0');
	ext_status_byte(0) <= status_u_out;
	
	--------------------------------------------------------------------------------
	-- generate output signals (includes commit/rollback handling)

	xout_p : process(reset, phi2_in, status_x_int)
	begin
		if (reset = '1') then
			status_x_out <= '1';
		elsif (falling_edge(phi2_in)) then
			status_x_out <= status_x_int;
		end if;
	end process;

	uout_p : process(reset, phi2_in, status_u_int)
	begin
		if (reset = '1') then
			status_u_out <= '1';
		elsif (falling_edge(phi2_in)) then
			status_u_out <= status_u_int;
		end if;
	end process;
	
	negout_p : process(reset, phi2_in, status_n_int, status_n_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_n_int_backup <= '0';
			status_n_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_n_int_backup <= status_n_int;
			end if;
			if (rollback = '1') then
				status_n_out <= status_n_int_backup;
			else
				status_n_out <= status_n_int;
			end if;
		end if;
	end process;

	ovlout_p : process(reset, phi2_in, status_v_int, status_v_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_v_int_backup <= '0';
			status_v_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_v_int_backup <= status_v_int;
			end if;
			if (rollback = '1') then
				status_v_out <= status_v_int_backup;
			else
				status_v_out <= status_v_int;
			end if;
		end if;
	end process;

	zeroout_p : process(reset, phi2_in, status_z_int, status_z_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_z_int_backup <= '0';
			status_z_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_z_int_backup <= status_z_int;
			end if;
			if (rollback = '1') then
				status_z_out <= status_z_int_backup;
			else
				status_z_out <= status_z_int;
			end if;
		end if;
	end process;
	
	carryout_p : process(reset, phi2_in, status_c_int, status_c_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_c_int_backup <= '0';
			status_c_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_c_int_backup <= status_c_int;
			end if;
			if (rollback = '1') then
				status_c_out <= status_c_int_backup;
			else
				status_c_out <= status_c_int;
			end if;
		end if;
	end process;
	
	irqout_p : process(reset, phi2_in, status_i_int, status_i_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_i_int_backup <= '0';
			status_i_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_i_int_backup <= status_i_int;
			end if;
			if (rollback = '1') then
				status_i_out <= status_i_int_backup;
			else
				status_i_out <= status_i_int;
			end if;
		end if;
	end process;
	
	decout_p : process(reset, phi2_in, status_d_int, status_d_int_backup, commit, rollback)
	begin
		if (reset = '1') then
			status_d_int_backup <= '0';
			status_d_out <= '0';
		elsif (falling_edge(phi2_in)) then
			if (commit = '1' and rollback = '0') then
				status_d_int_backup <= status_d_int;
			end if;
			if (rollback = '1') then
				status_d_out <= status_d_int_backup;
			else
				status_d_out <= status_d_int;
			end if;
		end if;
	end process;
	
	--------------------------------------------------------------------------------
	--
	-- generate the internal signals
	--
	
	p_neg : process (reset, phi2_in, status_n_in, value_in, value_width_in, pull_in, status_n_out)
	begin	
			case status_n_in is
			when stVALUE =>
				case value_width_in is
				when wBYTE => status_n_int <= value_in(7);
				when wWORD => status_n_int <= value_in(15);
				when wLONG => status_n_int <= value_in(minimum(W-1, 31));
				when wQUAD => status_n_int <= value_in(minimum(W-1, 63));
				end case;
			when stPULL =>
				status_n_int <= pull_in(7);
			when others =>
				status_n_int <= status_n_out;
			end case;
	end process;

	p_ovl : process (reset, phi2_in, status_v_in, value_in, value_width_in, status_c_int, status_n_int,
			ext_so_in, pull_in, status_v_out)
	begin	
			if (ext_so_in = '1') then
				status_v_int <= '1';
			else
				case status_v_in is
				when stVALUE =>
					case value_width_in is
					when wBYTE => status_v_int <= value_in(6);
					when wWORD => status_v_int <= value_in(14);
					when wLONG => status_v_int <= value_in(minimum(W-2, 30));
					when wQUAD => status_v_int <= value_in(minimum(W-2, 62));
					end case;
				when stCLR =>
					status_v_int <= '0';
				when stALU =>
					status_v_int <= not(status_c_int xor status_n_int);
				when stPULL =>
					status_v_int <= pull_in(6);
				when others =>
					status_v_int <= status_v_out;
				end case;
			end if;
	end process;

	p_zero : process (reset, phi2_in, status_z_in, value_in, value_width_in,
			pull_in, status_z_out)
	begin	
		case status_z_in is
		when stVALUE =>
			case value_width_in is
			when wBYTE => 
				if (value_in(7 downto 0) = (7 downto 0 => '0')) then
					status_z_int <= '1';
				else 
					status_z_int <= '0';
				end if;
			when wWORD => 
				if (value_in(15 downto 0) = (15 downto 0 => '0')) then
					status_z_int <= '1';
				else 
					status_z_int <= '0';
				end if;
			when wLONG => 
				if (value_in(minimum(W-1, 31) downto 0) = (minimum(W-1, 31) downto 0 => '0')) then
					status_z_int <= '1';
				else 
					status_z_int <= '0';
				end if;
			when wQUAD => 
				if (value_in(minimum(W-1, 63) downto 0) = (minimum(W-1, 63) downto 0 => '0')) then
					status_z_int <= '1';
				else 
					status_z_int <= '0';
				end if;
			end case;
		when stPULL =>
			status_z_int <= pull_in(1);
		when others =>
			status_z_int <= status_z_out;
		end case;
	end process;
	
	p_carry : process (reset, phi2_in, status_c_in, alu_c_in, pull_in, status_c_out)
	begin	
			case status_c_in is
			when stCLR =>
				status_c_int <= '0';
			when stSET =>
				status_c_int <= '1';
			when stALU =>
				status_c_int <= alu_c_in;
			when stPULL =>
				status_c_int <= pull_in(0);
			when others =>
				status_c_int <= status_c_out;
			end case;
	end process;

	p_irq : process (reset, phi2_in, status_i_in, pull_in, status_i_out)
	begin	
			case status_i_in is
			when stCLR =>
				status_i_int <= '0';
			when stSET =>
				status_i_int <= '1';
			when stPULL =>
				status_i_int <= pull_in(2);
			when others =>
				status_i_int <= status_i_out;
			end case;
	end process;
	
	p_dec : process (reset, phi2_in, status_d_in, pull_in, status_d_out)
	begin	
			case status_d_in is
			when stCLR =>
				status_d_int <= '0';
			when stSET =>
				status_d_int <= '1';
			when stPULL =>
				status_d_int <= pull_in(3);
			when others =>
				status_d_int <= status_d_out;
			end case;
	end process;	

	p_ext : process (reset, phi2_in, status_x_in, pull_in, status_x_out)
	begin	
			case status_x_in is
			when stCLR =>
				status_x_int <= '0';
			when stSET =>
				status_x_int <= '1';
			when stPULL =>
				status_x_int <= pull_in(5);
			when others =>
				status_x_int <= status_x_out;
			end case;
	end process;	

	p_user : process (reset, phi2_in, status_u_in, pull_in, status_u_out)
	begin	
			case status_u_in is
			when stCLR =>
				status_u_int <= '0';
			when stSET =>
				status_u_int <= '1';
			when stPULL =>
				status_u_int <= pull_in(0);
			when others =>
				status_u_int <= status_u_out;
			end case;
	end process;	
	
end Behavioral;

