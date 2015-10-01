
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#include "log.h"
#include "mem.h"
#include "position.h"
#include "infiles.h"


void do_test();

int main(int argc, char *argv[]) {

	log_module_init(LEV_DEBUG);

	printf("infiles:\n");

	infiles_module_init();

	infiles_register("testfiles/main.a65");
	infiles_includedir("testfiles/incdir1");

	do_test();

	return 0;
}


void do_test() {

        line_t *line;

	char *tmp = NULL;
	char *ptr = NULL;

        line = infiles_readline();
        while (line != NULL) {




		tmp = mem_alloc_str(line->line);
		if (strlen(tmp) > 110) {
			strcpy(tmp+100, "...");
		}
		printf("got f='%s', l=%03d: %s\n", line->position->filename, line->position->lineno, tmp);

		char *tok = strtok_r(tmp, " ", &ptr);
		if (tok != NULL && !strcmp("include", tok)) {
			char *incfilename = strtok_r(NULL, " ", &ptr);
			infiles_include(incfilename);
		}
		mem_free(tmp);
		tmp = NULL;

                line = infiles_readline();
        }

}

