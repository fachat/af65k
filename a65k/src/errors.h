/****************************************************************************

    error handling
    Copyright (C) 2015 Andre Fachat

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

#ifndef ERRORS_H
#define ERRORS_H


void error_module_init();

void error_illegal_opcode_size(const position_t *loc, int opsize_in_bytes);
void error_parameter_width_not_allowed_for_isa(const position_t *loc, const char *cpu_name, int opsize_in_bytes);
void error_illegal_cpu_type(cpu_type requested, int number_of_defined_cpus);



void trace_am_not_allowed_for_isa(const position_t *loc, const char *am_name, const char *cpu_name, int am_isa, int cpu_isa);
void trace_am_not_allowed_for_width(const position_t *loc, const char *am_name, const char *cpu_name, int am_width, int cpu_width);
void trace_no_opcode_for(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name);

#endif

