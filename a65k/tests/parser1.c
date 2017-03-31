

#include <stdio.h>

#include "types.h"
#include "position.h"
#include "cpu.h"
#include "segment.h"
#include "context.h"
#include "position.h"
#include "operation.h"
#include "parser.h"
#include "print.h"


int main(int argc, char *argv[]) {

	cpu_module_init();
	segment_module_init();
	operation_module_init();
	parser_module_init();


	const cpu_t *cpu = cpu_by_name("nmos");

	const segment_t *seg = segment_new(NULL, "test", SEG_ANY, cpu->type, true);

	const context_t *ctx = context_init(seg, cpu);

	position_t pos = { "bogusfile", 1 };
	
	line_t line = { "label adc #123", &pos };
		
	parser_push(ctx, &line);

	//log_set_level(LEV_DEBUG);

	list_iterator_t *iter = parser_get_statements();
	while (list_iterator_has_next(iter)) {
		statement_t *stmt = list_iterator_next(iter);
		print_debug_stmt(stmt);
	}
}



