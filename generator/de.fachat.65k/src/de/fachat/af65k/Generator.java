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
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

import javax.xml.bind.JAXB;

import de.fachat.af65k.doc.AdModeDocGenerator;
import de.fachat.af65k.doc.OpdescDocGenerator;
import de.fachat.af65k.doc.OptableDocGenerator;
import de.fachat.af65k.doc.html.HtmlWriter;
import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.validation.Validator;

public class Generator {

	
	public static void main(String argv[]) {
		
		String cpuname = "af65002";
		
		String filename = cpuname + ".xml";
		
		File file = new File(filename);
		
		CPU cpu = JAXB.unmarshal(file, CPU.class);
		
		Logger logger = new Logger() {
			
			@Override
			public void error(String msg) {
				// TODO Auto-generated method stub				
			}
		};
		
		Validator val = new Validator(logger, cpu);
				
				
//				() {
//			
//			@Override
//			public void error(String msg) {
//				// TODO Auto-generated method stub
//				
//			}
//		});
		
		try {
			FileOutputStream fos = new FileOutputStream("admodes-table-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			AdModeDocGenerator docgen = new AdModeDocGenerator(val);
			docgen.generateAddressingModeTable(new HtmlWriter(pwr));
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			FileOutputStream fos = new FileOutputStream("opcodes-table-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OptableDocGenerator docgen = new OptableDocGenerator(val);
			docgen.generateOpcodetable(new HtmlWriter(pwr), null, false);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			FileOutputStream fos = new FileOutputStream("opcodes-longtable-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OptableDocGenerator docgen = new OptableDocGenerator(val);
			docgen.generateOpcodetable(new HtmlWriter(pwr), null, true);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			FileOutputStream fos = new FileOutputStream("ext-table-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OptableDocGenerator docgen = new OptableDocGenerator(val);
			docgen.generateOpcodetable(new HtmlWriter(pwr), "EXT", false);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			FileOutputStream fos = new FileOutputStream("opcodes-desc-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OptableDocGenerator docgen = new OptableDocGenerator(val);
			docgen.generateOperationtable(new HtmlWriter(pwr), null, true);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		try {
			FileOutputStream fos = new FileOutputStream("ext-desc-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OptableDocGenerator docgen = new OptableDocGenerator(val);
			docgen.generateOperationtable(new HtmlWriter(pwr), "EXT", false);
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		try {
			FileOutputStream fos = new FileOutputStream("opdoc-" + cpuname + ".html");
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			PrintWriter pwr = new PrintWriter(osw);
			OpdescDocGenerator docgen = new OpdescDocGenerator(val);
			docgen.generateOperationtable(new HtmlWriter(pwr));
			pwr.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		

		//JAXB.marshal(cpu, System.out);
		
	}
}
