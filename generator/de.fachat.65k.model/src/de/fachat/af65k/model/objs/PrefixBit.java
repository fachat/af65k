package de.fachat.af65k.model.objs;

/*
The model parser for the af65k set of VHDL cores

Copyright (C) 2012  André Fachat

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
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

import java.util.List;


/**
 * Contains the description of a (set of) prefix bits
 * 
 * prefix bit is identified by the id
 * 
 * @author fachat
 *
 */
public class PrefixBit {

	String id;
	String name;
	
	// desc is in HTML notation
	String desc;
	
	// bit mask of the valid bits for the prefix
	String mask;
	
	List<PrefixValue> value;
	
	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public List<PrefixValue> getValue() {
		return value;
	}

	public void setValue(List<PrefixValue> value) {
		this.value = value;
	}
	
	public String getMask() {
		return mask;
	}
	public void setMask(String _mask) {
		mask = _mask;
	}
}
