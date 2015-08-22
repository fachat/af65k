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

#include "mem.h"
#include "array_list.h"
#include "hashmap.h"


static type_t hash_memtype = {
	"hashmap",
	sizeof(hash_t)
};

static type_t hash_bucket_memtype = {
	"hashmap_bucket",
	sizeof(hash_bucket_t)
};

static inline int bucket_from_hash(hash_t *hash, int hashval) {
	// find bucket by computing the modulo of the hash value
	int bucketno = hashval % hash->n_buckets;
	return bucketno;
}

hash_t *hash_init(int approx_size, int nbuckets, 
		int (*hash_from_key)(const void *key), 
		const void* (*key_from_entry)(const void *entry), 
		bool_t (*equals_key)(const void *fromhash, const void *tobeadded)) {

	hash_t *hash = mem_alloc(&hash_memtype);

	hash->approx_size = approx_size;
	hash->n_buckets = nbuckets;
	hash->hash_from_key = hash_from_key;
	hash->key_from_entry = key_from_entry;
	hash->equals_key = equals_key;

	hash->buckets = mem_alloc_n(nbuckets, &hash_bucket_memtype);

	return hash;
}


void *hash_put(hash_t *hash, void *value) {

	void *removed = NULL;

	const void *key = hash->key_from_entry(value);

	// calculate hash
	int hashval = hash->hash_from_key(key);

	// find bucket by computing the modulo of the hash value
	int bucketno = bucket_from_hash(hash, hashval);

	list_t *bucket_list = hash->buckets[bucketno].bucket_list;
	if (bucket_list == NULL) {
		// first with this value
		bucket_list = array_list_init(hash->approx_size / hash->n_buckets);
		hash->buckets[bucketno].bucket_list = bucket_list;
	} else {
		list_iterator_t *iter = list_iterator(bucket_list);
		while (list_iterator_has_next(iter)) {
			void *entry = list_iterator_next(iter);

			if (hash->equals_key(hash->key_from_entry(entry), key)) {
				list_iterator_remove(iter);
				removed = entry;
				break;
			}
		}
		list_iterator_free(iter);
	}
	
	list_add(bucket_list, value);

	return removed;
}


void *hash_get(hash_t *hash, void *key) {

	// calculate hash
	int hashval = hash->hash_from_key(key);

	// find bucket by computing the modulo of the hash value
	int bucketno = bucket_from_hash(hash, hashval);

	list_t *bucket_list = hash->buckets[bucketno].bucket_list;

	if (bucket_list == NULL) {
		return NULL;
	}

	list_iterator_t *iter = list_iterator(bucket_list);

	while (list_iterator_has_next(iter)) {

		void *fromhash = list_iterator_next(iter);
	
		if (hash->equals_key(hash->key_from_entry(fromhash), key)) {

			list_iterator_free(iter);

			return fromhash;
		}
	}

	list_iterator_free(iter);

	return NULL;
}


