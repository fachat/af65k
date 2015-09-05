/****************************************************************************

    65k processor assembler
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

/*
 * basically a malloc/free wrapper
 */

#include <stdio.h>
#include <malloc.h>
#include <string.h>

#include "types.h"

void mem_module_init(void) {
}


// allocate memory and copy given string
char *mem_alloc_str(const char *orig) {

	int len = strlen(orig);

	char *ptr = malloc(len+1);
	
	strcpy(ptr, orig);

	return ptr;
}

// allocate memory and copy given string, up to number of chars given
char *mem_alloc_strn(const char *orig, int nchars) {

	int len = strlen(orig);
	
	if (len < nchars) {
		nchars = len;
	}

	char *ptr = malloc(nchars+1);
	
	strncpy(ptr, orig, nchars);

	ptr[nchars] = 0;

	return ptr;
}


void *mem_alloc(const type_t *type) {
	// for now just malloc()

	return malloc(type->sizeoftype);
}

void *mem_alloc_c(size_t n, const char *name) {
	// for now just malloc()
	(void) name;

	return malloc(n);
}

// NOTE: does not handle padding, this must be fixed in the type->sizeofstruct value!
void *mem_alloc_n(const size_t n, const type_t *type) {
	// for now just malloc()

	return calloc(n, type->sizeoftype);
}

// NOTE: does not handle padding, this must be fixed in the type->sizeofstruct value!
void *mem_realloc_n(const size_t n, const type_t *type, void *data) {
	// for now just malloc()

	return realloc(data, n * type->sizeoftype);
}

void mem_free(void *ptr) {
	
	free(ptr);
}



