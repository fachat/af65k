# Generates the documentation tables (html and asciidoc) for all CPU types.
#
# The generator needs a Java 8 JDK (it uses javax.xml.bind, which was removed
# in Java 11). Select it e.g. with
#   make JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
# For newer JDKs, put the JAXB jars on the classpath with EXTRA_CP.

ifdef JAVA_HOME
JAVAC = $(JAVA_HOME)/bin/javac
JAVA  = $(JAVA_HOME)/bin/java
else
JAVAC = javac
JAVA  = java
endif

EXTRA_CP ?=

PROJECTS = de.fachat.65k.base de.fachat.65k.model de.fachat.65k
SOURCES  = $(shell find $(addsuffix /src,$(PROJECTS)) -name '*.java')
BIN      = build/classes
OUTDIR   = de.fachat.65k

all: docs

$(BIN)/.stamp: $(SOURCES)
	rm -rf $(BIN)
	mkdir -p $(BIN)
	$(JAVAC) -encoding UTF-8 -nowarn -cp "$(EXTRA_CP)" -d $(BIN) $(SOURCES)
	touch $@

compile: $(BIN)/.stamp

# the generator reads af65002.xml from, and writes into, the current directory
docs: compile
	cd $(OUTDIR) && $(JAVA) -cp "$(CURDIR)/$(BIN):$(EXTRA_CP)" de.fachat.af65k.Generator

clean:
	rm -rf build

.PHONY: all compile docs clean
