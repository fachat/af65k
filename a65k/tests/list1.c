
#include "linked_list.h"
#include "array_list.h"

static char *data[] = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9"
};

void do_test(list_t *list);

int main(int argc, char *argv[]) {

	list_t *list = NULL;

	printf("linked list:\n");

	list = linked_list_init();

	do_test(list);

	printf("array list:\n");

	list = array_list_init(8);

	do_test(list);

	return 0;
}


void do_test(list_t *list) {

	for (int i = 0; i < 9; i++) {
		
		list_add(list, data[i]);
	}

	list_iterator_t *iter = list_iterator(list);
	while (list_iterator_has_next(iter)) {
		char *data = (char*) list_iterator_next(iter);
		printf("-> %s\n", data);
	}
	list_iterator_free(iter);

	printf("pop\n");

	char *popped = (char*) list_pop(list);
	printf(" -> %s\n", popped);
	char *popped2 = (char*) list_pop(list);
	printf(" -> %s\n", popped2);

	iter = list_iterator(list);
	while (list_iterator_has_next(iter)) {
		char *data = (char*) list_iterator_next(iter);
		printf("-> %s\n", data);
	}
	list_iterator_free(iter);

}

