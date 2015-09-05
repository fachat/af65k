

#include <stdio.h>

#include "astring.h"


static void test(const char *c) {

	printf("hash of '%s' is %d\n",c, string_hash(c));
}

int main(int argc, char *argv[]) {

	printf("string_hash:\n");

	test("lda");
	test("inx");
	test("nmos_illegal_nobcd");
	test("65802");
	test("65k_w");
	test("abcdefghijklmnopqrstuvwxyz0123456789");
	test("@€_äÖas#*?^↓µ");

	return 0;
}


