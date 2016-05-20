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
 * describes an operation. contains all its addressing modes and prefix bits 
 * 
 * Operation is identified by the "name" attribute, which is something like "LDA"
 * 
 * @author fachat
 *
 */
@XmlAccessorType(XmlAccessType.FIELD)
public class Operation {

	String name;
	String desc;
	String expand;
	public String getExpand() {
		return expand;
	}

	public void setExpand(String expand) {
		this.expand = expand;
	}

	// operation class
	@XmlElement(name="feature")
	String clazz;
	
	@XmlElement(name="default-le")
	String defaultLe;

	@XmlElement(name="synonym")
	List<String> synonyms;
	
	// list of identifiers for prefix bits relevant to the operation
	List<String> prefixBits;
	
	// list of all supported addressing modes with related opcodes
	List<Opcode> opcodes;

	// list of all supported addressing modes with related opcodes
	List<Doc> doc;

	public String getDefaultLe() {
		return defaultLe;
	}

	public void setDefaultLe(String defaultLe) {
		this.defaultLe = defaultLe;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public List<String> getPrefixBits() {
		return prefixBits;
	}

	public void setPrefixBits(List<String> prefixBits) {
		this.prefixBits = prefixBits;
	}

	public List<Opcode> getOpcodes() {
		return opcodes;
	}

	public void setOpcodes(List<Opcode> opcodes) {
		this.opcodes = opcodes;
	}

	public String getDesc() {
		return desc;
	}

	public void setDesc(String desc) {
		this.desc = desc;
	}

	public String getClazz() {
		return clazz;
	}

	public void setClazz(String clazz) {
		this.clazz = clazz;
	}

	public List<Doc> getDoc() {
		return doc;
	}

	public void setDoc(List<Doc> doc) {
		this.doc = doc;
	}

	public List<String> getSynonyms() {
		return synonyms;
	}

	public void setSynonyms(List<String> synonyms) {
		this.synonyms = synonyms;
	}
	
}
