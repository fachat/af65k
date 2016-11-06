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
// TODO: ignore case flag
hash_t *hash_init_stringkey(int approx_size, int nbuckets, 
		const char* (*key_from_entry)(const void *entry));
// same but ignore case when computing hash and comparing keys
hash_t *hash_init_stringkey_nocase(int approx_size, int nbuckets, 
		const char* (*key_from_entry)(const void *entry));

// adds a new entry; returns any entry that has been removed (if match_equals is set)
void *hash_put(hash_t *, void *value);

// get the value for the given hash key, NULL if none found
void *hash_get(hash_t *hash, const void *key);

static inline bool_t hash_contains(hash_t *hash, void *key) {
        return NULL != hash_get(hash, key);
}



#endif

