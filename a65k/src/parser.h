/****************************************************************************

    parser
    Copyright (C) 2012 Andre Fachat

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


#ifndef PARSER_H
#define PARSER_H

#include "context.h"
#include "label.h"
#include "block.h"
#include "operation.h"
#include "tokenizer.h"
#include "arith.h"
#include "list.h"

typedef enum {
        S_LABEQPC,              // set label to PC
        S_LABDEF,               // set label from parameter
} stype_t;

typedef struct {
        const block_t           *blk;
        const context_t         *ctx;
        stype_t                 type;
        // optional
        const label_t           *label;
        const operation_t       *op;
        const anode_t           *param;
} statement_t;


void parser_module_init(void);

void parser_push(const context_t *context, const line_t *line);

list_iterator_t *parser_get_statements(void);

#endif

