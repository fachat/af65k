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


typedef struct hash_s hash_t;

//typedef struct {
//	// approximate size when filled
//	int		approx_size;
//	// number of buckets
//	int		n_buckets;
//	// ptr to array of buckets
//	hash_bucket_t	*buckets;
//	// ptr to hash function - hash from key
//	int		(*hash_from_key)(const void *key);
//	// get the key from an entry that is put into the map
//	const void*	(*key_from_entry)(const void *entry);
//	// optional - when set, check newly added entries if they are equal with a 
//	// previous entry and remove the previous one
//	bool_t		(*equals_key)(const void *fromhash, const void *tobeadded);
//} hash_t;

// initialize a hashmap. nbuckets is the number of hash values that are actually used
// The bucket number is computed by taking the modulo of the hash value to the base nbucket.
// The approximate size is divided by nbuckets to determine the initial size of 
// an allocated bucket.
hash_t *hash_init(int approx_size, int nbuckets, 
		int (*hash_from_key)(const void *data), 
		const void* (*key_from_entry)(const void *entry),
		bool_t (*equals_key)(const void *fromhash, const void *tobeadded));

// convenience - key is a string (char *), so we can use our internal functions for 
// hash_from_key and equals_key
hash_t *hash_init_stringkey(int approx_size, int nbuckets, 
		const void* (*key_from_entry)(const void *entry));

// adds a new entry; returns any entry that has been removed (if match_equals is set)
void *hash_put(hash_t *, void *value);

void *hash_get(hash_t *hash, const void *key);

static inline bool_t hash_contains(hash_t *hash, void *key) {
        return NULL != hash_get(hash, key);
}



#endif

