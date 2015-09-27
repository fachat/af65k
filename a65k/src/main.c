/****************************************************************************

    65k processor assembler
    Copyright (C) 2012 Andre Fachat

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

****************************************************************************/

/*
 * main program
 */


#include "main.h"
#include "mem.h"
#include "log.h"
#include "infiles.h"
#include "config.h"
#include "cpu.h"
#include "segment.h"
#include "context.h"
#include "parser.h"
#include "operation.h"


/**
 * pass1 pulls in lines from the infiles component,
 * and pushes them through the next steps
 */
static void pass1() {

	const cpu_t *cpu = cpu_by_name(config()->initial_cpu_name);
	const segment_t *segment = segment_new(NULL, NULL, SEG_ANY, cpu->type, false);
	context_init(segment, cpu);

	line_t *line;

	line = infiles_readline();
	while (line != NULL) {
	
		parser_push(context(), line);

		line = infiles_readline();
	}
}

static void main_parse_args(int argc, char *argv[]) {

	int i = 1;
	while (i < argc) {
		if (argv[i][0] == '-') {
		} else {
			infiles_register(argv[i]);
		}
	}
}

static void main_init() {

	// memory handling
	mem_module_init();
	// configuration
	config_module_init();
	// input files
	infiles_module_init();
	// operation
	operation_module_init();
	// segments
	segment_module_init();
	// parser
	parser_module_init();

}

int main(int argc, char *argv[]) {

	// initialize modules

	main_init();

	// parse command line parameters
	// TODO: need two functions, one legacy xa, one new a65k
	main_parse_args(argc, argv);

	// first pass
	pass1();

	// second pass
	// pass2();
}

