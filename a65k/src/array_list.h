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


#ifndef ARRAY_LIST_H
#define ARRAY_LIST_H

#include <stdio.h>

#include "types.h"
#include "list.h"

typedef struct {
	void		*next;		// array list of buckets
	void	 	*prev;
	int		bucket_size;
	void		**data;		// pointer to array of data pointers
} array_list_bucket_t;

typedef struct {
	// pointer shared with other list implementations 
	list_type_t		type;
	// array list struct
	array_list_bucket_t 	*first;
	array_list_bucket_t 	*last;
	int 			size;
	int			bucket_max_size;
} array_list_t;

typedef struct {
	// pointer shared with other list implementations to 
	list_iterator_t		type;
	// array list stuff
	array_list_bucket_t	*current_bucket;
	int			current_in_bucket;
} array_list_iterator_t;


list_t *array_list_init(int bucket_size);


#endif

