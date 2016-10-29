
/****************************************************************************

    config management
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

#include "types.h"
#include "mem.h"
#include "log.h"
#include "position.h"
#include "cpu.h"
#include "config.h"

// The configuration contains all the options that are available.
// They are set with functions only, and exported as const only,
// so only setters are required.

// The configuration is set during startup only, and then stays
// constant. This is even enforced.

static bool_t frozen = false;

static config_t conf = {
	NULL,			// initial CPU 
	false			// is_cpu_change_allowed
};

void config_module_init() {
	// init config fields if necessary
	frozen = false;
	conf_initial_cpu_name("nmos");
	conf_cpu_change_allowed(false);
}

// freeze config; any change after that results in exit
void config_freeze() {
	frozen = true;
}

// get the current configuration
const config_t *config() {
	return &conf;
}

void conf_initial_cpu_name(const char *initial_cpu_name) {

	if (frozen) {
		log_fatal("conf_initial_cpu_name (%s) while frozen", initial_cpu_name);
	}
	mem_free((char*)conf.initial_cpu_name);	
	conf.initial_cpu_name = mem_alloc_str(initial_cpu_name);
	
}

void conf_cpu_change_allowed(bool_t p) {
	if (frozen) {
		log_fatal("conf_is_cpu_change_allowed (%d) while frozen", p);
	}
	conf.is_cpu_change_allowed = p;
}


