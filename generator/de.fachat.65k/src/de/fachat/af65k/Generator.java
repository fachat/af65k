package de.fachat.af65k;

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

import java.io.File;
import java.io.IOException;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.JAXB;

import de.fachat.af65k.doc.AdModeDocGenerator;
import de.fachat.af65k.doc.DocWriter;
import de.fachat.af65k.doc.adoc.AsciidocWriter;
import de.fachat.af65k.doc.OpdescDocGenerator;
import de.fachat.af65k.doc.OptableDocGenerator;
import de.fachat.af65k.doc.html.HtmlWriter;
import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.logging.LoggerFactory;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.validation.Validator;

public class Generator {

	public static void main(String argv[]) {

		String filename = "af65002.xml";

		File file = new File(filename);

		generateCpu(file, "af65002", true);

		generateCpu(file, "6502", false);

		generateCpu(file, "6502_undoc", false);

		generateCpu(file, "65ce02", false);

		generateCpu(file, "65c02", false);

		generateCpu(file, "r65c02", false);
		
		generateCpu(file, "65816", false);

	}
	

	private static void generateCpu(File file, String cpuname, final boolean hasPrefix) {

		File dir = new File(cpuname);
		if (!dir.exists()) {
			dir.mkdir();
		}

		CPU cpu = JAXB.unmarshal(file, CPU.class);
		cpu.postProcess();

		Logger logger = LoggerFactory.getLogger(Generator.class);

		final Validator val = new Validator(logger, cpu);

		Map<String, String> cpu2fclass = new HashMap<String, String>();
		cpu2fclass.put("af65002", "65k");
		cpu2fclass.put("af65010", "65k10");
		cpu2fclass.put("6502", "nmos");
		cpu2fclass.put("6502_undoc", "nmosext");
		cpu2fclass.put("65c02", "cmos");
		cpu2fclass.put("r65c02", "rcmos");
		cpu2fclass.put("65ce02", "65ce02");
		cpu2fclass.put("65816", "65816");

		generate(dir, "admodes-table-" + cpuname, wr -> {
			AdModeDocGenerator docgen = new AdModeDocGenerator(val, cpu2fclass.get(cpuname));
			docgen.generateAddressingModeTable(wr, hasPrefix);
		});

		generate(dir, "opdoc-" + cpuname, wr -> {
			OpdescDocGenerator docgen = new OpdescDocGenerator(val);
			docgen.generateOperationtable(wr, cpu2fclass.get(cpuname), hasPrefix);
		});

		generatePage(cpuname, null, hasPrefix, dir, val, cpu2fclass);

		if (hasPrefix) {

			generatePage(cpuname, "ext", hasPrefix, dir, val, cpu2fclass);

			generatePage(cpuname, "quick", hasPrefix, dir, val, cpu2fclass);

			generatePage(cpuname, "sys", hasPrefix, dir, val, cpu2fclass);
			
			generatePage(cpuname, "txfer", hasPrefix, dir, val, cpu2fclass);
		}
	}


	private static void generatePage(String cpuname, String page, boolean hasPrefix, File dir, Validator val,
			Map<String, String> cpu2fclass) {
		
		String fileprefix = page == null ? "opcodes" : page;
		String pagename = page == null ? null : page.toUpperCase();
		boolean includeOrig = page == null;
		
		if (hasPrefix) {
			generate(dir, fileprefix + "-longtable-" + cpuname, wr -> {
				new OptableDocGenerator(val).generateOpcodetable(wr, pagename, true, cpu2fclass.get(cpuname), hasPrefix);
			});
		}

		generate(dir, fileprefix + "-table-" + cpuname, wr -> {
			new OptableDocGenerator(val).generateOpcodetable(wr, pagename, false, cpu2fclass.get(cpuname), hasPrefix);
		});

		generate(dir, fileprefix + "-desc-" + cpuname, wr -> {
			new OptableDocGenerator(val).generateOperationtable(wr, pagename, cpu2fclass.get(cpuname), includeOrig);
		});
	}

	private static interface DocCreator {
		void create(DocWriter wr);
	}

	/**
	 * writes the document twice, as HTML and as AsciiDoc
	 */
	private static void generate(File dir, String basename, DocCreator creator) {
		try (PrintWriter pwr = open(new File(dir, basename + ".html"))) {
			creator.create(new HtmlWriter(pwr));
		} catch (IOException e) {
			e.printStackTrace();
		}
		try (PrintWriter pwr = open(new File(dir, basename + ".adoc"))) {
			creator.create(new AsciidocWriter(pwr));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private static PrintWriter open(File f) throws IOException {
		return new PrintWriter(new OutputStreamWriter(new FileOutputStream(f), "UTF-8"));
	}
}
