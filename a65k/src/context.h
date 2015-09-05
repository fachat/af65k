
/****************************************************************************

    context management
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

// The context is what describes the current assembler context.
// It contains information about the source file, the current segment,
// the current CPU and its CPU modes (e.g. 65816 index register width,
// or 65k width)

#ifndef CONTEXT_H
#define CONTEXT_H


typedef struct context_s context_t;

struct context_s {
	const segment_t	*segment;
	const cpu_t	*cpu;
	int		cpu_width;	// CPU width, normally taken from *cpu, but can be modified with .width
        bool_t          index_width;    // true when index registers are wide in 65816 (.xe/.xs)
        bool_t          acc_width;      // true when accumulator is wide in 65816 
};

// create the initial context. Usually only called at beginning of parse
const context_t *context_init(const segment_t *segment, const cpu_t *cpu);

// duplicates context, so attributes can be modified. The new context becomes the 
// current context.
context_t *context_dup();

// return the current context
const context_t *context();

#endif

