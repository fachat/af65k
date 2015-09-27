/****************************************************************************

    generic logging interface
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


#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <strings.h>
#include <stdarg.h>
#include <ctype.h>

#include "infiles.h"
#include "log.h"


static err_level level = LEV_WARN;

void log_module_init(err_level l) {
	level = l;
}

void log_set_level(err_level l) {
	level = l;
}


void log_term(const char *msg) {
	
	int newline = 0;

	printf(">>>: ");
	char c;
	while ((c = *msg) != 0) {
		if (newline) {
			printf("\n>>>: ");
		}
		if (isprint(c)) {
			putchar(c);
			newline = 0;
		} else
		if (c == 10) {
			newline = 1;
		} else
		if (c == 13) {
			// silently ignore
		} else {
			printf("{%02x}", ((int)c) & 0xff);
			newline = 0;
		}
		msg++;
	}
	printf("\n");
}

void log_errno(const char *msg, ...) {
       va_list args;
       va_start(args, msg);
	char buffer[1024];

	if (index(msg, '%') != NULL) {
		// the msg contains parameter, so we need to fix it
		vsprintf(buffer, msg, args);
		msg = buffer;
	}
        printf(">> %s: errno=%d: %s\n", msg, errno, strerror(errno));
}

void log_x(err_level lev, const char *msg, ...) {

	const char *prefix = ">>>";
	switch (lev) {
	case LEV_TRACE: prefix = "TRC:"; break;
	case LEV_DEBUG: prefix = "DBG:"; break;
	case LEV_INFO: 	prefix = "INF:"; break;
	case LEV_WARN: 	prefix = "WRN:"; break;
	case LEV_ERROR: prefix = "ERR:"; break;
	case LEV_FATAL: prefix = "FTL:"; break;
	}

	if (lev >= level) {
       		va_list args;
       		va_start(args, msg);

       		printf(prefix);
       		vprintf(msg, args);
		printf("\n");
	}
}




