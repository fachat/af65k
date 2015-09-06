
#include <stdbool.h>

#include "log.h"
#include "tokenizer.h"


const char *teststrings[] = {
	"label1 lda #$10",
	"label2: lda <xyz ; comment",
	"dec 0125",
	"dec 0128",
	"inc 0x12df",
	"inc $1234f",
	".byt 'xsd&'",
	".asc \"dsdd'",
	".asc \"dsA€\"",
	NULL
};


void do_test(const char *teststr);

int main(int argc, char *argv[]) {


	printf("tokenizer:\n");

	for (int p = 0; ;p++) {
		const char *teststr = teststrings[p];
		if (teststr == NULL) {
			break;
		}

		do_test(teststr);
	}
	return 0;
}


void do_test(const char *teststr) {

	printf("tokenizing line: %s\n", teststr);

	tokenizer_t *tok = tokenizer_init(teststr);

	while (tokenizer_next(tok)) {

		printf("TOK -> type=%d, len=%d, val=%ld, ptr=%s\n", tok->type, tok->len, tok->value, tok->line+tok->ptr);
	}
	
	printf("END -> type=%d, value=%ld\n", tok->type, tok->value);

	tokenizer_free(tok);
}

