extra-gen   += sed
extra-flags += SED_SCRIPT

define sed_rule
cleanfiles += $(OUTDIR)$(1)

$(OUTDIR)$(1): SED_SCRIPT = $(call getvar,$(1),SED_SCRIPT)
$(OUTDIR)$(1): PRINTCMD = GEN
$(OUTDIR)$(1): CMD = $$(SED_SCRIPT)
$(OUTDIR)$(1): $(SRCDIR)$(call getsrc,$(1))
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))
endef

define sed_recipe
	sed -e $$(SED_SCRIPT) $$< >$$@.tmp && mv $$@.tmp $$@
endef

sed-suffix := c.sed
