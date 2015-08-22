

#include <string.h>

#define	DEBUG

#include "log.h"
#include "hashmap.h"

typedef struct {
	const char *name;
	const char *data;
} entry_t;

static entry_t data[] = {
	{ "a", "11" }, 
	{ "b", "22" }, 
	{ "c", "33" }, 
	{ "d", "44" }, 
	{ "e", "55" }, 
	{ "f", "66" }, 
	{ "g", "77" }, 
	{ "h", "88" }, 
	{ "i", "99" }
};

static bool_t equals_key(const void *data1, const void *data2) {

	log_debug("equals for '%s' vs. '%s' is %d\n", data1, data2, strcmp((char*)data1, (char*)data2));

	return (0 == strcmp((char*)data1, (char*)data2));
}

static const void* key_from_entry(const void *data) {

	entry_t *entry = (entry_t*) data;

	return 	entry->name;
}


static int hash_from_key(const void *data) {
	
	char *cdata = (char*)data;

	int len = strlen(cdata);
	
	int hash = len;

	// the hash algorithm used below only makes sense
	// for up to 8 bytes ( 13^8 approx. 32 bit )
	if (len > 8) {
		len = 8;
	}
	for (int i = 0; i < len; i++) {
		hash = hash * 13 + cdata[i];
	}

	log_debug("hash for '%s' is %d\n", cdata, hash);

	return hash;
}


void do_test(hash_t *hash);

int main(int argc, char *argv[]) {

	hash_t *hash = NULL;

	log_debug("hashmap:\n");

	hash = hash_init(10, 3, hash_from_key, key_from_entry, equals_key);

	do_test(hash);

	return 0;
}


void do_test(hash_t *hash) {

	for (int i = 0; i < 9; i++) {
		
		hash_put(hash, (void*)&(data[i]));
	}


	entry_t *data = (entry_t*) hash_get(hash, "4");

	log_debug("retrieved '%s'\n",data == NULL ? "<null>" : data->data);

	data = (entry_t*) hash_get(hash, "e");

	log_debug("retrieved '%s'\n",data == NULL ? "<null>" : data->data);

	entry_t new_e = { "e", "66" };

	data = hash_put(hash, &new_e);

	log_debug("removed '%s'\n",data == NULL ? "<null>" : data->data);

	data = (entry_t*) hash_get(hash, "e");

	log_debug("retrieved '%s'\n",data == NULL ? "<null>" : data->data);
}

