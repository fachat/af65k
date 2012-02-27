package de.fachat.af65k.model.test;

/*
Tests for the model parser for the af65k set of VHDL cores

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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Date;

import javax.xml.bind.JAXB;

import org.junit.Test;

import de.fachat.af65k.model.objs.AddressingMode;
import de.fachat.af65k.model.objs.CPU;
import de.fachat.af65k.model.objs.Opcode;
import de.fachat.af65k.model.objs.Operation;
import de.fachat.af65k.model.objs.Prefix;
import de.fachat.af65k.model.objs.PrefixBit;


public class ModelTest {

	
	@Test
	public void testSerial() {
		
		CPU cpu = createMockup();

		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		
		JAXB.marshal(cpu, bos);
		
		byte data[] = bos.toByteArray();
		ByteArrayInputStream bis = new ByteArrayInputStream(data);
		
		CPU newcpu = JAXB.unmarshal(bis, CPU.class);
		
		JAXB.marshal(newcpu, System.out);
	}

	private CPU createMockup() {
		CPU cpu = new CPU();
		cpu.setCreator("A. Fachat");
		cpu.setCreationDate(new Date());
		cpu.setIdentifier("af65002");
		cpu.setAddressingModes(new ArrayList<AddressingMode>());
		cpu.setPrefix(new ArrayList<Prefix>());
		cpu.setOpcodes(new ArrayList<Operation>());		
		
		//---------------------------------------------------------
		
		AddressingMode admode = new AddressingMode();
		admode.setIdentifier("imm");
		admode.setDesc("The immediate addressing mode uses the opcode parameter directly, without further lookup");
//		admode.setSyntax("#&lt;immediate_value&gt;");
		admode.setIgnoredPrefixes(new ArrayList<String>());

		admode.getIgnoredPrefixes().add("AM");
		admode.getIgnoredPrefixes().add("UM");
		
		cpu.getAddressingModes().add(admode);

		admode = new AddressingMode();
		admode.setIdentifier("zp");
		admode.setDesc("The opcode parameter is taken as a one-byte address, i.e. a zeropage location. The AM prefix bit can extend the parameter to 32 bit");
//		admode.setSyntax("&lt;zp_value&gt;");
		cpu.getAddressingModes().add(admode);

		//---------------------------------------------------------
		
		Prefix pref = new Prefix();
		pref.setName("prefix1");
		pref.setBits(new ArrayList<PrefixBit>());
		pref.setValue("0x10");
		
		PrefixBit pbit = new PrefixBit();
		pbit.setName("AM");
		pbit.setDesc("The AM bit allows to extend the addressing modes to larger sizes. The zeropage addressing modes become 32-bit addressing modes, "
					+ "while the 16-bit addressing modes become 64-bit addressing modes");
		pref.getBits().add(pbit);
		
		pbit = new PrefixBit();
		pbit.setName("UM");
		pbit.setDesc("When the UM mode bit is set, the effective address it not computed using the current mode, but the user mode. " +
				"This bit is ignored in user mode, but in supervisor mode it switches address calculation to user mode. The effective address" +
				"then also points to user mode memory");
		cpu.getPrefix().add(pref);
		
		//---------------------------------------------------------
		
		Operation op = new Operation();
		op.setName("LDA");
		op.setPrefixBits(new ArrayList<String>());
		op.setOpcodes(new ArrayList<Opcode>());
		cpu.getOpcodes().add(op);
		
		op.getPrefixBits().add("AM");
		op.getPrefixBits().add("UM");
		
		Opcode opc = new Opcode();
		opc.setAddressingMode("imm");
		opc.setOppage("STD");
		opc.setOpcode("0xa9");
		op.getOpcodes().add(opc);
		return cpu;
	}
}
