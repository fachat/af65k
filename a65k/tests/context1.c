

#include <stdio.h>

#include "types.h"
#include "infiles.h"
#include "cpu.h"
#include "segment.h"

#include "context.h"


int main(int argc, char *argv[]) {

	cpu_module_init();

	// test vectors
	openfile_t *f = (openfile_t*) 1;
	segment_t *s = (segment_t*) 2;
	cpu_t *c = cpu_by_name("nmos");

	context_t *ctx = context_init(f, s, c);

	if (ctx->cpu_width != c->cpu_width) {
		printf("cpu width mismatch, was %d, expected %d\n", ctx->cpu_width, c->cpu_width);
	}

	context_t *dup = context_dup(ctx);

	if (dup == NULL) {
		printf("ctx dup returned NULL\n");
	}
	if (dup == ctx) {
		printf("ctx dup returned original input\n");
	}

	if (dup->sourcefile != ctx->sourcefile) {
		printf("sourcefile mismatch, was %p, expected %p\n", (void*)dup->sourcefile, (void*)ctx->sourcefile);
	}
	if (dup->segment != ctx->segment) {
		printf("segment mismatch, was %p, expected %p\n", (void*)dup->segment, (void*)ctx->segment);
	}
	if (dup->cpu != ctx->cpu) {
		printf("cpu mismatch, was %p, expected %p\n", (void*)dup->cpu, (void*)ctx->cpu);
	}
}



