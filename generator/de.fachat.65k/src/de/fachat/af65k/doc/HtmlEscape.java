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

public class HtmlEscape {
	
	public static String escape(String orig) {
		
		StringBuilder sb = new StringBuilder(orig.length() + 32);
		
		int l = orig.length();
		for (int i = 0; i < l; i++) {
			char c = orig.charAt(i);
			
			if (c == '<') {
				sb.append("&lt;");
			} else
			if (c == '>') {
				sb.append("&gt;");
			} else
			if (c == '&') {
				sb.append("&quot;");
			} else {
				sb.append(c);
			}
		}
		
		return sb.toString();
	}

	public static String escape(char c) {
		if (c == '<') {
			return "&lt;";
		} else
		if (c == '>') {
			return "&gt;";
		} else
		if (c == '&') {
			return "&quot;";
		} else {
			return String.valueOf(c);
		}
	}
}
