
GENDIR=../generator/de.fachat.65k
XSL=scripts/htmlsrc2html.xsl
TARGET=html/doc.css html/af65002front.html

all: $(TARGET)

html/af65002front.html: src/af65002-front.htmlsrc $(XSL)
	xsltproc $(XSL) $< > $@.tmp
	cat $@.tmp
	mv $@.tmp $@

html/af65002opdesc.html: src/af65002-opdesc.htmlsrc $(XSL) $(GENDIR)/opdoc-af65002.html
	xsltproc $(XSL) $< > $@.tmp
	cat $@.tmp
	mv $@.tmp $@

html/doc.css: src/doc.css
	cp $< $@
