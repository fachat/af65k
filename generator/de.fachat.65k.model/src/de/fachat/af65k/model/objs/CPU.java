package de.fachat.af65k.model.objs;

/*
The model parser for the af65k set of VHDL cores

Copyright (C) 2012  Andr�� Fachat

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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlElementWrapper;
import javax.xml.bind.annotation.XmlRootElement;

/**
 * Main CPU class. Contains attributes for identifer etc
 * 
 * @author fachat
 *
 */
@XmlRootElement(name = "cpu")
@XmlAccessorType(XmlAccessType.FIELD)
public class CPU {

	String creator;
	Date creationDate;
	String identifier;

	// list of available addressing modes (String identifier)
	@XmlElement(name = "addrmode")
	@XmlElementWrapper(name = "addrmodes")
	List<AddressingMode> addressingModes;

	// list of available prefix bits
	@XmlElement(name = "prefix")
	@XmlElementWrapper(name = "prefixes")
	List<Prefix> prefix;

	// list of opcodes
	@XmlElement(name = "operation")
	@XmlElementWrapper(name = "operations")
	List<Operation> operations;

	// list of opcode classes (cmos, 65k, ...)
	@XmlElement(name = "class")
	@XmlElementWrapper(name = "classes")
	List<FeatureSet> featureSet;

	// list of feature sets (cmos, 65k, ...)
	@XmlElement(name = "feature")
	@XmlElementWrapper(name = "features")
	List<Feature> feature;

	// list of syntax descriptions
	@XmlElement(name = "syntax")
	@XmlElementWrapper(name = "syntaxes")
	List<Syntax> syntaxlist;

	public void postProcess() {

		Map<String, FeatureSet> features = new HashMap<>();

		for (FeatureSet fset : featureSet) {

			System.out.println("Checking FeatureSet " + fset.getName() + ", with includes " + fset.getXtends()
					+ " and features " + fset.getFeature());


			if (fset.getXtends() != null && fset.getXtends().size() > 0) {

				for (String inc : fset.getXtends()) {

					FeatureSet finc = features.get(inc);

					if (finc == null) {
						throw new IllegalStateException("FeatureSet " + fset.getName() + " includes FeatureSet " + inc
								+ " that is not (yet) dedfined");
					}

					System.out.println("Including FeatureSet " + finc.getName() + " with features " + finc.getFeature() + " into " + fset.getName());

					fset.getFeature().addAll(finc.getFeature());
				}
			}

			features.put(fset.getName(), fset);
			
			System.err.println("Defining feature set " + fset.getName() + " as feature list: " + fset.getFeature());
		}
	}

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

	public List<FeatureSet> getFeatureSet() {
		return featureSet;
	}

	public void setFeatureSet(List<FeatureSet> classes) {
		this.featureSet = classes;
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

	public List<Feature> getFeature() {
		return feature;
	}

	public void setFeature(List<Feature> feature) {
		this.feature = feature;
	}
}
