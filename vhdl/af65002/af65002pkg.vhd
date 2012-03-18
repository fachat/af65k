----------------------------------------------------------------------------------
--
--    Package with various definitions and helper functions for the af65k CPU
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
-- 	entity: 		n/a
--		purpose:		types, subtypes, constants and helper functions
--		features:	
--		version:		0.1 (first public release)
--		date:			18mar2012
--		
--		Changes:		
--


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


package af65k is

--  	type rs_width is (
--		wBYTE, wWORD, wLONG, wQUAD
--	);
	function minimum (W, V : integer) return integer;

	subtype rs_width is natural range 0 to 3;
	constant wBYTE : integer := 0;
	constant wWORD : integer := 1;
	constant wLONG : integer := 2;
	constant wQUAD : integer := 3;
	
	function max_width (W : integer) return rs_width;
	function slv_rs_width (A : rs_width) return std_logic_vector;
	function rs_width_bytes (A : rs_width) return natural;
	function rs_width_slv (A : std_logic_vector(1 downto 0)) return rs_width;
	
  	type par_width is (
		pNONE, 
		pBYTE, 
		pWORD, 
		pLONG, 
		pQUAD
	);

	function rs_width_par_width (A : rs_width) return par_width;
	function par_width_rs_width (A : par_width) return rs_width;
	
	type of_type is (
		oNONE, 
		oPC, 
		oSP, 
		oBASE
	);
	
	subtype cpu_register is natural range 0 to 9;
	constant rNONE 	: cpu_register := 5;
	constant rAC 		: cpu_register := 0;
	constant rXR 		: cpu_register := 1;
	constant rYR 		: cpu_register := 2;
	constant rB 		: cpu_register := 3;
	constant rE 		: cpu_register := 4;
	-- separated by single bit, to easy constant clearing optimization during synthesis
	-- according to logs, not sure if that actually works
	constant rUSP 		: cpu_register := 8;
	constant rSSP 		: cpu_register := 9;
	constant rMAX 		: cpu_register := 9;

	type idx_register is (
		iXR,
		iYR
	);
	
	function cpu_reg_idx_reg (A : idx_register) return cpu_register;
--	function slv_cpu_register (A : cpu_register) return std_logic_vector;

	-- maybe fix this by separating out an extra carry selector input
	-- e.g. SUB --> SBC,C=0; ADD --> ADC,C=0
	-- ASL --> ROL,C=0; LSR --> ROR,C=0
	-- but that's it, so keep it as it is for now
	type alu_operation is (
		aNONE, 
		aADD, 		-- add without carry (addr. modes, ADE, ADB)
		aADC, 		-- add with carry
		aSBC, 		-- substract with borrow
		aSUB,			-- substract without borrow (SBE, SBB, CMP, CPX, CPY)
		aOR, 			-- binary or
		aAND, 		-- binary and
		aXOR, 		-- binary xor
		aROL, 		-- rotate left via carry
		aROR, 		-- rotate right via carry
		aASL, 		-- arithmetic shift left
		aLSR, 		-- logical shift right
		aRDR,			-- rotate direct right (without carry)
		aRDL,			-- rotate direct left (without carry)
		aASR,			-- arithmetic shift right
		aINC,			-- increment by one
		aDEC,			-- decrement by one
		aINV,			-- inverse (2s complement)
		aBCN, 		-- bit count
		aSWP			-- swap halfs
	);
	
	type ext_type is (
		eZERO, 
		eONE, 
		eSIGN, 
		eNONE
	);

	type const_type is (
		cRESET,		-- address of reset vector
		cIRQ,			-- address of irq vector
		cNMI,			-- address of nmi vector
		cABORT,		-- address of abort vector
		cSTACK_INIT, -- initial (internal) stack pointer ($200Q)
		cZERO,		-- zero
		c1,			-- 1
		c2,			-- 2
		c4,			-- 4
		c8,			-- 8 
		c1m1,			-- 1-1 = 0
		c2m1,			-- 2-1 = 1
		c4m1,			-- 4-1 = 3
		c8m1			-- 8-1 = 7
	);
	
	subtype irqlevel_t is std_logic_vector(2 downto 0);
	
	-- TODO I have no idea how to make that generic
	type irqlevels_t is array (0 to 0) of irqlevel_t;
	
		
	-- some enumeration types (hoping that they will be optimized appropriately
		
	type cpu_syntax is (
			sUNKNOWN,
			sIMPLIED, 
			sIMMEDIATE, 
			sABSOLUTE, 
			sABSOLUTEIND, 
			sADDR, 
			sREL,
			sINDIRECT, 
			sEINDIRECT,
			sPOSTINDIRECT, 
			sPREINDIRECT
	);
	
	type cpu_operation is (
			xUNKNOWN,
			-- control
			xRESET, xIRQ, xNMI, xABORT,
			xBRK, 
			xTRP,
			xRTI, xCLEIM,
			-- flow
			xBPL, xBMI, xBVC, xBVS, xBCC, xBCS, xBNE, xBEQ, xBRA, 
			xJMP, xJSR, xBSR, xRTS, xNOP,
			-- load
			xLDY, xLDX, xLDA, xLDE, xLDB, 
			-- store
			xSTX, xSTY, xSTA, xSTZ,
			-- arithmetic ops
			xCPY, xCPX, xCMP, xORA, xAND, xEOR, xADC, xSBC, 
			xADE, xADS, xADB, xSBE, xSBS, xSBB, 
			-- two-register ops
			xADE_A, xADS_A, xADB_A, xSBE_A, xSBB_A, xSBS_A,
			-- read/modify/write memory ops
			xASL, xLSR, xROL, xROR, xINC, xDEC,
			xRDR, xRDL, xASR,
			-- read/modify/write register ops
			xASL_A, xLSR_A, xROL_A, xROR_A, xINC_A, xDEC_A,
			xRDR_A, xRDL_A, xASR_A,
			xDEY, xINY, xDEX, xINX, 
			xINV_A, xBCN_A,
			xEXT_A, xSWP_A,
			-- stack
			xPHP, xPLP, xPHA, xPLA, xPHX, xPLX, xPHY, xPLY,
			xPHE, xPLE, xPHB, xPLB, xPRB, 
			-- flags
			xCLC, xSEC, xCLI, xSEI, xCLV, xCLD, xSED, 
			-- transfer
			xTYA, xTAY, xTXA, xTAX, xTSX, xTXS, xTSY, xTYS, 
			xTPA, xTBA, xTEA, xTAE, xTAB,
			xTEB, xTBE,
			-- swap
			xSEB, xSAB, xSAE, xSAX, xSAY, xSXY,
			-- effect. addr
			xLEA, xPEA, 
			-- multi-byte
			xMVN, xMVP, xFIL, 
			-- test set/reset bit
			xTSB, xTRB, 
			-- bit
			xBIT, xBIT_A,
			-- multicore
			xWMB, xRMB, xSCA, xLLA
	);

	type out_source is (
		NO_BUS,
		IN_BUS,
		REG_BUS,
		OUT_BUS
	);
	
	type Regbus_source is (
		RB_NONE, 
		RB_REGFILE, 
		RB_PC, 
		RB_NEXT_PC, 
		RB_NEXT_PC_MINUS_1, 
		RB_STATUS
	);
	
	type Inbus_source is (
		IB_NONE, 
		IB_DIN, 
		IB_PARAM, 
		IB_TEMP, 
		IB_REGFILE, 
		IB_CONST
	);

	type Outbus_source is (
		OB_ALU, 
		OB_DIN, 
		OB_REGFILE, 
		OB_PARAM,
		OB_TEMP,
		OB_NEXT_PC,
		OB_CONST
	);

	type st_in_type is (
		stKEEP,
		stVALUE,
		stSET,
		stCLR,
		stPULL,
		stALU
	);
	
	type memrw_t is (
		rwNONE,			-- no access
		rwFETCH_RESET,	-- fetch reset vector
		rwFETCH_IRQ,	-- fetch irq vector
		rwFETCH_NMI,	-- fetch nmi vector
		rwFETCH_BRK,	-- fetch brk vector
		rwFETCH_ABORT,	-- fetch abort vector
		rwFETCH_TRAP,	-- fetch trap vector
		rwFETCH,			-- std. opcode fetch
		rwADDR,			-- address fetch for indirect addresses
		rwSTACK,			-- stack read/write (PHx, PLx, JSR, RTS, ...)
		rwSTD,			-- standard r/w operation
		rwRMW,			-- read/modify/write operation
		rwLLSC,			-- load linked (r) / store conditional (w)
		rwMB_ALL,		-- memory barrier - all memory (read/write depends on r/-w line)
		rwMB,				-- memory barrier for address (read/write depends on r/-w line)
		rwIMR,			-- interrupt mask register (write for SEI/CLI for now)
		rwEIMR,			-- effective interrupt mask register (read for irq stack frame and write for restore)
		rwCR				-- configuration register (TBD)
	);

	--subtype abort_t is natural range 0 to 7;
	subtype abort_t is std_logic_vector(3 downto 0);
	constant abUMODE 			: abort_t := "0000";		-- abort due to UM prefix set in user mode
	constant abNOEXEC			: abort_t := "0001";		-- abort due to fetch on No-Exec memory
	constant abFETCHNOMAP	: abort_t := "0010";		-- abort due to fetch on not-mapped addresses
	constant abWRITEPROT		: abort_t := "0011";		-- write to write-protected memory
	constant abNOMAP			: abort_t := "0100";		-- read or write to not-mapped addresses
	constant abNONE			: abort_t := "1111";		-- for beOK case
	
	subtype buserr_t is natural range 0 to 3;
	constant beOK				: buserr_t := 0;		-- no error
	constant beNOTMAPPED		: buserr_t := 1;		-- address not mapped
	constant beNOEXEC			: buserr_t := 2;		-- fetch on no-execute mapping
	constant beWRITEPROT		: buserr_t := 3;		-- write attempt on read-only mapping

	function fetch_buserr_abort_vec (A : buserr_t) return abort_t;
	function memrw_buserr_abort_vec (A : buserr_t) return abort_t;
	function errpins_buserr (A : std_logic_vector(1 downto 0)) return buserr_t;
	
--  type <new_type> is
--    record
--        <type_name>        : std_logic_vector( 7 downto 0);
--        <type_name>        : std_logic;
--    end record;
--
---- Declare constants
--
--  constant <constant_name>		: time := <time_unit> ns;
--  constant <constant_name>		: integer := <value>;
-- 
---- Declare functions and procedure
--
--  function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
--  procedure <procedure_name>	(<type_declaration> <constant_name>	: in <type_declaration>);

end af65k;


package body af65k is

	function minimum (W, V : integer) return integer is
	begin
		if (W > V) then
			return V;
		else
			return W;
		end if;
	end function;

	function errpins_buserr (A : std_logic_vector(1 downto 0)) return buserr_t is
		variable result : buserr_t;
	begin
		case A is
		when "00" => result := beOK;
		when "01" => result := beNOTMAPPED;
		when "10" => result := beNOEXEC;
		when "11" => result := beWRITEPROT;
		when others => result := beOK;
		end case;
		return result;
	end function;

	function fetch_buserr_abort_vec (A : buserr_t) return abort_t is
		variable result : abort_t;
	begin
		case A is
		when beOK => result := abNONE;
		when beNOTMAPPED => result := abFETCHNOMAP;
		when beNOEXEC => result := abNOEXEC;
		when beWRITEPROT => result := abWRITEPROT;	-- should not happen
		when others =>
		end case;
		return result;
	end function;

	function memrw_buserr_abort_vec (A : buserr_t) return abort_t is
		variable result : abort_t;
	begin
		case A is
		when beOK => result := abNONE;
		when beNOTMAPPED => result := abNOMAP;
		when beNOEXEC => result := abNOEXEC;
		when beWRITEPROT => result := abWRITEPROT;
		when others =>
		end case;
		return result;
	end function;

	function max_width(W : integer) return rs_width is
		variable result : rs_width;
	begin
		case W is
		when 8 => result := wWORD;
		when 16 => result := wWORD;
		when 32 => result := wLONG;
		when 64 => result := wQUAD;
		when others =>
		end case;
		return result;
	end function max_width;

	-- I really seem to have problems groking that VHDL type system
	-- with the conversions between integers and logic vectors...
	-- So I abstract the conversion into these helper functions
	function slv_rs_width(A : rs_width) return std_logic_vector is
		variable result : std_logic_vector(1 downto 0);
	begin
		case A is
		when wBYTE => result := "00";
		when wWORD => result := "01";
		when wLONG => result := "10";
		when wQUAD => result := "11";
		end case;
		return result;
	end function slv_rs_width;

	function rs_width_slv (A : std_logic_vector(1 downto 0)) return rs_width is
		variable result : rs_width;
	begin
		case A is 
		when "00" => result := wBYTE;
		when "01" => result := wWORD;
		when "10" => result := wLONG;
		when "11" => result := wQUAD;
		when others =>
		end case;
		return result;
	end function;

	function rs_width_bytes(A : rs_width) return natural is
		variable result : natural;
	begin
		case A is
		when wBYTE => result := 1;
		when wWORD => result := 2;
		when wLONG => result := 4;
		when wQUAD => result := 8;
		end case;
		return result;
	end function rs_width_bytes;

	function rs_width_par_width(A : rs_width) return par_width is
		variable result : par_width;
	begin
		case A is
		when wBYTE => result := pBYTE;
		when wWORD => result := pWORD;
		when wLONG => result := pLONG;
		when wQUAD => result := pQUAD;
		end case;
		return result;
	end function rs_width_par_width;

	function par_width_rs_width(A : par_width) return rs_width is
		variable result : rs_width;
	begin
		case A is
		when pBYTE => result := wBYTE;
		when pWORD => result := wWORD;
		when pLONG => result := wLONG;
		when pQUAD => result := wQUAD;
		when pNONE => result := wBYTE;	-- should  not happend!
		end case;
		return result;
	end function par_width_rs_width;

--	function slv_cpu_register(A : cpu_register) return std_logic_vector is
--		variable result : std_logic_vector(2 downto 0);
--	begin
--		case A is
--		when rNONE 	=> result := "111";
--		when rAC 	=> result := "000";
--		when rXR 	=> result := "001";
--		when rYR 	=> result := "010";
--		when rUSP 	=> result := "011";
--		when rSSP 	=> result := "100";
--		when rB 		=> result := "101";
--		when rE 		=> result := "110";
--		end case;
--		return result;
--	end function slv_cpu_register;

	function cpu_reg_idx_reg (A : idx_register) return cpu_register is
		variable result : cpu_register;
	begin
		case A is
		when iXR 	=> result := rXR;
		when iYR 	=> result := rYR;
		end case;
		return result;
	end function cpu_reg_idx_reg;
	

 
end af65k;
