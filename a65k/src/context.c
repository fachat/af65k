
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

#include <stdio.h>
#include <string.h>

#include "types.h"
#include "infiles.h"
#include "array_list.h"
#include "hashmap.h"
#include "mem.h"
#include "cpu.h"
#include "segment.h"
#include "context.h"


#define	DEFAULT_SIZE_CHILDREN_BUCKET	25

static type_t context_memtype = {
	"context",
	sizeof(context_t)
};

static context_t *current_context = NULL;


// create a new context. Usually only called at beginning of parse
const context_t *context_init(const segment_t *segment, const cpu_t *cpu) {

	context_t *ctx = mem_alloc(&context_memtype);

	ctx->segment = segment;
	ctx->cpu = cpu;

	ctx->cpu_width = cpu->width;
	ctx->index_width = false;
	ctx->acc_width = false;

	current_context = ctx;

	return current_context;
}

// duplicates context, so attributes can be modified
context_t *context_dup() {


	context_t *newctx = mem_alloc(&context_memtype);

	context_t *oldctx = current_context;

	memcpy(newctx, oldctx, sizeof(context_t));

	current_context = newctx;

	return current_context;
}


const context_t *context() {
	return current_context;
}

