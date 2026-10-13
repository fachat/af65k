# Builds the af65002 documentation in HTML (html/) and Asciidoc (adoc/) format.
#
#   make        - build both
#   make html   - build html only
#   make adoc   - build asciidoc only
#
# The tables (html/adoc) come from the generator, see ../generator/Makefile

GENDIR=../generator/de.fachat.65k/af65002

PAGES=front opdesc opcodes int compat regs opstruct prefixes admodes hyper mem config arch usage
STATIC=doc.css optable.css archcore.png archtop.png archtop.svg archcore.svg

HTML_XSL=scripts/htmlsrc2html.xsl
ADOC_XSL=scripts/htmlsrc2adoc.xsl
INSERT_SH=scripts/inserts.sh
XSLT_SH=scripts/doxsl.sh

HTML_TARGET=$(addprefix html/,$(STATIC)) $(patsubst %,html/af65002%.html,$(PAGES))
ADOC_TARGET=$(patsubst %,adoc/af65002%.adoc,$(PAGES))

# all generated tables are a dependency of every page
HTML_TABLES=$(wildcard $(GENDIR)/*.html)
ADOC_TABLES=$(wildcard $(GENDIR)/*.adoc)

all: html adoc

html: $(HTML_TARGET)

adoc: $(ADOC_TARGET)

html/af65002%.html: src/af65002-%.htmlsrc $(HTML_XSL) $(INSERT_SH) src/af65002-menu.src $(HTML_TABLES)
	$(XSLT_SH) $(HTML_XSL) $< $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR) html
	rm -f $@.tmp

adoc/af65002%.adoc: src/af65002-%.htmlsrc $(ADOC_XSL) $(INSERT_SH) $(ADOC_TABLES)
	@mkdir -p adoc
	$(XSLT_SH) $(ADOC_XSL) $< $@.tmp
	$(INSERT_SH) $@.tmp af65002 $@ $(GENDIR) adoc
	rm -f $@.tmp

html/%: src/%
	cp $< $@

clean:
	rm -rf adoc

.PHONY: all html adoc clean
