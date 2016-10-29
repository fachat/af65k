
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

// The configuration contains all the options that are available.
// They are set with functions only, and exported as const only,
// so only setters are required.

// The configuration is set during startup only, and then stays
// constant. This is even enforced.

#ifndef CONFIG_H
#define CONFIG_H



typedef struct {
	const char	 	*initial_cpu_name;
	bool_t			is_cpu_change_allowed;
} config_t;

void config_module_init();
// freeze config; any change after that results in exit
void config_freeze();

// get the current configuration
const config_t *config();

// set the configuration, e.g. via command line params
void conf_initial_cpu_name(const char *initial_cpu_name);
void conf_cpu_change_allowed(bool_t);

// convenience methods
inline static bool_t conf_is_cpu_change_allowed(void) {
	return config()->is_cpu_change_allowed;
}

#endif

