/****************************************************************************

    parser
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

#define	DEBUG

#include <stdio.h>

#include "log.h"
#include "mem.h"
#include "list.h"
#include "hashmap.h"

#include "infiles.h"
#include "cpu.h"
#include "segment.h"
#include "context.h"
#include "parser.h"
#include "label.h"
#include "block.h"
#include "tokenizer.h"
#include "operation.h"

typedef struct {
	block_t			*blk;
} parser_t;

typedef struct {
	const block_t		*blk;
	const context_t		*ctx;
	// optional
	const label_t		*label;
	const operation_t	*op;
} statement_t;

typedef enum {
	P_INIT,
} pstate_t;


static const type_t statement_memtype = {
	"statement_t",
	sizeof(statement_t)
};

static const type_t parser_memtype = {
	"parser_t",
	sizeof(parser_t)
};

static parser_t *p = NULL;

void parser_module_init(void) {

	p = mem_alloc(&parser_memtype);
	p->blk = NULL;
}

void parser_push(const context_t *ctx, const line_t *line) {

	position_t *pos = line->position;

	// is the first block already set?
	if (p->blk == NULL) {
		p->blk = block_init(NULL, pos);
	}

	statement_t *stmt = mem_alloc(&statement_memtype);
	stmt->blk = p->blk;
	stmt->ctx = ctx;
	stmt->op = NULL;
	stmt->label = NULL;

	const operation_t *op = NULL;
	const char *name = NULL;
	label_t *label = NULL;

	// tokenize the line
	pstate_t state = P_INIT;
	tokenizer_t *tok = tokenizer_init(line->line);
	while (tokenizer_next(tok)) {
		switch(state) {
		case P_INIT:
			switch(tok->type) {
			case T_NAME:
				name = mem_alloc_strn(tok->line + tok->ptr, tok->len);
				op = operation_find(ctx->cpu, name);
				if (op == NULL) {
					// label
					label = label_init(ctx, name, pos);
					stmt->label = label;
				} else {
					// operation
					stmt->op = op;
				}
				break;
			default:
				// syntax error
				break;
			}
			break;
		default:
			break;
		};
	}
	tokenizer_free(tok);
}


