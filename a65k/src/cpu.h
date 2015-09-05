
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


#ifndef CPU_H
#define CPU_H



typedef enum {
	CPU_NMOS,		// only legal NMOS opcodes
	CPU_NMOS_ILLEGAL,	// legal and illegal NMOS opcodes
	CPU_CMOS,		// CMOS opcodes (without Rockwell extensions)
	CPU_RCMOS,		// CMOS plus Rockwell extensions
	CPU_NOBCD,		// NMOS but without BCD mode
	CPU_NOBCD_ILLEGAL,	// NMOS with illegal opcodes, but without BCD mode
	CPU_802,		// 65802
	CPU_816,		// 65816
	CPU_65K,		// base 65k CPU (implicitely 64 bit, modifyable with .width) 
	CPU_65K_W,		// 65k CPU 16-bit width
	CPU_65K_L,		// 65k CPU 32-bit width
	CPU_65K_Q,		// 65k CPU 64-bit width
} cpu_type;

typedef struct {
	const cpu_type	type;
	const char 	*name;
	const cpu_type	base;
	const int	cpu_width;	// memory model size 16, 24, 32, 64
	const bool_t	has_bcd;
	const bool_t	has_illegal;
} cpu_t;


void cpu_module_init();

cpu_t *cpu_by_name(const char *name);

#endif

