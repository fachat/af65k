

#CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -g
CFLAGS=-g -W -Wall -pedantic -ansi -std=c11 -funsigned-char $(INCLUDE) 


# Enable verbose compile with make V=1
ifeq ($(V),1)
  V1=
  V2=@\#
else
  V1=@
  V2=@echo
endif

TARGET=a65k

all: $(TARGET) 

PREFIX=/usr/local
# OBJDIR contains temporary object and dependency files
OBJDIR=obj/
DEPDIR=$(OBJDIR).dep/

CC=$(CROSS)gcc
LD=$(CROSS)gcc
PKG_CONFIG=$(CROSS)pkg-config

# Create automatic dependency files (*.d) on the fly during compilation
AUTODEP=-MMD -MP -MF $(DEPDIR)$(@F).d

# Sorting include paths and defines simplifies checking them
INCPATHS=. util base
INCLUDE=$(sort $(addprefix -I,$(INCPATHS)))


SRC=$(wildcard *.c) $(wildcard util/*.c) $(wildcard base/*.c)

#output of `curl-config --libs`
#LDFLAGS=-L/usr/lib/i386-linux-gnu -lcurl -Wl,-Bsymbolic-functions
LDFLAGS=-lc

# Create object names from .c and .S
_OBJ=$(notdir $(patsubst %.c,%.o,$(patsubst %.S,%.o,$(SRC))))
OBJ=$(addprefix $(OBJDIR),$(_OBJ))
# Create dependency names from .o
DEP=$(addprefix $(DEPDIR),$(_OBJ:.o=.o.d))

# locations where make searches C source files
vpath %.c . base util 

# Include automatic dependencies, continue if they don't exist yet
-include $(DEP)


# Compile C files
$(OBJDIR)%.o: %.c
	$(V2) CC $<
	@#@echo "#"compile $< with CFLAGS=$(CFLAGS)
	$(V1) $(CC) $(CFLAGS) $(AUTODEP) -c $< -o $@

# Link object files
$(TARGET): $(OBJDIR) $(DEPDIR) $(OBJ)
	$(V2) LD $(notdir $@)
	$(V1) $(LD) $(OBJ) -o $@ $(LDFLAGS)
	$(V1)# Note: LIBS must be at the end for curl/libs to be found

veryclean:
	rm -rf $(TARGET)

# Clean directories
clean: objclean depclean

objclean:
	$(V2) Cleaning object files
	$(V1) rm -f $(OBJ)
	@# The object directory gets removed by make depclean

depclean:
	$(V2) Cleaning dependencies
	$(V1) rm -f $(DEP)
	$(V1) if [ -d $(DEPDIR) ]; then rmdir $(DEPDIR); fi


-include Makefile.local

doc:
	mkdir -p ../docsrc/doxygen
	doxygen Doxyfile

# Create build directories
$(OBJDIR):
	$(V1) mkdir -p $@
$(DEPDIR):
	$(V1) mkdir -p $@

install:
	@if [ `id -u` != "0" ] ; then echo "must be root!"; exit 1; fi;
	test -d $(PREFIX) || mkdir -p $(PREFIX)
	test -d $(PREFIX)/$(BINDIR) || mkdir -p $(PREFIX)/$(BINDIR)
	install -m 0755 $(TARGET) $(PREFIX)/$(BINDIR)
ifeq ($(PRIVILEGED),y)
	chmod u+s $(PREFIX)/$(BINDIR)/fsser
endif

uninstall:
	@if [ `id -u` != "0" ] ; then echo "must be root!"; exit 1; fi;
	rm -f $(PREFIX)/$(BINDIR)/$(TARGET)

.PHONY: all install uninstall run dmg fsser daemon exorcism
