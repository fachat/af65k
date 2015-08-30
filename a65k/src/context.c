
/****************************************************************************

    context management
    Copyright (C) 2012,2015 Andre Fachat

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


#include "types.h"
#include "array_list.h"
#include "hashmap.h"
#include "mem.h"
#include "context.h"


#define	DEFAULT_SIZE_CHILDREN_BUCKET	25

static type_t context_memtype = {
	"context",
	sizeof(context_t)
};

// create a new context, links it with parent (both ways)
// when parent is given. parent can be NULL
context_t *context_init(context_t *parent) {

	context_t *ctx = mem_alloc(&context_memtype);

	ctx->children = array_list_init(DEFAULT_SIZE_CHILDREN_BUCKET);
	ctx->parent = parent;

	return ctx;
}



