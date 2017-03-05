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

// this code simply tokenizes the input string given some simple basic rules.

#include <ctype.h>
#include <stdbool.h>

#include "types.h"
#include "mem.h"
#include "err.h"
#include "tokenizer.h"


static type_t tokenizer_memtype = {
	"tokenizer_t",
	sizeof(tokenizer_t)
};

// initialize a tokenizer 
tokenizer_t *tokenizer_init(const char *line) {
	
	tokenizer_t *tok = mem_alloc(&tokenizer_memtype);

	tok->line = line;
	tok->ptr = 0;
	tok->len = 0;
	tok->value = 0;
	tok->type = T_INIT;

	return tok;
}

static bool_t parse_base(tokenizer_t *tok, int ptr, int base) {

	int limit = base - 10;
	const char *line = tok->line;
	signed char c = 0;

	long value = 0;
	while (line[ptr] != 0) {
		if (isdigit(c = tok->line[ptr])) {
			c &= 0x0f;
			if (c > (base-1)) {
				// TODO: continue till end of number, so simple typo still allows detect further errors
				tok->value = E_TOK_DIGITRANGE;
				tok->type = T_ERROR;
				return false;
			}
			value = value * base + c;
		} else 
		if (base > 10) {
			c = tolower(c) - 'a';
		
			// c is char, which is unsigned, so no need to compare for <0
			if (c < limit) {
				value = value * base + c;
			} else {
				break;
			}
		} else {
			break;
		}
		ptr++;
	}
	tok->value = value;
	tok->len = ptr - tok->ptr;

	if (tok->len == 0) {
		// syntax error
		tok->value = E_TOK_EMPTY;
		tok->type = T_ERROR;
		return false;
	}
	return true;
}

static inline bool_t parse_decimal(tokenizer_t *tok, int ptr) {

	tok->type = T_DECIMAL_LITERAL;
	return parse_base(tok, ptr, 10);
}

static inline bool_t parse_octal(tokenizer_t *tok, int ptr) {

	tok->type = T_OCTAL_LITERAL;
	return parse_base(tok, ptr, 8);
}

static inline bool_t parse_binary(tokenizer_t *tok, int ptr) {

	tok->type = T_BINARY_LITERAL;
	return parse_base(tok, ptr, 2);
}

static inline bool_t parse_hex(tokenizer_t *tok, int ptr) {

	tok->type = T_HEX_LITERAL;
	return parse_base(tok, ptr, 16);
}

static inline bool_t parse_string(tokenizer_t *tok, int ptr) {

	const char *line = tok->line;

	char delim = line[ptr];
	tok->type = T_STRING_LITERAL;

	ptr++;
	tok->strptr = ptr;

	while (isPrint(line[ptr])) {
		if (line[ptr] == delim) {
			break;
		}
		ptr++;
	}
	tok->strlen = ptr - tok->strptr;
	
	if (line[ptr] == delim) {
		ptr++;
	} else 
	if (line[ptr] != 0) {
		// non-printable char ends string
		tok->value = E_TOK_NONPRINT;
		tok->type = T_ERROR;
		return false;
	}

	tok->len = ptr - tok->ptr;

	if (tok->strlen == 0) {
		// empty string
		tok->value = E_TOK_EMPTY;
		tok->type = T_ERROR;
		return false;
	}
	return true;
}

static inline bool_t parse_name(tokenizer_t *tok, int ptr) {

	const char *line = tok->line;
	tok->type = T_NAME;

	while (isalnum(line[ptr]) || (line[ptr] == '_')) {
		ptr++;
	}

	tok->len = ptr - tok->ptr;

	return true;
}

static inline bool_t parse_token(tokenizer_t *tok, int ptr, int can_have_operator, int allow_index) {

	const char *line = tok->line;

	char c = line[ptr];

	// default outcome
	tok->value = c;
	tok->type = T_TOKEN;
	tok->len = 1;

	switch(c) {
	case '@':
	case '`':
	case '\'':
	case '(':
	case ')':
	case '#':
	case ':':
	case '.':
	case ';':
		return true;
	case ',':
		// TODO: check OP_*IND
		// using allow_index
		return true;
	case '%':
		if (line[ptr+1] == '=') {
			tok->value = OP_ASSIGNMOD;
			tok->len++;
			return true;
		}
		return true;
	case '-':
		if (line[ptr+1] == '=') {
			tok->value = OP_ASSIGNSUB;
			tok->len++;
			return true;
		}
		return true;
	case '+':
		if (line[ptr+1] == '=') {
			tok->value = OP_ASSIGNADD;
			tok->len++;
			return true;
		}
		return true;
	case '*':
		if (line[ptr+1] == '=') {
			tok->value = OP_ASSIGNMULT;
			tok->len++;
			return true;
		}
		return true;
	case '/':
		if (line[ptr+1] == '=') {
			tok->value = OP_ASSIGNDIV;
			tok->len++;
			return true;
		}
		return true;
	case ']':
		if (line[ptr+1] == ']') {
			tok->value = OP_BBCLOSE;
			tok->len++;
			return true;
		}
		// OP_BOPEN
		return true;
	case '[':
		if (line[ptr+1] == '[') {
			tok->value = OP_BBOPEN;
			tok->len++;
			return true;
		}
		// OP_BOPEN
		return true;
	case '!':
		if (can_have_operator) {
			switch (line[ptr+1]) {
			case '=':
				tok->value = OP_NOTEQUAL;
				tok->len++;
				return true;
			default:
				// default
				// OP_EXCL
				return true;
			}
		} else {
			// OP_EXCL
			return true;
		}
	case '>':
		if (can_have_operator) {
			// check ">>", ">=", "><"
			switch (line[ptr+1]) {
			case '>':
				if (line[ptr+2] == '=') {
					tok->value = OP_ASSIGNSHIFTRIGHT;
					tok->len += 2;
					return true;
				}
				tok->value = OP_SHIFTRIGHT;
				tok->len++;
				return true;
			case '=':
				tok->value = OP_LARGEROREQUAL;
				tok->len++;
				return true;
			case '<':
				tok->value = OP_NOTEQUAL;
				tok->len++;
				return true;
			default:
				// default
				return true;
			}
		} else {
			// ">" for high byte modifier or larger than
			return true;
		}
	case '<':
		if (can_have_operator) {
			// check "<<", "<=", "<>"
			switch (line[ptr+1]) {
			case '<':
				if (line[ptr+2] == '=') {
					tok->value = OP_ASSIGNSHIFTLEFT;
					tok->len += 2;
					return true;
				}
				tok->value = OP_SHIFTLEFT;
				tok->len++;
				return true;
			case '=':
				tok->value = OP_LESSOREQUAL;
				tok->len++;
				return true;
			case '>':
				tok->value = OP_NOTEQUAL;
				tok->len++;
				return true;
			default:
				// default
				return true;
			}
		} else {
			// "<" for high byte modifier
			return true;
		}
	case '=':
		if (can_have_operator) {
			// check "==", "=>", "=<"
			switch (line[ptr+1]) {
			case '=':
				tok->value = OP_EQUAL;
				tok->len++;
				return true;
			default:
				// default, assign
				return true;
			}
		} else {
			// '=' assign
			return true;
		}
	case '&':
		// check "&", "&&", "&="
		switch (line[ptr+1]) {
		case '&':
			tok->value = OP_LOGICAND;
			tok->len++;
			return true;
		case '=':
			tok->value = OP_ASSIGNBITAND;
			tok->len++;
			return true;
		} 
		return true;
	case '|':
		// check "|", "||", "|="
		switch (line[ptr+1]) {
		case '|':
			tok->value = OP_LOGICOR;
			tok->len++;
			return true;
		case '=':
			tok->value = OP_ASSIGNBITOR;
			tok->len++;
			return true;
		} 
		return true;
	case '^':
		// check "^", "^^", "^="
		switch (line[ptr+1]) {
		case '^':
			tok->value = OP_LOGICXOR;
			tok->len++;
			return true;
		case '=':
			tok->value = OP_ASSIGNBITXOR;
			tok->len++;
			return true;
		} 
		return true;
	default:
		tok->value = E_TOK_UNKNOWN;
		tok->type = T_ERROR;
		return false;
	}

	return true;
}

// set to next token; return true when there is a valid token
bool_t tokenizer_next(tokenizer_t *tok, int allow_index) {

	tok->value = 0;

	// move behind last token
	int ptr = tok->ptr + tok->len;

	const char *line = tok->line;

	// attempt to not have to store an extra operand/operator flag in the tokenizer	
	// or even have to pass it to this function as parameter...
	bool_t can_have_operator = (tok->type == T_DECIMAL_LITERAL) 
			|| (tok->type == T_OCTAL_LITERAL)
			|| (tok->type == T_BINARY_LITERAL)
			|| (tok->type == T_HEX_LITERAL)
			|| (tok->type == T_TOKEN && line[ptr] == ')');

	// skip whitespace
	while (line[ptr] != 0 && isspace(line[ptr])) {
		ptr++;
	}

	tok->ptr = ptr;

	//printf("ptr=%d, c=%d\n", ptr, line[ptr]);

	// are we done with the line yet?
	if (line[ptr] == 0 || tok->type == T_END || tok->type == T_ERROR) {
		tok->len = 0;
		tok->type = T_END;
		return false;
	}

	char c = line[ptr];

	if (isdigit(c)) {
		// handle octal (starting with '0'), hex (starting with '0x'), dec
		if (c == '0') {
			if (line[ptr+1] == 'x' || line[ptr+1] == 'X') {
				// hex
				ptr += 2;
				tok->ptr = ptr;
				return parse_hex(tok, ptr);
			} else {
				// octal
				return parse_octal(tok, ptr);
			}
		} else {
			// dec
			return parse_decimal(tok, ptr);
		}
	} else
	if ((!can_have_operator) && (c == '%')) {
		// binary
		ptr++;
		tok->ptr = ptr;
		return parse_binary(tok, ptr);
	} else
	if ((!can_have_operator) && (c == '$')) {
		// hex
		ptr++;
		tok->ptr = ptr;
		return parse_hex(tok, ptr);
	} else
	if ((!can_have_operator) && (c == '&')) {
		// octal
		ptr++;
		tok->ptr = ptr;
		return parse_octal(tok, ptr);
	} else
	if (c == '\'' || c == '"') {
		// string literal
		return parse_string(tok, ptr);
	} else
	if (isalpha(c) || c == '_') {
		// name
		return parse_name(tok, ptr);
	} else
	if (ispunct(c)) {
		// any other token
		return parse_token(tok, ptr, can_have_operator, allow_index);
	} else {
		// non-printable - error
		tok->value = E_TOK_UNKNOWN;
		tok->type = T_ERROR;
		return false;
	}
	
}


void tokenizer_free(tokenizer_t *tok) {
	
	tok->line = NULL;

	mem_free(tok);
}



