
/****************************************************************************

    string util
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


#ifndef STRING_H
#define STRING_H

#include <ctype.h>


// simple hash algorithm. As we use string, we only use the lower 7 bits;
// we also use max the first 8 characters
static inline int string_hash(const char *str) {
	int h = 0;

	int p = 0;
	char c = 0;
	while ( (c = str[p]) ) {
		h = 13 * h + (c & 0x7f);
		p++;
	}
	return h;
}

// simple hash algorithm. As we use string, we only use the lower 7 bits;
// we also use max the first 8 characters
// ignore case by converting tolower() 
static inline int string_hash_nocase(const char *str) {
	int h = 0;

	int p = 0;
	char c = 0;
	while ( (c = str[p]) ) {
		h = 13 * h + (tolower(c) & 0x7f);
		p++;
	}
	return h;
}



#endif

