----------------------------------------------------------------------------------
--
--    CPU shell for a af65k CPU. 
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
--      entity:                 af65002cpu
--      purpose:                CPU shell for one af65k core
--      features:       	single core, with only 8bit memory interface.
--      version:                0.1 (first public release)
--      date:                   20aug2012
--              
--      Changes:                
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library af65002;
use af65002.af65km.all;



entity af65002mcpu is

        Generic (
                W, MW : integer
        );

   	Port (
       		A : out  STD_LOGIC_VECTOR (W-1 downto 0) := (others => '0');
                ISVALID : out STD_LOGIC;                                -- true when address valid
                ISFETCH : out STD_LOGIC;                                -- true when program fetch (i.e. opcode plus param)
	      	DOUT : out  STD_LOGIC_VECTOR (MW-1 downto 0);
      		DIN : in  STD_LOGIC_VECTOR (MW-1 downto 0);
                DWIDTH_OUT : out std_logic_vector(1 downto 0);  	-- which width should the data transfer have?
                DWIDTH_IN : in std_logic_vector(1 downto 0);    	-- actual data transfer width
                RDY : in STD_LOGIC;                                     -- true when data transferred (sampled at falling phi2)
                BUSERR : in std_logic_vector (1 downto 0);      	-- when true, current access is trapped on error
      		PHI2 : in  STD_LOGIC;
      		RNW : out  STD_LOGIC;
      		IRQIN : in  STD_LOGIC_VECTOR (6 downto 0);        	-- interrupt level input (high active)
                RESET : in STD_LOGIC;                                   -- active high input(!)
                SO : in STD_LOGIC                                       -- active in sets Overflow CPU status bit
        );

end;


architecture Behavioral of af65002mcpu is

	component af65002opmap is
                Port ( 
                        opcode : in  STD_LOGIC_VECTOR (7 downto 0);
                        opmap : in  STD_LOGIC_VECTOR (7 downto 0);
                        prefix_rs : in rs_width;
                        prefix_am : in std_logic;
                        -- true when valid
                        is_valid : out std_logic;
			-- out operation
                        operation : out cpu_operation;
                        admode : out cpu_syntax;
                        -- parameter length and syntax together define the addressing mode
                        -- e.g. syntax=ABSOLUTE and parlen=wBYTE is zeropage addressing
                        operand_width : out par_width;
                        operand_ext : out ext_type;
                        ind_width : out rs_width;
                        ind_ext : out ext_type;
                        oper_width : out rs_width;
                        oper_ext : out ext_type;
                        idxreg : out idx_register;
                        default_le : out ext_type
                );
        end component;
	

	---------------------------------------------------------------------------
	-- All of the phi2-related internal state have two signals, one the current signal
	-- value, and second the "next phi2" value. This is denoted by a leading "n_"
	--
	-- The status bits and stack registers have an additional set of values, 
	-- the committed and the uncommited ones. The uncommited values are denoted by 
	-- a trailing "_u"
	--

        -- core registers; note they are implemented as array as to allow use of block RAM
	subtype reg_t 		is std_logic_vector(W-1 downto 0);
	signal regs		: array(0 to 4) of reg_t;

	constant r_ac		: integer := 0;
	constant r_xr		: integer := 1;
	constant r_yr		: integer := 2;
	constant r_br		: integer := 3;
	constant r_er		: integer := 4;

	-- register write
	signal n_reg		: reg_t;
	signal writereg		: integer range 0 to 4;

        -- signal rega		: std_logic_vector(M-1 downto 0);
        -- signal regx		: std_logic_vector(M-1 downto 0);
        -- signal regy		: std_logic_vector(M-1 downto 0);
        -- signal regb		: std_logic_vector(M-1 downto 0);
        -- signal rege		: std_logic_vector(M-1 downto 0);

	-- stack and status registers; those need commit/rollback, so no block RAM
	signal usp		: std_logic_vector(M-1 downto 0);
	signal hsp		: std_logic_vector(M-1 downto 0);
	signal usp_u		: std_logic_vector(M-1 downto 0);
	signal hsp_u		: std_logic_vector(M-1 downto 0);

	signal n_usp		: std_logic_vector(M-1 downto 0);
	signal n_hsp		: std_logic_vector(M-1 downto 0);
	signal n_usp_u		: std_logic_vector(M-1 downto 0);
	signal n_hsp_u		: std_logic_vector(M-1 downto 0);

	-- status register
	signal statc		: std_logic;
	signal statz		: std_logic;
	signal statn		: std_logic;
	signal statv		: std_logic;

	signal n_statc		: std_logic;
	signal n_statz		: std_logic;
	signal n_statn		: std_logic;
	signal n_statv		: std_logic;

	---------------------------------------------------------------------------
	-- internal state, opcode decoding output
	--
	-- An opcode contains an operation, e.g. "ADC", and (optionally) an operand. The operand
	-- is interpreted according to the addressing mode encoded in the opcode. During decoding
	-- these three values, operation, operand and addressing mode are decoded after fetch.
	-- 
	-- The actual execution is separated into different phases, fetch, decode, address
	-- calculation and operation. The address calculation is further separated into
	-- sub-phases, e.g. operand fetch, indexing, indirect address fetch.
	-- Each phase can have more than one cycle, e.g. when fetching multi-byte values.
	--

	-- control
	signal phase		: phase_t;
	signal n_phase		: phase_t;

	----------------------------------
	-- parsing result, all set when the opcode is been decoded
	signal op_rs		: rs_width;
	signal op_of		: of_type;
	signal op_le		: ext_type;
	signal op_nf		: std_logic;
	signal op_am		: std_logic;
	signal op_um		: std_logic;
	signal op_map		: std_logic_vector(1 downto 0);

	----------------------------------
	-- decoder output
	signal n_isvalid	: std_logic;
	signal n_operation	: operation_t;
	signal n_syntax		: syntax_t;		-- addressing syntax
	-- addressing mode (separated into syntax and prefix-related signals)
	signal n_operand_width	: par_width;		-- operand width
	signal n_operand_ext	: ext_type;		-- operand extensions
	signal n_ind_width	: par_width;		-- indirect address fetch width
	signal n_ind_ext	: ext_type;		-- indirect address extension (?)
	signal n_oper_width	: rs_width;		-- width of the operation
	signal n_oper_ext	: ext_type;		-- extension for the operation result
	signal n_idxreg		: idx_register;
	signal n_default_le	: ext_type;

	-- decoder output - buffered
	signal isvalid		: std_logic;
	signal operation	: operation_t;
	signal syntax		: syntax_t;		-- addressing syntax
	-- addressing mode (separated into syntax and prefix-related signals)
	signal operand_width	: par_width;		-- operand width
	signal operand_ext	: ext_type;		-- operand extensions
	signal ind_width	: par_width;		-- indirect address fetch width
	signal ind_ext		: ext_type;		-- indirect address extension (?)
	signal oper_width	: rs_width;		-- width of the operation
	signal oper_ext		: ext_type;		-- extension for the operation result
	signal idxreg		: idx_register;
	signal default_le	: ext_type;

	----------------------------------
	-- input/output buffer signals
	signal d_in		: std_logic_vector(W-1 downto 0);
	signal d_out		: std_logic_vector(W-1 downto 0);

	signal rdy_in		: std_logic;
	signal res_in		: std_logic;

	signal a_out		: std_logic_vector(W-1 downto 0);
	signal a_type		: memrw_type;


	-- input collector buffers
	signal d_buf		: std_logic_vector(W-1 downto 0);
	signal op_buf		: std_logic_vector(7 downto 0);

	-- read/write counter and target; once target and current is equal, the last byte
	-- is currently being transferred
	signal bytecnt		: bytecnt_t;
	signal bytetrg		: bytecnt_t;

	
	---------------------------------------------------------------------------
	-- configuration

	signal vectorhi		: std_logic_vector(W-1 downto 16);

begin

	---------------------------------------------------------------------------
	-- i/o adaption

	A <= a_out;
	ISVALID <= '0' when a_type = rwNONE else '1';
	ISFETCH <= '1' when a_type = rwFETCH or a_type = rwOPERAND else '0';
	RNW <= '1' when a_type = rwNONE else rwn_out;

	d_in <= DIN;
	rdy_in <= RDY;
	res_in <= RESET;

	---------------------------------------------------------------------------
	-- main process

	main_p: process(phi2, phase)
	begin process

		if (res_in = '1') then
			n_phase <= phPREVECTOR;
			a_type <= rwNONE;
			rnw_out <= '1';

		elsif ((a_type = rwNONE or rdy_in = '1') and falling_edge(phi2)) then
			a_out <= (others => '0');
			a_type <= rwNONE;
			rnw_out <= '1';
			n_phase <= phase;

			-- reminder to self: this is executed at the _END_ of the 
			-- cycle of the named phase! 
			case phase is
			when phPREVECTOR =>
				-- setup to read reset vector
				-- TODO: which vector?
				a_out(15 downto 0) <= X"FFFC";
				a_out(W-1 downto 16) <= (others => vectorhi);
				d_buf(W-1 downto 16) <= (others => vectorhi);
				bytecnt <= 0;
				bytetrg <= 2;
				a_type <= rwFETCH_RESET;
				n_phase <= phVECTOR;
			when phVECTOR =>
				-- read vector byte by byte
				case bytecnt is
				when 0 =>
					d_buf(7 downto 0) <= d_in;
				when 1 =>
					d_buf(15 downto 8) <= d_in;
				others =>
				end case;
				if (bytecnt = bytetrg) then
					-- reached end of fetch
					n_phase <= phPREFETCH;
					a_type <= rwNONE;
				else
					a_out <= a_out + 1;
					a_type <= rwFETCH_RESET;
				end if;
			when phPREFETCH =>
				-- put address buffer onto address lines to read
				-- TODO: could probably save a cycle with more interweave into phVECTOR
				a_out <= d_buf;
				a_type <= rwFETCH;
				n_phase <= phFETCH;
			when phFETCH =>
				-- fetch first byte of operation
				d_buf(7 downto 0) <= d_in;
				a_out <= a_out + 1;
				a_type <= rwFETCH;
				n_phase <= phFETCHOP;
			when phFETCHOP =>
				-- At the beginning of this cycle we have in d_buf a prefix or operation code.
				-- During the cycle, a read happens with the next byte
				-- which may be further opcode byte, first operand byte, or the first
				-- byte of the next opcode. We need to catch that into d_buf anyway.

				if (op_map = "00" and d_buf(0) = '1' and d_buf(1) = '1') then
					-- Note: does not fully check the prefix order as required by
					-- the spec, do not rely on this behaviour!

					-- byte is a prefix
					if (d_buf(3) = '0') then
						-- prefix1
						op_am <= d_buf(2);
						op_rs <= rs_width_slv(d_buf(5 downto 4));
						op_of <= of_type_slv(d_buf(7 downto 6));
					elsif (d_buf(2) = '0') then
						-- prefix2
						op_le <= ext_type_slv(d_buf(6 downto 5));
						op_nf <= d_buf(4);
						op_um <= d_buf(7);
					else
						-- last opcode column
						if (d_buf = "00001111") then
							op_map <= "01";	-- EXT page
						elsif (d_buf = "00101111") then
							op_map <= "10";	-- SYS page
						elsif (d_buf = "01001111") then
							op_map <= "11"; -- QUICK page
						end if;
					end if;
				elsif (n_isvalid = '1') then
					-- byte is operation
					-- The byte, plus the prefix bits, are passed through the opcode
					-- decoder and available in the n_opcode and other signals
					--
					-- clear the parser output, as it is included in the decoder output
					op_am <= '0';
					op_um <= '0';
					op_nf <= '0';
					op_rs <= rs_width_slv("00");
					op_of <= of_width_slv("00");
					op_le <= ext_type_slv("00");
					--
					-- The opcodes handled here are single-cycle (in optimization 
					-- of the original two-cycle versions)
					case n_operation is
					when xSEC =>
						statc <= '1';
					when xCLC =>
						statc <= '0';
					when xSED =>
						statd <= '1';
					when xCLD =>
						statd <= '0';
					when xCLV =>
						statv <= '0';
					when xSEI =>
						-- TODO
					when others =>
						case n_syntax is
						when sIMPLIED =>
							n_phase <= phOPERATION;
						when sIMMEDIATE | sABSOLUTE | sABSOLUTEIND 
							| sADDR | sREL | sINDIRECT | sPOSTINDIRECT
							| sPREINDIRECT =>
							n_phase <= phOPERAND;
						when others =>
							n_phase <= phFETCHOP;
						end case;
					end case;
				else
				end if;

				-- TODO
				-- fetch next byte
				d_buf(7 downto 0) <= d_in;
				a_out <= a_out + 1;
				a_type <= rwFETCH;
				n_phase <= phFETCHOP;
	
			when phOPERAND =>
				-- read the operand
				-- fetch next byte
				d_buf(7 downto 0) <= d_in;
				a_out <= a_out + 1;
				a_type <= rwFETCH;
				n_phase <= phOPERATION;
						
			when phOPERATION =>
	
			end case;	
		end if;
	end process;
		
	phi1_p: process(phi2) 
	begin process
		if (res_in = '1') then
			phase <= phPREVECTOR;

		elsif (rising_edge(phi2)) then
		
			phase <= n_phase;
		end if;
	end process;

		
				-- read vector byte by byte
				--case bytecnt is
				--when 0 =>
				--	a_buf(7 downto 0) <= d_in;
				--when 1 =>
				--	a_buf(15 downto 8) <= d_in;
				--when 2 =>
				--	a_buf(minimum(W-1, 23) downto minimum(W-1 downto 16) <= d_in;
				--when 3 =>
				--	a_buf(minimum(W-1, 31) downto minimum(W-1 downto 24) <= d_in;
				--when 4 =>
				--	a_buf(minimum(W-1, 39) downto minimum(W-1 downto 32) <= d_in;
				--when 5 =>
				--	a_buf(minimum(W-1, 47) downto minimum(W-1 downto 40) <= d_in;
				--when 6 =>
				--	a_buf(minimum(W-1, 55) downto minimum(W-1 downto 48) <= d_in;
				--when 7 =>
				--	a_buf(minimum(W-1, 63) downto minimum(W-1 downto 56) <= d_in;
				--others =>
	

        -- find the actual operation, syntax mode, and parameter width
        -- for the opcode. Use the opcode map component for this. Note: no
        -- generics dependency :-)
        opmap : af65002opmap
        port map (
                        d_buf,
                        op_map,
                        op_rs,
                        op_am,
                        -- out true when valid
                        n_opvalid,
			-- out operation
                        n_operation,
                        n_syntax,
                        -- parameter length and syntax together define the addressing mode
                        -- e.g. syntax=ABSOLUTE and parlen=wBYTE is zeropage addressing
                        n_operand_width,
                        n_operand_ext,
                        n_ind_width,
                        n_ind_ext,
                        n_oper_width,
                        n_oper_ext,
                        n_idxreg,
                        default_le_int
        );

end Behavioral;


