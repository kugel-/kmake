extra-gen   += sed
extra-flags += SED_SCRIPT

define sed_rule
$(OUTDIR)$(1): SED_SCRIPT = $(call getvar,$(1),SED_SCRIPT)
$(OUTDIR)$(1): CMD = $$(SED_SCRIPT)
$(OUTDIR)$(1): $(SRCDIR)$(call getsrc,$(1))
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))
endef

define sed_recipe
$(addprefix $(OUTDIR),$(1)):
	$$(call printcmd,GEN,$$@)
	$$(AT)mkdir -p $$(@D)
	$$(Q)trap "rm -f $$@.tmp" EXIT && \
	     sed $$(addprefix --expression=,$$(SED_SCRIPT)) $$< >$$@.tmp && mv $$@.tmp $$@
endef

sed-suffix := .c.sed

.SUFFIXES: $(sed-suffix)
