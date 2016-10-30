
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


#ifndef ARITH_H
#define ARITH_H


typedef signed long maxval_t;

typedef enum {
	A_INIT,		// first nodee
	A_BRACKET,	// open bracket
} a_type;

/*
 The anode struct allows building the AST for an arithmetic expression.
*/
typedef struct anode_s anode_t;

struct anode_s {
	// type, incl. brackets, arithm. ops etc
	a_type		type;
	// parent node
	anode_t		*parent;	
	// child nodes in case of brackets
	anode_t		*child;
	// next in case of comma
	anode_t		*next;
	// the actual expression if any
	anode_t		*expr;
	// actual value
	
};


static type_t anode_memtype = {
	"label",
	sizeof(anode_t)
};

static inline anode_t *anode_init(a_type type, anode_t *parent) {
	anode_t *anode = mem_alloc(&anode_memtype);
	
	anode->type = type;
	anode->parent = parent;

	return anode;
}



#endif

