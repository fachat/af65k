
GENDIR=../generator/de.fachat.65k
XSL=scripts/htmlsrc2html.xsl
TARGET=html/doc.css html/optable.css html/af65002front.html html/af65002opdesc.html html/af65002opcodes.html html/af65002int.html html/af65002compat.html html/af65002regs.html html/af65002opstruct.html html/af65002prefixes.html html/af65002admodes.html html/af65002hyper.html html/af65002mem.html html/af65002config.html html/af65002arch.html html/archcore.png html/archtop.png html/archtop.svg html/archcore.svg

INSERT_SH=scripts/inserts.sh
XSLT_SH=scripts/doxsl.sh

all: $(TARGET)

html/af65002front.html: src/af65002-front.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002hyper.html: src/af65002-hyper.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002arch.html: src/af65002-arch.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002config.html: src/af65002-config.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002mem.html: src/af65002-mem.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opstruct.html: src/af65002-opstruct.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src 
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002prefixes.html: src/af65002-prefixes.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src $(GENDIR)/opcodes-longtable-af65002.html
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002admodes.html: src/af65002-admodes.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src $(GENDIR)/admodes-table-af65002.html
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002regs.html: src/af65002-regs.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002int.html: src/af65002-int.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002compat.html: src/af65002-compat.htmlsrc $(XSL) $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opdesc.html: src/af65002-opdesc.htmlsrc $(XSL) $(GENDIR)/opdoc-af65002.html $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/af65002opcodes.html: src/af65002-opcodes.htmlsrc $(XSL) $(GENDIR)/opcodes-table-af65002.html $(GENDIR)/opcodes-desc-af65002.html $(GENDIR)/ext-table-af65002.html $(GENDIR)/ext-desc-af65002.html $(INSERT_SH) src/af65002-menu.src
	$(XSLT_SH) $(XSL) $<  $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR)
	rm $@.tmp

html/doc.css: src/doc.css
	cp $< $@

html/optable.css: src/optable.css
	cp $< $@

html/archcore.png: src/archcore.png
	cp $< $@

html/archtop.png: src/archtop.png
	cp $< $@

html/archcore.svg: src/archcore.svg
	cp $< $@

html/archtop.svg: src/archtop.svg
	cp $< $@


