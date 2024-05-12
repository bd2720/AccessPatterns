PROG = access
PROG-C = $(PROG)-cpu
PROG-G = $(PROG)-gpu

CC-C = gcc
CC-G = nvcc

FLAGS-C = -Wall -Wextra -pedantic -lpthread -O4
FLAGS-G = -Xcompiler -Wall -Xcompiler -Wextra -Xcompiler -O4

all: $(PROG-C) $(PROG-G)

$(PROG-C): $(PROG-C).c $(PROG).h
	$(CC-C) $(FLAGS-C) $(PROG-C).c -o $(PROG-C)

$(PROG-G): $(PROG-G).cu $(PROG).h
	$(CC-G) $(FLAGS-G) $(PROG-G).cu -o $(PROG-G)

clean:
	rm $(PROG-C) $(PROG-G)
