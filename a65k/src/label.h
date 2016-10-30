
/****************************************************************************

    label management
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


#ifndef LABEL_H
#define LABEL_H


typedef struct {
	// context
	const context_t		*ctx;
	// position in file where defined
	const position_t	*position;
	// name
	const char 		*name;
	// TODO value, state etc
} label_t;


static type_t label_memtype = {
	"label",
	sizeof(label_t)
};

static inline label_t *label_init(const context_t *ctx, const char *name, const position_t *pos) {
	label_t *label = mem_alloc(&label_memtype);

	label->ctx = ctx;
	label->name = name;
	label->position = pos;

	return label;
}


#endif

