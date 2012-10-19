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
#include "parser.h"


/**
 * pass1 pulls in lines from the infiles component,
 * and pushes them through the next steps
 */
static void pass1() {

	char *line;

	line = infiles_readline();
	while (line != NULL) {
	
		parser_push(line);

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
	mem_init();
	// input files
	infiles_init();
	// parser
	parser_init();

	// pass 1
	pass1();

}

int main(int argc, char *argv[]) {

	main_init();

	main_parse_args(argc, argv);

}

