package de.fachat.af65k.doc.html;

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
import java.util.List;
import java.util.Map;
import java.util.Stack;

import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;

import de.fachat.af65k.doc.DocWriter;
import de.fachat.af65k.doc.HtmlEscape;

public class HtmlWriter implements DocWriter {

	private static enum STATE {
		DOC, SECTION, SUBSECTION, SUBSUBSECTION, TABLE, ROW, CELL, HCELL, PARAGRAPH, UNSORTEDLIST, LISTITEM,
		LINK, DIV
	}

	protected Stack<STATE> stack = new Stack<STATE>();
	protected PrintWriter wr;

	public HtmlWriter(PrintWriter pwr) {
		wr = pwr;
	}

	@Override
	public void startDoc() {
		doStartDoc();
	}

	private void doStartDoc() {
		wr.println("<html><body>");
	}

	private void doEndDoc() {
		wr.println("</body></html>");
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startUnsortedList() {

		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case PARAGRAPH:
				doEndParagraph();
				break;
			case CELL:
			case HCELL:
			case SUBSECTION:
			case SECTION:
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSection()");
			}
		}
		doStartUnsortedList();
	}

	@Override
	public void endUnsortedList() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case LISTITEM:
				doEndListItem();
				break;
			case UNSORTEDLIST:
				end = true;
				break;
			case DIV:
				doEndDiv();
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}
		doEndUnsortedList();
	}

	private void doStartUnsortedList() {
		wr.println("<ul>");
		stack.push(STATE.UNSORTEDLIST);
	}

	private void doEndUnsortedList() {
		wr.println("</ul>");
		stack.pop();
	}

	@Override
	public void startListItem() {

		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case LISTITEM:
				doEndListItem();
				break;
			case UNSORTEDLIST:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSection()");
			}
		}
		doStartListItem();
	}

	@Override
	public void endListItem() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case LISTITEM:
				doEndListItem();
				break;
			case LINK:
				doEndLink();
				break;
			case DIV:
				doEndDiv();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}
		doEndListItem();
	}

	private void doStartListItem() {
		wr.println("<li>");
		stack.push(STATE.LISTITEM);
	}

	private void doEndListItem() {
		wr.println("</li>");
		stack.pop();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startSection(String name) {

		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case PARAGRAPH:
				doEndParagraph();
				break;
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case SUBSECTION:
				doEndSubsection();
				break;
			case SUBSUBSECTION:
				doEndSubsubsection();
				break;
			case SECTION:
				doEndSection();
				break;
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSection()");
			}
		}
		doStartSection();
	}

	private void doStartSection() {
		wr.print("<h1>");
		wr.print("name");
		wr.println("</h1>");
		stack.push(STATE.SECTION);
	}

	private void doEndSection() {
		stack.pop();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startSubsection(String name) {

		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case PARAGRAPH:
				doEndParagraph();
				break;
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case SUBSECTION:
				doEndSubsection();
				break;
			case SUBSUBSECTION:
				doEndSubsubsection();
				break;
			case SECTION:
				end = true;
				break;
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartSubsection(name);
	}

	private void doStartSubsection(String name) {
		wr.print("<h2>");
		wr.print(name);
		wr.println("</h2>");
		stack.push(STATE.SUBSECTION);
	}

	private void doEndSubsection() {
		stack.pop();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startSubsubsection(String name) {

		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case PARAGRAPH:
				doEndParagraph();
				break;
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case SUBSUBSECTION:
				doEndSubsubsection();
				break;
			case SECTION:
			case SUBSECTION:
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartSubsubsection(name);
	}

	private void doStartSubsubsection(String name) {
		wr.print("<h3>");
		wr.print(name);
		wr.println("</h3>");
		stack.push(STATE.SUBSECTION);
	}

	private void doEndSubsubsection() {
		stack.pop();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startParagraph() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case PARAGRAPH:
				doEndParagraph();
				break;
			case SUBSECTION:
				end = true;
				break;
			case SECTION:
				end = true;
				break;
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartParagraph();
	}

	private void doStartParagraph() {
		wr.print("<p>");
		stack.push(STATE.PARAGRAPH);
	}

	private void doEndParagraph() {
		wr.println("</p>");
		stack.pop();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void startTable() {
		startTable(null);
	}

	@Override
	public void startTable(Map<String, String> atts) {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case PARAGRAPH:
				doEndParagraph();
				break;
			case SUBSECTION:
			case SECTION:
			case DOC:
			case DIV:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartTable(atts);
	}

	private void doStartTable(Map<String, String> atts) {
		if (atts != null && atts.size() > 0) {
			printStartWithAtts("table", atts);
		} else {
			wr.print("<table>");
		}
		stack.push(STATE.TABLE);
	}

	private void doEndTable() {
		wr.println("</table>");
		stack.pop();
	}

	@Override
	public void startTableRow() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case DIV:
				doEndDiv();
				break;
			case TABLE:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartRow();
	}

	private void doStartRow() {
		wr.print("<tr>");
		stack.push(STATE.ROW);
	}

	private void doEndRow() {
		wr.println("</tr>");
		stack.pop();
	}

	@Override
	public void startTableCell() {
		startTableCell(null);
	}

	@Override
	public void startTableCell(Map<String, String> atts) {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case DIV:
				doEndDiv();
				break;
			case ROW:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doStartCell(atts);
	}

	private void doStartCell(Map<String, String> atts) {
		if (atts != null && atts.size() > 0) {
			printStartWithAtts("td", atts);
		} else {
			wr.print("<td>");
		}
		stack.push(STATE.CELL);
	}

	private void doEndCell() {
		wr.print("</td>");
		stack.pop();
	}

	@Override
	public void startTableHeaderCell() {
		startTableHeaderCell(null);
	}

	@Override
	public void startTableHeaderCell(Map<String, String> atts) {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case HCELL:
				doEndHCell();
				break;
			case CELL:
				doEndCell();
				break;
			case DIV:
				doEndDiv();
				break;
			case ROW:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}
		doStartHCell(atts);
	}

	private void doStartHCell(Map<String, String> atts) {
		if (atts != null && atts.size() > 0) {
			printStartWithAtts("th", atts);
		} else {
			wr.print("<th>");
		}
		stack.push(STATE.HCELL);
	}

	private void doEndHCell() {
		wr.print("</th>");
		stack.pop();
	}

	@Override
	public void endTable() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case DIV:
				doEndDiv();
				break;
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				end = true;
				break;
			case LINK:
				doEndLink();
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}
		doEndTable();
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void print(String content) {
		if (content != null) {
			wr.print(HtmlEscape.escape(content));
		}
	}

	@Override
	public void print(char content) {
		wr.print(HtmlEscape.escape(content));
	}

	@Override
	public void endDoc() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case SUBSECTION:
				doEndSubsection();
				break;
			case SECTION:
				doEndSection();
				break;
			case LINK:
				doEndLink();
				break;
			case DIV:
				doEndDiv();
				break;
			case DOC:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doEndDoc();
	}

	@Override
	public void printline() {
		wr.print("<br/>");
	}

	// -------------------------------------------------------------------------------------------------------

	@Override
	public void endDiv() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case CELL:
				doEndCell();
				break;
			case HCELL:
				doEndHCell();
				break;
			case ROW:
				doEndRow();
				break;
			case TABLE:
				doEndTable();
				break;
			case SUBSECTION:
				doEndSubsection();
				break;
			case SUBSUBSECTION:
				doEndSubsubsection();
				break;
			case SECTION:
				doEndSection();
				break;
			case LINK:
				doEndLink();
				break;
			case DIV:
			case DOC:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}

		doEndDiv();
	}

	@Override
	public void startDiv(Map<String, String> atts) {
		doStartDiv(atts);
	}

	private void doStartDiv(Map<String, String> atts) {
		printStartWithAtts("div", atts);
		stack.push(STATE.DIV);
	}

	private void doEndDiv() {
		wr.println("</div>");
		stack.pop();
	}


	// -------------------------------------------------------------------------------------------------------

	private void printStartWithAtts(String ename, Map<String, String> atts) {
		wr.print("<" + ename);
		for (Map.Entry<String, String> en : atts.entrySet()) {
			String name = en.getKey();
			String val = en.getValue();
			wr.print(" " + name + "=\"" + HtmlEscape.escape(val) + "\"");
		}
		wr.print(">");
	}

	private void append(StringBuilder sb, Node n) {
		if (n instanceof Element) {
			Element e = (Element) n;
			String tag = e.getTagName();
			sb.append("<").append(tag);
			NamedNodeMap atts = e.getAttributes();
			if (atts != null) {
				int natts = atts.getLength();
				if (natts > 0) {
					for (int i = 0; i < natts; i++) {
						Attr att = (Attr) atts.item(i);
						sb.append(" ").append(att.getName());
						sb.append("=\"").append(att.getNodeValue()).append("\"");
					}
				}
			}
			boolean closed = false;
			NodeList children = e.getChildNodes();
			if (children != null) {
				int nch = children.getLength();
				if (nch > 0) {
					sb.append(">");
					for (int i = 0; i < nch; i++) {
						Node cn = children.item(i);
						append(sb, cn);
					}
					sb.append("</").append(tag).append(">");
					closed = true;
				}
			}
			if (!closed) {
				sb.append("</").append(tag).append(">");
			}
		} else
		if (n instanceof Text) {
			Text t = (Text) n;
			sb.append(t.getTextContent());
		}
	}

	@Override
	public void print(Node n) {
		StringBuilder sb = new StringBuilder();		
		append(sb, n);
		wr.print(sb.toString());
	}
	@Override
	public void print(List<Node> nl) {
		StringBuilder sb = new StringBuilder();		
		for (Node n: nl) {
			append(sb, n);
		}
		wr.print(sb.toString());
	}

	@Override
	public void createAnchor(String id) {
		wr.print("<a name=\"");
		wr.print(HtmlEscape.escape(id));
		wr.print("\"> </a>");
	}

	// -------------------------------------------------------------------------------------------------------
	
	@Override
	public void endLink() {
		boolean end = false;
		while ((!end) && (!stack.isEmpty())) {
			STATE s = stack.peek();
			switch (s) {
			case LINK:
				end = true;
				break;
			default:
				throw new IllegalStateException("Illegal state '" + s
						+ "' in startSubsection()");
			}
		}
		doEndLink();
	}
	
	@Override
	public void startLink(String link) {
		doStartLink(link);
	}

	private void doStartLink(String link) {
		wr.print("<a href=\"");
		wr.print(HtmlEscape.escape(link));
		wr.print("\">");
		stack.push(STATE.LINK);
	}

	private void doEndLink() {
		wr.println("</a>");
		stack.pop();
	}

}
