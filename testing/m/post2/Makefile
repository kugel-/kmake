.PHONY: all clean install install-strip dist distclean check

all: tool2

distclean clean:
	rm -f tool2

install install-strip:
	cp tool2 $(DESTDIR)/tmp

dist:
	mkdir -p $(DISTDIR)
	cp tool2.c $(DISTDIR)
