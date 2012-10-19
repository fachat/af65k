/****************************************************************************

    hashmap handling
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
 * a hashmap is used for example to quickly find labels
 */

#ifndef HASHMAP_H
#define HASHMAP_H

#include <stdio.h>

#include "types.h"
#include "list.h"


typedef struct {
	list_t		*bucket_list;
} hash_bucket_t;

typedef struct {
	// approximate size when filled
	int		approx_size;
	// number of buckets
	int		n_buckets;
	// ptr to array of buckets
	hash_bucket_t	*buckets;
	// ptr to hash function - hash from match parameter
	int		(*hash_from_param)(void *fromparam);
	// ptr to hash function - hash from hash entry or add parameter
	int		(*hash_from_entry)(void *fromhash);
	// ptr to match function, returns true when parameter matches fromhash, or value derived from it
	// note that both pointers need not be of the same type. you could have a pointer
	// with a key and a value in the hash, while the match parameter is matched with the key only
	bool_t		(*match_key)(void *fromhash, void *fromparam);
	// optional - when set, check newly added entries if they are equal with a 
	// previous entry and remove the previous one
	bool_t		(*match_equals)(void *fromhash, void *tobeadded);
} hash_t;


hash_t *hash_init(int approx_size, int nbuckets, 
		int (*hashfunc_from_param)(void *data), 
		int (*hashfunc_from_entry)(void *data), 
		bool_t (*match_key)(void *fromhash, void *fromparam),
		bool_t (*match_equals)(void *fromhash, void *tobeadded));

// adds a new entry; returns any entry that has been removed (if match_equals is set)
void *hash_add(hash_t *, void *value);

void *hash_get(hash_t *hash, void *matchparam);

static inline bool_t hash_contains(hash_t *hash, void *matchparam) {
        return NULL != hash_get(hash, matchparam);
}

#endif
