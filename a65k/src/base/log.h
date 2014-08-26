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


#ifndef LOG_H
#define LOG_H

void log_errno(const char *msg, ...);

void log_error(const char *msg, ...);

#ifdef DEBUG

void log_warn(const char *msg, ...);

void log_info(const char *msg, ...);

void log_debug(const char *msg, ...);

void log_term(const char *msg);

#define	log_rv(rv)	log_error("ERROR RETURN: %d\n", (rv))

#else

#define	log_warn(msg, ...)
#define	log_info(msg, ...)
#define	log_debug(msg, ...)
#define	log_term(msg, ...)
#define	log_rv(rv)

#endif

#endif

