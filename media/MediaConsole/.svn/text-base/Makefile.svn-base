INPUT_SOURCES = $(wildcard *cpp)
INPUT_OBJ = $(patsubst %.cpp,Unix/%.obj,$(INPUT_SOURCES))
OUTDIR=Unix

$(OUTDIR)/MediaConsole:

clean:
	rm -Rf $(OUTDIR)


dir:
	mkdir -p $(OUTDIR)

$(OUTDIR)/%.obj: %.cpp
	g++ -D__UNIX__ -c $< -o $@

$(OUTDIR)/MediaConsole: dir $(INPUT_OBJ)
	g++ -D__UNIX__ -lpthread $(INPUT_OBJ) -o $@
