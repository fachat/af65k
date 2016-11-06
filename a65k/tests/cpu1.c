

#include <stdio.h>

#include "types.h"
#include "position.h"
#include "cpu.h"


int main(int argc, char *argv[]) {

	cpu_module_init();

	const cpu_t *c = cpu_by_name("nmos");

	printf("nmos -> %s, type=%d, width=%d\n",
		c->name, c->type, c->width);


	c = cpu_by_name("rcmos");
	if (c != NULL) {
		printf("found wrong CPU type %s\n", c->name);
	}

	c = cpu_by_name("cmos_rockwell");
	printf("rcmos -> %s, type=%d, width=%d\n",
		c->name, c->type, c->width);

	c = cpu_by_type(NULL, -123);
	if (c != NULL) {
		printf("found wrong CPU type %d\n", -123);
	}

	c = cpu_by_type(NULL, CPU_816);
	printf("816 -> %s, type=%d, width=%d\n",
		c->name, c->type, c->width);

}



