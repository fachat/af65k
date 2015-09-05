/****************************************************************************

    input file handling
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


#ifndef INFILES_H
#define INFILES_H

struct openfile {
        char            *filename;      // the file name part
        char            *filepath;      // the path part
        int             current_line;
        FILE            *filep;
        int             buffer_size;
        char            *buffer;
};
typedef struct openfile openfile_t;

typedef struct {
        const openfile_t        *file;
        int                     lineno;
} position_t;

typedef struct {
	const char 		*line;
	position_t		*position;
} line_t;

void infiles_module_init(void);

// add an include directory to the input file processing
void infiles_includedir(const char *filename);

// register a top level input file 
void infiles_register(const char *filename);

// read a line from the input. Note the result is static and must not be freed.
// Ownership of the actual line stays with the infile module, so line must be copied
// when a modifyable version, or one that exists longer than the next call to infile_readline
// is needed. The position_t pointed to in the line is transferred to the caller
// and should/can be freed
line_t *infiles_readline();

// during read operation, and after parsing, an "include" operation can occur. 
// The indiles_include call opens the file given, and reads from there until end of file,
// before returning to the original file.
void infiles_include(const char *filename);

#endif

