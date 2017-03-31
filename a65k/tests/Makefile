
.PHONY: clean

TESTS=hash1 list1 tokenizer1 infiles1 block1 cpu1 context1 stringhash operation1 parser1

TESTBINS=$(addprefix bin/,$(TESTS))

SRCDIR=../src

CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -g

# Sorting include paths and defines simplifies checking them
INCPATHS=. util base
INCLUDES=$(addprefix -I$(SRCDIR)/,$(INCPATHS))
DEPS=$(addprefix $(SRCDIR)/,$(addsuffix /*.h,$(INCPATHS)))

OBJFILES=log.o linked_list.o array_list.o mem.o hashmap.o tokenizer.o infiles.o block.o cpu.o context.o errors.o segment.o operation.o parser.o arith.o print.o
OBJ=$(addprefix $(SRCDIR)/obj/,$(OBJFILES))

all: $(TESTBINS)

bin/%: %.c $(OBJ) $(DEPS)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(OBJ) $< 
	./$@ > $@.x
	cmp `echo "$@" | sed -e 's%bin/%%g'`.out $@.x
	rm $@.x

%: bin/%
	# not empty

clean:
	rm -f *.o $(TESTBINS)

 

