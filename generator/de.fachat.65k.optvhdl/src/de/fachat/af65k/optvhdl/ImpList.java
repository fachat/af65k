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

public class ImpList {

	int 	m[]	= new int[Constants.NBITS+1];
	int 	n[]	= new int[Constants.NBITS+1];
	Imp		tab[][] = new Imp[Constants.NBITS+1][];
	

	public ImpList() {
		int i;
		
		for(i=0;i<Constants.NBITS+1;i++) {
		  n[i] = 0;
		  m[i] = 0x10000;
		  tab[i] = new Imp[m[i]];
		}
	}

	void clear() {
		int i;
		for(i=0;i<Constants.NBITS+1;i++) {
		  n[i]=0;
		}
	}

	void addImp(Imp data) {
		int nbits = data.nbits;
		int i,nn;
		Imp t[] = null;

		if(n[nbits] >= m[nbits]) {
		  m[nbits] *= 2;
		  Imp[] ip = tab[nbits];
		  tab[nbits] = new Imp[m[nbits]];
		  System.arraycopy(ip, 0, tab[nbits], 0, m[nbits]/2);
//		  tab[nbits] = realloc(this->tab[nbits], 
//						this->m[nbits] * sizeof(imp));
		}

		nn= n[nbits];
		t = tab[nbits];
		for(i=0;i<nn;i++) {
		   if( (t[i].mask == data.mask) && (t[i].logic == data.logic) ) 
			return;
		}
		tab[nbits][n[nbits]]=data;
		n[nbits]++;
	}

	int n() {
		int i;
		int nn;

		for(nn=0,i=0;i<Constants.NBITS+1;i++) {
		  nn+=n[i];
		}
		return nn;
	}

	int m() {
		int i;
		int nn;

		for(nn=0,i=0;i<Constants.NBITS+1;i++) {
		  nn+=m[i];
		}
		return nn;
	}

}
