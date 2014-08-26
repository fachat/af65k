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


#ifndef LIST_H
#define LIST_H

#include <stdio.h>

#include "log.h"
#include "types.h"


typedef struct {
	void	 	*type;
	int		mod_cnt;
} list_t;

typedef struct {
	list_t		*list;
	int		mod_cnt;	// list mod count when iterator was generated (fail fast check)
} list_iterator_t;

typedef struct {
	void		(*add)(list_t *list, void *data);
	list_iterator_t	*(*iterator)(list_t *list);
	void		*(*iter_next)(list_iterator_t *iter);
	void		*(*iter_remove)(list_iterator_t *iter);
	bool_t		(*iter_has_next)(list_iterator_t *iter);
	void		(*iter_free)(list_iterator_t *iter);
	void		*(*pop)(list_t *list);
	void		*(*get_last)(list_t *list);
} list_type_t;

// internal list initialization
static inline void list_init(list_t *list, list_type_t *type) {
	list->type = type;
	list->mod_cnt = 0;
}

static inline void list_iterator_init(list_iterator_t *iter, list_t *list) {
	iter->list = list;
	iter->mod_cnt = list->mod_cnt;
}

static inline void list_check_mod(list_iterator_t *iter) {
	if (iter->list->mod_cnt != iter->mod_cnt) {
		log_error("List modification count mismatch! expected %d, was %d\n", 
			iter->mod_cnt, iter->list->mod_cnt);
	}
}

// public methods
static inline void list_add(list_t *list, void *data) {
	list->mod_cnt++;
	((list_type_t*)list->type)->add(list, data);
}

static inline void *list_pop(list_t *list) {
	list->mod_cnt++;
	return ((list_type_t*)list->type)->pop(list);
}

static inline void *list_get_last(list_t *list) {
	return ((list_type_t*)list->type)->get_last(list);
}

static inline list_iterator_t *list_iterator(list_t *list) {
	// the called method calls back into list_iterator_init()
	return ((list_type_t*)list->type)->iterator(list);
}

static inline bool_t list_iterator_has_next(list_iterator_t *iter) {
	list_check_mod(iter);
	return ((list_type_t*)iter->list->type)->iter_has_next(iter);
}

static inline void *list_iterator_next(list_iterator_t *iter) {
	list_check_mod(iter);
	return ((list_type_t*)iter->list->type)->iter_next(iter);
}

// remove the object that has been last returned by list_iterator_next()
static inline void *list_iterator_remove(list_iterator_t *iter) {
	list_check_mod(iter);
	return ((list_type_t*)iter->list->type)->iter_remove(iter);
}

static inline void list_iterator_free(list_iterator_t *iter) {
	((list_type_t*)iter->list->type)->iter_free(iter);
}

#endif

