subdir-y :=

include $(SRCDIR)$(src)subdir.mk

# remember custom vars for installation
prog_vars  := $(sort $(prog_vars) $(extra-progs))
lib_vars   := $(sort $(lib_vars) $(extra-libs))
data_vars  := $(sort $(data_vars) $(extra-data))

# There is only a single tests variable, and the programs need not be installed
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars) tests,$(if $($(v)-y),$(eval all_$(v) += $(addprefix $(src),$($(v)-y)))))
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(if $($(v)-dir),,$(error Must specify $(v)-dir in $(src)subdir.mk)))

# prepends CFLAGS-y to $(bin)-CFLAGS-y (and friends)
XFLAGS = CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
$(foreach flag,$(XFLAGS),\
	$(foreach v,$(prog_vars) $(lib_vars) tests,\
		$(foreach bin,$($(v)-y),$(call prepend_flags,$(bin),$(flag)))))

# Like above, except DEPS and LIBS should be appended
# per-directory -l options should occur last (as LIBS usually holds
# system libraries). Likewise, DEPS must occur before LIBS.
XFLAGS = DEPS LIBS
$(foreach flag,$(XFLAGS),\
	$(foreach v,$(prog_vars) $(lib_vars) tests,\
		$(foreach bin,$($(v)-y),$(call append_flags,$(bin),$(flag)))))

$(eval $(call clearvars))

$(foreach dir,$(addprefix $(src),$(subdir-y)),$(eval $(call inc_subdir,$(dir))))
