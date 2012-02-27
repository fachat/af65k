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

public class Imp {
	int mask;
	int logic;
	int nbits;
	char flag;

	public String toString() {
		return "{ [" + mask + "] " + (logic & mask) + "X (" + nbits + ")}"; // ,
																			// this->mask,this->logic
																			// &
																			// this->mask,
																			// this->nbits);
	}

	int nbits() {
		int xlogic;

		xlogic = logic & mask;

		return countBits(xlogic);
	}

	public static int countBits(int xlogic) {
		int i;
		int nn;
		for (nn = 0, i = 15; i >= 0; i--) {
			if ((xlogic & QMOpt.bitmask[i]) != 0)
				nn++;
		}
		return nn;
	}

	int mbits() {
		int xlogic;

		xlogic = mask;

		return countBits(xlogic);
	}

}
