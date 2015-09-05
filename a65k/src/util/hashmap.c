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
 *
 * Note: there is room for improvement. The actual hash of an entry is
 * not stored, so it needs to be computed on every put/get.
 * But for this to change, we need to remove the use of array_list
 * and hold our own arrays of [{ hash, &entry }]
 */

#include <string.h>

#include "mem.h"
#include "array_list.h"
#include "hashmap.h"
#include "astring.h"

// internal entry
typedef struct {
	int 		hash;
	const void 	*key;
	void	 	*data;
} entry_t;

// internal bucket
typedef struct {
	int		num_allocated;
	int		num_filled;
	entry_t		*array;
} hash_bucket_t;

struct hash_s {
      // initial size of a new bucket
      int             initial_bucket_size;
      // number of buckets
      int             n_buckets;
      // ptr to array of buckets
      hash_bucket_t   *buckets;
      // ptr to hash function - hash from key
      int             (*hash_from_key)(const void *key);
      // get the key from an entry that is put into the map
      const void*     (*key_from_entry)(const void *entry);
      // optional - when set, check newly added entries if they are equal with a 
      // previous entry and remove the previous one
      bool_t          (*equals_key)(const void *fromhash, const void *tobeadded);
};

static type_t entry_memtype = {
	"entry_t",
	sizeof(entry_t)
};

static type_t hash_memtype = {
	"hash_t",
	sizeof(hash_t)
};

static type_t hash_bucket_memtype = {
	"hashmap_bucket",
	sizeof(hash_bucket_t)
};

static int hash_from_stringkey(const void *data) {
	return string_hash((const char *)data);
}
static bool_t equals_stringkey(const void *fromhash, const void *tobeadded) {
	return !strcmp((const char*)fromhash, (const char*)tobeadded);
}

static inline int bucket_from_hash(hash_t *hash, int hashval) {
	// find bucket by computing the modulo of the hash value
	int bucketno = hashval % hash->n_buckets;

	if (bucketno < 0) {
		bucketno = -bucketno;
	}
	return bucketno;
}

hash_t *hash_init_stringkey(int approx_size, int nbuckets, 
		const void* (*key_from_entry)(const void *entry)) {

	return hash_init(approx_size, nbuckets, 
		hash_from_stringkey,
		key_from_entry,
		equals_stringkey);
}

hash_t *hash_init(int approx_size, int nbuckets, 
		int (*hash_from_key)(const void *key), 
		const void* (*key_from_entry)(const void *entry), 
		bool_t (*equals_key)(const void *fromhash, const void *tobeadded)) {

	hash_t *hash = mem_alloc(&hash_memtype);

	hash->initial_bucket_size = approx_size / nbuckets;
	if (hash->initial_bucket_size == 0) {
		hash->initial_bucket_size = 1;
	}
	hash->n_buckets = nbuckets;
	hash->hash_from_key = hash_from_key;
	hash->key_from_entry = key_from_entry;
	hash->equals_key = equals_key;

	// allocate buckets and initialize them as empty
	hash->buckets = mem_alloc_n(nbuckets, &hash_bucket_memtype);
	for (int i = 0; i < nbuckets; i++) {
		hash->buckets[i].num_allocated = 0;
		hash->buckets[i].num_filled = 0;
		hash->buckets[i].array = NULL;
	}
	return hash;
}


void *hash_put(hash_t *hash, void *value) {

	void *removed = NULL;

	const void *key = hash->key_from_entry(value);

	// calculate hash
	int hashval = hash->hash_from_key(key);

	// find bucket by computing the modulo of the hash value
	int bucketno = bucket_from_hash(hash, hashval);

	// find a suitable entry in the bucket
	entry_t *entry = NULL;

	hash_bucket_t *bucket_list = &hash->buckets[bucketno];
	if (bucket_list->array == NULL) {
		// bucket still empty, first with this value, so allocate first
		bucket_list->num_allocated = hash->initial_bucket_size;
		bucket_list->array = mem_alloc_n(bucket_list->num_allocated, &entry_memtype);
		
		entry = bucket_list->array;
		bucket_list->num_filled = 1;
	} else {
		// find the entry in the bucket
		int i = 0;
		for (i = 0; i < bucket_list->num_filled; i++) {
			entry = &bucket_list->array[i];
			if (entry->hash == hashval && hash->equals_key(entry->key, key)) {
				// found
				removed = entry->data;
				break;
			}
		}
		if (i >= bucket_list->num_filled) {
			// not found
			if (bucket_list->num_filled >= bucket_list->num_allocated) {
				// no more space in the bucket, increase bucket
				bucket_list->num_allocated = bucket_list->num_allocated * 2;
				bucket_list->array = mem_realloc_n(bucket_list->num_allocated, &entry_memtype, bucket_list->array);
			}
			// now we are sure to have space in the array
			entry = &bucket_list->array[bucket_list->num_filled];
			bucket_list->num_filled ++;
		}
	}
	entry->key = key;
	entry->hash = hashval;
	entry->data = value;
	
	return removed;
}


void *hash_get(hash_t *hash, const void *key) {

	// calculate hash
	int hashval = hash->hash_from_key(key);

	// find bucket by computing the modulo of the hash value
	int bucketno = bucket_from_hash(hash, hashval);

	hash_bucket_t *bucket_list = &hash->buckets[bucketno];

	entry_t *entry = NULL;
        // find the entry in the bucket
        for (int i = 0; i < bucket_list->num_filled; i++) {
	        entry = &bucket_list->array[i];
	        if (entry->hash == hashval && hash->equals_key(entry->key, key)) {
		        // found
			return entry->data;
	        }
        }
	return NULL;
}


