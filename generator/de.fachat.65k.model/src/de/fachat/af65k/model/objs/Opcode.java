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
 * describes the combination of an opcode and an addressing mode.
 * Is contained in an opcode, so only addressing mode is included here
 * 
 * oppage is the 256-byte page for the opcode, like  "SYS", "EXT", "QUICK", or empty for standard page
 * opcode is the actual opcode, like "0xea" (in Java integer notation)
 * 
 * @author fachat
 *
 */
@XmlAccessorType(XmlAccessType.FIELD)
public class Opcode {

	String addressingMode;
	String oppage;
	String opcode;
	String expand;
	String expand8;
	
	public String getExpand8() {
		return expand8;
	}

	public void setExpand8(String expand8) {
		this.expand8 = expand8;
	}

	// whether it is original (empty), CMOS ("cmos"), or 65k ("65k")
	String feature;
	
	List<PrefixSetting> fixed;
	
	public String getAddressingMode() {
		return addressingMode;
	}
	public void setAddressingMode(String addressingMode) {
		this.addressingMode = addressingMode;
	}
	public String getOppage() {
		return oppage;
	}
	public void setOppage(String oppage) {
		this.oppage = oppage;
	}
	public String getOpcode() {
		return opcode;
	}
	public void setOpcode(String opcode) {
		this.opcode = opcode;
	}
	public List<PrefixSetting> getFixed() {
		return fixed;
	}
	public void setFixed(List<PrefixSetting> fixed) {
		this.fixed = fixed;
	}
	public String getFeature() {
		return feature;
	}
	public void setFeature(String feature) {
		this.feature = feature;
	}
	public String getExpand() {
		return expand;
	}
	public void setExpand(String expand) {
		this.expand = expand;
	}
	
	public String toString() {
		return "Opc[" + oppage + "/" + opcode + ": " + feature + "]";
	}
}
