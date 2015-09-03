
/****************************************************************************

    block management
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

#include "types.h"
#include "array_list.h"
#include "hashmap.h"
#include "mem.h"
#include "label.h"
#include "block.h"
#include "astring.h"


#define	DEFAULT_SIZE_CHILDREN_BUCKET	25
#define	DEFAULT_SIZE_LABELS_MAP		512
#define	DEFAULT_SIZE_LABELS_BUCKETS	128

static type_t block_memtype = {
	"block_t",
	sizeof(block_t)
};

// key is the label name
static int block_hash_from_key(const void *data) {

	return string_hash((const char *)data);
}

static const void *block_key_from_entry(const void *entry) {

	return ((label_t*)entry)->name;
}

static bool_t block_equals_entry(const void *fromhash, const void *tobeadded) {

	return !strcmp((const char*) fromhash, (const char*) tobeadded);
}

// create a new block, links it with parent (both ways)
// when parent is given. parent can be NULL
block_t *block_init(block_t *parent) {

	block_t *blk = mem_alloc(&block_memtype);

	blk->children = array_list_init(DEFAULT_SIZE_CHILDREN_BUCKET);
	blk->parent = parent;

	blk->labels = hash_init(DEFAULT_SIZE_LABELS_MAP, DEFAULT_SIZE_LABELS_BUCKETS,
		block_hash_from_key, block_key_from_entry, block_equals_entry);

	return blk;
}


// returns NULL when successful. Returns a conflicting label when there is a conflict
label_t *block_add_label(block_t *blk, label_t *label) {

	label_t *conflict = NULL;
	const void *key = block_key_from_entry(label);
	block_t *b = blk;
	while (b != NULL) {
		conflict = hash_get(b->labels, key);
		if (conflict != NULL) {
			return conflict;
		}
		b = b->parent;
	}

	hash_put(blk->labels, label);

	return NULL;
}


