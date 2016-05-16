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
 * class describes a syntax for an addressing mode
 * It contains pointers to the addressing modes for the different operand sizes
 * 
 * @author fachat
 *
 */
@XmlAccessorType(XmlAccessType.FIELD)
public class Syntax {

	// identifier
	String id;
	
	// description
	String desc;
	
	// whether it is original (empty), CMOS ("cmos"), or 65k ("65k")
	@XmlElement(name="class")
	String clazz;

	// simple syntax - kind of formal
	@XmlElement(name="simplesyntax")
	String simpleSyntax;
	
	// list may contain same width multiple times (e.g. 0 for AC and implied) - then opcode must match
	@XmlElement(name="mode")
	List<SyntaxMode> addrModes;

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public String getSimpleSyntax() {
		return simpleSyntax;
	}

	public void setSimpleSyntax(String simpleSyntax) {
		this.simpleSyntax = simpleSyntax;
	}

	public List<SyntaxMode> getAddrModes() {
		return addrModes;
	}

	public void setAddrModes(List<SyntaxMode> addrModes) {
		this.addrModes = addrModes;
	}
}
