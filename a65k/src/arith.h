
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

/*
The anode_t struct is a node in an arithmetic expression
It is linked together in a tree-structure like such:

	(foo + 3) << 2, "foo", -1

	node0(A_BRACKET, AB_RND)
          |  |    |
          |  |    +-(expr)->node3(OP_SHFTLEFT, A_VALUE)
	  |  |
	  |  +-(child)->node1(A_LABEL)
	  |              |
          |              +-(expr)->node2(OP_ADD, A_VALUE)
	(next)
	  v
	node4(A_VALUE, AB_STRD)
	  |
	(next)
	  v
	node5(OP_NEG, A_VALUE, AV_DEC)

*/

typedef enum {
	A_INIT,		// first nodee
	A_BRACKET,	// open bracket
	A_VALUE,	// value
	A_LABEL,	// label reference
} a_type;

typedef enum {
	// A_VALUE subtypes
	AV_NONE,	// for unary operators when another op follows
	AV_HEX,		// $89ab
	AV_HEXC,	// 0x89ab
	AV_BIN,		// %0101
	AV_DEC,		// 1234
	AV_OCT,		// &1271
	AV_OCTC,	// 01271
	AV_STRS,	// string single quote '\''
	AV_STRD,	// string double quote '"'
	// A_BRACKET subtypes (not necessarily all are used)
	AB_RND,		// (
	AB_ANG,		// <
	AB_RCT,		// [
	AB_CRV,		// {
	AB_DBLRCT,	// [[
} asub_type;

/*
 The anode struct allows building the AST for an arithmetic expression.
*/
typedef struct anode_s anode_t;

struct anode_s {
	// type, incl. brackets, arithm. ops etc
	a_type		type;
	// sub type, depending on the type
	asub_type	subtype;
	// operation
	op_t		op;
	// parent node
	anode_t		*parent;	
	// child nodes in case of brackets
	anode_t		*child;
	// next in case of comma
	anode_t		*next;
	// the actual expression if any
	anode_t		*expr;
	// actual value
	union {
	  maxval_t 	intval;
	  struct {
	    const char 	*str;
	    int		len;
	  } strval;
	  // TODO: label etc
	} val;
};


static type_t anode_memtype = {
	"label",
	sizeof(anode_t)
};

static inline anode_t *anode_init(a_type type, anode_t *parent) {
	anode_t *anode = mem_alloc(&anode_memtype);
	
	anode->type = type;
	anode->subtype = AV_NONE;
	anode->op = OP_NONE;

	anode->parent = parent;
	anode->child = NULL;
	anode->next = NULL;
	anode->expr = NULL;

	return anode;
}

void arith_parse(tokenizer_t *tok, int allow_index, const anode_t **anode);

#endif

