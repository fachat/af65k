package de.fachat.af65k.model.objs;

import java.util.List;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlAnyElement;
import javax.xml.bind.annotation.XmlAttribute;

import org.w3c.dom.Node;

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

}
