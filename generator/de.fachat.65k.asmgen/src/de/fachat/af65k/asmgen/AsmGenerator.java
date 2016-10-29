package de.fachat.af65k.asmgen;

/*
 a65k assembler table generator for the whole 6502/65k CPU family
 
 Copyright (C) 2016  André Fachat

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
import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.JAXB;

import de.fachat.af65k.doc.AdModeDocGenerator;
import de.fachat.af65k.doc.OpdescDocGenerator;
import de.fachat.af65k.doc.OptableDocGenerator;
import de.fachat.af65k.doc.html.HtmlWriter;
import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.validation.Validator;

public class AsmGenerator {

	public static void main(String argv[]) {

		String filename = "../de.fachat.65k/af65002.xml";

		File file = new File(filename);

		generateCpu(file, "af65002", true);

//		generateCpu(file, "6502", false);
//
//		generateCpu(file, "6502_undoc", false);
//
//		generateCpu(file, "65ce02", false);
//
//		generateCpu(file, "65c02", false);
//
//		generateCpu(file, "r65c02", false);
	}
	

	private static void generateCpu(File file, String cpuname, boolean hasPrefix) {

		File dir = new File(cpuname);
		if (!dir.exists()) {
			dir.mkdir();
		}

		CPU cpu = JAXB.unmarshal(file, CPU.class);
		cpu.postProcess();

		Logger logger = new Logger() {

			@Override
			public void error(String msg) {
				System.err.println("ERR:" + msg);
			}

			@Override
			public void info(String msg) {
				System.out.println("INFO:" + msg);
			}
		};

		Validator val = new Validator(logger, cpu);

		Map<String, String> cpu2fclass = new HashMap<String, String>();
		cpu2fclass.put("af65002", "65k");
		cpu2fclass.put("af65010", "65k10");
		cpu2fclass.put("6502", "nmos");
		cpu2fclass.put("6502_undoc", "nmosext");
		cpu2fclass.put("65c02", "cmos");
		cpu2fclass.put("r65c02", "rcmos");
		cpu2fclass.put("65ce02", "65ce02");
		cpu2fclass.put("65816", "65816");

		try {
			FileOutputStream fos = new FileOutputStream(new File(dir, "asmtabl-" + cpuname + ".c"));
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			AsmTableGenerator docgen = new AsmTableGenerator(val);
			docgen.generateOperationtable(pwr, cpu2fclass.get(cpuname), hasPrefix);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}
}

