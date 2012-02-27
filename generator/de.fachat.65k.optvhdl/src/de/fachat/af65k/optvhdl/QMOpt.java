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

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Formatter;
import java.util.List;

public class QMOpt {

	static boolean ISVERBOSE = false;

	private final PrintStream logStream;
	public QMOpt(PrintStream logstr	) {
		logStream = logstr;
	}
	
	public static int bitmask[] = { 1,2,4,8,16,32,64,128, 0x100,0x200,0x400,0x800,
			0x1000,0x2000,0x4000,0x8000 };

	int nbits[] = new int[Constants.NBITS];

	static //private static Formatter fmt = new Formatter();

	String fmt(int v) {
		Formatter fmt = new Formatter();
		fmt.format("%04x", v);
		return fmt.toString();
	}
	
	protected void LOG (String msg) {
		logStream.println("> " + msg);
	}
	protected void LOGN (String msg) {
		logStream.print(msg);
		logStream.flush();
	}
		
	public static void main(String argv[]) {

		int NBITS = 2;
		
		byte data[] = new byte[0x10000];

		QMOpt opt = new QMOpt(System.err);

		int n = opt.readFile(argv, data);

		Terms terms = opt.optimize(data, n, NBITS);

		opt.LOG("Stats:");
		for (int i = 0; i < NBITS; i++) {
			opt.LOG("Bit " + i);
			BitTerm bterm = terms.get(i);
			opt.LOG("  number of used input bits:" + Imp.countBits(bterm.allmaskbits));
			opt.LOG("  number of terms          :" + bterm.nterms);
		}
	}

	public int readFile(String[] argv, byte[] data) {
		String file = argv[0];
		File fp = new File(file);
		if(!fp.canRead()) {
		    LOG("Could not open file " + file);
		    System.exit(1);
		}
		int n = 0;
		try {
			FileInputStream fis = new FileInputStream(file);
			n = fis.read(data);
			fis.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		if(! (n!=0 && 0==(n & (n-1)))) {
			LOG("sorry, file (" + n +") size must be power of 2!");
			System.exit(1);
		}

		LOG("File `" + file + "', read " + n + " bytes");
		return n;
	}
	
	public Terms optimize(byte data[], int ndata, int nbits) {

		int bmask[] = new int[0x10000];
		int blogic[] = new int[0x10000];

		int xlist[] = new int[0x10000];

		ImpList t1, t2, tp, tt;
		Imp simp;
		Imp ip[], ib, ipx;
		int amask;
		int xdiff;
		int n1, n2, m, i, j, k, l, nc;
		int b;
		int bbmask, xmask;
				
		/* allocate initial tables */
		t1 = new ImpList();
		t2 = new ImpList();
		tp = new ImpList();

		Terms bitterms = new Terms();
		
		/* iterate bits */
		for(b=0;b<nbits;b++) {

		   tp.clear();
		   t1.clear();
		   t2.clear();

		   LOG("Checking bit " + b);

		   long startTime = System.currentTimeMillis();
		   
		   m=0;
		   bbmask=bitmask[b];
		   xmask=0;
		   for(j=0;j<ndata;j++) {
		       if((data[j] & bbmask) != 0) {
				  m++;
			   }
		   }
		   if (m>(ndata/2)) {
			   LOG("got " + m + " 1s out of " + ndata + ", so checking 0s");
			   xmask = bbmask;
		   }

		   /* precomputation - remove all unecessary bits from mask */
		   /* first separate to bits & mask */
		   for(m=0,i=0;i<ndata;i++) {
			   if(( (data[i] ^ xmask) & bbmask) != 0) {
			       bmask[m] = ndata-1;
			       blogic[m] = i;
			       m++;
			     }
			   }
			   /* now reduce all possible bits */
			   for(k=0;k<Constants.NBITS;k++) {
			     amask = bitmask[k];
			     for(i=0;i<m-1;i++) {
			       for(j=i+1;j<m;j++) {
				 if((bmask[i]==bmask[j])
					&& (((blogic[i] ^ blogic[j]) & bmask[i]) == amask)
				 ) {
				   bmask[i] &= ~amask;
				   bmask[j] = bmask[m-1];
				   blogic[j] = blogic[m-1];
				   m--;
				   break;
				 }
			       }
			     }
			   }
			   /* now OR all masks. Bits not used should show up as 0 anyway */
			   amask=0;
			   for(i=0;i<m;i++) {
			     amask |= bmask[i];
			   }
			   if(ISVERBOSE) LOG("m=" + m + " -> amask=" + fmt(amask));

			   /* now put all into first implicants list */
			   m=0;
			   for(j=0;j<ndata;j++) {
			       if(( (data[j] ^ xmask) & bbmask) != 0) {
			    	  simp = new Imp();
			          simp.logic=j & amask;
			          simp.mask=amask;
			          simp.flag=0;
			          simp.nbits = simp.nbits();
			          t1.addImp(simp);
			       }
			   }

			   do {
			      t2.clear();
			      if(ISVERBOSE) {
			    	  LOG("translation started with " + t1.n() +"/" + t1.m() +" impl:");
			    	  System.err.flush();
			      }

			      for(k=0;k<Constants.NBITS;k++) {
			    	  n1 = t1.n[k];
			    	  n2 = t1.n[k+1];
			    	  for(i=0;i<n1;i++) {
			    		  for(j=0;j<n2;j++) {
			    			  if(t1.tab[k][i].mask == t1.tab[k+1][j].mask) {
			    				  xdiff = t1.tab[k][i].mask 
			    				  	& (t1.tab[k][i].logic ^ t1.tab[k+1][j].logic);
			    				  /* check if they differ by one bit */
			    				  if ((xdiff != 0) && ((xdiff & (xdiff-1)) == 0)) {
			    					  t1.tab[k][i].flag=1;
			    					  t1.tab[k+1][j].flag=1;
			    					  simp = new Imp();
			    					  simp.mask = t1.tab[k][i].mask & ~xdiff;
			    					  simp.logic = t1.tab[k][i].logic & ~xdiff;
			    					  simp.flag=0;
			    					  simp.nbits = simp.nbits();

			    					  /* imp_print(&simp); */

			    					  t2.addImp(simp);
			    				  }
			    			  }
			    		  }
			    	  }
			    	  if(ISVERBOSE) {
			    		  LOGN(".");
			    		  System.err.flush();
			    	  }
			      }
			      for(k=0;k<Constants.NBITS+1;k++) {
			    	  n1=t1.n[k];
			    	  for(i=0;i<n1;i++) {
			    		  if (t1.tab[k][i].flag == 0) {
			    			  tp.addImp(t1.tab[k][i]);
			    		  }
			    	  }
			    	  if(ISVERBOSE) {
			    		  LOGN(",");
			    		  System.err.flush();
			    	  }
			      }
			      tt = t1;
			      t1 = t2;
			      t2 = tt;
			      t2.clear();
			      if(ISVERBOSE) {
		     	        LOG("");
		     	        LOG("now have " + tp.n() + " prime implicants");
			      }
			   } while(t1.n() != 0);

			   /* now find the essential prime implicants */

			   t1.clear();
			   t2.clear();
			   /* get a list of which combination is covered how many times */
			   for(i=0;i<ndata;i++) {
			     xlist[i]=0;
			     for(k=0;k<Constants.NBITS+1;k++) {
			       ip = tp.tab[k];
			       for(j=0;j<tp.n[k];j++) {
				 if(0== (ip[j].mask & (ip[j].logic ^ i))) {
				   xlist[i]++;
				 }
			       }
			     }
			   }
			   for(i=0;i<ndata;i++) {
			     if(xlist[i]==1) {
			       for(k=0;k<Constants.NBITS+1;k++) {
			         ip = tp.tab[k];
			         for(j=0;j<tp.n[k];j++) {
				   if(0== (ip[j].mask & (ip[j].logic ^ i))) {
				     t1.addImp(ip[j]);
				     ip[j].flag = 1;
				     /* clear bits covered by this essential implicant */
				     for(l=0;l<ndata;l++) {
				       if(0== (ip[j].mask & (ip[j].logic ^ l))) {
				         xlist[l] = 0;
				       }
				     }
				     break;
				   }
			         }
			       } 
			     }
			   }
		       for(k=0;k<Constants.NBITS+1;k++) {
			     ip = tp.tab[k];
			     for(j=0;j<tp.n[k];j++) {
			       if(0== (ip[j].flag)) {
			         t2.addImp(ip[j]);
			       }
			     }
			   }
			   /* now the essential prime implicants are in t1, and the 
			      "optional" ones in t2; xlist contains != 0 for each 
			      column still open. */

			   if(ISVERBOSE) {
			     LOG("found essential prime implicants:\n");
			     for(k=0;k<Constants.NBITS+1;k++) {
			       for(i=0;i<t1.n[k];i++) {
			    	   LOG("" + fmt(t1.tab[k][i].mask) + " " + fmt(t1.tab[k][i].logic) + "");
			       }
			     }
			     if (ISVERBOSE)
			    	 LOG("found secondary prime implicants:\n");
			     for(k=0;k<Constants.NBITS+1;k++) {
			       for(i=0;i<t2.n[k];i++) {
			    	   LOG("" + fmt(t2.tab[k][i].mask) + " " + fmt(t2.tab[k][i].logic) + "");
			       }
			     }
			     LOG("\n");
			   }

			   /* this could probably be done more efficiently... */
			   do {	
			     /* count the number of open columns */
			     m=0;
			     for(i=0;i<ndata;i++) {
			       if(xlist[i] != 0) m++;
			     }
			     if (ISVERBOSE)
			    	 LOG("" + m + " columns still open");
			     if(m == 0) break;
			     
			     /* now, for each secondary implicant, compute the number of
					columns it covers and along the way save the best one */
			     	ib=null;
			     	for(k=0;k<Constants.NBITS+1;k++) {
			     		for(i=0;i<t2.n[k];i++) {
			     			ipx=t2.tab[k][i];
			     			ipx.flag = 0;
			     			for(j=0;j<ndata;j++) {
			     				if(xlist[j] != 0) {
			     					if(0== (ipx.mask & (ipx.logic ^ j))) {
			     						ipx.flag++;
			     						if((ib == null) || (ipx.flag>=ib.flag)) {
			     							ib=ipx;
			     						}
			     					}
			     				}
			     			}
			     		}
			     	}
			     	/* mark all new columns as covered */
			     	if(ib != null) {
			     		for(j=0;j<ndata;j++) {
			     			if(0== (ib.mask & (ib.logic ^ j))) {
			     				xlist[j] = 0;
			     			}
			     		}
			     		t1.addImp(ib);
			     	}
			   } while(ib != null);

			   long endTime = System.currentTimeMillis();
			   long dur = (endTime - startTime) / 1000;
			   double durmin = Math.round((float)dur / 60. * 100) / 100;
			   
			   LOG("Needed " + dur + " seconds (" + durmin + " minutes)");
		
			   List<Term> terms = new ArrayList<QMOpt.Term>();
			   
			   LOG("Logic found for " + (xmask!=0 ? "!":"") + "B" + b + " = ");
			   int allmaskbits = 0;
			   boolean isFirst = true;
			   for(k=0;k<Constants.NBITS+1;k++) {
				   for(i=0;i<t1.n[k];i++) {
					   ipx=t1.tab[k][i];
					   nc=0;
					   LOGN("[" + fmt(ipx.mask) + " " + fmt(ipx.logic) + "] ");
					   
					   if(isFirst) isFirst = false; else LOGN("| ");
					   
					   for(j=0;j<Constants.NBITS;j++) {
						   	allmaskbits |= ipx.mask;
					   		if(( ipx.mask & bitmask[j] ) != 0) {
					   			if(nc != 0) LOGN(" & ");
					   			if(0==(ipx.logic&bitmask[j])) {
					   				LOGN("!");
					   			}
					   			LOGN("A" + j + "");
					   			nc++;
					   		}
					   }
					   LOG("");
					   Term t = new Term(xmask != 0, ipx.mask, ipx.logic);
					   terms.add(t);
			   		}
		   		}
			    BitTerm bterm = new BitTerm(terms, allmaskbits);
			    bitterms.add(bterm);
		   		LOG("");
			}
			return bitterms;
		}
	
	public static class Terms {
		ArrayList<BitTerm> bterms = new ArrayList<QMOpt.BitTerm>();

		public void add(BitTerm bterm) {
			bterms.add(bterm);
		}
		public BitTerm get(int i) {
			return bterms.get(i);
		}
	}
	
	public static class BitTerm {
		BitTerm(List<Term> iterms, int iallmaskbits) {
			terms = iterms;
			nterms = iterms.size();
			allmaskbits = iallmaskbits;
		}
		int allmaskbits;
		int nterms;
		List<Term> terms;
		
		public void toString(PrintStream out) {
			out.println("  number of used input bits:" + Imp.countBits(allmaskbits) + " (" + QMOpt.fmt(allmaskbits) + ")");
			out.println("  number of terms          :" + nterms);
		}
	}
	public static class Term {
		Term(boolean iinverted, int imask, int ilogic) {
			mask = imask;
			logic = ilogic;
			inverted = iinverted;
		}
		boolean inverted;
		int mask;
		int logic;
	}
}
