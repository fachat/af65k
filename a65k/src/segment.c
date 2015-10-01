
/****************************************************************************

    segment management
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

#include "mem.h"
#include "types.h"
#include "hashmap.h"
#include "position.h"
#include "cpu.h"
#include "segment.h"


// default names for the xa65 default segments
const char *SEG_ANY_NAME = "*";
const char *SEG_BSS_NAME = "bss";
const char *SEG_TEXT_NAME = "text";
const char *SEG_DATA_NAME = "data";
const char *SEG_ZP_NAME = "zp";

static hash_t *segments = NULL;

static type_t segment_memtype = {
	"segment_t",
	sizeof(segment_t)
};

static const void *segment_key_from_entry(const void *entry) {
	return ((const segment_t*)entry)->name;
}

void segment_module_init() {

	segments = hash_init_stringkey(5, 5, &segment_key_from_entry);
}

// create a new segment or find an existing, matching one
segment_t *segment_new(const position_t *loc, const char *name, seg_type type, cpu_type cpu, bool_t readonly) {

	segment_t *existing = hash_get(segments, name);

	if (existing == NULL) {
		existing = mem_alloc(&segment_memtype);

		existing->name = mem_alloc_str(name);
		existing->type = type;
		existing->readonly = readonly;
		existing->cpu_width = cpu_by_type(loc, cpu)->width;
	}

	return existing;
}


