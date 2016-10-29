package de.fachat.af65k.optvhdl;

/*
Logic equation optimizer for the af65k set of VHDL cores

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
import java.io.IOException;
import java.io.PrintStream;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import javax.xml.bind.JAXB;

import de.fachat.af65k.logging.Logger;
import de.fachat.af65k.model.objs.AddressingMode;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.objs.FeatureSet;
import de.fachat.af65k.model.objs.Opcode;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.CodeMapEntry;
import de.fachat.af65k.optvhdl.QMOpt.BitTerm;
import de.fachat.af65k.optvhdl.QMOpt.Terms;

public class Optimizer {

	protected final static int NTHREADS = 1;

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		String cpuname = "af65002";

		String filename = cpuname + ".xml";

		File file = new File("../de.fachat.65k/" + filename);

		CPU cpu = JAXB.unmarshal(file, CPU.class);

		Validator val = new Validator(new Logger() {

			@Override
			public void error(String msg) {
				System.err.println(msg);
			}
		}, cpu);

//		runOperations(cpuname, cpu, val);
		
		runAdmoes(cpuname, cpu, val);
	}

	public static void runOperations(String cpuname, CPU cpu, Validator val) {
		try {
			// output stream
			String name = "opt-" + cpuname + "-opcodes.txt";
			FileOutputStream fos = new FileOutputStream(name);
			final PrintStream pstr = new PrintStream(fos, true, "UTF-8");
			
			// now prepare the optimizer run

			PrintStreamFactory pstrFact = null;
			if (NTHREADS == 1) {
				// this implementation only works in one thread
				pstrFact = new PrintStreamFactory() {
					
					@Override
					public PrintStream getPrintStream() {
						return pstr;
					}
				};
			}
			// first run - operation decoding
			minimizeOperations(cpu, val, pstrFact);
			
			pstr.flush();
			pstr.close();
			fos.close();
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void runAdmoes(String cpuname, CPU cpu, Validator val) {
		try {
			// output stream
			String name = "opt-" + cpuname + "-admodes.txt";
			FileOutputStream fos = new FileOutputStream(name);
			final PrintStream pstr = new PrintStream(fos, true, "UTF-8");
			
			// now prepare the optimizer run

			PrintStreamFactory pstrFact = null;
			if (NTHREADS == 1) {
				// this implementation only works in one thread
				pstrFact = new PrintStreamFactory() {
					
					@Override
					public PrintStream getPrintStream() {
						return pstr;
					}
				};
			}
			// first run - operation decoding
			minimizeAdmodes(cpu, val, pstrFact);
			
			pstr.flush();
			pstr.close();
			fos.close();
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private static void minimizeOperations(CPU cpu, Validator val, PrintStreamFactory outstrfact) {

		Collection<OpHandle> handles = encodeOperations(cpu, val, outstrfact);

		List<Future<OpResult>> results = executeHandles(handles);

		for (Future<OpResult> f : results) {
			// waits till the result is computed
			OpResult opres;
			BitTerm bterm;
			String name;
			try {
				opres = f.get();

				name = opres.name;
				bterm = opres.bterm;
				PrintStream outstr = opres.logStream;
				
				outstr.println("Operation: " + name + " (with " + opres.n + " opcodes)");
				bterm.toString(outstr);
				outstr.println("===========================================================");
				
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (ExecutionException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

	private static void minimizeAdmodes(CPU cpu, Validator val, PrintStreamFactory outstrfact) {

		Collection<OpHandle> handles = encodeAddrModes(cpu, val, outstrfact);

		List<Future<OpResult>> results = executeHandles(handles);

		for (Future<OpResult> f : results) {
			// waits till the result is computed
			OpResult opres;
			BitTerm bterm;
			String name;
			try {
				opres = f.get();

				name = opres.name;
				bterm = opres.bterm;
				PrintStream outstr = opres.logStream;
				
				outstr.println("Addressing mode: " + name + " (with " + opres.n + " opcodes)");
				bterm.toString(outstr);
				outstr.println("===========================================================");
				
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (ExecutionException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}


	public static List<Future<OpResult>> executeHandles(
			Collection<OpHandle> handles) {
		ExecutorService exec = Executors.newFixedThreadPool(NTHREADS);

		List<Future<OpResult>> results = new ArrayList<Future<OpResult>>(
				handles.size());

		for (OpHandle handle : handles) {
			if (handle.n > 1) {
				Future<OpResult> f = exec.submit(handle);
				results.add(f);
			}
		}
		exec.shutdown(); // finish all results
		return results;
	}

	/**
	 * used to encapsulate where we get the prinstream - in multithreading the stream must be 
	 * threadsafe so with this method we allow to create a new one for each invocation (i.e. thread)
	 */
	private static interface PrintStreamFactory {
		public PrintStream getPrintStream();
	}

	public static Collection<OpHandle> encodeAddrModes(CPU cpu, Validator val, PrintStreamFactory logstrFact) {
		int ADDRBITS = 10;

		// we have 10 "address" bits - 2 bits to select the page,
		// 8 bits per page
		Map<String, OpHandle> handles = new HashMap<String, OpHandle>();

		for (AddressingMode ad : cpu.getAddressingModes()) {

			OpHandle handle = new OpHandle(ad.getName(), ADDRBITS, logstrFact.getPrintStream());

			handles.put(ad.getIdentifier(), handle);
		}

		// now run over all ops in all pages, and set the appropriate bits
		Map<String, CodeMapEntry[]> map = val.getOpcodeMap();

		// basic page
		CodeMapEntry map0[] = map.get(null);
//		setAdmMap(handles, 0, map0, "");	// original 6502 
//		setAdmMap(handles, 0, map0, "cmos"); // 65c02
		setAdmMap(handles, 0, map0, null); // 65002
		// EXT page
//		CodeMapEntry map1[] = map.get("EXT");
//		setAdmMap(handles, 256, map1, null);

		return handles.values();
	}


	public static Collection<OpHandle> encodeOperations(CPU cpu, Validator val, PrintStreamFactory logstrFact) {
		int ADDRBITS = 10;

		// we have 10 "address" bits - 2 bits to select the page,
		// 8 bits per page
		Map<String, OpHandle> handles = new HashMap<String, OpHandle>();

		for (Operation op : cpu.getOperations()) {

			OpHandle handle = new OpHandle(op.getName(), ADDRBITS, logstrFact.getPrintStream());

			handles.put(op.getName(), handle);
		}

		// now run over all ops in all pages, and set the appropriate bits
		Map<String, CodeMapEntry[]> map = val.getOpcodeMap();

		// basic page
		CodeMapEntry map0[] = map.get(null);
//		setOpMap(handles, 0, map0, "");	// original 6502 
//		setOpMap(handles, 0, map0, "cmos"); // 65c02
		setOpMap(handles, 0, map0, null); // 65002
		// EXT page
		CodeMapEntry map1[] = map.get("EXT");
		setOpMap(handles, 256, map1, null);

		return handles.values();
	}

	private static void setAdmMap(Map<String, OpHandle> handles, int pageoffset,
			CodeMapEntry[] codepage, String clazz) {

		for (CodeMapEntry codeen : codepage) {
			if (codeen != null) {
				Opcode opc = codeen.getOpcode();
				String opname = opc.getAddressingMode();
				
				FeatureSet fclass = codeen.getFclass();
				
				if (clazz == null
					|| fclass == null
					|| (clazz.equals(fclass.getName()))) {

					OpHandle handle = handles.get(opname);
					handle.n++;

					int addr = Validator.parseCode(opc.getOpcode());

					addr |= pageoffset;

					handle.data[addr] = 1;
				}
			}
		}
	}

	private static void setOpMap(Map<String, OpHandle> handles, int pageoffset,
			CodeMapEntry[] codepage, String clazz) {

		for (CodeMapEntry codeen : codepage) {
			if (codeen != null) {
				Opcode opc = codeen.getOpcode();
				Operation op = codeen.getOperation();
				String opname = op.getName();
				FeatureSet fclass = codeen.getFclass();
				
				if (clazz == null
					|| fclass == null
					|| (clazz.equals(fclass.getName()))) {

					OpHandle handle = handles.get(opname);
					handle.n++;

					int addr = Validator.parseCode(opc.getOpcode());

					addr |= pageoffset;

					handle.data[addr] = 1;
				}
			}
		}
	}

	private static class OpHandle implements Callable<OpResult> {
		OpHandle(String iname, int addrbits, PrintStream logstr) {
			data = new byte[1 << addrbits];
			Arrays.fill(data, (byte) 0);
			name = iname;
			logStream = logstr;
		}

		int n = 0;
		String name;
		byte data[];
		PrintStream logStream;

		@Override
		public OpResult call() throws Exception {

			QMOpt optimizer = new QMOpt(logStream);

			Terms t = optimizer.optimize(data, data.length, 1);
			logStream.flush();
			return new OpResult(name, n, t.get(0), logStream);
		}
	}
	
	private static class OpResult {
		OpResult(String iname, int nopcodes, BitTerm ibterm, PrintStream prStr) {
			name = iname;
			bterm = ibterm;
			n = nopcodes;
			logStream = prStr;
		}
		PrintStream logStream;
		String name;
		int n;
		BitTerm bterm;
	}
}
