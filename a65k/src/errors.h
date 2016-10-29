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


#define	loclog_error(loc, msg, ...)	loclog(LEV_ERROR, loc, msg, __VA_ARGS__)
#define	loclog_warn(loc, msg, ...)	loclog(LEV_WARN, loc, msg, __VA_ARGS__)
#define	loclog_info(loc, msg, ...)	loclog(LEV_INFO, loc, msg, __VA_ARGS__)
#define	loclog_debug(loc, msg, ...)	loclog(LEV_DEBUG, loc, msg, __VA_ARGS__)
#define	loclog_trace(loc, msg, ...)	loclog(LEV_TRACE, loc, msg, __VA_ARGS__)

void loclog(err_level l, const position_t *loc, const char *msg, ...);


// convenience methods

static inline void error_illegal_opcode_size(const position_t *loc, int opsize_in_bytes) {
	loclog_error(loc, "illegal opcode size %d", opsize_in_bytes);
}

static inline void error_parameter_width_not_allowed_for_isa(const position_t *loc, const char *cpu_name, int opsize_in_bytes) {
	loclog_error(loc, "parameter width %d is not allowed for CPU type %s", opsize_in_bytes, cpu_name);
}

static inline void error_illegal_cpu_type(const position_t *loc, int requested, int number_of_defined_cpus) {
	loclog_error(loc, "illegal CPU type - requested type %d (of %d)", 
			requested, number_of_defined_cpus);
}


static inline void trace_am_not_allowed_for_isa(const position_t *loc, const char *am_name, const char *cpu_name, int am_isa, int cpu_isa) {
	loclog_trace(loc, "addressing mode %s (%02x) is not allowed for cpu type %s (%02x)",
			am_name, am_isa, cpu_name, cpu_isa);
}

static inline void trace_am_not_allowed_for_width(const position_t *loc, const char *am_name, const char *cpu_name, int am_width, int cpu_width) {
	loclog_trace(loc, "addressing mode %s (width %d) is not allowed for CPU %s width (%d)",
			am_name, am_width, cpu_name, cpu_width);
}

static inline void trace_no_opcode_for(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name) {
	loclog_trace(loc, "no opcode %s with addressing mode %s has no opcode for CPU %s",
			op_name, am_name, cpu_name);
}

static inline void trace_narrow_operand_wide_ac(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name) {
	loclog_trace(loc, "AC in opcode %s with addressing mode %s for CPU %s is wide (word), operand is narrow (byte)",
			op_name, am_name, cpu_name);
}

static inline void error_wide_operand_narrow_ac(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name) {
	loclog_error(loc, "AC in opcode %s with addressing mode %s for CPU %s is narrow (byte), operand is wide (word)",
			op_name, am_name, cpu_name);
}


static inline void trace_narrow_operand_wide_idx(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name) {
	loclog_trace(loc, "Index in opcode %s with addressing mode %s for CPU %s is wide (word), operand is narrow (byte)",
			op_name, am_name, cpu_name);
}

static inline void error_wide_operand_narrow_idx(const position_t *loc, const char *op_name, const char *am_name, const char *cpu_name) {
	loclog_error(loc, "Index in opcode %s with addressing mode %s for CPU %s is narrow (byte), operand is wide (word)",
			op_name, am_name, cpu_name);
}

static inline void warn_operation_not_for_cpu(const position_t *loc, const char *op_name, const char *cpu_name) {
	loclog_warn(loc, "Operation name %s is not available for CPU %s, assuming label!", op_name, cpu_name);
}

#endif

