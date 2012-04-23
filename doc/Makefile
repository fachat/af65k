
GENDIR=../generator/de.fachat.65k
XSL=scripts/htmlsrc2html.xsl
TARGET=html/doc.css html/optable.css html/af65002front.html html/af65002opdesc.html html/af65002opcodes.html html/af65002int.html html/af65002compat.html
INSERT_SH=scripts/inserts.sh

all: $(TARGET)

html/af65002front.html: src/af65002-front.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
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

