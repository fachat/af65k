/****************************************************************************

    logging 
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

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#include "infiles.h"
#include "log.h"
#include "errors.h"

#define	MAX_BUF	8192
static char buf[MAX_BUF];

void error_module_init() {
}

void loclog(err_level l, const position_t *loc, const char *msg, ...) {
	va_list va;

	va_start(va, msg);
	
	vsnprintf(buf, MAX_BUF, msg, va);

	const char *filename = (loc == NULL) ? "<>" : loc->file->filename;
	int lineno = (loc == NULL) ? 0 : loc->lineno;

	log_x(l, "%s:%d %s", filename, lineno, buf);
}


