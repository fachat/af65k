
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

#include <string.h>

#include "mem.h"
#include "hashmap.h"
#include "astring.h"
#include "cpu.h"


static const cpu_t cpus[] = {
	{ CPU_NMOS, 		"nmos",			CPU_NMOS,	16,	true, 	false },
	{ CPU_NMOS_ILLEGAL, 	"nmos_illegal",		CPU_NMOS,	16,	true, 	true },
	{ CPU_CMOS,		"cmos",			CPU_CMOS,	16,	true, 	false },
	{ CPU_RCMOS,		"cmos_rockwell",	CPU_CMOS,	16,	true, 	false },
	{ CPU_NOBCD,		"nmos_nobcd",		CPU_NMOS,	16,	false, 	false },
	{ CPU_NOBCD_ILLEGAL,	"nmos_illegal_nobcd",	CPU_NMOS,	16,	false,	true },
	{ CPU_802,		"65802",		CPU_816,	16,	true,	false },
	{ CPU_816,		"65816",		CPU_816,	24,	true, 	false },
	{ CPU_65K,		"65k",			CPU_65K,	64,	true, 	false },
	{ CPU_65K_W,		"65k_w",		CPU_65K,	16,	true, 	false },
	{ CPU_65K_L,		"65k_l",		CPU_65K,	32,	true, 	false },
	{ CPU_65K_Q,		"65k_q",		CPU_65K,	64,	true, 	false },
};

static hash_t *cpu_typemap = NULL;

static const void *cpu_key_from_entry(const void *entry) {
	cpu_t *cpu = (cpu_t*) entry;
	return cpu->name;
}

void cpu_module_init() {

	int num_cpus = sizeof(cpus)/sizeof(cpu_t);

	cpu_typemap = hash_init_stringkey(10, 5, cpu_key_from_entry);

	for (int i = 0; i < num_cpus; i++) {
		hash_put(cpu_typemap, (void*)&cpus[i]);
	}
}

const cpu_t *cpu_by_name(const char *name) {

	cpu_t *cpu = (cpu_t*) hash_get(cpu_typemap, name);

	return cpu;
}

const cpu_t *cpu_by_type(cpu_type type) {

	int num_cpus = sizeof(cpus)/sizeof(cpu_t);
	
	for (int i = 0; i < num_cpus; i++) {
		if (cpus[i].type == type) {
			return &cpus[i];
		}
	}

	return NULL;
}



