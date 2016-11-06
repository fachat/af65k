
/****************************************************************************

    CPU operation management
    Copyright (C) 2015 Andre Fachat

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

****************************************************************************/

#include <string.h>

#include "mem.h"
#include "hashmap.h"
#include "astring.h"
#include "position.h"	
#include "cpu.h"
#include "segment.h"
#include "context.h"
#include "operation.h"
#include "errors.h"



// ordering by SY_*, then AM_*
#define	AMODES_MAX 	5
static amode_type sy_amode[SY_MAX][AMODES_MAX] = {
	{ // SY_IMP
		AM_IMP, 	AM_IMP, 	AM_IMP, 	AM_IMP,		AM_IMP 		},
	{ // SY_IMM
		AM_IMM8,	AM_IMM16,	AM_NONE, 	AM_IMM32,	AM_IMM64	},
	{ // SY_ABS
		AM_ABS8,	AM_ABS16,	AM_ABS24, 	AM_ABS32,	AM_ABS64	},
	{ // SY_ABSX
		AM_ABS8X,	AM_ABS16X,	AM_NONE, 	AM_ABS32X,	AM_ABS64X	},
	{ // SY_ABSY
		AM_ABS8Y,	AM_ABS16Y,	AM_NONE, 	AM_ABS32Y,	AM_ABS64Y	},
	{ // SY_IND
		AM_IND8,	AM_IND16,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_INDY
		AM_IND8Y,	AM_IND16Y,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_XIND
		AM_XIND8,	AM_XIND16,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_INDL
		AM_IND8L,	AM_IND16L,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_INDYL
		AM_IND8YL,	AM_IND16YL,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_XINDL
		AM_XIND8L,	AM_XIND16L,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_INDQ
		AM_IND8Q,	AM_IND16Q,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_INDYQ
		AM_IND8YQ,	AM_IND16YQ,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_XINDQ
		AM_XIND8Q,	AM_XIND16Q,	AM_NONE, 	AM_NONE	,	AM_NONE		},
	{ // SY_MV
		AM_MV,		AM_NONE,	AM_NONE, 	AM_NONE,	AM_NONE		},
	{ // SY_BBREL
		AM_BBREL,	AM_NONE,	AM_NONE, 	AM_NONE,	AM_NONE		}
};

// corresponding parameter widts for table sy_amode
static width_map sy_amode_widths[AMODES_MAX] = {
		W_8,		W_16,		W_24,		W_32,		W_64	
};

// ordering by AM_*
static struct { 
	const char *name;
	isa_map isa;
	bool_t set_am;		// only relevant for CPU with AM prefix
	bool_t check_width;	// only relevant for CPU with AC/index width mode (65816)
} amodes[] = {
	{ "implied",		// AM_IMP 		
		ISA_BASE,			false,	false },

	{ "immediate byte",	// AM_IMM8 	
		ISA_BASE,			false,	true },
	{ "immediate word",	// AM_IMM16 	
		ISA_816 | ISA_65K,		false,	true },
	{ "immediate long",	// AM_IMM32 		
		ISA_65K,			false,	true },
	{ "immediate quad",	// AM_IMM64 		
		ISA_65K, 			false,	true },

	{ "absolute zeropage",	// AM_ABS8
		ISA_BASE,			false,	false },
	{ "absolute 16bit",	// AM_ABS16
		ISA_BASE,			false,	false },
	{ "absolute 24bit",	// AM_ABS24
		ISA_816,			false,	false },
	{ "absolute 32bit",	// AM_ABS32
		ISA_65K,			true,	false },
	{ "absolute 64bit",	// AM_ABS64
		ISA_65K,			true,	false },

	{ "zeropage x-indexed",	// AM_ABS8X
		ISA_BASE,			false,	false },
	{ "16bit x-indexed",	// AM_ABS16X
		ISA_BASE,			false,	false },
	{ "32bit x-indexed",	// AM_ABS32X
		ISA_65K,			true,	false },
	{ "64bit x-indexed",	// AM_ABS64X
		ISA_65K,			true,	false },
	{ "zeropage y-indexed",	// AM_ABS8Y
		ISA_BASE,			false,	false },
	{ "16bit y-indexed",	// AM_ABS16Y
		ISA_BASE,			false,	false },
	{ "32bit y-indexed",	// AM_ABS32Y
		ISA_65K,			true,	false },
	{ "64bit y-indexed",	// AM_ABS64Y
		ISA_65K,			true,	false },

	{ "zeropage indirect word address", // AM_IND8
		ISA_CMOS,			false,	false },
	{ "16bit indirect word address", // AM_IND16
		ISA_BASE,			false,	false },
	{ "zeropage indirect y-indexed word address", // AM_IND8Y
		ISA_BASE,			false,	false },
	{ "16bit indirect y-indexed word address", // AM_IND16Y
		ISA_65K,			false,	false },
	{ "zeropage x-indexed indirect word address", // AM_XIND8
		ISA_BASE,			false,	false },
	{ "16bit x-indexed indirect word address", // AM_XIND16
		ISA_65K,			false,	false },

	{ "zeropage indirect long address", // AM_IND8L
		ISA_65K,			true,	false },
	{ "16bit indirect long address", // AM_IND16L
		ISA_65K,			true,	false },
	{ "zeropage indirect y-indexed long address", // AM_IND8YL
		ISA_65K,			true,	false },
	{ "16bit indirect y-indexed long address", // AM_IND16YL
		ISA_65K,			true,	false },
	{ "zeropage x-indexed indirect long address", // AM_XIND8L
		ISA_65K,			true,	false },
	{ "16bit x-indexed indirect long address", // AM_XIND16L
		ISA_65K,			true,	false },

	{ "zeropage indirect quad address", // AM_IND8Q
		ISA_65K,			true,	false },
	{ "16bit indirect quad address", // AM_IND16Q
		ISA_65K,			true,	false },
	{ "zeropage indirect y-indexed quad address", // AM_IND8YQ
		ISA_65K,			true,	false },
	{ "16bit indirect y-indexed quad address", // AM_IND16YQ
		ISA_65K,			true,	false },
	{ "zeropage x-indexed indirect quad address", // AM_XIND8Q
		ISA_65K,			true,	false },
	{ "16bit x-indexed indirect quad address", // AM_XIND16Q
		ISA_65K,			true,	false },

	{ "MVN/MVP double byte", // AM_MV
		ISA_816,			false,	false },
	{ "BBREL",		// AM_BBREL
		ISA_RCMOS,			false,	false },
};

// the map entry contains all the opcode widths that can handle the given parameter width;
// order by the parameter width, 0 to 8
static width_map widths_map[] = {
	// 0,	
		0,
	// 1,	
		W_8 + W_16 + W_24 + W_32 + W_64,
	// 2,
		W_16 + W_24 + W_32 + W_64,
	// 3,	
		W_24 + W_32 + W_64,
	// 4,	
		W_32 + W_64,
	// 5,	
		W_64,
	// 6,	
		W_64,
	// 7,	
		W_64,
	// 8,
		W_64,
};

#include "table.h"

//static operation_t opcodes[] = {
//	{ 	"adc",	ISA_ALL, false,	true, false, NULL, {
//		// AM_IMP
//		{  false  },	
//		// AM_IMM8
//		{ true,	0x69, PG_BASE },
//		// AM_IMM16
//		{  true, 0x69, PG_BASE },	
//	} },
//	{	"adc", 	ISA_816, false,	true, false, NULL, {
//		// AM_IMP
//		{  false  },
//		// AM_IMM8
//		{  true, 0x69, PG_BASE  },
//		// AM_IMM16
//		{  true, 0x69, PG_BASE  },
//
//	} },
//};
//

static hash_t *opcode_map = NULL;


static const char *key_from_operation(const void *entry) {
	return ((operation_t*)entry)->name;
}

void operation_module_init() {

	opcode_map = hash_init_stringkey_nocase(400, 64, &key_from_operation);

	int n = sizeof(cpu_operations)/sizeof(operation_t);
	for (int i = 0; i < n; i++) {
		operation_t *orig = hash_put(opcode_map, &cpu_operations[i]);
		if (orig != NULL) {
			cpu_operations[i].next = orig;
		}
	}
}


const operation_t *operation_find(const char *name) {

	operation_t *op = hash_get(opcode_map, name);

	return op;
}


bool_t opcode_find(const position_t *loc, 
		const context_t *ctx, 
		const operation_t *op_initial, 
		syntax_type syntax, 
		int opsize_in_bytes,
		codepoint_t *returned_code) {

	const cpu_t *cpu = ctx->cpu;

	codepoint_t *rc = returned_code;

	const operation_t *op = op_initial;

	if (opsize_in_bytes < 0 || opsize_in_bytes > 8) {
		error_illegal_opcode_size(loc, opsize_in_bytes);
		return false;
	}

	// possible opcode widths (as bitmap)
	width_map par_widths = widths_map[opsize_in_bytes];

	// possible ISAs
	isa_map isas = cpu->isa;
	width_map isa_widths = cpu->width;

	// effectively possible parameter widths
	width_map eff_widths = par_widths & isa_widths;
	
	if (eff_widths == 0) {
		error_parameter_width_not_allowed_for_isa(loc, cpu->name, opsize_in_bytes);
		return false;
	}

	// isa, syntax, param_width -> list of AM_* to check
	amode_type *ams = sy_amode[syntax];

	do {

		// loop over potential opcode definitions

		for (int i = 0; i < AMODES_MAX; i++) {
			// check all adressing modes for the syntax
			amode_type am = ams[i];

			if (am == AM_NONE) {
				continue;
			}

			// ISA
			isa_map am_isa = amodes[am].isa;
			if ((am_isa & isas) == 0) {
				trace_am_not_allowed_for_isa(loc, amodes[am].name, cpu->name, 
					(int) am_isa, (int) cpu->isa);
				// adressing mode is not allowed for ISA
				continue;
			}

			width_map am_width = sy_amode_widths[i];
			if ((eff_widths & am_width) == 0) {
				// adressing mode is not allowed for requested width
				trace_am_not_allowed_for_width(loc, amodes[am].name, cpu->name,
					(int) am_width, (int) cpu->width);
				continue;
			}

			if (cpu->has_check_width && amodes[am].check_width) {
				if (op->check_ac_w) {
					switch (opsize_in_bytes) {
					case 1:
						if (!ctx->acc_width) {
							break;	// ok
						}
						trace_narrow_operand_wide_ac(loc, op->name, amodes[am].name, cpu->name);
						continue;
					case 2:
						if (ctx->acc_width) {
							break; 	// ok
						}
						error_wide_operand_narrow_ac(loc, op->name, amodes[am].name, cpu->name);
						return NULL;
					default:
						break;
					}
				}
				if (op->check_idx_w) {
					switch (opsize_in_bytes) {
					case 1:
						if (!ctx->index_width) {
							break;	// ok
						}
						trace_narrow_operand_wide_idx(loc, op->name, amodes[am].name, cpu->name);
						continue;
					case 2:
						if (ctx->index_width) {
							break; 	// ok
						}
						error_wide_operand_narrow_idx(loc, op->name, amodes[am].name, cpu->name);
						return NULL;
					default:
						break;
					}
				}
			}

			// check adressing mode in current operation
			const opcode_t *opc = &op->opcodes[am];

			//if (!opc->is_valid) { 
			//	trace_no_opcode_for(loc, op->name, amodes[am].name, cpu->name);
			//	continue;
			//}

			// ok, found my opcode

			rc->set_am_prefix = amodes[am].set_am;
			rc->rs_is_width = false;	// TODO
			rc->page_prefix = opc->page_prefix;
			rc->code = opc->code;

			return true;
		}
		op = op->next;
	} while(op != NULL);

	return false;
}

