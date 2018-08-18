bin-y := g

g-y := dummy.c
g-DEPS-y := $(objdir)g.c

$(objdir)g.c: $(srcdir)g.c.in
	$(call printcmd,GEN,$@)
	$(Q)sed -e 's,_MAIN_,main,g' $< > $@.tmp && mv $@.tmp $@

clean-y := $(objdir)g.c
