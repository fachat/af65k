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

#ifndef MEM_H
#define MEM_H

#include <stdio.h>

#include "types.h"

/*
 * basically a malloc/free wrapper
 */

void mem_module_init(void);

void mem_free(void *ptr);

// alloc single object
void *mem_alloc(const type_t *type);

// alloc multiple object, returning a pointer to an array
void *mem_alloc_n(size_t n, const type_t *type);

// re-alloc multiple objects, returning a pointer to the new array
void *mem_realloc_n(size_t n, const type_t *type, void *orig);

// alloc multiple object, returning a pointer to an array
void *mem_alloc_c(size_t n, const char *name);

// allocate memory and copy given string
char *mem_alloc_str(const char *orig);

// allocate memory and copy given string, up to given number of chars;
// Note: result will always be null byte terminated.
char *mem_alloc_strn(const char *orig, int nchars);

#endif

