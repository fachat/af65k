package de.fachat.af65k.model.validation;

/*
Validator for the model parser for the af65k set of VHDL cores

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
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.hamcrest.FeatureMatcher;
import org.w3c.dom.CDATASection;

import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.model.objs.AddressingMode;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.objs.Feature;
import de.fachat.af65k.model.objs.FeatureSet;
import de.fachat.af65k.model.objs.Opcode;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.objs.Prefix;
import de.fachat.af65k.model.objs.PrefixBit;
import de.fachat.af65k.model.objs.PrefixSetting;
import de.fachat.af65k.model.objs.Syntax;
import de.fachat.af65k.model.objs.SyntaxMode;

/**
 * This class implements a validator for the CPU class It sorts the data into
 * various ways and allows to return this information
 * 
 * @author fachat 
 *
 */
public class Validator {

	protected CPU cpu;
	protected Logger LOG;

	protected List<Operation> synonyms = new ArrayList<Operation>();
	protected Map<String, AddressingMode> admodes = new HashMap<String, AddressingMode>();
	protected Map<String, PrefixBit> pbits = new HashMap<String, PrefixBit>();
	protected Map<String, FeatureSet> fclass = new HashMap<String, FeatureSet>();
	protected Map<String, Feature> feature = new HashMap<String, Feature>();
	protected Map<String, Syntax> syntaxMap = new HashMap<String, Syntax>();
	protected Map<String, Set<SyntaxMode>> syntaxModesPerAM = new HashMap<String, Set<SyntaxMode>>();
	protected Map<SyntaxMode, Syntax> syntaxPerSM = new HashMap<SyntaxMode, Syntax>();

	public Validator(Logger log, CPU mycpu) {

		LOG = log;
		cpu = mycpu;

		if (cpu == null) {
			throw new IllegalArgumentException("CPU is null");
		}

		for (Feature f : cpu.getFeature()) {
			String id = f.getName();
			if (feature.containsKey(id)) {
				LOG.error("Feature '" + id + "' is duplicate!");
				throw new RuntimeException();
			} else {
				System.err.println("Registering feature " + id);
				feature.put(id, f);
			}
		}

		for (FeatureSet fc : cpu.getFeatureSet()) {
			String id = fc.getName();
			if (fclass.containsKey(id)) {
				LOG.error("Feature class '" + id + "' is duplicate!");
				throw new RuntimeException();
			} else {
				LOG.info("Registering feature set " + id);
				fclass.put(id, fc);
			}

			List<String> featureList = fc.getFeature();
			for (String fn : featureList) {
				if (!feature.containsKey(fn)) {
					LOG.error("Feature " + fn + " for FeatureSet " + id + " is not defined!");
				}
			}
		}

		for (Prefix pref : cpu.getPrefix()) {
			if (pref.getBits() != null) {
				for (PrefixBit pb : pref.getBits()) {
					String id = pb.getId();
					if (pbits.containsKey(id)) {
						LOG.error("Prefix bit '" + id + "' is duplicate!");
						throw new RuntimeException();
					} else {
						pbits.put(id, pb);
					}
				}
			}
		}
		int i = 0;
		for (AddressingMode am : cpu.getAddressingModes()) {

			am.setPos(i);
			i++;
			String id = am.getIdentifier();

			if (admodes.containsKey(id)) {
				LOG.error("Addressing mode '" + id + "' is duplicate!");
				throw new RuntimeException();
			} else {
				admodes.put(id, am);
				String fclassStr = am.getFeature();
				if (fclassStr != null && !feature.containsKey(fclassStr)) {
					LOG.error("Feature class '" + fclassStr + "' for addressing mode '" + id + "' is not defined!");
				}
				List<String> ignoredPrefixes = am.getIgnoredPrefixes();
				if (ignoredPrefixes != null) {
					for (String pbit : am.getIgnoredPrefixes()) {
						if (!pbits.containsKey(pbit)) {
							LOG.error("Ignored prefix '" + pbit + "' for addressing mode '" + id + "' is not defined!");
						}
					}
				}
			}
		}

		Map<String, String> lengthsyntaxes = new HashMap<String, String>();
		lengthsyntaxes.put("a1", "zp");
		lengthsyntaxes.put("a2", "abs");
		lengthsyntaxes.put("a3", "bank");
		lengthsyntaxes.put("a4", "long");
		lengthsyntaxes.put("a8", "quad");
		lengthsyntaxes.put("o1", "byte");
		lengthsyntaxes.put("o2", "word");
		lengthsyntaxes.put("o3", "bank");
		lengthsyntaxes.put("o4", "long");
		lengthsyntaxes.put("o8", "quad");

		Set<String> allAdModes = new HashSet<String>();
		allAdModes.addAll(admodes.keySet());
		for (Syntax syn : cpu.getSyntaxlist()) {
			String id = syn.getId();
			if (syntaxMap.containsKey(id)) {
				LOG.error("Syntax '" + id + "' is defined more than once!");
			} else {
				for (SyntaxMode synmode : syn.getAddrModes()) {
					String addrMode = synmode.getAddrMode();

					if (!admodes.containsKey(addrMode)) {
						LOG.error("Addressing mode '" + addrMode + "' for syntax definition '" + id
								+ "' is not defined!");
					} else {
						AddressingMode am = admodes.get(addrMode);

						Set<SyntaxMode> modes = syntaxModesPerAM.get(addrMode);
						if (modes == null) {
							modes = new HashSet<SyntaxMode>();
							syntaxModesPerAM.put(addrMode, modes);
						}
						if (modes.size() > 0) {
							LOG.error("More than one syntax mode for addressing mode " + addrMode);
						}
						modes.add(synmode);

						if (synmode.getSimplesyntax() == null) {
							String sisyn = syn.getSimpleSyntax();
							if (sisyn != null && am.getWidthInByte() > 0) {
								String amsyn = sisyn.replace("<address>",
										lengthsyntaxes.get("a" + am.getWidthInByte()));
								amsyn = amsyn.replace("<operand>", lengthsyntaxes.get("o" + am.getWidthInByte()));
								synmode.setSimplesyntax(amsyn);
							} else {
								synmode.setSimplesyntax(sisyn);
							}
						}

						allAdModes.remove(addrMode);
					}
					syntaxPerSM.put(synmode, syn);
				}
				syntaxMap.put(id, syn);

			}
		}
		allAdModes.remove("prefix");
		if (!allAdModes.isEmpty()) {
			LOG.error("Not all addressing modes have syntax defined. Missing modes are: " + allAdModes);
		}
	}

	public FeatureSet getFClass(String fc) {
		return fclass.get(fc);
	}

	public static class CodeMapEntry {

		public CodeMapEntry(Operation operation, Opcode opcode, AddressingMode addrmode,
				Collection<PrefixBit> prefixbits, Feature fclass, Set<SyntaxMode> synmodes) {
			super();
			this.operation = operation;
			this.opcode = opcode;
			this.addrmode = addrmode;
			this.prefixbits = prefixbits;
			this.fclass = fclass;
			this.synmodes = synmodes;
			// default name
			this.name = operation.getName();
		}

		public CodeMapEntry(String name, Operation operation, Opcode opcode, AddressingMode addrmode,
				Collection<PrefixBit> prefixbits, Feature fclass, Set<SyntaxMode> synmodes) {
			this(operation, opcode, addrmode, prefixbits, fclass, synmodes);
			this.name = name;
		}

		String name;
		Operation operation;
		Opcode opcode;
		AddressingMode addrmode;
		Collection<PrefixBit> prefixbits;
		Feature fclass;
		Set<SyntaxMode> synmodes;

		public Operation getOperation() {
			return operation;
		}

		public Opcode getOpcode() {
			return opcode;
		}

		public AddressingMode getAddrmode() {
			return addrmode;
		}

		public Collection<PrefixBit> getPrefixbits() {
			return prefixbits;
		}

		public Feature getFclass() {
			return fclass;
		}

		public Set<SyntaxMode> getSynmodes() {
			return synmodes;
		}

		public String getName() {
			return name;
		}
	}

	/**
	 * return a map from opcode page, to opcode row (high nibble) to opcode col
	 * (low nibble) to Opcode object
	 * 
	 * @return
	 */
	public String[] getPrefixes() {

		String rv[] = new String[256];

		for (Prefix p : cpu.getPrefix()) {

			int baseval = parseCode(p.getValue());

			int varmask = 0;

			if (p.getBits() == null) {
				int v = baseval;
				if (rv[v] != null) {
					LOG.error("Prefix " + v + " is already set to '" + rv[v] + "' when trying to set to '" + p.getName()
							+ "'");
				}
				rv[v] = p.getName();
			} else {
				for (PrefixBit pb : p.getBits()) {
					String maskstr = pb.getMask();
					if (maskstr != null) {
						varmask |= parseCode(maskstr);
					}

					// TODO check if the values are covered by the mask
				}

				// brute force, to tired to look for a good algorithm...
				int i;
				for (i = 0; i < 256; i++) {
					int v = baseval + i;
					if ((i & varmask) == i) {
						if (rv[v] != null) {
							LOG.error("Prefix " + v + " is already set to '" + rv[v] + "' when trying to set to '"
									+ p.getName() + "'");
						}
						rv[v] = p.getName();
					}
				}
			}
		}

		return rv;
	}

	public Collection<Operation> getOperations() {
		return cpu.getOperations();
	}
	
	/**
	 * return a map from opcode page, to opcode row (high nibble) to opcode col
	 * (low nibble) to Opcode object
	 * 
	 * @return
	 */
	public Map<String, CodeMapEntry[]> getOpcodeMap(String fsetStr) {

		FeatureSet fset = fclass.get(fsetStr);
		Collection<String> features = fset.getFeature();

		Map<String, CodeMapEntry[]> rv = new HashMap<String, Validator.CodeMapEntry[]>();

		for (Operation op : cpu.getOperations()) {

			if (op.getClazz() != null && !features.contains(op.getClazz())) {
				continue;
			}

			Feature opFClass = null;
			String fclassStr = op.getClazz();
			if (fclassStr != null && !feature.containsKey(fclassStr)) {
				LOG.error("Feature class '" + fclassStr + "'  for operation '" + op.getName() + "' is not defined!");
			} else {
				opFClass = feature.get(fclassStr);
			}

			// find valid prefix bits
			Map<String, PrefixBit> pbs = new HashMap<String, PrefixBit>();
			Collection<String> pbitns = op.getPrefixBits();
			if (pbitns != null) {
				for (String pbname : pbitns) {
					PrefixBit pbit = pbits.get(pbname);
					if (pbits == null) {
						LOG.error("Prefix bit '" + pbname + "' for operation '" + op.getName() + "' is not defined!");
					} else {
						pbs.put(pbit.getId(), pbit);
					}
				}
			}

			if (op.getOpcodes() == null) {
				synonyms.add(op);
			} else
			for (Opcode opcode : op.getOpcodes()) {

				String page = opcode.getOppage();
				String codeStr = opcode.getOpcode();

				int code = parseCode(codeStr);

				String codeFClassStr = opcode.getFeature();
				Feature codeFClass = feature.get(codeFClassStr);
				// if (codeFClass == null) {
				// LOG.error("Feature class '" + codeFClassStr + "' for opcode
				// '" + page + "/" + codeStr + "' is not defined");
				// }
				if (codeFClass != null && !features.contains(codeFClassStr)) {
					continue;
				}

				// addressing mode
				Feature admodeclass = null;
				AddressingMode admode = admodes.get(opcode.getAddressingMode());
				if (admode == null) {
					LOG.error("Addressing mode '" + opcode.getAddressingMode() + "' for operation '" + op.getName()
							+ "' is not defined!");
				} else {
					String admodefeatureStr = admode.getFeature();
					admodeclass = feature.get(admodefeatureStr);
					// find class (derive from addressing mode and operation if
					// necessary)

					if (codeFClass == null) {
						if (admodeclass != null) {
							opcode.setFeature(admodeclass.getName());
						} else if (opFClass != null) {
							opcode.setFeature(opFClass.getName());
							// if (codeFClass == null || opFClass.getPrio() >
							// codeFClass.getPrio()) {
							// codeFClass = opFClass;
							// }
						}
					} else {
						opcode.setFeature(codeFClass.getName());
					}

					if (!(opcode.getFeature() != null && !features.contains(opcode.getFeature()))) {

						LOG.info("Op " + opcode.getOpcode() + " with Addressing mode '" + admode.getName() + "("
								+ admode.getIdentifier() + ":" + admode.getFeature() + ")' for operation '"
								+ op.getName() + "' (" + op.getClazz() + ") -> feature: " + opcode.getFeature() + "!");

						Set<SyntaxMode> synmodes = syntaxModesPerAM.get(admode.getIdentifier());

						// compute the correct list of valid prefix bits (from
						// operation and addressing modes)
						Map<String, PrefixBit> pbitset = new HashMap<String, PrefixBit>();
						pbitset.putAll(pbs);
						if (admode.getIgnoredPrefixes() != null) {
							for (String pb : admode.getIgnoredPrefixes()) {
								pbitset.remove(pb);
							}
						}

						// enter the code into the return structure
						CodeMapEntry pageEntries[] = rv.get(page);
						if (pageEntries == null) {
							pageEntries = new CodeMapEntry[256];
							rv.put(page, pageEntries);
						}
						if (op.getExpand() == null) { 	
							CodeMapEntry pageEntry = new CodeMapEntry(op, opcode, admode, pbitset.values(),
									feature.get(opcode.getFeature()), synmodes);
							
							addToPage(op.getName(), page, code, pageEntries, pageEntry);
						} else {
							int expand = parseCode(op.getExpand());
							// compute the expand steps as lowest 1-bit
							int w = 0;
							int e = expand;
							while ((e & 1) == 0) {
								w++;
								e /= 2;
							}
							e = 1 << w;
							// list of expands
							Set<Integer> expList = new HashSet<>();
							w = 0;
							while (w <= expand) {
								expList.add(w & expand);
								w += e;
							}
							// loop over all
							w = 0;
							for (Integer ex : expList) {
								CodeMapEntry pageEntry = new CodeMapEntry(op.getName() + w, op, opcode, admode, pbitset.values(),
										feature.get(opcode.getFeature()), synmodes);
								
								addToPage(op.getName(), page, code + ex, pageEntries, pageEntry);
								w++;
							}
						}
					}
				}
			}
		}

		return rv;
	}

	private void addToPage(String name, String page, int code, 
			CodeMapEntry[] pageEntries, CodeMapEntry entry) {
		if (pageEntries[code] != null) {
			LOG.error("Opcode '" + page + "/$" + Integer.toHexString(code) + "' is duplicate entry in operations '"
					+ name + "' and '" + pageEntries[code].getOperation().getName() + "'!");
			throw new RuntimeException();
		} else {
			pageEntries[code] = entry;
		}
	}

	public static int parseCode(String codeStr) {
		int code = 0;
		if (codeStr.startsWith("0x")) {
			code = Integer.parseInt(codeStr.substring(2), 16);
		} else {
			code = Integer.parseInt(codeStr);
		}
		return code;
	}

	public static class AModeEntry {
		public AModeEntry(AddressingMode addrmode, Syntax syntax, SyntaxMode sm, Feature fclass) {
			super();
			this.addrmode = addrmode;
			this.syntax = syntax;
			this.fclass = fclass;
			this.syntaxmode = sm;
		}

		AddressingMode addrmode;
		Syntax syntax;
		Feature fclass;
		SyntaxMode syntaxmode;

		public AddressingMode getAddrmode() {
			return addrmode;
		}

		public Syntax getSyntax() {
			return syntax;
		}

		public int getLen() {
			return addrmode.getWidthInByte();
		}

		public Feature getFclass() {
			return fclass;
		}

		public String getSimplesyntax() {
			return syntaxmode.getSimplesyntax();
		}

		public PrefixSetting getPrefix() {
			return syntaxmode.getPrefix();
		}
	}

	public List<AModeEntry> getAddressingModeList() {

		List<AModeEntry> rv = new ArrayList<Validator.AModeEntry>();

		for (Syntax syn : syntaxMap.values()) {

			for (SyntaxMode sm : syn.getAddrModes()) {

				String amid = sm.getAddrMode();

				AddressingMode amode = admodes.get(amid);

				if (amode == null) {
					throw new IllegalStateException("Did not find definition for addressing mode " + amid);
				}

				String amfcid = amode.getFeature();
				Feature amfc = feature.get(amfcid);

				String modefcid = sm.getFeature();
				Feature modefc = feature.get(modefcid);

				Feature fc = amfc;
				if (fc == null) {
					fc = modefc;
				}

				// int len = sm.getWidthInByte();
				//
				// String simplesyn = sm.getSimplesyntax();

				AModeEntry ame = new AModeEntry(amode, syn, sm, fc);

				rv.add(ame);
			}
		}
		return rv;
	}

	public Syntax getSyntax(SyntaxMode sm) {
		return syntaxPerSM.get(sm);
	}

	public AddressingMode getAddressingMode(String id) {
		return admodes.get(id);
	}

	public String id() {
		return cpu.getIdentifier();
	}

	public List<Operation> getSynonyms() {
		return synonyms;
	}

	public void setSynonyms(List<Operation> synonyms) {
		this.synonyms = synonyms;
	}
}
