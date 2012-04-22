package de.fachat.af65k.model.objs;

import java.util.List;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlAttribute;

import org.w3c.dom.Attr;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;

@XmlAccessorType(XmlAccessType.FIELD)
public class Doc {

	@XmlAttribute(name="mode")
	String mode;
	
	@XmlAnyElement
	List<Node> text;

	public String getMode() {
		return mode;
	}

	public void setMode(String mode) {
		this.mode = mode;
	}

	public List<Node> getText() {
		return text;
	}

	public String getTextStr() {
		StringBuilder sb = new StringBuilder();
		
		for (Node e : text) {
			append(sb, e);
		}
		return sb.toString();
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
}
