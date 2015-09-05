

#include <stdio.h>

#include "types.h"
#include "cpu.h"


int main(int argc, char *argv[]) {

	cpu_module_init();

	cpu_t *c = cpu_by_name("nmos");

	printf("nmos -> %s, type=%d, base=%d, width=%d, has_bcd=%d, has_illegal=%d\n",
		c->name, c->type, c->base, c->cpu_width, c->has_bcd, c->has_illegal);


	c = cpu_by_name("rcmos");
	if (c != NULL) {
		printf("found wrong CPU type %s\n", c->name);
	}

	c = cpu_by_name("cmos_rockwell");
	printf("rcmos -> %s, type=%d, base=%d, width=%d, has_bcd=%d, has_illegal=%d\n",
		c->name, c->type, c->base, c->cpu_width, c->has_bcd, c->has_illegal);

}



