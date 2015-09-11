
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


// operation - equivalent to the mnemonic, like "lda", "adc", "inx", ...
typedef struct {
	const char	*name;
	const bool_t	is_illegal;
} operation_t;

typedef enum {
	ISA_NMOS		= 1,	// standard NMOS
	ISA_NMOS_ILLEGAL	= 2,	// NMOS illegal opcodes
	ISA_NMOS_BCD		= 4,	// NMOS SED opcode
	ISA_CMOS		= 8,	// CMOS extensions
	ISA_CMOS_ROCKWELL	= 16,	// RMB/SMB/BBS/BBR opcodes
	ISA_816			= 32,	// 65816 extensions to CMOS 6502
	ISA_65K			= 64,	// 65K extensions to CMOS 6502
} isa_type;

typedef enum {
	W_8			= 1,
	W_16			= 2,
	W_24			= 4,
	W_32			= 8,
	W_64			= 16,
} width_map;

typedef enum {
	AM_IMP		= 0,	// implied
	AM_IMM		= 1,	// immediate
	
	AM_ABS		= 2,	// absolute address: zp; word; long; quad; rel; relwide; rellong; relquad
	AM_ABSX		= 3,	// absolute x-indexed: zp,x; word,x; long,x; quad,x
	AM_ABSY		= 4,	// absolute y-indexed: zp,y; word,y; long,y; quad,y

	AM_INDD		= 5,	// zp/word-indirect, dynamic address: ((zp)); ((word))
	AM_INDYD	= 6,	// zp/word-zp-indirect, y-indexed, dynamic address: ((zp)),y; ((word)),y
	AM_XINDD	= 7,	// x-indexed, zp/word-indirect, dynamic address: ((zp,x)); ((word,x))

	AM_IND		= 8,	// zp/word-indirect, word address: (zp); (word)
	AM_INDY		= 9,	// zp/word-indirect, y-indexed, word address: (zp),y; (word),y
	AM_XIND		= 10,	// x-indexed, zp/word-indirect, word address: (zp,x); (word,x)

	AM_INDL		= 11,	// zp/word-indirect, long address: [zp]; [word]
	AM_INDYL	= 12,	// zp/word-indirect, y-indexed, long address: [zp],y; [word],y
	AM_XINDL	= 13,	// x-indexed, zp/word-indirect, long address: [zp,x]; [word,x]

	AM_INDQ		= 14,	// zp/word-indirect, quad address: [[zp]]; [[word]]
	AM_INDYQ	= 15,	// zp/word-indirect, y-indexed, quad address: [[zp]],y; [[word]],y
	AM_XINDQ	= 16,	// x-indexed, zp/word-indirect, quad address: [[zp,x]]; [[word,x]]
	
	AM_MV		= 17,	// two byte 65816 MVN/MVP addressing
	AM_BBREL	= 18,	// zeropage address, plus relative address, R65C02 BBR/BBS
} amode_t;
	
void operation_module_init();

operation_t *operation_find(const cpu_t *cpu, const char *name);

#endif

