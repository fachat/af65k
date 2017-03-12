/****************************************************************************

    arithmetic operations and expressions
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


#include "types.h"
#include "mem.h"
#include "tokenizer.h"
#include "arith.h"


void arith_parse(tokenizer_t *tok, int allow_index, const anode_t **anode) {

	*anode = NULL;
	anode_t *new_anode = NULL;

	// when true, last token was a value
	int expect_op = 0;

	while (tokenizer_next(tok, allow_index)) {
	
		if (!expect_op) {
			switch(tok->type) {
			case T_INIT:
			case T_BRACKET:
			case T_NAME:
			case T_TOKEN:
				// identify arithmetic tokens
				break;
			case T_STRING:
				new_anode = anode_init(A_VALUE, *anode);
			case T_LITERAL:
				// new node for literal value
				new_anode = anode_init(A_VALUE, *anode);
				new_anode->val.intv.type = tok->vals.literal.type;
				new_anode->val.intv.value = tok->vals.literal.value;
				break;
			case T_ERROR:
			case T_END:
				break;
			}		
		} else {
		}	
	}
}



