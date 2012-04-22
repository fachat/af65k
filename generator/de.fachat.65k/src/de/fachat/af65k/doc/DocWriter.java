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

import java.util.Map;

/**
 * interface for document generation
 * 
 * @author fachat
 *
 */
public interface DocWriter {

	/**
	 * starts a document
	 */
	void startDoc();
	
	/**
	 * start a section
	 * ends previous parapgraph, tables, subsection, section when appropriate
	 * @param name
	 */
	void startSection(String name);
	
	/**
	 * start a subsection
	 * ends previous paragraph, table, subsection when appropriate
	 * @param name
	 */
	void startSubsection(String name);

	/**
	 * start a subsection
	 * ends previous paragraph, table, subsection when appropriate
	 * @param name
	 */
	void startSubsubsection(String name);

	/**
	 * start a new paragraph (ends previous paragraph as appropriate
	 */
	void startParagraph();
	
	/**
	 * starts a table.
	 */
	void startTable();

	/**
	 * starts a table.
	 */
	void startTable(Map<String, String> attributes);

	/**
	 * start Table row (ends previous row)
	 */
	void startTableRow();
	
	/**
	 * start a new table cell within a row
	 * ends a previous cell when one were there
	 */
	void startTableCell();

	/**
	 * start a new table cell within a row
	 * ends a previous cell when one were there
	 */
	void startTableCell(Map<String, String> attributes);

	/**
	 * start a new table header cell within a row
	 * ends a previous cell when one were there
	 */
	void startTableHeaderCell();

	/**
	 * start a new table cell within a row
	 * ends a previous cell when one were there
	 */
	void startTableHeaderCell(Map<String, String> attributes);

	/**
	 * print content, which will be escaped appropriately depending on output format
	 * 
	 * @param content (maybe null)
	 */
	void print(String content);
	
	/**
	 * print content, which will be escaped appropriately depending on output format
	 * 
	 * @param content (maybe null)
	 */
	void print(char content);
	
	/**
	 * print a newline
	 */
	void printline();
	
	/**
	 * end a table (ends cells and tables as appropriate)
	 */
	void endTable();
	
	/**
	 * end a document (ends tables as appropriate)
	 */
	void endDoc();

	void startUnsortedList();

	void endUnsortedList();

	void startListItem();

	void endListItem();
	
}
