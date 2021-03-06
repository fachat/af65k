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

typedef enum {
	LEV_TRACE	= 0,
	LEV_DEBUG	= 1,
	LEV_INFO	= 2,
	LEV_WARN	= 3,
	LEV_ERROR	= 4,
	LEV_FATAL	= 5
} err_level;

void log_module_init(err_level l);

void log_set_level(err_level l);

void log_errno(const char *msg, ...);

void log_x(err_level l, const char *msg, ...);

#define	log_error(msg, ...)	log_x(LEV_ERROR, msg, __VA_ARGS__)
#define	log_warn(msg, ...)	log_x(LEV_WARN,  msg, __VA_ARGS__)
#define	log_info(msg, ...)	log_x(LEV_INFO,  msg, __VA_ARGS__)
#define	log_debug(msg, ...)	log_x(LEV_DEBUG, msg, __VA_ARGS__)
#define	log_trace(msg, ...)	log_x(LEV_TRACE, msg, __VA_ARGS__)
#define	log_fatal(msg, ...)	log_x(LEV_FATAL, msg, __VA_ARGS__)


void log_term(const char *msg);

#define	log_rv(rv)	log_error("ERROR RETURN: %d\n", (rv))


#endif

