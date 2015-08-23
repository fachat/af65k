
/****************************************************************************

    error defnitions
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


#ifndef ERR_H
#define ERR_H


typedef enum {
	E_TOK_DIGITRANGE 	= 100,		// illegal digit when parsing an int value
	E_TOK_EMPTY		= 101,		// empty token (e.g. "$" hex indicator, but no digits), or empty string
	E_TOK_NONPRINT		= 102,		// illegal (non-printable) character in parsed string
	E_TOK_UNKNOWN		= 103,		// unknown token
	
} err_t;


#endif


