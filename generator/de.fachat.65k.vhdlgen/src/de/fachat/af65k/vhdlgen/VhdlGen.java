package de.fachat.af65k.vhdlgen;

/*
VHDL code generator for the af65k set of VHDL cores

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

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.JAXB;

import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.logging.LoggerFactory;
import de.fachat.af65k.model.objs.AddressingMode;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.objs.PrefixSetting;
import de.fachat.af65k.model.objs.Syntax;
import de.fachat.af65k.model.objs.SyntaxMode;
import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.CodeMapEntry;
import de.fachat.af65k.optvhdl.QMOpt;
import de.fachat.af65k.optvhdl.QMOpt.Terms;

public class VhdlGen {

	protected final static int NTHREADS = 1;

	private Validator val;

	class Fix {
		Fix(String _admode, String _indexreg, String _indwidth) {
			admode = _admode;
			indexreg = _indexreg;
			indwidth = _indwidth;
		}
		String admode;
		String indexreg;
		String indwidth;
	}
	
	// admodefix maps from syntax to process
	private Map<String, Fix> admodefix = new HashMap<String, Fix>();
	
	public VhdlGen(Validator val2) {
		val = val2;

		admodefix.put("ABSOLUTEX", 		new Fix("ABSOLUTEIND", 		"XR", 	null));
		admodefix.put("ABSOLUTEY", 		new Fix("ABSOLUTEIND", 		"YR", 	null));
		admodefix.put("XINDIRECT", 		new Fix("PREINDIRECT", 		"XR", 	"WORD"));
		admodefix.put("XINDIRECTQUAD", 	new Fix("PREINDIRECT", 		"XR", 	"QUAD"));
		admodefix.put("XINDIRECTLONG", 	new Fix("PREINDIRECT", 		"XR", 	"LONG"));
		admodefix.put("INDIRECTY", 		new Fix("POSTINDIRECT", 	"YR", 	"WORD"));
		admodefix.put("INDIRECTYQUAD", 	new Fix("POSTINDIRECT", 	"YR", 	"QUAD"));
		admodefix.put("INDIRECTYLONG", 	new Fix("POSTINDIRECT", 	"YR", 	"LONG"));
		admodefix.put("INDIRECT", 		new Fix("INDIRECT", 		null, 	"WORD"));
		admodefix.put("INDIRECTQUAD", 	new Fix("INDIRECT", 		null, 	"QUAD"));
		admodefix.put("INDIRECTLONG", 	new Fix("INDIRECT", 		null, 	"LONG"));
		
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		String cpuname = "af65002";

		String filename = cpuname + ".xml";

		File file = new File("../de.fachat.65k/" + filename);

		CPU cpu = JAXB.unmarshal(file, CPU.class);

		Validator val = new Validator(LoggerFactory.getLogger(VhdlGen.class), cpu);

		// runOperations(cpuname, cpu, val);

		try {
			FileOutputStream fos = new FileOutputStream("ops-" + cpuname
					+ ".vhdl");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			VhdlGen gen = new VhdlGen(val);

			gen.generateOps(pwr);
			
			gen.generateWidths(pwr);
			
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	
	// ===================================================================================
	
	
	// create statements to define the parameter width
	private void generateWidths(PrintWriter pwr) {
		
		// here we do some optimizing
		
		// the bitmask for this run will be:
		// 0 = byte parameter
		// 1 = word parameter
		// 2 = long parameter
		// 3 = quad parameter
		// 4 = no parameter
		// 8 = illegal;
		//
		// input parameters are
		// bit 12/11: rs (0=byte, 1=word, 2=long, 3=quad)
		// bit 10: am 
		// bit 9/8: opcode page
		// bit 7-0: opcode
		//
		byte data[] = new byte[1<<13];		// 13 bits input

		Arrays.fill(data, (byte)8);
		
		// fill in the parameter width values
		// standard page
		int opmap = 0;
		CodeMapEntry entries[] = val.getOpcodeMap().get(null);
		fillPage(data, opmap, entries);
		opmap = 1;
		entries = val.getOpcodeMap().get("EXT");
		fillPage(data, opmap, entries);
		
		QMOpt opt = new QMOpt(System.err);
		Terms terms = opt.optimize(data, data.length, 4);
		
		System.err.println(terms.toString());
	}

	public void fillPage(byte[] data, int opmap, CodeMapEntry[] entries) {
		for (int i = 0; i < 256; i++) {
			CodeMapEntry en = entries[i];
			int opcode = (opmap << 8) + i;
			
			// default for no opcode -> clear out everything
//			for (int am = 0; am < 2; am++) {
//				for (int rs = 0; rs < 4; rs++) {
//					data[opcode + (am<<10) + (rs<<11)] = 8;
//				}
//			}
			
			if (en != null) {
				
				System.err.println("en!= null for opcode=" + opcode);
				
				AddressingMode admode = en.getAddrmode();
				String admodename = admode.getIdentifier().toUpperCase();
				
				SyntaxMode sm = en.getSynmodes().iterator().next();
				PrefixSetting ps = sm.getPrefix();
				boolean isAM = false;
				if (ps!=null) {
					if ("AM".equals(ps.getName()) && "1".equals(ps.getValue())) {
						// filter out those entries that only work on AM=1
						isAM = true;
					}
				}
				if (!isAM) {
					// enter std
					
					fillStdOpcode(data, opcode, admode, admodename);
				}
				
				String altadmodename = admode.getAltMode();
				
				if (altadmodename != null) {
					// enter alt
					admode = val.getAddressingMode(altadmodename);
					
					fillStdOpcode(data, opcode, admode, altadmodename);
				}
			}
		}
	}

	public void fillStdOpcode(byte[] data, int opcode, AddressingMode admode,
			String admodename) {
		// parameter width
		// TODO: offset
		int w = admode.getWidthInByte();
		w = w - 1;
		if (w < 0) w = 4;
		
		if (admodename.equals("REL") || admodename.equals("IMM")) {
			// do the RS loop
			for (int rs = 0; rs < 4; rs++) {
				data[opcode + (rs<<11)] = (byte) rs;
			}
		} else {
			// all other addressing modes do not depend on RS
			data[opcode] = (byte) w;
		}
	}

	
	// ===================================================================================
	
	
	private void generateOps(PrintWriter pwr) {
		// TODO Auto-generated method stub

//		pwr.println("operation <= xUNKNOWN;");
//		pwr.println("admode <= sUNKNOWN;");
//		pwr.println("idxreg <= rNONE;");
//		pwr.println("indwidth <= wWORD;");
//		pwr.println("parwidth <= pNONE;");
//		pwr.println("is_valid <= '1';");
		pwr.println();
		pwr.println("case mapin is");

		int pagemap = 0;
		CodeMapEntry[] pageentries = val.getOpcodeMap().get(null);
		writeOpcodePage(pwr, pagemap, pageentries);

		pagemap = 1;
		pageentries = val.getOpcodeMap().get("EXT");
		writeOpcodePage(pwr, pagemap, pageentries);

		pwr.println("when others =>");
		pwr.println("  is_valid <= '0';");
		pwr.println("end case;");
	}

	public void writeOpcodePage(PrintWriter pwr, int pagemap,
			CodeMapEntry[] pageentries) {
		for (int i = 0; i < 256; i++) {

			CodeMapEntry en = pageentries[i];

			if (en != null) {
				if (en.getSynmodes().size() != 1)
					throw new IllegalStateException();
				SyntaxMode sm = en.getSynmodes().iterator().next();
				Syntax syn = val.getSyntax(sm);

				// select criterion
				pwr.print("when \"");
				// pwr.print(((am & 1) != 0) ? '1' : '0');
				pwr.print(((pagemap & 2) != 0) ? '1' : '0');
				pwr.print(((pagemap & 1) != 0) ? '1' : '0');
				pwr.print(((i & 128) != 0) ? '1' : '0');
				pwr.print(((i & 64) != 0) ? '1' : '0');
				pwr.print(((i & 32) != 0) ? '1' : '0');
				pwr.print(((i & 16) != 0) ? '1' : '0');
				pwr.print(((i & 8) != 0) ? '1' : '0');
				pwr.print(((i & 4) != 0) ? '1' : '0');
				pwr.print(((i & 2) != 0) ? '1' : '0');
				pwr.print(((i & 1) != 0) ? '1' : '0');
				pwr.print("\" =>          -- ");
				Formatter fmt = new Formatter();
				fmt.format("%02x", i);
				pwr.println("$"
						+ fmt.toString()
						+ ", "
						+ en.getName()
						+ " "
						+ en.getAddrmode().getName()
						+ ": "
						+ en.getSynmodes().iterator().next().getSimplesyntax()
						+ " "
						+ ((en.getFclass() != null) ? " ("
								+ en.getFclass().getName() + ")" : ""));
				// values
				String admode = syn.getId().toUpperCase();
				String adid = en.getAddrmode().getIdentifier().toUpperCase();
				
				String acc = "";
				if (adid.equals("A")) {
					acc = "_A";
				}
				Operation op = en.getOperation();
				
				pwr.println("  operation <= x"
						+ op.getName().toUpperCase() + acc + ";");

				if (op.getDefaultLe() != null && op.getDefaultLe().length() > 0) {
					pwr.println("  default_le <= e" + op.getDefaultLe().toUpperCase() + ";");
				}
				
				Fix xmode = admodefix.get(admode);
				if (xmode != null) {
					admode = xmode.admode;
					if (xmode.indexreg != null) {
						pwr.println("  idxreg <= i" + xmode.indexreg.toUpperCase() +";");
					}
					if (xmode.indwidth != null) {
						pwr.println("  indwidth <= w" + xmode.indwidth.toUpperCase() +";");
					}
				} else {
//					pwr.println("  idxreg <= rNONE");
				}
				
				if (adid.equals("REL") || adid.equals("IMM")) {
					// do the RS (but only for REL, not for RELJ)
					pwr.println("  parwidth <= pw_rs;");
				} else {
					int width = en.getAddrmode().getWidthInByte();
					// TODO: offset
					int offset = en.getAddrmode().getOffset();
					if (width != 0) {
						String w1 = parWidth(width);
						
						if (en.getAddrmode().getAltMode() != null) {
							AddressingMode admode2 = val.getAddressingMode(en.getAddrmode().getAltMode());
							int width2 = admode2.getWidthInByte();
System.err.println("i=" + i + ", am=" + adid + ", altam=" + admode2.getIdentifier().toUpperCase());

							if (width != width2) {
								if (width == 1 && width2 == 4) {
									pwr.println("  parwidth <= pw_bl;");
								} else
								if (width == 2 && width2 == 8) {
									pwr.println("  parwidth <= pw_wq;");
								} else {
									String w2 = parWidth(width2);
									pwr.println("  if (prefix_am = '0') then parwidth <= p" + w1 + "; else parwidth <= p" + w2 + "; end if;");
								}
							} else {
								pwr.println("  parwidth <= p" + w1 +";");
							}
						} else {
							pwr.println("  parwidth <= p" + w1 +";");
						}
					}
				}

				if (adid.contains("ADDR")) {
					pwr.println("  admode <= sADDR;");
				} else {
					// translate from RELJ to REL
					if (adid.contains("REL")) {
						pwr.println("  admode <= sREL;");
					} else {
						pwr.println("  admode <= s" + admode + ";");
					}
				}
				//pwr.println("  is_valid <= '1';");
			}
		}
	}

	public String parWidth(int width) {
		String w = "";
		//pwr.println("; width=" + width);
		
		switch(width) {
		case 8: w = "QUAD"; break;
		case 4: w = "LONG"; break;
		case 2: w = "WORD"; break;
		case 1: w = "BYTE"; break;
		case 0: w = "NONE"; break;
		}
		return w;
	}

}
