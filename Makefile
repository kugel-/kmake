.DEFAULT_GOAL := all

CC = cc
CXX = c++
AR = ar
LD = cc
RM = rm -f
LIBTOOL_CC = libtool $(LIBTOOL_SILENT) --mode=compile --tag CC $(CC)
LIBTOOL_CXX = libtool $(LIBTOOL_SILENT) --mode=compile --tag CC $(CXX)
LIBTOOL_LD = libtool $(LIBTOOL_SILENT) --mode=link --tag CC $(CC)
LIBTOOL_RM = libtool $(LIBTOOL_SILENT) --mode=clean --tag CC $(RM)

S = @
ifneq ($(V),1)
Q = @
LIBTOOL_SILENT = --silent
endif

ifneq ($(O),)
OUTDIR := $(O)
endif

ifneq ($(OUTDIR),)
OUTDIR := $(OUTDIR)/
endif

empty :=
space := $(empty) $(empty)

subdir-y  := a/ b/ c/ s/
all_dirs  :=
all_libs  :=
all_progs :=
#define reset_vars =
#LOCAL_SRC :=
#LOCAL_CFLAGS :=
#LOCAL_LDFLAGS :=
#LOCAL_LDLIBS :=
#endef                  g

ALL_CPPFLAGS = -I.
ALL_CFLAGS = -O2

define inc_subdir
src := $(1)
include process-subdir.mk
endef

varname = $(notdir $(basename $(1)))

getobjext = $(if $(filter %.la,$(1)),.lo,.o)
getvar = $($(call varname,$(1))-$(2))
getsrc = $(addprefix $(dir $(1)),$(or $($(call varname,$(1))-y),$(call varname,$(1)).c))
getobj = $(addprefix $(OUTDIR),$(addsuffix $(call getobjext,$(1)),$(basename $(call getsrc,$(1)))))
getdep = $(addprefix $(OUTDIR),$($(call varname,$(1))-deps-y:.c=.o))
# use libtool if building a shared library
getcc = $(if $(filter %.cpp,$($(call varname,$(1))-y)),$(CXX),$(CC))
getcompile = $(if $(filter %.la,$(1)),libtool compile --tag CC $(call getcc,$(1)),$(call getcc,$(1)))
getcmdfile = $(addsuffix .cmd,$(dir $(1)).deps/$(notdir $(1)))
getdepfile = $(dir $(1)).deps/$(patsubst %.lo,%.d,$(patsubst %.o,%.d,$(notdir $(1))))
getdepopt = -MD -MP -MF$(call getdepfile,$(1))

# Prepend variable $(2)-y to $(1)-(2)
# e.g. prepend CFLAGS-y to libfoo-CFLAGS
define prepend_flags
$(1)-$(2) := $($(2)-y) $($(1)-$(2))
endef

# Call with $1: object file, $2: src file
define obj_rule
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(2))
endef

define prog_rule
cleanfiles += $(call getobj,$(1)) $(1)
cleanfiles += $(foreach f,$(call getobj,$(1)),$(call getdepfile,$(f)))
cleanfiles += $(foreach f,$(call getobj,$(1)),$(call getcmdfile,$(f)))
$(OUTDIR)$(1): CPPFLAGS = $(call getvar,$(1),CPPFLAGS)
$(OUTDIR)$(1): CFLAGS = $(call getvar,$(1),CFLAGS)
$(OUTDIR)$(1): CXXFLAGS = $(call getvar,$(1),CXXFLAGS)
$(OUTDIR)$(1): LDFLAGS = $(call getvar,$(1),LDFLAGS)
$(OUTDIR)$(1): $(call getobj,$(1))
$(OUTDIR)$(1): $(call getdep,$(1))

$(foreach f,$(call getsrc,$(1)),$(eval $(call obj_rule,$(addsuffix $(call getobjext,$(1)),$(basename $(f))),$(f))))
endef

$(foreach dir,$(subdir-y),$(eval $(call inc_subdir,$(dir))))
$(foreach prog,$(all_progs),$(eval $(call prog_rule,$(prog))))
$(foreach lib,$(all_libs),$(eval $(call prog_rule,$(lib))))

changedir = $(if $(OUTDIR),cd $(OUTDIR))
printcmd = $(if $(Q),@printf "  %-7s%s\n" "$(1)" "$(2)")

.PHONY: FORCE all clean

FORCE: ;

all: $(addprefix $(OUTDIR),$(all_libs)) $(addprefix $(OUTDIR),$(all_progs)) ;

clean:
	$(call printcmd,CLEAN,$(cleanfiles))
	$(Q)$(LIBTOOL_RM) $(cleanfiles)

$(OUTDIR)%.cpp.cmd: COMPILE_FLAGS = $(ALL_CXXFLAGS) $(CXXFLAGS)
$(OUTDIR)%.c.cmd: COMPILE_FLAGS = $(ALL_CFLAGS) $(CFLAGS)

$(OUTDIR)%.cmd: FORCE
	$(Q)(cmd="$(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS)" ; \
	new=$$(echo $$cmd | md5sum | cut -c-32); \
	uptodate= ; \
	if [ -f "$@" ]; then old=$$(cut -c-32 $@); test "$$old" = "$$new" && uptodate=y ; fi ;\
	test -n "$$uptodate" || echo "$$new" - "$$cmd" >$@)

$(OUTDIR)%.o: %.c
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(CC) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(ALL_CFLAGS) $(CFLAGS) -c -o $@ $<

$(OUTDIR)%.lo: %.c
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(LIBTOOL_CC) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(ALL_CFLAGS) $(CLAGS) -c -o $@ $<

$(OUTDIR)%.o: %.cpp
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(CXX) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(ALL_CXXFLAGS) $(CXXFLAGS) -c -o $@ $<

$(OUTDIR)%.o: %.cpp
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(LIBTOOL_CXX) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(ALL_CXXFLAGS) $(CXXFLAGS) -c -o $@ $<

$(OUTDIR)%.la:
	$(call printcmd,AR,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LD)  -rpath /usr/lib $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $^

$(OUTDIR)%.a:
	$(call printcmd,AR,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(AR) rcs $@ $^

$(OUTDIR)%:
	$(call printcmd,LD,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LD) $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $^

$(OUTDIR)%.d:;

-include $(filter %.d,$(cleanfiles))
