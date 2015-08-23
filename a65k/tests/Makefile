
TESTS=hash1 list1

SRCDIR=../src

CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -g

# Sorting include paths and defines simplifies checking them
INCPATHS=. util base
INCLUDES=$(sort $(addprefix -I$(SRCDIR)/,$(INCPATHS)))

DEPS=$(addsuffix /*.h,$(INCLUDES))

OBJFILES=log.o linked_list.o array_list.o mem.o hashmap.o tokenizer.o
OBJ=$(addprefix $(SRCDIR)/obj/,$(OBJFILES))

all: $(TESTS)

clean:
	rm -f *.o $(TESTS)

%: %.c $(OBJ)
	echo "INCLUDES=" $(INCLUDES)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(OBJ) $< 
	./$@ > $@.x
	cmp $@.out $@.x
	rm $@.x

 

