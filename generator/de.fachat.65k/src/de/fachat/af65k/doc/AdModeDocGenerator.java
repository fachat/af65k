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

import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

import de.fachat.af65k.model.validation.Validator;
import de.fachat.af65k.model.validation.Validator.AModeEntry;

/**
 * this class provides methods to generate various types of (HTML) docs from the CPU definition.
 * 
 * @author fachat
 *
 */
public class AdModeDocGenerator {

	final Validator cpu;
	
	public AdModeDocGenerator(Validator mycpu) {
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
}
