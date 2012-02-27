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

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;

/**
 * constains the description of an addressing mode.
 * 
 * mode is identified by the identifier string
 * 
 * @author fachat
 *
 */
@XmlAccessorType(XmlAccessType.FIELD)
public class AddressingMode {

	String identifier;
	
	// official name of the addressing mode
	String name;
	
	int width;
	
	// alternative name
	String altname;
	
	// position in file; not read from XML (gets overwritten)
	int pos; 
	
	// desc is in HTML notation
	String desc;
	
	// list of prefixes ignored in this addressing mode
	List<String> ignoredPrefixes;

	// alternative addressing mode when the AM prefix bit is set
	String altMode;

	// class of the addressing mode (e.g. CMOS, 65k, ...)
	@XmlElement(name="class")
	String clazz;
	
	public String getIdentifier() {
		return identifier;
	}

	public void setIdentifier(String identifier) {
		this.identifier = identifier;
	}

	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public List<String> getIgnoredPrefixes() {
		return ignoredPrefixes;
	}

	public void setIgnoredPrefixes(List<String> ignoredPrefixes) {
		this.ignoredPrefixes = ignoredPrefixes;
	}

	public String getAltMode() {
		return altMode;
	}

	public void setAltMode(String altMode) {
		this.altMode = altMode;
	}

	public String getClazz() {
		return clazz;
	}

	public void setClazz(String clazz) {
		this.clazz = clazz;
	}

	public int getPos() {
		return pos;
	}

	public void setPos(int pos) {
		this.pos = pos;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getAltname() {
		return altname;
	}

	public void setAltname(String altname) {
		this.altname = altname;
	}

	public int getWidthInByte() {
		return width;
	}
	
	public void setWidthInByte(int w) {
		width = w;
	}

}
