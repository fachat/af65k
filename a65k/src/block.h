
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


#ifndef BLOCK_H
#define BLOCK_H

#include "block.h"
#include "list.h"
#include "hashmap.h"

typedef struct block_s block_t;

struct block_s {
	// parent block
	block_t 	*parent;
	// line where block starts and end
	position_t	*blk_start;
	position_t	*blk_end;
	// child contexts
	list_t		*children;
	// labels
	hash_t		*labels;
};

// create a new block, links it with parent (both ways)
// when parent is given. parent can be NULL
block_t *block_init(block_t *parent, position_t *start_position);

// returns NULL when successful. Returns a conflicting label when there is a conflict
label_t *block_add_label(block_t *blk, label_t *label);

// find a label in the block hierarchy
label_t *block_find_label(const block_t *blk, const char *name);

// closes a block, and returns its parent (when available, NULL otherwise)
block_t *block_close(block_t *blk, position_t *end_position);

#endif

