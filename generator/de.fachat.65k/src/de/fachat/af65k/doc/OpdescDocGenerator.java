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
public class OpdescDocGenerator {

	final Validator cpu;

	public OpdescDocGenerator(Validator mycpu) {
		cpu = mycpu;
	}

	public void generateOperationtable(HtmlWriter wr, String fclass, boolean hasPrefix) {

		Map<String, CodeMapEntry[]> opcodes = cpu.getOpcodeMap(fclass);

		Map<String, Operation> ops = new TreeMap<String, Operation>();

		for (CodeMapEntry page[] : opcodes.values()) {
			prepareOperationTable(ops, page, true);
		}

		FeatureSet fset = cpu.getFClass(fclass);
		Collection<String> fclasses = fset.getFeature();

		createToc(wr, ops, fclasses);

		createTable(wr, ops, fclasses, hasPrefix);
	}

	private void prepareOperationTable(Map<String, Operation> ops, CodeMapEntry[] page, boolean includeOrig) {

		for (int i = 0; i < 256; i++) {
			CodeMapEntry en = page[i];
			if (en != null) {
				Operation op = en.getOperation();

				if (includeOrig || op.getClazz() != null) {
					ops.put(op.getName(), op);
				}
			}
		}

	}

	private void createToc(DocWriter wr, Map<String, Operation> ops, Collection<String> fclasses) {

		wr.startSubsection("List of operations");
		wr.startUnsortedList();

		for (Map.Entry<String, Operation> en : ops.entrySet()) {
			Operation op = en.getValue();

			if (op.getClazz() == null || fclasses.contains(op.getClazz())) {

				wr.startListItem();
				wr.startLink("#" + op.getName());
				wr.print(op.getName());
				wr.endLink();
				wr.print(" - ");
				wr.print(op.getDesc());
			}
		}
		wr.endUnsortedList();
	}

	private void createTable(DocWriter wr, Map<String, Operation> ops, Collection<String> fclasses, boolean hasPrefix) {

		Map<String, String> optable = new HashMap<String, String>();
		optable.put("class", "optable");

		for (Map.Entry<String, Operation> en : ops.entrySet()) {
			Operation op = en.getValue();

			if (op.getClazz() == null || fclasses.contains(op.getClazz())) {

				wr.startSubsection(op.getName());
				wr.createAnchor(op.getName());
				if (op.getSynonyms() != null && op.getSynonyms().size() > 0) {
					wr.startParagraph();
					wr.print("Synonyms:");
					for (String syn : op.getSynonyms()) {
						wr.print(" " + syn);
					}
				}
				wr.startParagraph();
				wr.print(op.getDesc());

				wr.startTable(optable);
				wr.startTableRow();
				Map<String, String> atts = new HashMap<String, String>();
				atts.put("colspan", "10");
				wr.startTableHeaderCell(atts);
				wr.print(op.getName());
				wr.startTableRow();
				wr.startTableHeaderCell();
				wr.print("Page");
				wr.startTableHeaderCell();
				wr.print("Opcode");
				wr.startTableHeaderCell();
				wr.print("Class");
				if (hasPrefix) {
					wr.startTableHeaderCell();
					wr.print("Prefixes");
				}
				wr.startTableHeaderCell();
				wr.print("Addressing Mode");
				wr.startTableHeaderCell();
				wr.print("Syntax");

				Collection<String> prefixes = op.getPrefixBits();

				for (Opcode opcode : op.getOpcodes()) {

					if (opcode.getFeature() == null || fclasses.contains(opcode.getFeature())) {
						String admode = opcode.getAddressingMode();
						AddressingMode am = cpu.getAddressingMode(admode);

						wr.startTableRow();
						wr.startTableCell();
						wr.print(opcode.getOppage());
						wr.startTableCell();
						wr.print(opcode.getOpcode());
						wr.startTableCell();

						String clss = opcode.getFeature();
						if (clss == null || clss.length() == 0) {
							clss = op.getClazz();
						}
						wr.print(opcode.getFeature());
						if (hasPrefix) {

							wr.startTableCell();
							Collection<String> prefs = prefixes;
							if (prefs != null) {
								if (am.getIgnoredPrefixes() != null && am.getIgnoredPrefixes().size() > 0) {
									prefs = new ArrayList<String>(prefs.size());
									prefs.addAll(prefixes);
									prefs.removeAll(am.getIgnoredPrefixes());
								}
								Iterator<String> pref = prefs.iterator();
								while (pref.hasNext()) {
									wr.print(pref.next());
									if (pref.hasNext())
										wr.print(", ");
								}
							}
						}
						wr.startTableCell();
						wr.print(am.getName());
						wr.startTableCell();

					}
				}
				wr.endTable();

				List<Doc> docs = op.getDoc();

				if (docs != null) {
					for (Doc doc : docs) {
						String name = doc.getMode();
						if (name == null || name.length() == 0) {
							name = "Description";
						} else
						if (!fclasses.contains(name)) {
							continue;
						}
						wr.startSubsubsection(name);
						

						wr.print(doc.getText());
					}
				}
			}

		}
	}

}
