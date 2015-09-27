

#include <string.h>

#define	DEBUG

#include "log.h"
#include "astring.h"
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
	{ "i", "99" },
	{ "nmos_illegal_nobcd", "has negative hash caused illegal pointer reference" },
};

static bool_t equals_key(const void *data1, const void *data2) {

	log_debug("equals for '%s' vs. '%s' is %d", data1, data2, strcmp((char*)data1, (char*)data2));

	return (0 == strcmp((char*)data1, (char*)data2));
}

static const void* key_from_entry(const void *data) {

	entry_t *entry = (entry_t*) data;

	return 	entry->name;
}


static int hash_from_key(const void *data) {
	
	char *cdata = (char*)data;

	int hash = string_hash(cdata);

	log_debug("hash for '%s' is %d", cdata, hash);

	return hash;
}


void do_test(hash_t *hash);

int main(int argc, char *argv[]) {

	log_module_init(LEV_DEBUG);

	hash_t *hash = NULL;

	log_debug("hashmap:", 0);

	hash = hash_init(10, 3, hash_from_key, key_from_entry, equals_key);

	do_test(hash);

	return 0;
}


void do_test(hash_t *hash) {

	int datasize = sizeof(data)/sizeof(entry_t);
	printf ("sizeof data=%d\n", datasize);
	
	for (int i = 0; i < datasize; i++) {
		
		hash_put(hash, (void*)&(data[i]));
	}


	entry_t *data = (entry_t*) hash_get(hash, "4");

	log_debug("retrieved '%s'",data == NULL ? "<null>" : data->data);

	data = (entry_t*) hash_get(hash, "e");

	log_debug("retrieved '%s'",data == NULL ? "<null>" : data->data);

	entry_t new_e = { "e", "66" };

	data = hash_put(hash, &new_e);

	log_debug("removed '%s'",data == NULL ? "<null>" : data->data);

	data = (entry_t*) hash_get(hash, "e");

	log_debug("retrieved '%s'",data == NULL ? "<null>" : data->data);
}

