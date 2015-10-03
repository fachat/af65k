

#include <stdio.h>

#include "types.h"
#include "position.h"
#include "cpu.h"
#include "segment.h"
#include "context.h"
#include "operation.h"


int main(int argc, char *argv[]) {

	cpu_module_init();
	segment_module_init();
	operation_module_init();

	const cpu_t *cpu = cpu_by_name("nmos");

	const segment_t *seg = segment_new(NULL, "test", SEG_ANY, cpu->type, true);

	const context_t *ctx = context_init(seg, cpu);

	const operation_t *op = operation_find("adc");

	if (op == NULL) {
		printf("Opcode 'adc' not found!\n");
	}

	codepoint_t cp;

	bool_t rc = opcode_find(NULL, ctx, op, SY_IMM, 1, &cp);

	if (rc) {
		printf("Opcode 'adc' with addressing mode am=%d, rs_is_width=%d, prefix=%d, found: %02x\n",
			cp.set_am_prefix, cp.rs_is_width, cp.page_prefix, cp.code);
	}
}



