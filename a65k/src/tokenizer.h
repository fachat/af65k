/****************************************************************************

    tokenizing a line
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


#ifndef TOKENIZER_H
#define TOKENIZER_H

#include <stdio.h>

#include "types.h"

// token type
typedef enum {
	T_INIT,				// initial state
	T_BRACKET,			// any type of bracket
	T_NAME,				// a name, like label1 do_this
	T_TOKEN,			// a token, like ( ) . ++ == <> & 
	T_STRING,			// string
	T_LITERAL,			// a numerical literal value (decimal, hex, ...)
	T_ERROR,			// an error has happened
	T_END,				// end of string reached
} tok_t;

// literal type
typedef enum {
	LIT_NONE,
	LIT_DECIMAL,			// a decimal number, like 1 2 3
	LIT_OCTAL,			// an octal number, like &127 0127
	LIT_BINARY,			// a binary number, like %110101
	LIT_HEX				// a hex number, like $12dA 0x12Ad
} littype_t;

// quote type for strings
typedef enum {
	Q_SINGLE		= '\'',
	Q_DOUBLE		= '"'
} quotetype_t;

static inline bool is_string_delim(char c) {
	return (c == Q_SINGLE || c == Q_DOUBLE);
} 

typedef enum {
	OP_NONE			= 0,
	OP_EXCL 		= '!',	
	OP_AT			= '@',
	OP_XQUOTE		= '`',
	OP_SQUOTE		= '\'',
	OP_OPEN			= '(',
	OP_CLOSE		= ')',
	OP_HASH			= '#',
	OP_BOPEN		= '[',
	OP_BBOPEN		= 136,	// "[["
	OP_BCLOSE		= ']',
	OP_BBCLOSE		= 137,	// "]]"
	OP_STAR			= '*',
	OP_COMMA		= ',',
	OP_PLUS			= '+',	// binary as usual, as unary modified label scope
	OP_MINUS		= '-',
	OP_DIV			= '/',
	OP_COLON		= ':',
	OP_SEMICOLON		= ';',
	OP_DOT			= '.',
	OP_LARGER		= '>',
	OP_LARGEROREQUAL	= 128,	// ">="
	OP_LESS			= '<',
	OP_LESSOREQUAL		= 129,	// "<="
	OP_ASSIGN		= '=',
	OP_ASSIGNADD		= 138,	// "+="
	OP_ASSIGNSUB		= 139,	// "-="
	OP_ASSIGNMULT		= 140,	// "*="
	OP_ASSIGNDIV		= 141,	// "/="
	OP_ASSIGNMOD		= 142,	// "%="
	OP_ASSIGNBITOR		= 143,	// "|="
	OP_ASSIGNBITAND		= 144,	// "&="
	OP_ASSIGNBITXOR		= 145,	// "^="
	OP_ASSIGNSHIFTLEFT	= 146,	// "<<="
	OP_ASSIGNSHIFTRIGHT	= 147,	// ">>="
	OP_BITXOR		= '^',
	OP_BITOR		= '|',
	OP_BITAND		= '&',	// binary as usual, as unary modifies label scope
	OP_EQUAL		= 138,	// "=="
	OP_NOTEQUAL		= 130,	// "!=", "<>", "><"
	OP_SHIFTLEFT		= 131,	// "<<"
	OP_SHIFTRIGHT		= 132,	// ">>"
	OP_LOGICAND		= 133,	// "&&"
	OP_LOGICOR		= 134,	// "||"
	OP_LOGICXOR		= 135,	// "^^"
	OP_BITINV		= '~',
	OP_MOD			= '%',
	// register indexing
	OP_XIND			= 148, 	// ",x"
	OP_YIND			= 149,	// ",y"
	OP_ZIND			= 150,	// ",z"
	OP_SIND			= 151,	// ",s"
	OP_BIND			= 152, 	// ",b"
} op_t;

static inline op_t closing_op(op_t opening_bracket) {
	switch (opening_bracket) {
	case OP_OPEN: 	return OP_CLOSE;
	case OP_BOPEN:	return OP_BCLOSE;
	case OP_BBOPEN:	return OP_BBCLOSE;
	default:	return OP_NONE;
	}
}

extern int prio_of_operator_table[];

static inline int prio_of_operator(const op_t op) {
	return prio_of_operator_table[op];
}

typedef struct {
	const char 	*line;		// line to tokenize
	tok_t		type;		// type of token
	int 		ptr;		// current pointer to token in line
	int		len;		// length of current token (total, i.e. incl. quotes for a string)
	union {
		struct {
			int		ptr;		// pointer to start of string for T_STRING_LITERAL
			int		len;		// length of string for T_STRING_LITERAL
			quotetype_t	type;		// what quote was used?
		} string;
		struct {
			long		value;		// value for decimal, octal, binary, or hex literal
			littype_t	type;		// type of literal, for T_LITERAL
		} literal;
		op_t op;
		int errno;
	} vals;
} tokenizer_t;

// initialize a tokenizer 
tokenizer_t *tokenizer_init(const char *line);

// set to next token; return true when there is a valid token
// if allow_index is true, comma is folded into ",x" etc addressig mode tokens
bool_t tokenizer_next(tokenizer_t *tok, int allow_index);

void tokenizer_free(tokenizer_t *tok);

#endif


