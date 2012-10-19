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

#include "log.h"
#include "mem.h"
#include "infiles.h"
#include "linked_list.h"

#define	PATH_SEPARATOR_CHAR 	'/'
#define	PATH_SEPARATOR_STR 	"/"

#define	INITIAL_BUFFER_SIZE	4096

typedef struct {
	char 		*filename;	// the file name part
	char 		*filepath;	// the path part
	int		current_line;
	FILE		*filep;
	int		buffer_size;
	char		*buffer;
} openfile_t;

static type_t openfile_memtype = {
	"openfile",
	sizeof(openfile_t)
};

static openfile_t *current_file = NULL;

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

void infiles_init(void) {

	infiles = linked_list_init();
	infile_iter = list_iterator(infiles);

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
	}
	strcat(fp, PATH_SEPARATOR_STR);
	strcat(fp, name);
	
	return fp;
}

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
		log_errno("Could not open file: '%s'", filepath);
		mem_free(filepath);
		return NULL;
	}
}

// open a file
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


char *infiles_readline() {

	if (current_file != NULL && feof(current_file->filep)) {
		// file completely read, close it
		fclose(current_file->filep);
		current_file = NULL;
	}

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
			log_error("Could not open file from all include dirs: %s\n", filename);
			return NULL;
		}
	}

	char *buffer = current_file->buffer;

	// current_file is not NULL
	char *r = fgets(buffer, current_file->buffer_size, current_file->filep);
	if (r == NULL) {
		// EOF without chars, or error
		if (ferror(current_file->filep)) {
			log_error("Error on reading file %s\n", current_file->filename);
			return NULL;
		}
		// EOF without chars
		// should not happen
		fclose(current_file->filep);

		log_warn("EOF for file %s without chars!\n", current_file->filename);
		// fake return
		return "";
	}

	int len = strlen(buffer);
	if (buffer[len-1] != '\n') {
		// buffer overflow
		log_error("Line buffer overflow on line %d of file %s\n", 
			current_file->current_line, current_file->filename);
	} else {
		// overwrite final newline
		buffer[len-1] = 0;
	}
	
	return buffer;
}

