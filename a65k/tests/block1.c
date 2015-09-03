
#include "mem.h"
#include "list.h"
#include "hashmap.h"
#include "label.h"
#include "block.h"


void do_test();



int main(int argc, char *argv[]) {

	block_t *blk = block_init(NULL);

	label_t *label1 = label_init(NULL, "label1");
	label_t *ladd1 = block_add_label(blk, label1);
	if (ladd1 != NULL) {
		printf("ERROR: l1add not null\n");
	}

	label_t *label2 = label_init(NULL, "label2");
	label_t *ladd2 = block_add_label(blk, label2);
	if (ladd2 != NULL) {
		printf("ERROR: l1add not null\n");
	}

	// add child block
	block_t *blk2 = block_init(blk);

	label_t *label3 = label_init(NULL, "label3");
	label_t *ladd3 = block_add_label(blk2, label3);
	if (ladd3 != NULL) {
		printf("ERROR: ladd3 not null\n");
	}

	label_t *label4 = label_init(NULL, "label4");
	label_t *ladd4 = block_add_label(blk2, label4);
	if (ladd4 != NULL) {
		printf("ERROR: ladd4 not null\n");
	}

	// check conflicts
	
	// duplicate label1 in top level blk
	label_t *label5 = label_init(NULL, "label1");
	label_t *ladd5 = block_add_label(blk, label5);
	if (ladd5 != label1) {
		printf("ERROR: duplicate label not detected (was %p, expected %p)\n", (void*)ladd5, (void*)label1);
	}

	// duplicate label in child block
	label_t *label6 = label_init(NULL, "label2");
	label_t *ladd6 = block_add_label(blk2, label6);
	if (ladd6 != label2) {
		printf("ERROR: duplicate label in child block not detected (was %p, expected %p)\n", (void*)ladd6, (void*)label2);
	}

	// allow duplicate label in higher level block
	label_t *label7 = label_init(NULL, "label4");
	label_t *ladd7 = block_add_label(blk, label7);
	if (ladd7 != NULL) {
		printf("ERROR: did not allow dup in higher block\n");
	}

	
	return 0;
}


void do_test(list_t *list) {

}

