INPUT_SOURCES = $(wildcard *cpp)
INPUT_OBJ = $(patsubst %.cpp,Unix/%.obj,$(INPUT_SOURCES))
OUTDIR=Unix
SYSTEM_INFO=$(shell uname)
EXTRA_LDFLAG=
CC=g++
CC_FLAGS=-pthread -g

ifeq ($(SYSTEM_INFO),SunOS)
   EXTRA_LDFLAG += -lsocket -lnsl -lstd++
   CC=gcc
   CC_FLAGS=-D_REENTRANT
endif

all:$(OUTDIR)/SipperProxy

clean:
	rm -Rf $(OUTDIR)


dir:
	mkdir -p $(OUTDIR)

$(OUTDIR)/%.obj: %.cpp
	$(CC) $(CC_FLAGS) -D__UNIX__ -c $< -o $@ 

$(OUTDIR)/SipperProxy: dir $(INPUT_OBJ)
	$(CC) $(CC_FLAGS) -D__UNIX__ $(INPUT_OBJ) -lpthread $(EXTRA_LDFLAG) -o $@ 
