
----------------------------------------------------------------------------------
--
--    Control sequencer for opcode operations
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
-- 	entity: 		af65002ctrl
--		purpose:		controller for all other parts during opcode execution
--		features:	- timing is better than 6502 in some cases
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65k.all;


entity af65002ctrl is
	Generic (
		-- full width for address computations (given to ALU adds)
		full_width : in rs_width
	);
   Port ( 
		reset : in std_logic;
		phi2 : in std_logic;
		is_hypervisor : in std_logic;
		ovalid : in  STD_LOGIC;
      outrdy : out  STD_LOGIC;
      operation : in cpu_operation;
      admode : in cpu_syntax;
		idxreg : in idx_register;
      parwidth : in par_width;
      indwidth : in rs_width;
      prefix_le : in ext_type;
      prefix_rs : in rs_width;
      prefix_um : in  STD_LOGIC;
      prefix_nf : in  STD_LOGIC;
      prefix_of : in of_type;
		---------------------------------------------
		-- output control values
		--
		-- output when memory access is requested
		is_memrw : out std_logic;
		memrw_type : out memrw_t;		-- defines type of memory access
		memrw_hyper : out std_logic;		-- set when memory access is in hypervisor space
		memrw_width : out rs_width;
		-- returns when memory access is done
		is_memrw_done : in std_logic;
		is_memrw_err : in buserr_t;
		-- is memory access read or write?
		mem_rnw : out std_logic;
		-- bus configuration
		sel_inbus : out inbus_source;
		sel_regbus : out regbus_source;
		sel_outbus : out outbus_source;
		sel_addrout : out out_source;
		sel_dataout : out out_source;
		take_addr: out std_logic;			-- when set, take address from addrout into addr out register
		take_pc: out std_logic;				-- when set, take new PC from outbus
		inbus_ext_type : out ext_type;
		inbus_ext_width : out rs_width;
		outbus_ext_type : out ext_type;
		outbus_ext_width : out rs_width;
		constname : out const_type;
		-- register config
		tempreg_latch : out std_logic;
		sel_store_to_reg : out cpu_register;
		store_to_reg_width : out rs_width;
		sel_read_from_reg : out cpu_register;
		-- ALU configuration
      alu_op : out  alu_operation;
		alu_op_width : out rs_width;
		-- hypervisor mode control
		st_u : out st_in_type;
		st_x : out st_in_type;
		-- status control
		st_n : out st_in_type;
		st_v : out st_in_type;
		st_z : out st_in_type;
		st_c : out st_in_type;
		st_i : out st_in_type;
		st_d : out st_in_type;
		st_value_width : out rs_width;
		stat_brk_bit : out std_logic;
		-- status values
		st_n_in : in std_logic;
		st_v_in : in std_logic;
		st_z_in : in std_logic;
		st_c_in : in std_logic;
		st_x_in : in std_logic;			-- is extended stack frame?
		-- interrupt handling
		release_irqlevel : out std_logic;	-- when set, clear interrupt level
		-- configuration section (runtime config)
		is_restricted_stack : in std_logic;
		user_width : in rs_width;		-- address width in user mode
		-- commit/rollback handling
		-- when commit is _not_ set, any changes are temporary until commit is set again
		-- when rollback is set, temporary changes are rolled back 
		commit : out std_logic;
		rollback : out std_logic;
		abort_vec : out abort_t
	);
end af65002ctrl;

architecture Behavioral of af65002ctrl is

	-- buffered input
   signal operation_b : cpu_operation := xNOP;
   signal admode_b : cpu_syntax := sUNKNOWN;
   signal parwidth_b : par_width := pNONE;
	signal indwidth_b : rs_width := wBYTE;
	signal idxreg_b : idx_register := iXR;
	
	signal prefix_le_b : ext_type := eNONE;
   signal prefix_rs_b : rs_width := wBYTE;
   --signal prefix_um_b : STD_LOGIC;
   signal prefix_nf_b : STD_LOGIC := '0';
   signal prefix_of_b : of_type := oNONE;

	-- internal state
	
	-- true when buffers needs to be refilled
	signal is_init : std_logic;
	-- set on last opcode cycle, signals pre-decode for next addressing mode
	signal last_op_cycle : std_logic;
	-- set on last addressing mode cycle, signals pre-decode for operation
	signal last_ad_cycle : std_logic;

	subtype cnt_t is integer range 0 to 15;
	signal resolve_cnt : cnt_t;
	signal operation_cnt : cnt_t;

	-- internal signals pre-decode
	signal resp_read_from_reg : cpu_register;
	
	-- internal signals decode
	signal res_addrout : out_source;
	signal res_dataout : out_source;
	signal res_inbus : inbus_source;
	signal res_regbus : regbus_source;
	signal res_outbus : outbus_source;
	signal res_memrw : std_logic;
	signal res_mem_rnw : std_logic;
	signal res_store_to_reg : cpu_register;
	signal res_read_from_reg : cpu_register;
	signal res_alu : alu_operation;
	signal res_alu_width : rs_width;
	signal res_memrw_width : rs_width;
	signal res_tempreg_latch : std_logic;
	signal res_take_addr : std_logic;
	signal res_inbus_ext_type : ext_type;
	signal res_inbus_ext_width : rs_width;
	signal res_outbus_ext_type : ext_type;
	signal res_outbus_ext_width : rs_width;
	signal res_skip_next : std_logic;		-- when set, skip next cycle (e.g. for option OF prefix)
	signal res_memrw_type : memrw_t;
	signal res_memrw_hyper : std_logic;
	
	-- internal signals pre-operation
	signal opp1_read_from_reg : cpu_register;
	signal opp2_read_from_reg : cpu_register;
	
	-- internal signals operation
	signal op_addrout : out_source;
	signal op_dataout : out_source;
	signal op_inbus : inbus_source;
	signal op_regbus : regbus_source;
	signal op_outbus : outbus_source;
	signal op_memrw : std_logic;
	signal op_mem_rnw : std_logic;
	signal op_store_to_reg : cpu_register;
	signal op_store_to_reg_width : rs_width;
	signal op_read_from_reg : cpu_register;
	signal op_alu : alu_operation;
	signal op_alu_width : rs_width;
	signal op_memrw_width : rs_width;
	signal op_tempreg_latch : std_logic;
	signal op_take_addr : std_logic;
	signal op_inbus_ext_type : ext_type;
	signal op_inbus_ext_width : rs_width;
	signal op_outbus_ext_type : ext_type;
	signal op_outbus_ext_width : rs_width;
	--
	signal op_st_u : st_in_type;
	signal op_st_x : st_in_type;
	--
	signal op_st_n : st_in_type;
	signal op_st_v : st_in_type;
	signal op_st_z : st_in_type;
	signal op_st_c : st_in_type;
	signal op_st_i : st_in_type;
	signal op_st_d : st_in_type;
	signal op_st_value_width : rs_width;
	signal op_jmp : std_logic;
	signal op_memrw_type : memrw_t;
	signal op_memrw_hyper : std_logic;
	
	signal op_stat_brk_bit : std_logic;
	
	signal op_commit : std_logic;
	
	signal is_op_mode : std_logic;
	signal is_predecode : std_logic;
	signal start_control : std_logic;
	
	signal op_wait : std_logic;			-- set to 1 when operation done
	signal res_wait : std_logic;
	
	signal indreg : cpu_register;

	signal cur_stack_pointer : cpu_register;
	signal cur_stack_pointer_b : cpu_register; -- := rUSP;
	signal irq_stack_pointer : cpu_register;
	signal irq_stack_pointer_b : cpu_register; -- := rUSP;
	
	signal is_hypervisor_b : std_logic;
	signal is_restricted_stack_b : std_logic;
	
	signal op_release_irqlevel : std_logic;
	
	-- set when a rollback occurred, and reset on a new start
	signal is_rollback : std_logic;
	--buffered version
	signal is_rollback_b : std_logic;
	
begin

	sp: process(is_hypervisor, prefix_um, operation)
	begin
		if (is_hypervisor = '1' and prefix_um = '0') then 
			cur_stack_pointer <= rSSP;
		else
			cur_stack_pointer <= rUSP;
		end if;
		if (is_hypervisor = '0' and operation = xBRK) then 
			irq_stack_pointer <= rUSP;
		else
			irq_stack_pointer <= rSSP;
		end if;
	end process;
	
	-- create is_init signal
	init_p : process(phi2, reset)
	begin
		-- TODO re-init?
		if (reset = '1') then
			is_init <= '1';
		elsif (falling_edge(phi2)) then
			if (ovalid = '1') then
				is_init <= '0';
			end if;
		end if;
	end process;

	rollback_p : process(phi2, reset, is_memrw_done, is_memrw_err, is_rollback_b, start_control)
	begin
		if (reset = '1') then
			is_rollback <= '0';
			abort_vec <= abNONE;
		elsif (rising_edge(phi2)) then
			-- is_memrw_err is masked with is_rollback_b, to avoid hanging in operation_cnt=0
			-- in an abort after the final write in an RTI traps
			if (is_memrw_done = '1' and is_rollback_b = '0' and not(is_memrw_err = beOK)) then
				is_rollback <= '1';
				abort_vec <= memrw_buserr_abort_vec(is_memrw_err);
			elsif (start_control = '1' and is_rollback_b = '1') then
				is_rollback <= '0';
			end if;
		end if;
	end process;
	
	rollback_b_p : process(phi2, reset, is_rollback, start_control)
	begin
		if (reset = '1') then
			is_rollback_b <= '0';
		elsif (falling_edge(phi2)) then
			-- create buffered version; extra cycle on rollback gives usp/ssp time to recover
			is_rollback_b <= is_rollback;
--			if (start_control = '1') then
--				is_rollback_b <= '0';
--			end if;
		end if;
	end process;
	rollback <= is_rollback;
	
	start_control <= is_predecode;
	
	-- count operation/addressing mode states
	count_p : process(phi2, reset, last_op_cycle, last_ad_cycle, start_control, admode, operation,
					op_memrw, is_memrw_done, is_rollback, is_op_mode, op_wait, is_rollback)
	begin
		if (reset = '1') then
			resolve_cnt <= 0;
			operation_cnt <= 0;
			is_op_mode <= '0';
		elsif (falling_edge(phi2)) then
		
			if (start_control = '1') then
				resolve_cnt <= 0;
			elsif (is_rollback = '0' 
					and is_op_mode = '0' and res_wait = '0' and (res_memrw = '0' or is_memrw_done = '1')) then 
				if (res_skip_next = '1') then 
					resolve_cnt <= resolve_cnt + 2;
				else
					resolve_cnt <= resolve_cnt + 1;
				end if;
			end if;
			
			if (last_ad_cycle = '1') then
				-- start operation when addressing done
				operation_cnt <= 0;
				is_op_mode <= '1';
			elsif (start_control = '1' and (admode = sIMPLIED or operation = xBRK)
						and (op_memrw = '0' or is_memrw_done = '1')) then
				-- start operation when implied addressing mode
				-- Do the latter directly, without addressing mode phase
				-- Note: needs specific sIMPLIED predecode to read register
				-- Note: BRK needs to start with operation_cnt=0 even though it is "immediate"
				operation_cnt <= 0;
				is_op_mode <= '1';
			elsif (start_control = '1' and admode = sIMMEDIATE
						and (op_memrw = '0' or is_memrw_done = '1')) then
				-- start operation when immediate addressing mode, but at cycle 1 (after the read)
				-- Do the latter directly, without addressing mode phase
				-- This allows to reuse non-immediate processing with immediate processing
				-- Note: needs specific sIMMEDIATE predecode (duplicates the 
				-- register read in the first operation control cycle that otherwise reads
				-- the operand and is skipped here
				operation_cnt <= 1;
				is_op_mode <= '1';
			elsif (start_control = '1') then
				is_op_mode <= '0';
				if (op_memrw = '0' or is_memrw_done = '1') then 
					operation_cnt <= operation_cnt + 1;
				end if;
			elsif (is_rollback = '0' and is_op_mode = '1' and op_wait = '0' 
					and (op_memrw = '0' or is_memrw_done = '1')) then 
				operation_cnt <= operation_cnt + 1;
			end if;
		end if;
	end process;
	
	buffer_input_p : process(phi2, reset)
	begin
		if (falling_edge(phi2)) then
			if (start_control = '1') then
				operation_b <= operation;
				admode_b <= admode;
				parwidth_b <= parwidth;
				indwidth_b <= indwidth;
				idxreg_b <= idxreg;
				prefix_le_b <= prefix_le;				
				prefix_rs_b <= prefix_rs;
				--prefix_um_b <= prefix_um;
				prefix_nf_b <= prefix_nf;
				prefix_of_b <= prefix_of;
				cur_stack_pointer_b <= cur_stack_pointer;
				irq_stack_pointer_b <= irq_stack_pointer;
				is_hypervisor_b <= is_hypervisor;
				is_restricted_stack_b <= is_restricted_stack;
			end if;
		end if;
	end process;
	

	---------------------------
	-- select the actual output values

	-- set during the cycle before the first "official" cycle of an opcode,
	-- i.e. during the last cycle of the previous opcode
	is_predecode <= '1' when ovalid='1' and (is_init = '1' or is_rollback = '1'
														or (last_op_cycle = '1' and (op_memrw = '0' or is_memrw_done = '1'))
														or op_wait = '1') else '0';
	outrdy <= is_predecode after 2 ns;
	
	sel_addrout <= res_addrout when is_op_mode = '0' else op_addrout;
	sel_dataout <= res_dataout when is_op_mode = '0' else op_dataout;
	sel_inbus <= res_inbus when is_op_mode = '0' else op_inbus;
	sel_outbus <= res_outbus when is_op_mode = '0' else op_outbus;
	sel_regbus <= res_regbus when is_op_mode = '0' else op_regbus;

	inbus_ext_type <= res_inbus_ext_type when is_op_mode = '0' else op_inbus_ext_type;
	inbus_ext_width <= res_inbus_ext_width when is_op_mode = '0' else op_inbus_ext_width;
	outbus_ext_type <= res_outbus_ext_type when is_op_mode = '0' else op_outbus_ext_type;
	outbus_ext_width <= res_outbus_ext_width when is_op_mode = '0' else op_outbus_ext_width;
	
	take_addr <= res_take_addr when is_op_mode = '0' else op_take_addr;
	is_memrw <= res_memrw when is_op_mode = '0' else op_memrw;
	memrw_width <= res_memrw_width when is_op_mode = '0' else op_memrw_width;
	memrw_type <= res_memrw_type when is_op_mode = '0' else op_memrw_type;
	memrw_hyper <= res_memrw_hyper when is_op_mode = '0' else op_memrw_hyper;
	mem_rnw <= res_mem_rnw when is_op_mode = '0' else op_mem_rnw;
	sel_store_to_reg <= rNONE when is_rollback = '1' else res_store_to_reg when is_op_mode = '0' else op_store_to_reg;
	tempreg_latch <= res_tempreg_latch when is_op_mode = '0' else op_tempreg_latch;
	
	alu_op <= res_alu when is_op_mode = '0' else op_alu;
	alu_op_width <= res_alu_width when is_op_mode = '0' else op_alu_width;

	-- only in opcode phase
	store_to_reg_width <= op_store_to_reg_width;
	st_u <= op_st_u;
	st_x <= op_st_x;
	st_n <= op_st_n;
	st_v <= op_st_v;
	st_z <= op_st_z;
	st_c <= op_st_c;
	st_i <= op_st_i;
	st_d <= op_st_d;
	st_value_width <= op_st_value_width;
	take_pc <= op_jmp;
	stat_brk_bit <= op_stat_brk_bit;
	release_irqlevel <= op_release_irqlevel;
	commit <= '1' when is_op_mode = '0' else op_commit;
	
	-- determine the register to read from. This depends on the 
	-- count state ( sel predecode, sel, op predecode, op ) and
	-- the addressing mode
	read_reg_p : process(res_read_from_reg, op_read_from_reg, resp_read_from_reg, 
		opp1_read_from_reg, opp2_read_from_reg, is_op_mode, is_predecode, admode, last_ad_cycle)
	begin
		if (is_predecode = '1') then
			-- in predecode we already read the value for the next opcode,
			-- as the register value read only becomes ready in the next cycle,
			-- but for the current opcode there is no next cycle
			if (admode = sIMPLIED or admode = sIMMEDIATE) then
				-- if implied, make sure we prepare for the opcode by reading the register
				sel_read_from_reg <= opp1_read_from_reg;
			else
				-- else read the resolver predecode requested register
				-- (never set on sIMPLIED)
				sel_read_from_reg <= resp_read_from_reg;
			end if;
		else
			-- we are in an active opcode
			if (last_ad_cycle = '1') then
				-- we are in the last resolver (addressing mode) cycle
				-- then read the register determined by operation predecode
				sel_read_from_reg <= opp2_read_from_reg;
			elsif (is_op_mode = '1') then
				-- operation mode, then read register for operation control
				sel_read_from_reg <= op_read_from_reg;
			else
				-- not operation mode, then read register for resolver control
				sel_read_from_reg <= res_read_from_reg;
			end if;
		end if;
	end process;
	
	---------------------------
	
	indreg <= cpu_reg_idx_reg(idxreg);
	
	-- addressing mode predecode; use unbuffered inputs
	resolve_predecode_p : process(phi2, admode, is_predecode, indreg, prefix_of, prefix_um, cur_stack_pointer)
	begin
		resp_read_from_reg <= rNONE;
		if (is_predecode = '1') then
			case admode is
			when sABSOLUTE | sINDIRECT | sPOSTINDIRECT | sADDR =>
				case prefix_of is
				when oBASE => 
					resp_read_from_reg <= rB;
				when oSP => 
					resp_read_from_reg <= cur_stack_pointer;
				when others =>
					-- note that oPC handling is ... different ...
				end case;
			when sABSOLUTEIND =>
				resp_read_from_reg <= indreg;
			when sPREINDIRECT =>
				resp_read_from_reg <= indreg;
			when sEINDIRECT =>
				resp_read_from_reg <= rE;
			when others =>
			end case;
		end if;
	end process;

	-- addressing mode decode; use buffered inputs
	--
	-- result is the address in addr_out but also in the tempreg latch
	-- The latter is used in the JMP operation for example.
	--
	resolve_p : process(phi2, admode_b, resolve_cnt, prefix_rs_b, prefix_le_b, prefix_of_b, last_op_cycle,
			parwidth_b, indwidth_b, idxreg_b, cur_stack_pointer_b, operation_b, is_hypervisor_b, is_op_mode)
	begin
		last_ad_cycle <= '0';
		res_wait <= '0';
		res_addrout <= NO_BUS;
		res_dataout <= NO_BUS;
		res_inbus <= IB_NONE;
		res_regbus <= RB_NONE;
		res_outbus <= OB_ALU;
		res_mem_rnw <= '1';		-- read
		res_memrw <= '0';			-- no access
		res_memrw_width <= wBYTE;	
		res_store_to_reg <= rNONE;
		res_read_from_reg <= rNONE;
		res_alu <= aNONE;
		res_alu_width <= full_width;
		res_tempreg_latch <= '0';
		res_take_addr <= '0';
		res_inbus_ext_type <= eZERO;
		res_inbus_ext_width <= full_width;
		res_outbus_ext_type <= eZERO;
		res_outbus_ext_width <= full_width;
		res_memrw_type <= rwADDR;
		res_skip_next <= '0';
		
		-- TODO: actually set res_memrw_hyper correctly in processes below
		if ((is_hypervisor_b = '1')) then -- and (prefix_um_b = '0')) then
			res_memrw_hyper <= '1';
		else
			res_memrw_hyper <= '0';
		end if;
		
		if (is_op_mode = '0') then
		case admode_b is 
		-------------------------------------------------------------------------
		-- relative addressing modes (rel, relwide, rellong, relquad)
		-- used for both branches and BSR
		--
		when sREL =>
			case resolve_cnt is
			when 0 =>
				-- extend parameter
				res_inbus <= IB_PARAM;
				res_inbus_ext_type <= eSIGN; 	-- this is different from other modes
				res_inbus_ext_width <= par_width_rs_width(parwidth_b);
				-- setup other side of ALU
				res_regbus <= RB_NEXT_PC;
				-- ALU op
				res_alu <= aADD;		-- add without carry
				-- output
				res_outbus <= OB_ALU;
				-- store in temp register
				res_tempreg_latch <= '1';
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		-- absolute addressing modes (zp, abs, long, quad)
		-- absolute indirect addressing modes ( zpind, absind  )
		--
		when sABSOLUTE | sINDIRECT | sADDR =>
			case resolve_cnt is
			when 0 =>
				-- do prefix_of handling
				-- SP/B have been setup to be read by predecode
				case prefix_of_b is
				when oPC =>
					-- pass via ALU, add PC
					-- extend address parameter
					res_inbus_ext_type <= eZERO;
					res_inbus_ext_width <= par_width_rs_width(parwidth_b);
					res_inbus <= IB_PARAM;
					res_regbus <= RB_PC;
					res_alu <= aADD;
					res_alu_width <= full_width;
					res_outbus <= OB_ALU;
				when oBASE | oSP =>
					-- pass via ALU, add B/SP
					-- extend address parameter
					res_inbus_ext_type <= eZERO;
					res_inbus_ext_width <= par_width_rs_width(parwidth_b);
					res_inbus <= IB_PARAM;
					res_regbus <= RB_REGFILE;
					res_alu <= aADD;
					res_alu_width <= full_width;
					res_outbus <= OB_ALU;
				when oNONE =>
					res_outbus_ext_type <= eZERO;
					res_outbus_ext_width <= par_width_rs_width(parwidth_b);
					res_outbus <= OB_PARAM;
				--when others =>
				end case;
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				if (admode_b = sABSOLUTE or admode_b = sADDR) then
					-- we're done, just finish up
					-- take it into tempreg just if it's PEA or LEA
					res_tempreg_latch <= '1';
					-- done
					last_ad_cycle <= '1';
				end if;
			when 1 =>
				-- not done yet, use computed address to read effective address
				res_mem_rnw <= '1';
				res_memrw <= '1';		-- read
				res_memrw_width <= indwidth_b;  -- as given from decode
			when 2 =>
				-- now we have the effective address in data_in
				-- take care of address extension
				res_outbus <= OB_DIN;
				res_outbus_ext_type <= eZERO;
				res_outbus_ext_width <= indwidth_b;
				-- finish up
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- take it into tempreg just if it's PEA or LEA
				res_tempreg_latch <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		-- absolute indexed addressing modes (zpx/xpy, absx/absy, longx/longy, quadx/quady)
		--
		when sABSOLUTEIND =>
			case resolve_cnt is
			when 0 =>
				-- extend address parameter
				res_inbus <= IB_PARAM;
				res_inbus_ext_type <= eZERO;
				res_inbus_ext_width <= par_width_rs_width(parwidth_b);
				-- index register is already read and ready on regfile
				res_regbus <= RB_REGFILE;
				res_alu <= aADD;		-- add without carry
				res_alu_width <= full_width;
				res_tempreg_latch <= '1';	-- take into tempreg
				case prefix_of_b is
				when oBASE =>
					res_read_from_reg <= rB;
				when oSP =>
					res_read_from_reg <= cur_stack_pointer_b;
				when oNONE =>
					-- prepare address bus
					res_addrout <= OUT_BUS;
					res_take_addr <= '1';
					-- take it into tempreg just if it's PEA or LEA
					res_tempreg_latch <= '1';
					last_ad_cycle <= '1';
				when others =>
				end case;
			when 1 =>
				-- do prefix_of handling
				-- SP/B have been setup to be read by previous cycle
				res_inbus <= IB_TEMP;
				case prefix_of_b is
				when oPC =>
					-- pass via ALU, add PC
					res_regbus <= RB_PC;
				when oBASE | oSP =>
					-- pass via ALU, add B/SP
					res_regbus <= RB_REGFILE;
				when oNONE => 			-- skipped above
				when others =>
				end case;
				res_alu <= aADD;
				res_alu_width <= full_width;
				res_outbus <= OB_ALU;
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- take it into tempreg just if it's PEA or LEA
				res_tempreg_latch <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		-- E indirect ( eind )
		--
		when sEINDIRECT =>
			case resolve_cnt is
			when 0 =>
				-- value of E register is already available on regfile
				res_outbus <= OB_REGFILE;
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- take it into tempreg just if it's JMP for example
				res_tempreg_latch <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		-- pre indexed indirect addressing modes ( zpxind absxind )
		--
		when sPREINDIRECT =>
			case resolve_cnt is
			when 0 =>
				-- extend address parameter
				res_inbus <= IB_PARAM;
				res_inbus_ext_type <= eZERO;
				res_inbus_ext_width <= par_width_rs_width(parwidth_b);
				-- index has already been read and is available from regfile
				-- pass via ALU, add index reg
				res_regbus <= RB_REGFILE;
				res_alu <= aADD;
				res_alu_width <= full_width;
				res_outbus <= OB_ALU;
				case prefix_of_b is
				when oNONE =>
					-- prepare address bus
					res_addrout <= OUT_BUS;
					res_take_addr <= '1';
					res_skip_next <= '1';		-- skip adding the OF prefix reg
				when oSP =>
					res_read_from_reg <= cur_stack_pointer_b;
					res_tempreg_latch <= '1';
				when oBASE =>
					res_read_from_reg <= rB;
					res_tempreg_latch <= '1';
				when others =>
				end case;
			when 1 =>
				case prefix_of_b is
				when oPC =>
					-- pass via ALU, add PC
					res_inbus <= IB_TEMP;
					res_regbus <= RB_PC;
					res_alu <= aADD;
					res_alu_width <= full_width;
					res_outbus <= OB_ALU;
				when oBASE | oSP =>
					-- pass via ALU, add B/SP
					res_inbus <= IB_TEMP;
					res_regbus <= RB_REGFILE;
					res_alu <= aADD;
					res_alu_width <= full_width;
					res_outbus <= OB_ALU;
				when oNONE =>
					--res_outbus <= OB_TEMP;		-- should not happen
				--when others =>
				end case;
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
			when 2 =>
				-- not done yet, use computed address to read effective address
				res_mem_rnw <= '1';
				res_memrw <= '1';		-- read
				res_memrw_width <= indwidth_b;  -- as given from decode
			when 3 =>
				-- now we have the effective address in data_in
				-- take care of address extension
				res_outbus <= OB_DIN;
				res_outbus_ext_type <= eZERO;
				res_outbus_ext_width <= indwidth_b;
				-- finish up
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- take it into tempreg just if it's PEA or LEA
				res_tempreg_latch <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		-- post indexed indirect addressing modes ( zpindy absindy )
		--
		when sPOSTINDIRECT =>
			case resolve_cnt is
			when 0 =>
				if (prefix_of_b = oNONE) then
					-- extend address parameter
					res_outbus <= OB_PARAM;
					res_outbus_ext_type <= eZERO;
					res_outbus_ext_width <= par_width_rs_width(parwidth_b);
				else
					-- extend address parameter
					res_inbus <= IB_PARAM;
					res_inbus_ext_type <= eZERO;
					res_inbus_ext_width <= par_width_rs_width(parwidth_b);
					case prefix_of_b is
					when oPC =>
						-- pass via ALU, add PC
						res_regbus <= RB_PC;
						res_alu <= aADD;
						res_alu_width <= full_width;
						res_outbus <= OB_ALU;
					when oBASE | oSP =>
						-- pass via ALU, add B/SP
						res_regbus <= RB_REGFILE;
						res_alu <= aADD;
						res_alu_width <= full_width;
						res_outbus <= OB_ALU;
					when oNONE =>
						--res_outbus <= OB_TEMP;		-- should not happen
					--when others =>
					end case;
				end if;
				-- prepare address bus
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
			when 1 =>
				-- use computed address to read effective address
				res_mem_rnw <= '1';
				res_memrw <= '1';		-- read
				res_memrw_width <= indwidth_b;  -- as given from decode
				-- prepare next cycle by reading index register
				-- TODO: is this kept over memory access wait states?
				res_read_from_reg <= cpu_reg_idx_reg(idxreg_b);
			when 2 =>
				-- now we have the indirect address in data_in
				-- take care of address extension
				res_inbus <= IB_DIN;
				res_inbus_ext_type <= eZERO;
				res_inbus_ext_width <= indwidth_b;
				-- and add index register
				res_regbus <= RB_REGFILE;
				res_alu <= aADD;
				res_alu_width <= full_width;
				res_outbus <= OB_ALU;
				-- finish up
				res_addrout <= OUT_BUS;
				res_take_addr <= '1';
				-- take it into tempreg just if it's PEA or LEA
				res_tempreg_latch <= '1';
				-- done
				last_ad_cycle <= '1';
			when others =>
				res_wait <= '1';
			end case;
		-------------------------------------------------------------------------
		when others =>
		end case;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- with implied and immediate addressing modes we directly start at predecode
	--
	op_implied_predecode_p : process(operation, admode, is_predecode, cur_stack_pointer) 
	begin
		opp1_read_from_reg <= rNONE;
		if (is_predecode = '1') then
			if (admode = sIMPLIED) then
				case operation is
				when xIRQ | xNMI | xABORT
						=>
					opp1_read_from_reg <= rSSP;		-- always use SSP on interrupt handling
				when xTAX | xTAY | xTAE | xTAB 
						| xASL_A | xLSR_A | xROL_A | xROR_A | xDEC_A 
						| xINC_A | xRDR_A | xRDL_A | xASR_A
						| xSAE | xSAX | xSAY | xSAB
						| xEXT_A | xINV_A | xBCN_A | xSWP_A | xBIT_A
						| xSBB_A | xSBE_A | xSBS_A | xADB_A | xADE_A | xADS_A
						=>
					opp1_read_from_reg <= rAC;
				when xTXA | xTXS 
						| xINX | xDEX 
						| xSXY
						=>
					opp1_read_from_reg <= rXR;
				when xTYA | xTYS 
						| xINY | xDEY 
						=>
					opp1_read_from_reg <= rYR;
				when xPRB
						| xTBE | xTBA
						=>
					opp1_read_from_reg <= rB;
				when xTEB | xTEA
						=>
					opp1_read_from_reg <= rE;
				when xTSX | xTSY 
						| xPLX | xPLY | xPLA | xPLB | xPLE
						| xRTS 
						| xPHX | xPHY | xPHA | xPHE | xPHB
						| xPEA
						| xRTI
						=>
					opp1_read_from_reg <= cur_stack_pointer;
				when others =>
				end case;
			elsif (admode = sIMMEDIATE) then
				-- predecode for immediate addressing modes
				-- mirrors the register read from the first operation control cycle
				-- as that is skipped from the master control (count_p process)
				case operation is
				when xSBC | xADC | xCMP 
						| xAND | xORA | xEOR
						| xBIT
						=>
					opp1_read_from_reg <= rAC;
				when xCPY
						=>
					opp1_read_from_reg <= rYR;
				when xCPX
						=>
					opp1_read_from_reg <= rXR;
				when xADE | xSBE
						=>
					opp1_read_from_reg <= rE;
				when xADB | xSBB
						=>
					opp1_read_from_reg <= rB;
				when xADS | xSBS
						| xBRK
						=>
					opp1_read_from_reg <= cur_stack_pointer;
				when others =>
				end case;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------
	-- predecode for operations with non-implied/non-immediate addressing modes
	-- used during the last cycle of the resolver operation
	-- normally nothing necessary, as first cycle is the memory read that gets the operand
	--
	op_predecode_p : process(operation_b, last_ad_cycle, cur_stack_pointer_b)
	begin
		opp2_read_from_reg <= rNONE;
		if (last_ad_cycle = '1') then
			case operation_b is
			when xSTA 
				=>	
				opp2_read_from_reg <= rAC;
			when xSTX
				=>
				opp2_read_from_reg <= rXR;
			when xSTY
				=>
				opp2_read_from_reg <= rYR;
			when xJSR | xBSR
				=>
				opp2_read_from_reg <= cur_stack_pointer_b;
			when others =>
			end case;
		end if;
	end process;
	
	-- for all other operations, we have at least one cycle addressing mode
	-- where the address is prepared on the address out register (needs enough time
	-- for MMU operation, so no direct parameter > addrout > read can be done in a single
	-- cycle)
	--
	op_decode_p : process(phi2, operation_b, prefix_rs_b, operation_cnt, admode_b, prefix_le_b,
								cur_stack_pointer_b, prefix_nf_b,
								st_z_in, st_n_in, st_c_in, st_v_in, st_x_in,
								parwidth_b, indwidth_b, user_width,
								is_hypervisor_b, is_restricted_stack_b,
								is_op_mode, irq_stack_pointer_b)
	begin
		op_wait <= '0';
		last_op_cycle <= '0';
		op_addrout <= NO_BUS;
		op_dataout <= NO_BUS;
		op_inbus <= IB_NONE;
		op_regbus <= RB_NONE;
		op_outbus <= OB_ALU;
		op_mem_rnw <= '1';		-- read
		op_memrw <= '0';			-- no access
		op_memrw_width <= wBYTE;	
		op_memrw_type <= rwSTD;
		op_store_to_reg <= rNONE;
		op_read_from_reg <= rNONE;
		op_alu <= aNONE;
		op_alu_width <= full_width;
		op_tempreg_latch <= '0';
		op_take_addr <= '0';
		op_inbus_ext_type <= eZERO;
		op_inbus_ext_width <= full_width;		-- quad width passes through
		op_outbus_ext_type <= eZERO;
		op_outbus_ext_width <= full_width;
		constname <= cRESET;
		op_store_to_reg_width <= full_width;
		op_st_n <= stKEEP;
		op_st_v <= stKEEP;
		op_st_z <= stKEEP;
		op_st_c <= stKEEP;
		op_st_i <= stKEEP;
		op_st_d <= stKEEP;
		op_st_u <= stKEEP;
		op_st_x <= stKEEP;
		op_st_value_width <= full_width;
		op_jmp <= '0';
		op_stat_brk_bit <= '0';		-- extended stack frame
		op_release_irqlevel <= '0';
		op_commit <= '1';				-- always commit (by default)
		
		-- TODO: actually set res_memrw_hyper correctly in processes below
		if ((is_hypervisor_b = '1')) then -- and (prefix_um_b = '0')) then
			op_memrw_hyper <= '1';
		else
			op_memrw_hyper <= '0';
		end if;

		if (is_op_mode = '1') then
		case operation_b is
		-----------------------------------------------
		-- control operations
		--
		-- missing: xTRP
		--
		when xRESET =>
			case operation_cnt is
			when 0 =>
				-- set user stack pointer
				op_outbus <= OB_CONST;
				constname <= cSTACK_INIT;
				op_store_to_reg <= rUSP;
			when 1 =>
				-- set hypervisor stack pointer
				op_outbus <= OB_CONST;
				constname <= cSTACK_INIT;
				op_store_to_reg <= rSSP;
			when 2 =>
				-- AC
				op_outbus <= OB_CONST;
				constname <= cZERO;
				op_store_to_reg <= rAC;
			when 3 =>
				-- XR
				op_outbus <= OB_CONST;
				constname <= cZERO;
				op_store_to_reg <= rXR;
			when 4 =>
				-- YR
				op_outbus <= OB_CONST;
				constname <= cZERO;
				op_store_to_reg <= rYR;
			when 5 =>
				-- E
				op_outbus <= OB_CONST;
				constname <= cZERO;
				op_store_to_reg <= rE;
			when 6 =>
				-- B
				op_outbus <= OB_CONST;
				constname <= cZERO;
				op_store_to_reg <= rB;
			when 7 =>
				-- status
				op_st_n <= stCLR;
				op_st_v <= stCLR;
				op_st_z <= stCLR;
				op_st_c <= stCLR;
				op_st_i <= stSET;
				op_st_d <= stCLR;
				op_st_u <= stCLR;
				op_st_x <= stSET;
				-- prepare address
				op_inbus <= IB_CONST;		-- reset address onto inbus
				constname <= cRESET;		-- default
				op_addrout <= IN_BUS;
				op_take_addr <= '1';
			when 8 =>
				-- after I-flag is set, ...
				op_release_irqlevel <= '1';
				-- read reset address
				op_memrw_width <= wWORD;
				op_memrw <= '1';				-- access
				op_memrw_type <= rwFETCH_RESET;
			when 9 =>
				-- set PC
				op_outbus <= OB_DIN;
				-- sign-extend the value read
				-- TODO: flag to use original reset vector? 
				-- no, because that should only hold for core0
				-- to keep symmetry, this has to be fixed in cpu.vhd
				op_outbus_ext_type <= eSIGN;
				op_outbus_ext_width <= wWORD;
				-- new_pc is taken directly from outbus
				op_jmp <= '1';
				-- done;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- interrupt handling
		--		xIRQ, xBRK, xRTI
		--
		--Note: much of the IRQ/BRK handling is similar to the JSR/BSR code
		-- but replicated here for clearer separation and to not introduce cross-opcode bugs
		--
		-- no commit/rollback handling - to be defined what happens on rollback during e.g. abort?
		--
		when xIRQ | xNMI | xBRK | xABORT
			=>
			case operation_cnt is
			when 0 =>
				-- predecode has read the stack pointer from regfile
				--
				-- first substract the return address length minus one from the stack pointer
				-- to get the store address
				op_inbus <= IB_CONST;
				-- TODO: restrict if user mode (BRK) has smaller width
				if (operation_b = xBRK and is_hypervisor_b = '0') then
					case user_width is
					when wBYTE | wWORD => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				else
					case full_width is
					when wBYTE | wWORD => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				end if;
				op_regbus <= RB_REGFILE;
				-- alu setup
				op_alu <= aSUB;
				-- output
				op_outbus <= OB_ALU;
				-- store back in SR
				op_store_to_reg <= irq_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				end if;
				-- but also to store address for next cycle
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
			when 1 =>
				-- write the return address on stack
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_type <= rwSTACK;
				if (operation_b = xBRK and is_hypervisor_b = '0') then
					op_memrw_width <= user_width;
				else
					op_memrw_hyper <= '1';	-- hypervisor stack
					op_memrw_width <= full_width;
				end if;
				-- select data to write
				if (operation_b = xBRK) then
					op_regbus <= RB_NEXT_PC;
				else
					op_regbus <= RB_PC;
				end if;
				op_dataout <= REG_BUS;
				-- read stack pointer in next cycle to fix it up
				op_read_from_reg <= irq_stack_pointer_b;
			when 2 =>
				-- Note: in theory I could probably interleave the push with the stack pointer fixup,
				-- but if there is a wait state while writing, take_addr would overwrite the original
				-- stack address. take_addr could probably be qualified by is_memrw_done on the cpu level
				-- but this needs thorough testing. Rather leave that for a later optimization stage.
				--
				-- fix up stack pointer for status bytes
				op_regbus <= RB_REGFILE;
				op_inbus <= IB_CONST;
				if (operation_b = xBRK) then
					constname <= c1;
				else
					constname <= c2;
				end if;
				op_alu <= aSUB;
				op_outbus <= OB_ALU;
				op_store_to_reg <= irq_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;
				-- but also to store address for next cycle
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
				-- set X-flag for the next cycle to store on stack
				-- extended stack frame of IRQ, NMI, old-style stack frame for BRK
				if (operation_b = xBRK) then
					op_st_x <= stSET;
				else
					op_st_x <= stCLR;
				end if;
			when 3 =>
				-- store status high byte and status low byte
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_type <= rwSTACK;
				if (operation_b = xBRK) then
					op_stat_brk_bit <= '1';		-- set BRK bit on stack
					op_memrw_width <= wBYTE;
				else 
					op_memrw_hyper <= '1';	-- hypervisor stack
					op_memrw_width <= wWORD;
				end if;
				-- select data to write
				op_regbus <= RB_STATUS;
				op_dataout <= REG_BUS;
				-- read stack pointer in next cycle to fix it up
				op_read_from_reg <= irq_stack_pointer_b;
			when 4 =>
				-- fix status register bits (after status write)
				op_st_d <= stCLR;		-- clear decimal flag
				-- if BRK then set I-flag
				-- (note: needs to be the same in user/hypervisor, as BRK does not trap into hypervisor
				-- where we could fix things if they were different)
				if (operation_b = xBRK) then 
					op_st_i <= stSET;
				end if;
				-- For normal IRQ, NMI in fact we don't need to set the I flag. 
				-- in hypervisor mode this is handled by the irqlevel
				-- when going from there into user mode, it can/has to be set up
				-- by software
				-- fix up stack pointer for status bytes
				op_inbus <= IB_REGFILE;
				op_alu <= aDEC;
				op_outbus <= OB_ALU;
				op_store_to_reg <= irq_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;
			when 5 =>
				-- prepare address
				op_inbus <= IB_CONST;		-- reset address onto inbus
				if (operation_b = xNMI) then
					constname <= cNMI;
				elsif (operation_b = xABORT) then
					constname <= cABORT;
				else
					constname <= cIRQ;
				end if;
				op_addrout <= IN_BUS;
				op_take_addr <= '1';
			when 6 =>
				-- read reset address
				op_memrw_hyper <= '1';	-- hypervisor stack
				op_memrw_width <= wWORD;
				op_memrw <= '1';				-- access
				if (operation_b = xNMI) then
					op_memrw_type <= rwFETCH_NMI;
				elsif (operation_b = xBRK) then
					op_memrw_type <= rwFETCH_BRK;
				else
					-- IRQ and BRK
					op_memrw_type <= rwFETCH_IRQ;
				end if;
			when 7 =>
				-- go to hypervisor (clear use mode)
				if (not(operation_b = xBRK)) then
					op_st_u <= stCLR;	
				end if;
				-- set PC
				op_outbus <= OB_DIN;
				-- sign-extend the value read
				-- why no flag to use original reset vector? 
				-- no, because that should only hold for core0
				-- to keep symmetry, this has to be fixed in cpu.vhd
				op_outbus_ext_type <= eSIGN;
				op_outbus_ext_width <= wWORD;
				-- new_pc is taken directly from outbus
				op_jmp <= '1';
				-- done;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-- note that in contrast to xIRQ/xNMI the RTI opcode needs to work for
		-- userspace as well!
		when xRTI 
			=>
			case operation_cnt is
			when 0 =>
				-- current stack pointer is on the regfile
				op_inbus <= IB_REGFILE;
				op_alu <= aINC;
				op_outbus <= OB_ALU;
				op_store_to_reg <= cur_stack_pointer_b;
				op_commit <= '0';		-- only temporary
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				end if;
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
			when 1 =>
				-- read status from stack
				op_memrw <= '1';
				op_memrw_type <= rwSTACK;
				op_memrw_width <= wBYTE;
				--
				op_commit <= '0';		-- only temporary
				-- at the same time prepare for stack fixup
				op_read_from_reg <= cur_stack_pointer_b;
			when 2 =>
				-- evaluate status read from stack
				op_st_n <= stPULL;
				op_st_v <= stPULL;
				op_st_z <= stPULL;
				op_st_c <= stPULL;
				op_st_i <= stPULL;
				op_st_d <= stPULL;
				op_st_x <= stPULL;
				-- inc stack pointer
				op_inbus <= IB_REGFILE;
				op_alu <= aINC;
				op_outbus <= OB_ALU;
				op_store_to_reg <= cur_stack_pointer_b;
				--
				op_commit <= '0';		-- only temporary
				-- next address (either extended status or return address)
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
			when 3 =>
				-- this cylce is a no-op for old-style stack frame...
				if (st_x_in = '0') then 
					-- read extended status from stack
					op_memrw <= '1';
					op_memrw_type <= rwSTACK;
					op_memrw_width <= wBYTE;
					-- for next cycle fixup (on extended status)
					op_read_from_reg <= cur_stack_pointer_b;
				end if;
				--
				op_commit <= '0';		-- only temporary
				-- clear interrupt level
				op_release_irqlevel <= '1';
			when 4 =>
				if (st_x_in = '0') then
					-- evaluate status
					-- TODO this should trigger a privilege ABORT when user mode wants to go to hypervisor
					op_st_u <= stPULL;
					-- stack width?
					-- inc stack
					op_inbus <= IB_REGFILE;
					op_alu <= aINC;
					op_outbus <= OB_ALU;
					op_store_to_reg <= cur_stack_pointer_b;
					op_addrout <= OUT_BUS;
					op_take_addr <= '1';
				end if;
				--
				op_commit <= '0';		-- only temporary
				--
				op_read_from_reg <= cur_stack_pointer_b;
			when 5 =>
				-- read return address from stack
				op_memrw <= '1';
				op_memrw_type <= rwSTACK;
				if (is_hypervisor_b = '1') then
					op_memrw_width <= full_width;
					case full_width is
					when wBYTE | wWORD => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				else
					op_memrw_width <= user_width;
					case user_width is
					when wBYTE | wWORD => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				end if;
				-- at the same time fix up stack
				op_inbus <= IB_CONST;
				op_regbus <= RB_REGFILE;
				op_alu <= aADD;
				op_outbus <= OB_ALU;
				--
				op_commit <= '0';		-- only temporary
				--
				op_store_to_reg <= cur_stack_pointer_b;
			when 6 =>
				-- TODO: jump to user mode if necessary
				-- commit stack pointer and status reg. changes
				-- op_commit <= '1';	-- default
				-- set PC
				op_outbus <= OB_DIN;
				-- sign-extend the value read
				op_outbus_ext_type <= eSIGN;
				op_outbus_ext_width <= wWORD;
				-- new_pc is taken directly from outbus
				op_jmp <= '1';
				-- done;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
			
		-----------------------------------------------
		-- transfer operations
		--
		when xTXA | xTYA | xTEA | xTBA | xTEB
			| xTAX | xTAY | xTAE | xTAB | xTBE 
			=>
			case operation_cnt is
			when 0 =>
				-- source has been setup on register output by predecode
				op_outbus <= OB_REGFILE;
				-- load extension
				op_outbus_ext_type <= prefix_le_b;
				if (operation_b = xTEA or operation_b = xTBA 
					or operation_b = xTEB or operation_b = xTBE) then
					op_outbus_ext_width <= full_width;
					op_st_value_width <= full_width;
				else
					op_outbus_ext_width <= prefix_rs_b;
					op_st_value_width <= prefix_rs_b;
				end if;
				-- set flags
				if (prefix_nf_b = '0' ) then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
			   end if;
				case operation_b is
				when xTXA | xTYA | xTEA | xTBA => op_store_to_reg <= rAC;
				when xTAX | xTSX => op_store_to_reg <= rXR;
				when xTAY | xTSY => op_store_to_reg <= rYR;
				when xTAE | xTBE => op_store_to_reg <= rE;
				when xTAB | xTEB => op_store_to_reg <= rB;
				when others =>
				end case;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xTYS | xTXS
			=>
			case operation_cnt is
			when 0 =>
				-- source has been setup on register output by predecode
				op_outbus <= OB_REGFILE;
				op_outbus_ext_type <= prefix_le_b;
				op_outbus_ext_width <= prefix_rs_b;
				--
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				elsif (prefix_le_b = eNONE) then
					op_store_to_reg_width <= prefix_rs_b;
				end if;	-- else is full width which is default
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when	xTSY | xTSX 
			=>
			case operation_cnt is
			when 0 =>
				-- source has been setup on register output by predecode
				op_outbus <= OB_REGFILE;
				-- load extension
				op_outbus_ext_type <= prefix_le_b;
				op_outbus_ext_width <= prefix_rs_b;
				--
				op_st_value_width <= prefix_rs_b;
				-- set flags
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
			   end if;
				-- op_store_to_reg_width <= full_width;	-- default
				case operation_b is
				when xTSX => op_store_to_reg <= rXR;
				when xTSY => op_store_to_reg <= rYR;
				when others =>
				end case;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when	xTPA 
			=>
			case operation_cnt is
			when 0 =>
				op_outbus <= OB_NEXT_PC;
				-- set flags
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
			   end if;
				op_store_to_reg <= rAC;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- load operations (done)
		--
		when xLDA | xLDY | xLDX | xLDE | xLDB =>
			case operation_cnt is
			when 0 =>
				-- read data, address is already in addrout
				-- from predecode
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read
				op_memrw_width <= prefix_rs_b;
			when 1 =>
				if (admode_b = sIMMEDIATE) then
					op_outbus <= OB_PARAM;
				else
					op_outbus <= OB_DIN;
				end if;
				-- extend as required
				op_outbus_ext_type <= prefix_le_b;
				op_outbus_ext_width <= prefix_rs_b;
				-- use prefix_nf_b
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
					op_st_value_width <= prefix_rs_b;
				end if;
				-- store width
				if (prefix_le_b = eNONE) then
					op_store_to_reg_width <= prefix_rs_b;
				end if; -- (else is default: full_width)
				-- target register
				case operation_b is
				when xLDA => op_store_to_reg <= rAC;
				when xLDX => op_store_to_reg <= rXR;
				when xLDY => op_store_to_reg <= rYR;
				when xLDE => op_store_to_reg <= rE;
				when xLDB => op_store_to_reg <= rB;
				when others => op_store_to_reg <= rNONE;
				end case;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- store operations (done)
		--
		when xSTA | xSTX | xSTY =>
			case operation_cnt is
			when 0 =>
				-- write data from register, address is already in addrout
				-- also register output has been set in predecode
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_width <= prefix_rs_b;
				op_dataout <= REG_BUS;
				op_regbus <= RB_REGFILE;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xSTZ =>
			case operation_cnt is
			when 0 =>
				-- write data from zero constant, address is already in addrout
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_width <= prefix_rs_b;
				op_dataout <= IN_BUS;
				op_inbus <= IB_CONST;
				constname <= cZERO;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- arithmetic operations (done)
		--
		when xADC | xSBC | xCMP | xCPY | xCPX 
			| xADE | xSBE | xADB | xSBB | xADS | xSBS
			| xEOR | xORA | xAND
			=>
			case operation_cnt is
			when 0 =>
				-- read data, address is already in addrout
				-- from predecode
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read
				op_memrw_width <= prefix_rs_b;
				-- prepare second operand for operation
				case operation_b is
				when xCPY => op_read_from_reg <= rYR;
				when xCPX => op_read_from_reg <= rXR;
				when xADE | xSBE => op_read_from_reg <= rE;
				when xADB | xSBB => op_read_from_reg <= rB;
				when xADS | xSBS => op_read_from_reg <= cur_stack_pointer_b;
				when others => op_read_from_reg <= rAC;
				end case;
			when 1 =>
				if (admode_b = sIMMEDIATE) then
					op_inbus <= IB_PARAM;
				else
					op_inbus <= IB_DIN;
				end if;
				-- extend as required
				op_inbus_ext_type <= prefix_le_b;
				op_inbus_ext_width <= prefix_rs_b;
				-- second operand
				op_regbus <= RB_REGFILE;
				-- ALU operation
				case operation_b is
				when xADC => op_alu <= aADC;
				when xADE | xADB => op_alu <= aADD;
				when xSBE | xSBB => op_alu <= aSUB;
				when xORA => op_alu <= aOR;
				when xAND => op_alu <= aAND;
				when xEOR => op_alu <= aXOR;
				when others => op_alu <= aSBC;  -- includes all the compares
				end case;
				-- ALU width
				case operation_b is
				when xADE | xADB | xSBB | xSBE => op_alu_width <= full_width;
				when others => 
					if (prefix_le_b = eNONE) then
						op_alu_width <= prefix_rs_b;
						op_st_value_width <= prefix_rs_b;
					end if;	-- else is full width from default
				end case;
				-- output
				op_outbus <= OB_ALU;
				-- flags
				-- TODO set v-flag
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
					if ((operation_b = xADC) 
						or (operation_b = xSBC)
						or (operation_b = xCMP)
						or (operation_b = xCPX)
						or (operation_b = xCPY)
						) then
						op_st_c <= stALU;
					end if;
				end if;
				-- store width
				if (prefix_le_b = eNONE) then
					op_store_to_reg_width <= prefix_rs_b;
				end if; -- (else is default: full_width)
				-- target register
				case operation_b is
				when xCPX | xCPY | xCMP => op_store_to_reg <= rNONE;	-- discard result, only use flags
				when xADE | xSBE => op_store_to_reg <= rE;
				when xADB | xSBB => op_store_to_reg <= rB;
				when xADS | xSBS => op_store_to_reg <= cur_stack_pointer_b;
				when others => op_store_to_reg <= rAC;
				end case;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- BIT operation
		--
		when xBIT
			=>
			case operation_cnt is
			when 0 =>
				-- read data, address is already in addrout
				-- from predecode
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read
				op_memrw_width <= prefix_rs_b;
			when 1 =>
				-- data read is in DIN
				-- set n/v flags
				op_outbus <= OB_DIN;
				--
				if (prefix_nf_b = '0') then
					op_st_n <= stVALUE;
					op_st_v <= stVALUE;
					op_st_value_width <= prefix_rs_b;
				end if;
				-- prepare second operand for operation
				op_read_from_reg <= rAC;
			when 2 =>
				-- set z-flag by ANDing with AC
				op_inbus <= IB_DIN;
				-- extend as required
				op_inbus_ext_type <= prefix_le_b;
				op_inbus_ext_width <= prefix_rs_b;
				-- second operand
				op_regbus <= RB_REGFILE;
				-- ALU operation
				op_alu <= aAND;
				-- ALU width
				if (prefix_le_b = eNONE) then
					op_alu_width <= prefix_rs_b;
					op_st_value_width <= prefix_rs_b;
				end if;	-- else is full width from default
				-- output
				op_outbus <= OB_ALU;
				-- flags
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
				end if;
				-- no need to actually store the value
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- BIT operation
		--
		when xBIT_A
			=>
			case operation_cnt is
			when 0 =>
				-- read data, AC is already read from predecode
				-- data read is in DIN
				-- set n/v flags
				op_outbus <= OB_REGFILE;
				--
				if (prefix_nf_b = '0') then
					op_st_n <= stVALUE;
					op_st_v <= stVALUE;
					op_st_z <= stVALUE;
					op_st_value_width <= prefix_rs_b;
				end if;
				-- no need to actually store the value
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- two-register operations (done)
		--
		-- first register is moved into tempreg to be fed into 
		-- ALU on the second cycle
		--
		when xADE_A | xADS_A | xADB_A
			| xSBE_A | xSBS_A | xSBB_A
			=>
			case operation_cnt is
			when 0 =>
				-- transfer register value into temp reg
				-- in predecode we have read AC here
				op_outbus <= OB_REGFILE;
				-- prepare second operand for operation
				-- read second register
				case operation_b is
				when xADE_A | xSBE_A => op_read_from_reg <= rE;
				when xADB_A | xSBB_A => op_read_from_reg <= rB;
				when xADS_A | xSBS_A => op_read_from_reg <= cur_stack_pointer_b;
				when others => 
				end case;
			when 1 =>
				-- transfer register into regbus ALU input
				op_regbus <= RB_REGFILE;
				-- transfer temp reg into inbus ALU input
				op_inbus <= IB_TEMP;
				-- ALU operation
				case operation_b is
				when xADE_A | xADB_A | xADS_A => op_alu <= aADD;
				when xSBE_A | xSBB_A | xSBS_A => op_alu <= aSUB;
				when others =>
				end case;
				-- put on outbus to write to register
				op_outbus <= OB_ALU;
				-- write into register
				case operation_b is
				when xADE_A | xSBE => op_store_to_reg <= rE;
				when xADB_A | xSBB => op_store_to_reg <= rB;
				when xADS_A | xSBS => op_store_to_reg <= cur_stack_pointer_b;
				when others =>
				end case;
				-- set flags
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
				end if;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- read/modify/write memory operations
		--
		when xASL | xLSR | xROL | xROR | xINC | xDEC
			| xRDR | xRDL | xASR
			=>
			case operation_cnt is
			when 0 =>
				-- read data, address is already in addrout
				-- from predecode
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read
				op_memrw_width <= prefix_rs_b;
				op_memrw_type <= rwRMW;
			when 1 =>
				-- input parameter
				op_inbus <= IB_DIN;
				-- we only have a single operand and no extension
				-- for rmw ops
				-- ALU operation
				case operation_b is
				when xASL => op_alu <= aASL;
				when xASR => op_alu <= aASR;
				when xLSR => op_alu <= aLSR;
				when xROL => op_alu <= aROL;
				when xROR => op_alu <= aROR;
				when xRDR => op_alu <= aRDR;
				when xRDL => op_alu <= aRDL;
				when xINC => op_alu <= aINC;
				when xDEC => op_alu <= aDEC;
				when others =>
				end case;
				-- ALU width
				op_alu_width <= prefix_rs_b;
				-- output
				op_outbus <= OB_ALU;
				-- store in temp register
				op_tempreg_latch <= '1';
				-- flags
				op_st_value_width <= prefix_rs_b;
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
					if (not(operation_b = xINC) 
						and not(operation_b = xDEC)
						) then
						op_st_c <= stALU;
					end if;
				end if;
				--
				op_commit <= '0';		-- only temporary
			when 2 =>
				-- store back to memory
				-- addr out is still set from read cycle
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_width <= prefix_rs_b;
				op_memrw_type <= rwRMW;
				-- select data to write
				op_inbus <= IB_TEMP;
				op_dataout <= IN_BUS;
				--
				op_commit <= '0';		-- only temporary
				-- next step is next opcode that commits the status register
			when 3 =>
				-- we need this cycle to allow for the abort code to catch up
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- read/modify/write register operations
		-- 
		-- note: no rollback/commit handling, as only registers and no memory access
		--
		when xASL_A | xLSR_A | xROL_A | xROR_A | xINC_A | xDEC_A
			| xRDR_A | xRDL_A | xASR_A
			| xDEY | xINY | xDEX | xINX 
			| xINV_A | xBCN_A
			| xSWP_A
			=>
			case operation_cnt is
			when 0 =>
				-- operand has already been made available by selecting register
				-- in predecode
				-- input parameter
				op_inbus <= IB_REGFILE;
				-- we only have a single operand and no extension
				-- for rmw ops
				-- ALU operation
				case operation_b is
				when xASL_A => op_alu <= aASL;
				when xASR_A => op_alu <= aASR;
				when xLSR_A => op_alu <= aLSR;
				when xROL_A => op_alu <= aROL;
				when xROR_A => op_alu <= aROR;
				when xRDR_A => op_alu <= aRDR;
				when xRDL_A => op_alu <= aRDL;
				when xINC_A | xINY | xINX => op_alu <= aINC;
				when xDEC_A | xDEY | xDEX => op_alu <= aDEC;
				when xINV_A => op_alu <= aINV;
				when xBCN_A => op_alu <= aBCN;
				when xSWP_A => op_alu <= aSWP;
				when others =>
				end case;
				-- ALU width
				op_alu_width <= prefix_rs_b;
				-- output
				op_outbus <= OB_ALU;
				-- directly store in correct register
				case operation_b is
				when xINX | xDEX => op_store_to_reg <= rXR;
				when xINY | xDEY => op_store_to_reg <= rYR;
				when others => op_store_to_reg <= rAC;
				end case;
				op_store_to_reg_width <= prefix_rs_b;
				-- flags
				op_st_value_width <= prefix_rs_b;
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
					if (not(operation_b = xINC) 
						and not(operation_b = xDEC)
						) then
						op_st_c <= stALU;
					end if;
				end if;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xEXT_A 
			=>
			case operation_cnt is
			when 0 =>
				-- operand has already been made available by selecting register
				-- in predecode
				-- input parameter
				op_outbus <= OB_REGFILE;
				-- the actual operation is the extension, which is not done in the AC
				op_outbus_ext_width <= prefix_rs_b;
				op_outbus_ext_type <= prefix_le_b;
				-- directly store in correct register
				op_store_to_reg <= rAC;
				op_store_to_reg_width <= full_width;
				-- flags
				op_st_value_width <= prefix_rs_b;
				if (prefix_nf_b = '0') then
					op_st_z <= stVALUE;
					op_st_n <= stVALUE;
					if (not(operation_b = xINC) 
						and not(operation_b = xDEC)
						) then
						op_st_c <= stALU;
					end if;
				end if;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- flow opcodes
		--
		-- 	JMP, JSR, BSR, RTS, NOP
		--    BMI, BPL, BNE, BEQ, BCC, BCS, BVS, BVC, BRA
		--
		when xNOP
			=>
			case operation_cnt is
			when 0 =>
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;				
		when xBPL | xBMI | xBEQ | xBNE | xBCC | xBCS | xBVS | xBVC
			| xBRA
			=>
			case operation_cnt is
			when 0 =>
				-- parameter holds the relative address
				-- but we only need to compute something if the condition holds
				if (
					((operation_b = xBPL) and (st_n_in = '0'))
					or ((operation_b = xBMI) and (st_n_in = '1'))
					or ((operation_b = xBEQ) and (st_z_in = '1'))
					or ((operation_b = xBNE) and (st_z_in = '0'))
					or ((operation_b = xBCC) and (st_c_in = '0'))
					or ((operation_b = xBCS) and (st_c_in = '1'))
					or ((operation_b = xBVS) and (st_v_in = '1'))
					or ((operation_b = xBVC) and (st_v_in = '0'))
					or ((operation_b = xBRA))
					) then
					-- condition is fulfilled
					-- address is taken from address calculation that stored it in
					-- the temp register
					op_outbus <= OB_TEMP;
					-- set new PC from outbus
					op_jmp <= '1';
				end if;
				-- TODO: not sure if that mixes up predecode with JMP
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xJMP
			=>
			case operation_cnt is
			when 0 =>
				-- address is calculated in the resolver phase
				-- and stored in the temp register
				op_outbus <= OB_TEMP;
				-- tell decoder to jmp
				op_jmp <= '1';
				-- TODO: not sure if that mixes up predecode with JMP
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xJSR | xBSR
			=>
			case operation_cnt is
			when 0 =>
				-- predecode has read the stack pointer from regfile
				-- and the actual jump address is in the temp register
				-- (so we can't change that during our stack processing)
				--
				-- first substract the return address length from the stack pointer
				-- to get the store address
				op_inbus <= IB_CONST;
				case prefix_rs_b is
				when wBYTE | wWORD => constname <= c2m1;
				when wLONG => constname <= c4m1;
				when wQUAD => constname <= c8m1;
				end case;
				op_regbus <= RB_REGFILE;
				-- alu setup
				op_alu <= aSUB;
				-- output
				op_outbus <= OB_ALU;
				-- store back in SR
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				end if;
				-- but also to store address for next cycle
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
				--
				op_commit <= '0';		-- only temporary
			when 1 =>
				-- write the return address on stack
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_type <= rwSTACK;
				if (prefix_rs_b = wBYTE) then
					op_memrw_width <= wWORD;
				else
					op_memrw_width <= prefix_rs_b;				
				end if;
				-- select data to write
				op_regbus <= RB_NEXT_PC_MINUS_1;
				op_dataout <= REG_BUS;
				-- read stack pointer in next cycle to fix it up
				op_read_from_reg <= cur_stack_pointer_b;
				--
				op_commit <= '0';		-- only temporary
			when 2 =>
				-- fix up stack pointer
				op_inbus <= IB_REGFILE;
				op_alu <= aDEC;
				op_outbus <= OB_ALU;
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
					op_store_to_reg_width <= wBYTE;
				end if;
			when 3 =>
				-- temp reg still holds jmp address
				op_outbus <= OB_TEMP;
				op_jmp <= '1';
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xRTS
			=>
			case operation_cnt is
			when 0 =>
				-- predecode has read the stack pointer from regfile
				--
				-- read from the stack address plus 1
				op_inbus <= IB_REGFILE;
				op_alu <= aINC;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;
				op_outbus <= OB_ALU;
				-- take address
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
				--
				-- read stack pointer (again)
				op_read_from_reg <= cur_stack_pointer_b;
				--
			when 1 =>
				-- setup to add size of data read to stack pointer
				op_regbus <= RB_REGFILE;
				-- but also setup ALU to add stack offset
				op_inbus <= IB_CONST;
				case prefix_rs_b is
				when wBYTE | wWORD => constname <= c2;
				when wLONG => constname <= c4;
				when wQUAD => constname <= c8;
				end case;
				-- setup ALU
				op_alu <= aADD;
				-- result
				op_outbus <= OB_ALU;
				-- store to stack pointer
				-- TODO: rollback on ABORT
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				end if;
				-- at the same time read the value from the stack
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read data from stack
				op_memrw_type <= rwSTACK;
				if (prefix_rs_b = wBYTE) then
					op_memrw_width <= wWORD;
				else
					op_memrw_width <= prefix_rs_b;
				end if;
				--
				op_commit <= '0';		-- only temporary
				--
			when 2 =>
				-- now jump address-1 is on DIN
				-- setup add of one
				op_inbus <= IB_DIN;
				op_inbus_ext_type <= eZERO;
				if (prefix_rs_b = wBYTE) then
					op_inbus_ext_width <= wWORD;
				else
					op_inbus_ext_width <= prefix_rs_b;
				end if;
				-- alu setup
				op_alu <= aINC;
				op_alu_width <= full_width;
				-- output
				op_outbus <= OB_ALU;
				-- now jump to it
				op_jmp <= '1';
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- flags
		-- 	xCLC, xSEC, xCLI, xSEI, xCLV, xCLD, xSED, 
		--
		when xCLC | xSEC | xSED | xCLD | xSEI | xCLI | xCLV
			=>
			case operation_cnt is
			when 0 =>
				case operation_b is
				when xCLC => op_st_c <= stCLR;
				when xSEC => op_st_c <= stSET;
				when xCLD => op_st_d <= stCLR;
				when xSED => op_st_d <= stSET;
				when xCLI => op_st_i <= stCLR;
				when xSEI => op_st_i <= stSET;
				when xCLV => op_st_v <= stCLR;
				when others =>
				end case;
				if (not(operation_b = xCLI)) then
					last_op_cycle <= '1';
				end if;
			when 1 =>
				-- give interrup handling time to start the interrupt immediately
				-- after CLI
				if (not(operation_b = xCLI)) then
					op_wait <= '1';
				else
					op_wait <= '1';
				end if;
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- stack operations
		--
		-- 	xPHP, xPHA, xPHX, xPHY,
		-- 	xPHE, xPHB
		--  	xPLP, xPLA, xPLX, xPLY, 
		--		xPLE, xPLB
		--		xPEA
		--
		-- missing: 
		--		xPRB
		--
		when xPLA | xPLX | xPLY | xPLP | xPLE | xPLB
			=>
			case operation_cnt is
			when 0 =>
				-- predecode has read the stack pointer from regfile
				--
				-- read the data from the stack address plus 1
				op_inbus <= IB_REGFILE;
				op_alu <= aINC;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;	-- else is full_width which is default
				
				op_outbus <= OB_ALU;
				--
				-- take read address
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
				-- but also read stack pointer again to fix it up in next cycle
				op_read_from_reg <= cur_stack_pointer_b;
			when 1 =>
				-- fix up stack pointer for real
				op_regbus <= RB_REGFILE;
				-- but also setup ALU to add stack offset
				op_inbus <= IB_CONST;
				if (operation_b = xPLP) then
					constname <= c1;
				elsif (operation_b = xPLE or operation_b = xPLB) then
					case full_width is
					when wBYTE => constname <= c2;
					when wWORD => constname <= c2;
					when wLONG => constname <= c4;
					when wQUAD => constname <= c8;
					end case;
				else
					case prefix_rs_b is
					when wBYTE => constname <= c1;
					when wWORD => constname <= c2;
					when wLONG => constname <= c4;
					when wQUAD => constname <= c8;
					end case;
				end if;
				-- setup ALU
				op_alu <= aADD;
				op_alu_width <= full_width;
				-- result
				op_outbus <= OB_ALU;
				-- store to stack pointer
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg <= wBYTE;
				end if; -- else is full_width which is default
				--
				-- at the same time read the actual data from the stack memory
				op_memrw <= '1';
				op_mem_rnw <= '1';	-- read return address-1 from stack
				op_memrw_type <= rwSTACK;
				if (not(operation_b = xPLE) and not(operation_b = xPLB)) then
					if (operation_b = xPLP) then
						op_memrw_width <= wBYTE;
					else
						op_memrw_width <= prefix_rs_b;
					end if;
				end if; -- PLE/PLB are full_width, which is default
				--
				op_commit <= '0';		-- only temporary
				--
			when 2 =>
				-- now data read is on DIN
				-- store into register
				if (operation_b = xPLP) then
					-- no need to set outbus, directly taken from DIN on pull
					op_st_n <= stPULL;
					op_st_v <= stPULL;
					op_st_z <= stPULL;
					op_st_c <= stPULL;
					op_st_i <= stPULL;
					op_st_d <= stPULL;
				else
					op_outbus <= OB_DIN;
					if (operation_b = xPLE or operation_b = xPLB) then
						op_outbus_ext_type <= eNONE;
						op_outbus_ext_width <= full_width;
					else
						op_outbus_ext_type <= prefix_le_b;
						op_outbus_ext_width <= prefix_rs_b;
					end if;
					case operation_b is
					when xPLA => op_store_to_reg <= rAC;
					when xPLX => op_store_to_reg <= rXR;
					when xPLY => op_store_to_reg <= rYR;
					when xPLE => op_store_to_reg <= rE;
					when xPLB => op_store_to_reg <= rB;
					when others =>
					end case;
					if (prefix_nf_b = '0') then
						op_st_n <= stVALUE;
						op_st_z <= stVALUE;
						-- note rs prefix even on extend (see docs)
						op_st_value_width <= prefix_rs_b;
					end if;
					if (operation_b = xPLE or operation_b = xPLB) then
						-- default already is full width
					elsif (prefix_le_b = eNONE) then
						op_store_to_reg_width <= prefix_rs_b;
					end if;	-- else is full width, which is default
				end if;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		when xPHA | xPHX | xPHY | xPHP | xPHE | xPHB
			| xPEA
			=>
			case operation_cnt is
			when 0 =>
				-- predecode has read the stack pointer from regfile
				op_regbus <= RB_REGFILE;
				-- offset (data width) to make place for data to write
				-- substract width minus 1, as pointer points to uppermost free byte
				-- (that can be written)
				op_inbus <= IB_CONST;
				if (operation_b = xPHE or operation_b = xPHB or operation_b = xPEA) then
					case full_width is
					when wWORD | wBYTE => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				elsif (operation_b = xPHP) then
					constname <= c1m1;
				else
					case prefix_rs_b is
					when wBYTE => constname <= c1m1;
					when wWORD => constname <= c2m1;
					when wLONG => constname <= c4m1;
					when wQUAD => constname <= c8m1;
					end case;
				end if;
				--
				op_alu <= aSUB;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;	-- else is full_width which is default
				--
				op_outbus <= OB_ALU;
				
				-- store back in SR, but is still one byte off
				-- can't use temp register to temporarily store
				-- pointer, as it holds effective address for PEA				
				op_store_to_reg <= cur_stack_pointer_b;
				if (is_restricted_stack_b = '1') then
					op_store_to_reg_width <= wBYTE;
				end if; -- else is full width, which is default
				
				-- take read address to store
				op_addrout <= OUT_BUS;
				op_take_addr <= '1';
				-- 
				-- read the register to write
				case operation_b is
				when xPHA => op_read_from_reg <= rAC;
				when xPHY => op_read_from_reg <= rYR;
				when xPHX => op_read_from_reg <= rXR;
				when xPHB => op_read_from_reg <= rB;
				when xPHE => op_read_from_reg <= rE;
				when others =>
				end case;
				-- set the extended stack frame bit to old-style in next cycle
				op_st_x <= stSET;
				--
				op_commit <= '0';		-- only temporary
				--
			when 1 =>
				-- write the actual data from the stack memory
				op_memrw <= '1';
				op_mem_rnw <= '0';	-- write
				op_memrw_type <= rwSTACK;
				if (not(operation_b = xPHE) and not(operation_b = xPHB)) then
					if (operation_b = xPHP) then
						op_memrw_width <= wBYTE;
					else
						op_memrw_width <= prefix_rs_b;
					end if;
				end if; -- PLE/PLB are full_width, which is default
				-- data to actually write
				if (operation_b = xPHP) then
					op_regbus <= RB_STATUS;
					-- set B-flag in value to write
					op_stat_brk_bit <= '1';
					op_dataout <= REG_BUS;
				elsif (operation_b = xPEA) then
					op_outbus <= OB_TEMP;
					op_dataout <= OUT_BUS;
				else
					op_regbus <= RB_REGFILE;
					op_dataout <= REG_BUS;
				end if;
				-- read stack pointer to fix it up
				op_read_from_reg <= cur_stack_pointer_b;
				--
				op_commit <= '0';		-- only temporary
				--
			when 2 =>
				-- regfile has stack pointer from previous cycle
				op_inbus <= IB_REGFILE;
				op_alu <= aDEC;
				if (is_restricted_stack_b = '1') then
					op_alu_width <= wBYTE;
				end if;	-- else is default (full width)
				op_outbus <= OB_ALU;
				op_store_to_reg <= cur_stack_pointer_b;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- LEA
		--
		when xLEA 
			=>
			case operation_cnt is
			when 0 =>
				-- address computation has put the effective address into temp reg
				op_outbus <= OB_TEMP;
				-- write to E
				op_store_to_reg <= rE;
				-- set flags
				if (prefix_nf_b = '0') then
					op_st_n <= stVALUE;
					op_st_z <= stVALUE;
				end if;
				last_op_cycle <= '1';
			when others =>
				op_wait <= '1';
			end case;
		-----------------------------------------------
		-- still missing:
		--
		-- control
		--		xTRP, RTU
		-- swap
		--		xSEB, xSAB, xSAE, xSAX, xSAY, xSXY,
		-- addressing
		--		xPRB
		-- multi-byte
		--		xMVN, xMVP, xFIL, 
		-- test set/reset bit
		--		xTSB, xTRB, 
		-- multicore
		--		xWMB, xRMB, xSCA, xLLA
		--

		when others =>
		end case;
		end if;
	end process;
	
	
end Behavioral;

