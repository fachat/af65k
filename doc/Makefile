
GENDIR=../generator/de.fachat.65k
XSL=scripts/htmlsrc2html.xsl
TARGET=html/doc.css html/optable.css html/af65002front.html html/af65002opdesc.html html/af65002opcodes.html html/af65002int.html html/af65002compat.html html/af65002regs.html html/af65002opstruct.html html/af65002prefixes.html html/af65002admodes.html

INSERT_SH=scripts/inserts.sh

all: $(TARGET)

html/af65002front.html: src/af65002-front.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opstruct.html: src/af65002-opstruct.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src 
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002prefixes.html: src/af65002-prefixes.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src $(GENDIR)/opcodes-longtable-af65002.html
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002admodes.html: src/af65002-admodes.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src $(GENDIR)/admodes-table-af65002.html
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002regs.html: src/af65002-regs.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002int.html: src/af65002-int.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002compat.html: src/af65002-compat.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opdesc.html: src/af65002-opdesc.htmlsrc $(XSL) $(GENDIR)/opdoc-af65002.html $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opcodes.html: src/af65002-opcodes.htmlsrc $(XSL) $(GENDIR)/opcodes-table-af65002.html $(GENDIR)/opcodes-desc-af65002.html $(GENDIR)/ext-table-af65002.html $(GENDIR)/ext-desc-af65002.html $(INSERT_SH) src/af65002-menu.src
	xsltproc $(XSL) $< > $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/doc.css: src/doc.css
	cp $< $@

html/optable.css: src/optable.css
	cp $< $@

