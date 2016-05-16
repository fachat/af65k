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

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;

/**
 * pointer from syntax to addressing mode
 * 
 * @author fachat
 *
 */
@XmlAccessorType(XmlAccessType.FIELD)
public class SyntaxMode {

	// width of the operand
//	@XmlElement(name="width")
//	int widthInByte;
	
	String addrMode;
	
	PrefixSetting prefix;

	// if not set, it is filled with the simplesyntax from syntax, with 
	// "<address>" and "<operand>" replaced with width-related names like
	// "zp", "abs", or "byte", "word", ...
	String simplesyntax;
	
	// feature class for a syntax mode
	@XmlElement(name="feature")
	String feature;
	
//	public int getWidthInByte() {
//		return widthInByte;
//	}
//
//	public void setWidthInByte(int widthInByte) {
//		this.widthInByte = widthInByte;
//	}

	public String getAddrMode() {
		return addrMode;
	}

	public void setAddrMode(String addrMode) {
		this.addrMode = addrMode;
	}

	public PrefixSetting getPrefix() {
		return prefix;
	}

	public void setPrefix(PrefixSetting prefix) {
		this.prefix = prefix;
	}

	public String getSimplesyntax() {
		return simplesyntax;
	}

	public void setSimplesyntax(String simplesyntax) {
		this.simplesyntax = simplesyntax;
	}

	public String getFeature() {
		return feature;
	}

	public void setFeature(String clazz) {
		this.feature = clazz;
	}
}
