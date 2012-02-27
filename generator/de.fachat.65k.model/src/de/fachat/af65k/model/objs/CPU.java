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

import java.util.Date;
import java.util.List;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * Main CPU class. Contains attributes for identifer etc
 * 
 * @author fachat
 *
 */
@XmlRootElement(name="cpu")
@XmlAccessorType(XmlAccessType.FIELD)
public class CPU {

	String creator;
	Date creationDate;
	String identifier;
	
	// list of available addressing modes (String identifier)
	@XmlElement(name="addrmode")
	List<AddressingMode> addressingModes;
	
	// list of available prefix bits
	List<Prefix> prefix;
	
	// list of opcodes
	@XmlElement(name="operation")
	List<Operation> operations;

	// list of opcode classes (cmos, 65k, ...)
	@XmlElement(name="class")
	List<FeatureClass> classes;

	// list of syntax descriptions
	@XmlElement(name="syntax")
	List<Syntax> syntaxlist;
	
	public String getCreator() {
		return creator;
	}

	public void setCreator(String creator) {
		this.creator = creator;
	}

	public Date getCreationDate() {
		return creationDate;
	}

	public void setCreationDate(Date creationDate) {
		this.creationDate = creationDate;
	}

	public String getIdentifier() {
		return identifier;
	}

	public void setIdentifier(String identifier) {
		this.identifier = identifier;
	}

	public List<AddressingMode> getAddressingModes() {
		return addressingModes;
	}

	public void setAddressingModes(List<AddressingMode> addressingModes) {
		this.addressingModes = addressingModes;
	}

	public List<Operation> getOpcodes() {
		return operations;
	}

	public void setOpcodes(List<Operation> opcodes) {
		this.operations = opcodes;
	}

	public List<Operation> getOperations() {
		return operations;
	}

	public void setOperations(List<Operation> operations) {
		this.operations = operations;
	}

	public List<FeatureClass> getClasses() {
		return classes;
	}

	public void setClasses(List<FeatureClass> classes) {
		this.classes = classes;
	}

	public List<Syntax> getSyntaxlist() {
		return syntaxlist;
	}

	public void setSyntaxlist(List<Syntax> syntaxlist) {
		this.syntaxlist = syntaxlist;
	}

	public List<Prefix> getPrefix() {
		return prefix;
	}

	public void setPrefix(List<Prefix> prefix) {
		this.prefix = prefix;
	}
}
