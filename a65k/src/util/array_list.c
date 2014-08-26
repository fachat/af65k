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


#include <stdio.h>
#include <string.h>

// controls the log.h definitions
#undef DEBUG

#include "log.h"
#include "array_list.h"
#include "mem.h"

/*

An array_list is a an array-based list of pointers to any kind of 
other objects. For performance reasons, the full array of the array list
is separated into sublists, called buckets.

Each bucket has the same max size, as defined in the main array list, so
for each bucket the "bucket_size" is the current number of entries in the
bucket.

 */

typedef struct {
        void            *next;          // array list of buckets
        void            *prev;
        int             bucket_size;
        void            **data;         // pointer to array of data pointers
} array_list_bucket_t;

typedef struct {
        // pointer shared with other list implementations 
        list_type_t             type;
        // array list struct
        array_list_bucket_t     *first;
        array_list_bucket_t     *last;
        int                     size;
        int                     bucket_max_size;
} array_list_t;

typedef struct {
        // pointer shared with other list implementations to 
        list_iterator_t         type;
        // array list stuff
        array_list_bucket_t     *current_bucket;
        int                     current_in_bucket;
} array_list_iterator_t;

// static struct inits

static type_t list_memtype = {
	"array_list",
	sizeof(array_list_t)
};

static type_t list_bucket_memtype = {
	"array_list_bucket",
	sizeof(array_list_bucket_t)
};

static type_t list_iterator_memtype = {
	"array_list_iterator",
	sizeof(array_list_iterator_t)
};


static void            	alist_add(list_t *list, void *data);
static list_iterator_t 	*alist_iterator(list_t *list);
static void            	*alist_iter_next(list_iterator_t *iter);
static void            	*alist_iter_remove(list_iterator_t *iter);
static bool_t          	alist_iter_has_next(list_iterator_t *iter);
static void          	alist_iter_free(list_iterator_t *iter);
static void            	*alist_pop(list_t *list);
static void            	*alist_get_last(list_t *list);

static list_type_t list_type = {
	alist_add,
	alist_iterator,
	alist_iter_next,
	alist_iter_remove,
	alist_iter_has_next,
	alist_iter_free,
	alist_pop,
	alist_get_last
};

// init linked list
list_t *array_list_init(int bucket_size) {

	array_list_t *list = mem_alloc(&list_memtype);

	list_init((list_t*)list, &list_type);

	// buckets
	list->first = NULL;
	list->last = NULL;

	log_debug("%p: Creating array_list with max bucket size %d\n", list, bucket_size);

	list->bucket_max_size = bucket_size;

	list->size = 0;
	
	return (list_t*) list;
}

static void list_bucket_free(array_list_bucket_t *bucket) {
	mem_free(bucket->data);
	mem_free(bucket);
}

static void *alist_get_last(list_t *_list) {

        array_list_t *list = (array_list_t*)_list;

        array_list_bucket_t *lastbucket = list->last;

        return lastbucket == NULL ? NULL : lastbucket->data[lastbucket->bucket_size-1];
}

static void *alist_pop(list_t *_list) {

        array_list_t *list = (array_list_t*)_list;

        array_list_bucket_t *lastbucket = list->last;
        if (lastbucket != NULL) {
		// when bucket exists, it always has at least one element
		void *value = lastbucket->data[--lastbucket->bucket_size];

		if (lastbucket->bucket_size == 0) {

			log_debug("%p: removed last bucket entry, removing bucket\n", list);

			// just removed last entry in the bucket
			if (list->first == lastbucket) {
				// was only bucket
				list->first = NULL;
			}
			list->last = lastbucket->prev;
			if (list->last != NULL) {
				list->last->next = NULL;
			}
			list_bucket_free(lastbucket);
		}

                return value;
        }
        return NULL;
}


static array_list_bucket_t *alloc_bucket(int bucketsize) {

	array_list_bucket_t *bucket = mem_alloc(&list_bucket_memtype);
	
	bucket->data = mem_alloc_c(sizeof(void*) * bucketsize, "array_list_bucket_data");

	bucket->bucket_size = 0;

	return bucket;
}

static void alist_add(list_t *_list, void *data) {

	array_list_t *list = (array_list_t*)_list;

	array_list_bucket_t *bucket = list->last;
	if (bucket == NULL) {

		log_debug("%p: no entry yet, create first bucket\n", list);

		// no bucket yet, so alloc one
		bucket = alloc_bucket(list->bucket_max_size);
		
		list->last = bucket;
		list->first = bucket;
	}

	if (bucket->bucket_size >= list->bucket_max_size) {

		log_debug("%p: add new bucket\n", list);

		// last bucket full, so alloc a new one
		bucket = alloc_bucket(list->bucket_max_size);
		
		bucket->next = NULL;
		bucket->prev = list->last;
		list->last->next = bucket;
		list->last = bucket; 
		// no need to set list->first, as this is not the first
	}

	// finally add to bucket
	bucket->data[bucket->bucket_size++] = data;	
}


// forward iterator
static list_iterator_t *alist_iterator(list_t *_list) {

	array_list_t *list = (array_list_t*) _list;

	array_list_iterator_t *iter = mem_alloc(&list_iterator_memtype);

	list_iterator_init((list_iterator_t*)iter, _list);

	iter->current_bucket = list->first;
	iter->current_in_bucket = 0;

	// forward to first element if necessary	
	alist_iter_has_next((list_iterator_t*) iter);

	return (list_iterator_t*) iter;
}


static void *alist_iter_next(list_iterator_t *_iter) {

	array_list_iterator_t *iter = (array_list_iterator_t*)_iter;

	array_list_bucket_t *bucket = iter->current_bucket;

	if (bucket != NULL) {
		return bucket->data[iter->current_in_bucket++];
	}
	return NULL;
}

// remove the item that has last been returned by _next
static void *alist_iter_remove(list_iterator_t *_iter) {

	void *removed = NULL;

	array_list_iterator_t *iter = (array_list_iterator_t*)_iter;

	array_list_bucket_t *ptr_bucket = iter->current_bucket;
	int ptr_in_bucket = iter->current_in_bucket;

	// rewind
	ptr_in_bucket--;
	while (ptr_in_bucket < 0 && ptr_bucket != NULL) {
		ptr_bucket = ptr_bucket->prev;
		ptr_in_bucket = ptr_bucket->bucket_size - 1;
	}

	if (ptr_bucket != NULL) {

		removed = ptr_bucket->data[ptr_in_bucket];

		memmove(ptr_bucket->data + ptr_in_bucket, ptr_bucket->data + ptr_in_bucket + 1, 
				sizeof(void*) * (((array_list_t*)_iter->list)->bucket_max_size - ptr_in_bucket - 1));
	}
	return removed;
}


static bool_t alist_iter_has_next(list_iterator_t *_iter) {

	array_list_iterator_t *iter = (array_list_iterator_t*)_iter;

	while (iter->current_bucket != NULL && iter->current_in_bucket >= iter->current_bucket->bucket_size) {

		log_debug("iterator: next bucket, current in bucket=%d, bucket size=%d, next=%p\n", 
			iter->current_in_bucket, iter->current_bucket->bucket_size,
			iter->current_bucket->next);

		iter->current_bucket = iter->current_bucket->next;
		iter->current_in_bucket = 0;
	}

	log_debug("next bucket is NULL - %d\n", iter->current_bucket != NULL);

	return iter->current_bucket != NULL;
}
 
static void alist_iter_free(list_iterator_t *iter) {
	mem_free(iter);
}


