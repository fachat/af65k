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
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

import de.fachat.af65k.doc.html.HtmlWriter;
import de.fachat.af65k.model.objs.FeatureClass;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.objs.PrefixBit;
import de.fachat.af65k.model.objs.PrefixSetting;
import de.fachat.af65k.model.objs.SyntaxMode;
import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.AModeEntry;
import de.fachat.af65k.model.validation.Validator.CodeMapEntry;

/**
 * this class provides methods to generate various types of (HTML) docs from the CPU definition.
 * 
 * @author fachat
 *
 */
public class DocGenerator {

	final Validator cpu;
	
	public DocGenerator(Validator mycpu) {
		cpu = mycpu;
	}
	
	public void generateAddressingModeTable(DocWriter wr) {
		
		Map<String, String> tabatts = new HashMap<String, String>();
		tabatts.put("class", "optable");
		wr.startTable(tabatts);
		
		wr.startTableRow();
		
		wr.startTableHeaderCell();
		wr.print("Name");
		wr.startTableHeaderCell();
		wr.print("Alternative Name");
		wr.startTableHeaderCell();
		wr.print("Prefix");
		wr.startTableHeaderCell();
		wr.print("Operand Length");
		wr.startTableHeaderCell();
		wr.print("Syntax");
		wr.startTableHeaderCell();
		wr.print("Origin");
		wr.startTableHeaderCell();
		wr.print("Description");
		
		List<AModeEntry> amodes = cpu.getAddressingModeList();
		if (amodes != null) {
			
			TreeSet<AModeEntry> sortedAmodes = new TreeSet<Validator.AModeEntry>(new Comparator<AModeEntry>() {

				@Override
				public int compare(AModeEntry o1, AModeEntry o2) {
					int d = o1.getAddrmode().getPos() - o2.getAddrmode().getPos();
					if (d != 0) return d;
					return o1.getLen() - o2.getLen();
				}
			});
			sortedAmodes.addAll(amodes);
			
			for (AModeEntry am : sortedAmodes) {
				wr.startTableRow();
				
				wr.startTableCell();
				wr.print(am.getAddrmode().getName());
				
				wr.startTableCell();
				wr.print(am.getAddrmode().getAltname());
			
				wr.startTableCell();
				if (am.getPrefix() != null) {
					wr.print(am.getPrefix().getName() + "=" + am.getPrefix().getValue());
				}
				
				wr.startTableCell();
				wr.print(String.valueOf(am.getLen()));
				
				wr.startTableCell();
				//wr.print(am.getSyntax().getSimpleSyntax());
				wr.print(am.getSimplesyntax());
				
				wr.startTableCell();
				if (am.getFclass() != null) {
					wr.print(am.getFclass().getName());
				}
				
				wr.startTableCell();
				wr.print(am.getAddrmode().getDesc());
			}
		}
		wr.endTable();
	}

	public void generateOperationtable(HtmlWriter wr, String pagename, boolean includeOrig) {
		
		Map<String, CodeMapEntry[]> opcodes = cpu.getOpcodeMap();
		CodeMapEntry page[] = opcodes.get(pagename);	// get standard map
		writeOperationTable(wr, page, pagename == null ? cpu.getPrefixes() : null, includeOrig);
	}


	private void writeOperationTable(DocWriter wr, CodeMapEntry[] page,
			String[] strings, boolean includeOrig) {
		
		Map<String, Operation> ops = new TreeMap<String, Operation>();
		for (int i = 0; i < 256; i++) {
			CodeMapEntry en = page[i];
			if (en != null) {
				Operation op = en.getOperation();
				if (includeOrig || op.getClazz() != null) {
					ops.put(op.getName(), op);
				}
			}
		}
		
		wr.startUnsortedList();
		
		for (Map.Entry<String, Operation> en: ops.entrySet()) {
			Operation op = en.getValue();
			
			wr.startListItem();
			wr.print(op.getName() + ": " + op.getDesc());
		}
		wr.endUnsortedList();
	}

	public void generateOpcodetable(DocWriter wr, String pagename, boolean doLong) {
		
		Map<String, CodeMapEntry[]> opcodes = cpu.getOpcodeMap();
		CodeMapEntry page[] = opcodes.get(pagename);	// get standard map
		writeOpcodeTable(wr, page, pagename == null ? cpu.getPrefixes() : null, doLong);
	}

	private void writeOpcodeTable(DocWriter wr, CodeMapEntry[] page, String prefixes[], boolean doLong) {
		final String hex = "0123456789ABCDEF";
		
		Map<String, String> unusedatts = new HashMap<String, String>();
		unusedatts.put("class", "unused");
		Map<String, String> prefixatts = new HashMap<String, String>();
		prefixatts.put("class", "prefix");
		
		Map<String, Map<String, String>> classatts = new HashMap<String, Map<String,String>>();
		Map<String, String> tmp = new HashMap<String, String>();
		tmp.put("class", "c65k");
		classatts.put("65k", tmp);
		tmp = new HashMap<String, String>();
		tmp.put("class", "cmos");
		classatts.put("cmos", tmp);
				
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
				if ((!doLong) && (prefix != null)) {
					wr.startTableCell(prefixatts);
					wr.print(prefix);
				} else
				if (entry != null) {
					Map<String, String> atts = new HashMap<String, String>();
					if (prefixes != null && prefixes[i] != null) {
						atts.put("class", "prefix");
					} else {
						FeatureClass fc = entry.getFclass();
						if (fc != null) {
							atts.putAll(classatts.get(fc.getName()));
						}
						if (prefixes == null && atts.containsKey("class")) {
							if (atts.get("class").equals("c65k")) {
								atts.remove("class");
							}
						}
					}
					wr.startTableCell(atts);
					wr.print(entry.getOperation().getName());
					Set<SyntaxMode> synmodes = entry.getSynmodes();
					if (synmodes != null) {
						for (SyntaxMode sm : synmodes) {
							//wr.printline();
							wr.print(' ');
							wr.print(sm.getSimplesyntax());
						}
					}
					if (doLong) {
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
									wr.print(",");
								}
							}
						}						
					}
				} else
				if (prefix != null && prefix.length() > 0) {
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
