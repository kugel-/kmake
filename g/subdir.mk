bin-y := g g1

g-y := dummy.c
g-DEPS-y := $(objdir)g.c

$(objdir)g.c: $(srcdir)g.c.in
	$(call printcmd,GEN,$@)
	$(Q)sed -e 's,_MAIN_,main,g' $< > $@.tmp && mv $@.tmp $@

clean-y := $(objdir)g.c

sed-y := g1.c

g1.c-SED_SCRIPT-y := 's,_MAIN_,main,g'
