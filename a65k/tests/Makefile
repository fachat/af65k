

CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -I../src -g

DEPS=../src/*.h

SRC=../src/log.o ../src/linked_list.o ../src/array_list.o ../src/mem.o ../src/hashmap.o

all: list1 hash1

a65k: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	rm $(OBJS)

%: %.c $(DEPS) $(SRC)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(SRC) $< 
	./$@ > $@.x
	cmp $@.out $@.x
	rm $@.x

 

