.PHONY: all clean install install-strip dist distclean check

all dist install install-strip: ;

all: $(OUTDIR)$(SUBMAKE)libmlib.a

$(OUTDIR)$(SUBMAKE)mlib.o: mlib.c
	@mkdir -p $(@D)
	cc -c -o $@ $<

$(OUTDIR)$(SUBMAKE)libmlib.a: $(OUTDIR)$(SUBMAKE)mlib.o
	@sleep 0.2
	ar r $@ $<

clean distclean:
	rm -rf $(addprefix $(OUTDIR)$(SUBMAKE),libmlib.a *.o)
