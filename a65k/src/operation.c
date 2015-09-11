
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
#include "cpu.h"
#include "operation.h"


static struct { 
	cpu_type cpu; 
	isa_type isa;
	width_map width;
} cpu_isa[] = {
	{ CPU_NMOS,		ISA_NMOS + ISA_NMOS_BCD,			W_8 + W_16	},
	{ CPU_NMOS_ILLEGAL,	ISA_NMOS + ISA_NMOS_ILLEGAL + ISA_NMOS_BCD,	W_8 + W_16 	},
	{ CPU_CMOS,		ISA_NMOS + ISA_CMOS,				W_8 + W_16	},
	{ CPU_RCMOS,		ISA_NMOS + ISA_CMOS + ISA_CMOS_ROCKWELL,	W_8 + W_16	},
	{ CPU_NOBCD,		ISA_NMOS, 					W_8 + W_16	},
	{ CPU_NOBCD_ILLEGAL,	ISA_NMOS + ISA_NMOS_ILLEGAL,			W_8 + W_16	},
	{ CPU_802,		ISA_NMOS + ISA_CMOS + ISA_816,			W_8 + W_16 + W_24 },
	{ CPU_816,		ISA_NMOS + ISA_CMOS + ISA_816,			W_8 + W_16 + W_24 },
	{ CPU_65K,		ISA_NMOS + ISA_CMOS + ISA_65K,			W_8 + W_16 + W_32 + W_64 },
	{ CPU_65K_W,		ISA_NMOS + ISA_CMOS + ISA_65K,			W_8 + W_16 	},
	{ CPU_65K_L,		ISA_NMOS + ISA_CMOS + ISA_65K,			W_8 + W_16 + W_32 },
	{ CPU_65K_Q,		ISA_NMOS + ISA_CMOS + ISA_65K,			W_8 + W_16 + W_32 + W_64 },
	
};

void operation_module_init() {
}


operation_t *operation_find(const cpu_t *cpu, const char *name) {
	(void) cpu;
	(void) name;
	return NULL;
}

