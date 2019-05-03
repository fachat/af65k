package de.fachat.af65k.doc;

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
import de.fachat.af65k.model.objs.Feature;
import de.fachat.af65k.model.objs.FeatureSet;
import de.fachat.af65k.model.objs.Opcode;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.objs.PrefixBit;
import de.fachat.af65k.model.objs.PrefixSetting;
import de.fachat.af65k.model.objs.SyntaxMode;
import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.CodeMapEntry;

/**
 * this class provides methods to generate various types of (HTML) docs from the
 * CPU definition.
 * 
 * @author fachat
 *
 */
public class OptableDocGenerator {

	final Validator cpu;

	public OptableDocGenerator(Validator mycpu) {
		cpu = mycpu;
	}

	public void generateOperationtable(HtmlWriter wr, String pagename, String fclass, boolean includeOrig) {

		Map<String, CodeMapEntry[]> opcodes = cpu.getOpcodeMap(fclass, false);
		CodeMapEntry page[] = opcodes.get(pagename); // get standard map
		if (page != null) {
			writeOperationTable(wr, page, pagename == null ? cpu.getPrefixes() : null, fclass, includeOrig);
		}
	}

	private void writeOperationTable(DocWriter wr, CodeMapEntry[] page, String[] strings, String fclass, boolean includeOrig) {

		FeatureSet fset = cpu.getFClass(fclass);
		Collection<String> fclasses = fset.getFeature();

		Map<String, Operation> ops = new TreeMap<String, Operation>();
		for (int i = 0; i < 256; i++) {
			CodeMapEntry en = page[i];
			if (en != null) {
				Operation op = en.getOperation();
				if (fclasses.contains(op.getClazz())) {
					ops.put(en.getName(), op);
				} else {
					// feature (clazz) is not set, so we need to check the ops
					for (Opcode opc : op.getOpcodes()) {
						if (fclasses.contains(opc.getFeature())) {
							ops.put(en.getName(), op);
							break;
						}
						if (fclasses.contains(cpu.getAddressingMode(opc.getAddressingMode()).getFeature())) {
							ops.put(en.getName(), op);
							break;
						}
					}
					if (!ops.containsKey(en.getName())) {
						if (includeOrig) {
							ops.put(en.getName(), op);
						}
					}
				}
				
			}
		}

		wr.startUnsortedList();

		for (Map.Entry<String, Operation> en : ops.entrySet()) {
			Operation op = en.getValue();

			wr.startListItem();
			wr.startLink(cpu.id() + "opdesc.html#" + op.getName());
			wr.print(op.getName() + ": ");
			wr.endLink();
			wr.print(op.getDesc());
		}
		wr.endUnsortedList();
	}

	public void generateOpcodetable(DocWriter wr, String pagename, boolean doLong, String fclass, boolean hasPrefix) {

		Map<String, CodeMapEntry[]> opcodes = cpu.getOpcodeMap(fclass, true);
		CodeMapEntry page[] = opcodes.get(pagename); // get standard map
		if (page != null) {
			writeOpcodeTable(wr, page, pagename == null ? cpu.getPrefixes() : null, doLong, fclass, hasPrefix);
		}
	}

	private void writeOpcodeTable(DocWriter wr, CodeMapEntry[] page, String prefixes[], boolean doLong, String fclass,
			boolean hasPrefix) {
		final String hex = "0123456789ABCDEF";

		FeatureSet fset = cpu.getFClass(fclass);
		Collection<String> fclasses = fset.getFeature();

		Map<String, String> unusedatts = new HashMap<String, String>();
		unusedatts.put("class", "unused");
		Map<String, String> prefixatts = new HashMap<String, String>();
		prefixatts.put("class", "prefix");
		Map<String, String> prefixdivatts = new HashMap<String, String>();
		prefixdivatts.put("class", "prefixes");
		Map<String, String> opcodedivatts = new HashMap<String, String>();
		opcodedivatts.put("class", "opc");

		Map<String, Map<String, String>> classatts = new HashMap<String, Map<String, String>>();
		Map<String, String> tmp = new HashMap<String, String>();
		tmp.put("class", "ce02");
		classatts.put("ce02", tmp);
		tmp = new HashMap<String, String>();
		tmp.put("class", "c65k");
		classatts.put("65k", tmp);
		tmp = new HashMap<String, String>();
		tmp.put("class", "c65k10");
		classatts.put("65k10", tmp);
		tmp = new HashMap<String, String>();
		tmp.put("class", "cmos");
		classatts.put("cmos", tmp);
		classatts.put("cmos_ind", tmp);
		classatts.put("rcmos", tmp);
		classatts.put("rcmos_bbx", tmp);

		Map<String, String> tabatts = new HashMap<String, String>();
		tabatts.put("class", "optable");
		wr.startTable(tabatts);

		wr.startTableRow();

		wr.startTableHeaderCell();
		wr.print("LSB->");
		wr.printline();
		wr.print("MSB");

		for (int i = 0; i < 16; i++) {
			wr.startTableHeaderCell();
			wr.print(hex.charAt(i));
		}

		for (int m = 0; m < 16; m++) {
			wr.startTableRow();
			wr.startTableHeaderCell();
			wr.print(hex.charAt(m));
			for (int l = 0; l < 16; l++) {
				int i = m * 16 + l;
				CodeMapEntry entry = page[i];
				String prefix = (prefixes == null) ? "" : prefixes[i];
				if ((!doLong) && hasPrefix && (prefix != null && prefix.length() > 0)) {
					wr.startTableCell(prefixatts);
					wr.print(prefix);
				} else if (entry != null) {
					Map<String, String> atts = new HashMap<String, String>();
					if (prefixes != null && prefixes[i] != null) {
						atts.put("class", "prefix");
					} else {
						Feature fc = entry.getFclass();

						if (fc != null) {
							if (fclasses.contains(fc.getName())) {
								Map<String, String> ca = classatts.get(fc.getName());
								if (ca != null) {
									atts.putAll(ca);
								}
							} else {
								atts.putAll(unusedatts);
							}
						}
						if (prefixes == null && atts.containsKey("class")) {
							if (atts.get("class").equals("c65k")) {
								atts.remove("class");
							}
						}
					}
					wr.startTableCell(atts);
					wr.startDiv(opcodedivatts);
					wr.print(entry.getName());
					Set<SyntaxMode> synmodes = entry.getSynmodes();
					if (synmodes != null) {
						for (SyntaxMode sm : synmodes) {
							// wr.printline();
							wr.print(' ');
							wr.print(sm.getSimplesyntax());
						}
					}
					wr.endDiv();
					if (doLong) {
						if (hasPrefix) {
							wr.startDiv(prefixdivatts);
							List<PrefixSetting> fixed = entry.getOpcode().getFixed();
							if (!entry.getPrefixbits().isEmpty()) {
								wr.printline();
								Collection<String> pbits = new ArrayList<String>();
								for (PrefixBit pb : entry.getPrefixbits()) {
									pbits.add(pb.getId());
								}
								pbits.removeAll(entry.getPrefixbits());
								Iterator<String> it = pbits.iterator();
								while (it.hasNext()) {
									String pb = it.next();
									wr.print(pb);
									if (fixed != null) {
										for (PrefixSetting ps : fixed) {
											if (pb.equals(ps.getName())) {
												wr.print("=" + ps.getValue());
											}
										}
									}
									if (it.hasNext()) {
										wr.print(", ");
									}
								}
							}
							wr.endDiv();
						}
					}
				} else if (hasPrefix && prefix != null && prefix.length() > 0) {
					wr.startTableCell(prefixatts);
					wr.print(prefix);
				} else {
					wr.startTableCell(unusedatts);
				}
			}
		}
		wr.endTable();
	}
}
