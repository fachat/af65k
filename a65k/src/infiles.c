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

#include <string.h>
#include <strings.h>

#include "log.h"
#include "mem.h"
#include "infiles.h"
#include "linked_list.h"

#define	PATH_SEPARATOR_CHAR 	'/'
#define	PATH_SEPARATOR_STR 	"/"

#define	INITIAL_BUFFER_SIZE	4096



static type_t openfile_memtype = {
	"openfile",
	sizeof(openfile_t)
};

static type_t position_memtype = {
	"position_t",
	sizeof(position_t)
};

static openfile_t *current_file = NULL;

static line_t line;

// contains the stack of open files
// with entries of openfile_t. Note that entries are not 
// deleted (freed) when the file is closed, as other parts
// hold references to e.g. the file name
static list_t *filestack;

// list of input files as given by the command line (char*)
static list_t *infiles;
// iterator over the input files
static list_iterator_t *infile_iter;

// list of include dirs to be used when finding an input file,
// be it from the command line or from include statements
static list_t *incdirs;

void infiles_module_init(void) {

	infiles = linked_list_init();
	infile_iter = NULL;

	incdirs = linked_list_init();

	filestack = linked_list_init();

	current_file = NULL;
}

// add an include directory to the input file processing
void infiles_includedir(const char *dirname) {

	list_add(incdirs, (char*) dirname);
}


// register a top level input file 
void infiles_register(const char *filename) {

	list_add(infiles, (char*) filename);
}

// combine the (optional) path and the name into a full file path,
// allocating memory for it and copying it there.
static char *alloc_fullpath(const char *path, const char *name) {
	
	char *fp = NULL;
	int len = strlen(name);
	int plen = path == NULL ? 0 : strlen(path);

	// two strings, path separator, and final zero byte
	fp = mem_alloc_c(plen + 1 + len + 1, "fullpath");

	fp[0] = '\0';
	if (path != NULL) {
		strcat(fp, path);
		strcat(fp, PATH_SEPARATOR_STR);
	}
	strcat(fp, name);
	
	return fp;
}

// low level open given single path. Return NULL on not found
static openfile_t *open_file(char *filepath) {

	FILE *filep = fopen(filepath, "r");

	if (filep != NULL) {

		openfile_t *of = mem_alloc(&openfile_memtype);
		
		of->buffer_size = INITIAL_BUFFER_SIZE;
		of->buffer = mem_alloc_c(of->buffer_size, "openfile_buffer");

		of->filep = filep;
		of->current_line = 1;
		
		// separate into file name and path
		char *lastsep = rindex(filepath, PATH_SEPARATOR_CHAR);
		if (lastsep == NULL) {
			of->filename = mem_alloc_str(filepath);
		} else {
			of->filename = mem_alloc_str(lastsep+1);
			*lastsep='\0';
			of->filepath = mem_alloc_str(filepath);
		}
		mem_free(filepath);

		return of;
	} else {
		// file not opened
		log_debug("Could not open file: '%s'", filepath);
		mem_free(filepath);
		return NULL;
	}
}

// open a file, checking all the include dirs
static openfile_t *infile_open(const char *filename) {


	// first try with current dir
	char *fullpath = alloc_fullpath(current_file == NULL ? NULL : current_file->filepath, filename);

	// opens file, frees fullpath, returns openfile struct or NULL
	openfile_t *ofile = open_file(fullpath);

	// not found, so try include dirs
	if (ofile == NULL) {

		list_iterator_t *iter = list_iterator(incdirs);
		while (ofile == NULL && list_iterator_has_next(iter)) {
			char *incpath = (char*) list_iterator_next(iter);

			fullpath = alloc_fullpath(incpath, filename);

			ofile = open_file(fullpath);
		}
		list_iterator_free(iter);
	}

	// still not found, so use current dir (if not yet checked if current_file is NULL)
	if (ofile == NULL && current_file != NULL) {

		fullpath = alloc_fullpath(NULL, filename);

		ofile = open_file(fullpath);
	}

	return ofile;
}

void infiles_include(const char *filename) {

	list_add(filestack, current_file);

	current_file = infile_open(filename);
}

// low level close, also releases the allocated attributes (buffer)
// but not the struct itself, as references to it can be held 
static void infiles_close(openfile_t *file) {

	fclose(file->filep);

	mem_free(file->buffer);
	file->buffer = NULL;

	if (current_file == file) {
		current_file = NULL;
	}
}

line_t *infiles_readline() {

	if (infile_iter == NULL) {
		infile_iter = list_iterator(infiles);
	}

	if (current_file != NULL && feof(current_file->filep)) {
		// file completely read, close it
		infiles_close(current_file);
	}

	// first check if we are in an include, and return to parent file
	if (current_file == NULL) {

		current_file = list_pop(filestack);
	}

	// we were not in an include, so try the next top level file	
	if (current_file == NULL) {

		char *filename = list_iterator_next(infile_iter);

		if (filename == NULL) {
			// last input file done
			// end of pass
			return NULL;
		}

		current_file = infile_open(filename);

		if (current_file == NULL) {
			// could not open file
			log_error("Could not open file from all include dirs: %s", filename);
			return NULL;
		}
	}

	char *buffer = current_file->buffer;

	// current_file is not NULL
	char *r = fgets(buffer, current_file->buffer_size, current_file->filep);
	if (r == NULL) {
		// EOF without chars, or error
		if (ferror(current_file->filep)) {
			log_error("Error on reading file %s", current_file->filename);
			infiles_close(current_file);
			return NULL;
		}
		// EOF without chars
		// should not happen

		log_debug("EOF for file %s without chars!", current_file->filename);
		// fake return empty line
		strcpy(current_file->buffer, "\n");
	}

	int len = strlen(buffer);
	if (buffer[len-1] != '\n') {
		if (len >= current_file->buffer_size - 1) {
			// buffer overflow
			log_error("Line buffer overflow on line %d of file %s after %d bytes", 
				current_file->current_line, current_file->filename, current_file->buffer_size);
		}
	} else {
		// overwrite final newline
		buffer[len-1] = 0;
	}


	line.position = mem_alloc(&position_memtype);
	line.position->file = current_file;
	line.position->lineno = current_file->current_line;
	line.line = buffer;

	current_file->current_line++;
	return &line;
}

