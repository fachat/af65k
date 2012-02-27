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
 * this class describes a prefix
 * 
 * The variable bits for the prefix are accumulated from the list PrefixBits masks
 * 
 * @author fachat
 *
 */
public class Prefix {

	// name of the prefix
	String name;
	
	// fixed bits values
	String value;
	
	List<PrefixBit> bits;
	
	// move into opcode page (optional)
	String page;

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getValue() {
		return value;
	}

	public void setValue(String value) {
		this.value = value;
	}

	public List<PrefixBit> getBits() {
		return bits;
	}

	public void setBits(List<PrefixBit> bits) {
		this.bits = bits;
	}

	public String getPage() {
		return page;
	}

	public void setPage(String page) {
		this.page = page;
	}
}
