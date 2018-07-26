include cleanvars.mk

include $(src)/subdir.mk

all_libs += $(addprefix $(src),$(libs-y))
all_progs += $(addprefix $(src),$(progs-y))

# prepends CFLAGS-y to $(bin)-CFLAGS (and friends)
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CPPFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),CXXFLAGS)))
$(foreach bin,$(libs-y) $(progs-y),$(eval $(call prepend_flags,$(call varname,$(bin)),LDFLAGS)))

$(foreach dir,$(addprefix $(src),$(subdir-y)),$(eval $(call inc_subdir,$(dir))))
