package de.fachat.af65k.asmgen;

import java.io.PrintWriter;

/*
Documentation table generator for the af65k set of VHDL cores

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

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

import de.fachat.af65k.doc.html.HtmlWriter;
import de.fachat.af65k.model.objs.AddressingMode;
import de.fachat.af65k.model.objs.Doc;
import de.fachat.af65k.model.objs.FeatureSet;
import de.fachat.af65k.model.objs.Opcode;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.CodeMapEntry;

/**
 * this class provides methods to generate various types of (HTML) docs from the
 * CPU definition.
 * 
 * @author fachat
 *
 */
public class AsmTableGenerator {

	final Validator cpu;

	public AsmTableGenerator(Validator mycpu) {
		cpu = mycpu;
	}
 
	public void generateOperationtable(PrintWriter wr, String fclass, boolean hasPrefix) {

		wr.println("static operation_t cpu_operations[] = {");
 
		for (Operation op : cpu.getOperations()) {
			
			System.err.println("name:" + op.getName() + " feature " + op.getClazz());
			
			wr.print("{ \"" + op.getName() + "\", ");
			
//			// synonyme
//			wr.print("	{ ");
//			if (op.getSynonyms() != null && op.getSynonyms().size() > 0) {
//				for (String s : op.getSynonyms()) {
//					wr.print("\"" + s + "\", ");
//				}
//			}
//			wr.print(" NULL, }, ");
			
			// featuresets
			if (op.getClazz() == null) {
				// undefined (so far). Need to look at opcodes and addressing modes
				Set<String> features = new HashSet<>();
				for (Opcode o : op.getOpcodes()) {
					String f = o.getFeature();
					if (f == null) {
						// not known (yet). Neet to look at addressing mode
						String amname = o.getAddressingMode();
						AddressingMode am = cpu.getAddressingMode(amname);
						f = am.getFeature();
						if (f == null) {
							features.add("BASE");
						} else {
							features.add(am.getFeature().toUpperCase());
						}
					} else {
						features.add(o.getFeature().toUpperCase());
					}
				}
				//
				Iterator<String> it = features.iterator();
				while (it.hasNext()) {
					wr.print("ISA_" + it.next());
					if (it.hasNext()) {
						wr.print(" + ");
					}
				}
			} else {
				wr.print("ISA_" + op.getClazz().toUpperCase());
			}
			wr.print(", ");
			
			// three booleans
			// - abs_is_rel
			// - check_ac_w
			// - check_idx_w
			wr.print("false, false, false,");
			
			// space for next operation pointer
			wr.print("NULL,");
			
			// opcodes
			wr.println("{");
			for (Opcode o : op.getOpcodes()) {
				wr.print("    { ");
				// code
				wr.print(o.getOpcode());
				wr.print(", ");
				// page (where applicable)
				wr.print(o.getOppage() == null ? "PG_BASE, " : "PG_" + o.getOppage().toUpperCase() + ", ");
				// addressing mode
				String amname = o.getAddressingMode();
				wr.print("\"" + amname + "\", ");
				// feature
				String f = o.getFeature();
				if (f == null) {
					// not known (yet). Neet to look at addressing mode
					AddressingMode am = cpu.getAddressingMode(amname);
					f = am.getFeature();
				}
				if (f == null) {
					wr.print("ISA_BASE, ");
				} else {
					wr.print("ISA_" + f.toUpperCase() + ", ");
				}
				wr.println("},");
			}
			wr.println("}");
			
			wr.println("},");
		}
		
		wr.println("};");
	}


}
