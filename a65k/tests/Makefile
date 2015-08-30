
TESTS=hash1 list1 tokenizer1 infiles1

TESTBINS=$(addprefix bin/,$(TESTS))

SRCDIR=../src

CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -g

# Sorting include paths and defines simplifies checking them
INCPATHS=. util base
INCLUDES=$(sort $(addprefix -I$(SRCDIR)/,$(INCPATHS)))

DEPS=$(addsuffix /*.h,$(INCLUDES))

OBJFILES=log.o linked_list.o array_list.o mem.o hashmap.o tokenizer.o infiles.o
OBJ=$(addprefix $(SRCDIR)/obj/,$(OBJFILES))

all: $(TESTBINS)

%: bin/%

clean:
	rm -f *.o $(TESTBINS)

bin/%: %.c $(OBJ)
	echo "INCLUDES=" $(INCLUDES)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(OBJ) $< 
	./$@ > $@.x
	cmp `echo "$@" | sed -e 's%bin/%%g'`.out $@.x
	rm $@.x

 

