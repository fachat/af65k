/****************************************************************************

    list handling
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


#ifndef LINKED_LIST_H
#define LINKED_LIST_H

#include <stdio.h>

#include "types.h"
#include "list.h"


typedef struct {
	void		*next;
	void	 	*prev;
	void		*data;
} linked_list_item_t;

typedef struct {
        // pointer shared with other list implementations to 
        // struct with method pointers
        list_type_t             type;
	// linked list specific
	linked_list_item_t 	*first;
	linked_list_item_t 	*last;
} linked_list_t;

typedef struct {
        // pointer shared with other list implementations 
        list_iterator_t         type;
	// linked list stuff
	linked_list_item_t	*current;
} linked_list_iterator_t;


list_t *linked_list_init();

 

#endif

