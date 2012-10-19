
OBJS=main.o mem.o log.o infiles.o list.o linked_list.o array_list.o hashmap.o parser.o
IFILES=infiles.h list.h log.h main.h mem.h types.h linked_list.h array_list.h hashmap.h

CFLAGS=-Wall -pedantic -O2 -std=gnu99 -DMALLOC_CHECK_=3 -g

all: a65k

a65k: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

clean:
	rm $(OBJS)

%.o: %.c $(IFILES)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<
 

