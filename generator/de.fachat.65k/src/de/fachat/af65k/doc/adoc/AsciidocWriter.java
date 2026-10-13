package de.fachat.af65k.doc.adoc;

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

import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.w3c.dom.Node;

import de.fachat.af65k.doc.DocWriter;

/**
 * DocWriter creating AsciiDoc output. Tables are buffered and written when
 * they are ended, so that the number of columns is known. HTML specific
 * attributes (css classes) and divs are ignored.
 */
public class AsciidocWriter implements DocWriter {

	private final PrintWriter wr;

	/** where text is currently collected; null means directly to the writer */
	private StringBuilder cell = null;

	private boolean inParagraph = false;
	private int listDepth = 0;
	private boolean linkOpen = false;
	private String linkUrl;
	private int linkStart;

	private boolean inTable = false;
	private final List<List<String>> rows = new ArrayList<List<String>>();
	private final List<List<Integer>> spans = new ArrayList<List<Integer>>();
	private List<String> row = null;
	private List<Integer> rowSpans = null;
	private boolean cellHeader;
	private int cellSpan;

	public AsciidocWriter(PrintWriter pwr) {
		wr = pwr;
	}

	private void out(String s) {
		if (cell != null) {
			cell.append(s);
		} else {
			wr.print(s);
		}
	}

	private void closeText() {
		if (linkOpen) {
			endLink();
		}
		if (inParagraph) {
			inParagraph = false;
			wr.println();
			wr.println();
		}
	}

	private void closeTable() {
		if (inTable) {
			endTable();
		}
	}

	@Override
	public void startDoc() {
	}

	@Override
	public void endDoc() {
		closeText();
		closeTable();
		wr.flush();
	}

	private void heading(String level, String name) {
		closeText();
		closeTable();
		wr.println();
		wr.println(level + " " + name);
		wr.println();
	}

	@Override
	public void startSection(String name) {
		heading("=", name);
	}

	@Override
	public void startSubsection(String name) {
		heading("==", name);
	}

	@Override
	public void startSubsubsection(String name) {
		heading("===", name);
	}

	@Override
	public void startParagraph() {
		closeText();
		if (cell == null) {
			inParagraph = true;
		}
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startTable() {
		startTable(null);
	}

	@Override
	public void startTable(Map<String, String> attributes) {
		closeText();
		closeTable();
		inTable = true;
		rows.clear();
		spans.clear();
		row = null;
	}

	@Override
	public void startTableRow() {
		endRow();
		row = new ArrayList<String>();
		rowSpans = new ArrayList<Integer>();
	}

	private void endCell() {
		if (cell != null) {
			if (linkOpen) {
				endLink();
			}
			String text = cell.toString().trim();
			String spec = (cellSpan > 1 ? cellSpan + "+" : "") + (cellHeader ? "h" : "");
			row.add(spec + "| " + text);
			rowSpans.add(cellSpan);
			cell = null;
		}
	}

	private void endRow() {
		endCell();
		if (row != null) {
			rows.add(row);
			spans.add(rowSpans);
			row = null;
		}
	}

	private void startCell(Map<String, String> atts, boolean header) {
		if (row == null) {
			startTableRow();
		}
		endCell();
		cellHeader = header;
		cellSpan = 1;
		if (atts != null && atts.get("colspan") != null) {
			try {
				cellSpan = Integer.parseInt(atts.get("colspan"));
			} catch (NumberFormatException e) {
				cellSpan = 1;
			}
		}
		cell = new StringBuilder();
	}

	@Override
	public void startTableCell() {
		startTableCell(null);
	}

	@Override
	public void startTableCell(Map<String, String> attributes) {
		startCell(attributes, false);
	}

	@Override
	public void startTableHeaderCell() {
		startTableHeaderCell(null);
	}

	@Override
	public void startTableHeaderCell(Map<String, String> attributes) {
		startCell(attributes, true);
	}

	@Override
	public void endTable() {
		endRow();
		inTable = false;
		int cols = 1;
		for (List<Integer> rs : spans) {
			int n = 0;
			for (int s : rs) {
				n += s;
			}
			cols = Math.max(cols, n);
		}
		wr.println();
		wr.println("[cols=\"" + cols + "*\"]");
		wr.println("|===");
		for (List<String> r : rows) {
			for (String c : r) {
				wr.println(c);
			}
			wr.println();
		}
		wr.println("|===");
		wr.println();
		rows.clear();
		spans.clear();
	}

	// -------------------------------------------------------------------------------------------------------

	private static String escape(String s) {
		return s.replace("|", "\\|");
	}

	@Override
	public void print(String content) {
		if (content != null) {
			out(escape(content));
		}
	}

	@Override
	public void print(char content) {
		out(escape(String.valueOf(content)));
	}

	@Override
	public void printline() {
		out(" +\n");
	}

	@Override
	public void print(Node n) {
		out(escape(n.getTextContent().replaceAll("\\s+", " ")));
	}

	@Override
	public void print(List<Node> nl) {
		for (Node n : nl) {
			print(n);
		}
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startUnsortedList() {
		closeText();
		listDepth++;
	}

	@Override
	public void endUnsortedList() {
		listDepth--;
		if (listDepth == 0 && cell == null) {
			wr.println();
		}
	}

	@Override
	public void startListItem() {
		if (cell != null) {
			out(" +\n\u2022 ");
		} else {
			wr.print("\n* ");
		}
	}

	@Override
	public void endListItem() {
		if (linkOpen) {
			endLink();
		}
		if (cell == null) {
			wr.println();
		}
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void createAnchor(String id) {
		out("[[" + id + "]]");
	}

	@Override
	public void startLink(String link) {
		if (linkOpen) {
			endLink();
		}
		linkOpen = true;
		linkUrl = link;
		StringBuilder cur = cell;
		linkStart = cur != null ? cur.length() : 0;
		if (cur == null) {
			cell = new StringBuilder();
			linkStart = 0;
			linkToWriter = true;
		}
	}

	private boolean linkToWriter = false;

	@Override
	public void endLink() {
		if (!linkOpen) {
			return;
		}
		linkOpen = false;
		String text = cell.substring(linkStart).replace("]", "\\]");
		String target = linkUrl.startsWith("#") ? "<<" + linkUrl.substring(1) + "," + text + ">>"
				: "link:" + linkUrl + "[" + text + "]";
		cell.setLength(linkStart);
		cell.append(target);
		if (linkToWriter) {
			linkToWriter = false;
			String s = cell.toString();
			cell = null;
			wr.print(s);
		}
	}

	@Override
	public void startDiv(Map<String, String> opcodedivatts) {
		// no equivalent in AsciiDoc: separate div contents by a blank
		out(" ");
	}

	@Override
	public void endDiv() {
		out(" ");
	}
}
