
/****************************************************************************

    CPU management
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


#ifndef OPERATION_H
#define OPERATION_H



typedef enum {
	SY_IMP		= 0,	// implied
	SY_IMM		= 1,	// immediate
	
	SY_ABS		= 2,	// absolute/relative address: zp; word; long; quad; rel; relwide; rellong; relquad
	SY_ABSX		= 3,	// absolute x-indexed: zp,x; word,x; long,x; quad,x
	SY_ABSY		= 4,	// absolute y-indexed: zp,y; word,y; long,y; quad,y

	SY_IND		= 5,	// zp/word-indirect, word address: (zp); (word)
	SY_INDY		= 6,	// zp/word-indirect, y-indexed, word address: (zp),y; (word),y
	SY_XIND		= 7,	// x-indexed, zp/word-indirect, word address: (zp,x); (word,x)

	SY_INDL		= 8,	// zp/word-indirect, long address: [zp]; [word]
	SY_INDYL	= 9,	// zp/word-indirect, y-indexed, long address: [zp],y; [word],y
	SY_XINDL	= 10,	// x-indexed, zp/word-indirect, long address: [zp,x]; [word,x]

	SY_INDQ		= 11,	// zp/word-indirect, quad address: [[zp]]; [[word]]
	SY_INDYQ	= 12,	// zp/word-indirect, y-indexed, quad address: [[zp]],y; [[word]],y
	SY_XINDQ	= 13,	// x-indexed, zp/word-indirect, quad address: [[zp,x]]; [[word,x]]
	
	SY_MV		= 14,	// two byte 65816 MVN/MVP addressing
	SY_BBREL	= 15,	// zeropage address, plus relative address, R65C02 BBR/BBS
	
	SY_MAX		= 16,	// end

	// virtual addressing modes. Will be mapped to SY_IND, SY_INDL or SY_INDQ depending
	// on memory model used during assembly
	SY_INDD		= 17,	// zp/word-indirect, dynamic address: ((zp)); ((word))
	SY_INDYD	= 18,	// zp/word-zp-indirect, y-indexed, dynamic address: ((zp)),y; ((word)),y
	SY_XINDD	= 19,	// x-indexed, zp/word-indirect, dynamic address: ((zp,x)); ((word,x))

} syntax_type;


typedef enum {
	AM_NONE		= -1,

	AM_IMP		= 0,	// implied
	AM_IMM8		= 1,	// immediate
	AM_IMM16	= 2,	// immediate
	AM_IMM32	= 3,	// immediate
	AM_IMM64	= 4,	// immediate
	
	AM_ABS8		= 5,	// absolute/relative address: zp
	AM_ABS16	= 6,	// absolute/relative address: word
	AM_ABS24	= 7,	// absolute address: word+bank byte
	AM_ABS32	= 8,	// absolute/relative address: long
	AM_ABS64	= 9,	// absolute/relative address: quad

	AM_ABS8X	= 10,	// absolute x-indexed: zp,x
	AM_ABS16X	= 11,	// absolute x-indexed: word,x
	AM_ABS32X	= 12,	// absolute x-indexed: long,x
	AM_ABS64X	= 13,	// absolute x-indexed: quad,x

	AM_ABS8Y	= 14,	// absolute y-indexed: zp,y
	AM_ABS16Y	= 15,	// absolute y-indexed: word,y
	AM_ABS32Y	= 16,	// absolute y-indexed: long,y
	AM_ABS64Y	= 17,	// absolute y-indexed: quad,y

	AM_IND8		= 18,	// zp/word-indirect, word address: (zp)
	AM_IND16	= 19,	// zp/word-indirect, word address: (word)
	AM_IND8Y	= 20,	// zp/word-indirect, y-indexed, word address: (zp),y
	AM_IND16Y	= 21,	// zp/word-indirect, y-indexed, word address: (word),y
	AM_XIND8	= 22,	// x-indexed, zp/word-indirect, word address: (zp,x)
	AM_XIND16	= 23,	// x-indexed, zp/word-indirect, word address: (word,x)

	AM_IND8L	= 24,	// zp/word-indirect, long address: [zp]
	AM_IND16L	= 25,	// zp/word-indirect, long address: [word]
	AM_IND8YL	= 26,	// zp/word-indirect, y-indexed, long address: [zp],y
	AM_IND16YL	= 27,	// zp/word-indirect, y-indexed, long address: [word],y
	AM_XIND8L	= 28,	// x-indexed, zp/word-indirect, long address: [zp,x]
	AM_XIND16L	= 29,	// x-indexed, zp/word-indirect, long address: [word,x]

	AM_IND8Q	= 30,	// zp/word-indirect, quad address: [[zp]]
	AM_IND16Q	= 31,	// zp/word-indirect, quad address: [[word]]
	AM_IND8YQ	= 32,	// zp/word-indirect, y-indexed, quad address: [[zp]],y
	AM_IND16YQ	= 33,	// zp/word-indirect, y-indexed, quad address: [[word]],y
	AM_XIND8Q	= 34,	// x-indexed, zp/word-indirect, quad address: [[zp,x]]
	AM_XIND16Q	= 35,	// x-indexed, zp/word-indirect, quad address: [[word,x]]
	
	AM_MV		= 36,	// two byte 65816 MVN/MVP addressing
	AM_BBREL	= 37,	// zeropage address, plus relative address, R65C02 BBR/BBS
	
	AM_MAX		= 38,	// end
} amode_type;
	
typedef enum {
	PG_BASE		= 0,	// base page, no page prefix needed
	PG_EXT		= 1,	// extended page
	PG_QUICK	= 2,	// quick page
	PG_SYS		= 3,	// system page
} pg_type;


typedef struct {
	bool_t		is_valid;
	unsigned char	code;
	pg_type 	page_prefix;
} opcode_t;

// operation - equivalent to the mnemonic, like "lda", "adc", "inx", ...
typedef struct operation_s operation_t;
struct operation_s {
	const char	*name;
	const isa_map	isa;		// what ISA is it from? Also selects BCD and Illegal opcodes
	const bool_t	abs_is_rel;	// is branch with relative addressing?
	operation_t	*next;
	opcode_t	opcodes[AM_MAX];
};

typedef struct {
	bool_t		set_am_prefix;
	bool_t		rs_is_width;		// use RS-prefix for width
	pg_type		page_prefix;
	unsigned char	code;
} codepoint_t;

void operation_module_init();

const operation_t *operation_find(const char *name);

bool_t opcode_find(const position_t *loc, const cpu_t *cpu, const operation_t *op, syntax_type syntax, int opsize_in_bytes,
	codepoint_t *returned_code);

#endif

