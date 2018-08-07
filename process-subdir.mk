include $(src)subdir.mk

# remember custom vars for installation
prog_vars  := $(sort $(prog_vars) $(extra-progs))
lib_vars   := $(sort $(lib_vars) $(extra-libs))
data_vars  := $(sort $(data_vars) $(extra-data))

$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(eval all_$(v) += $(addprefix $(src),$($(v)-y))))
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(if $($(v)-dir),,$(error Must specify $(v)-dir in $(src)subdir.mk)))

# prepends CFLAGS-y to $(bin)-CFLAGS (and friends)
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CPPFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CXXFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),LDFLAGS)))

$(eval $(call clearvars))

$(foreach dir,$(addprefix $(src),$(subdir-y)),$(eval $(call inc_subdir,$(dir))))
