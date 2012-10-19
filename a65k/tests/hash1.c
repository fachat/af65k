

#include <string.h>

#define	DEBUG

#include "log.h"
#include "hashmap.h"

static char *data[] = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9"
};

static bool_t equalsfunc(void *data1, void *data2) {

	log_debug("equals for '%s' vs. '%s' is %d\n", data1, data2, strcmp((char*)data1, (char*)data2));

	return 0 == strcmp((char*)data1, (char*)data2);
}

static int hashfunc(void *data) {
	
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

	hash = hashmap_init(10, 3, hashfunc, equalsfunc);

	do_test(hash);

	return 0;
}


void do_test(hash_t *hash) {

	for (int i = 0; i < 9; i++) {
		
		hash_add(hash, data[i]);
	}


	char *data = (char*) hash_get(hash, "4");

	log_debug("retrieved '%s'\n",data);
}

