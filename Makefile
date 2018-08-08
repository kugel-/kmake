.DEFAULT_GOAL := all

include autoconf.mk

# COMPILE and LINK are set in per-target rules
CC = cc
CXX = c++
AR = ar
RM = rm -f
LIBTOOL_COMPILE = libtool $(LIBTOOL_SILENT) --mode=compile --tag CC $(COMPILE)
LIBTOOL_LINK = libtool $(LIBTOOL_SILENT) --mode=link --tag CC $(LINK)
LIBTOOL_RM = libtool $(LIBTOOL_SILENT) --mode=clean --tag CC $(RM)
LIBTOOL_INSTALL = libtool $(LIBTOOL_SILENT) --mode=install --tag CC $(INSTALL_PROGRAM)

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

define clearvar
$(1)-y :=

endef

define clearvars
# clear each $xx-y
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(call clearvar,$(v)))
$(foreach v,CPPFLAGS CFLAGS CXXFLAGS LDFLAGS,$(call clearvar,$(v)))
extra-progs :=
extra-libs :=
extra-data :=
endef

subdir-y  := a/ b/ c/ d/ s/

progs-dir := $(bindir)
libs-dir := $(libdir)
data-dir  := $(datadir)
sysconf-dir := $(sysconfdir)

prog_vars := progs
lib_vars := libs
data_vars := data sysconf

#define reset_vars =
#LOCAL_SRC :=
#LOCAL_CFLAGS :=
#LOCAL_LDFLAGS :=
#LOCAL_LDLIBS :=
#endef                  g

ALL_CPPFLAGS = -I.
ALL_CFLAGS = -O2
ALL_CXXFLAGS = -Os


define inc_subdir
src := $(1)
include process-subdir.mk
endef

varname = $(notdir $(basename $(1)))
prefixtarget = $(foreach src,$(1),$(addprefix $(dir $(src))$(2)-,$(call varname,$(src))))

getvar = $($(call varname,$(1))-$(2))
# call with $(1) = target (incl. extension)
getsrc = $(addprefix $(dir $(1)),$(or $(call getvar,$(1),y),$(call varname,$(1)).c)) $(call getvar,$(1),ext-y)
# call with $(1) = target (incl. extension)
getobjext = $(if $(filter %.la,$(1)),lo,o)
# call with $(1) = src file, $(2) = target varname
getobjbase = $(addprefix $(OUTDIR),$(call prefixtarget,$(1),$(2)))
# call with $(1) = src file, $(2) = target (incl. extension)
getobjfile = $(call getobjbase,$(1),$(call varname,$(2))).$(call getobjext,$(2))
# call with $(1) = target (incl. extension)
getobj = $(foreach src,$(call getsrc,$(1)),$(call getobjfile,$(src),$(1)))
# call with $(1) = target (incl. extension)
getdep = $(addprefix $(OUTDIR),$(call getvar,$(1),deps-y))
# use libtool if building a shared library
is_cxx = $(filter %.cpp,$($(call varname,$(1))-y))
getcc = $(if $(call is_cxx,$(1)),$(CXX),$(CC))
# call with $(1) = obj file
getdepsdir = $(dir $(1)).deps/
# call with $(1) = obj file
getcmdfile = $(call getdepsdir,$(1))$(notdir $(1)).cmd
getdepfile = $(call getdepsdir,$(1))$(notdir $(1)).dep
getdepopt = -MD -MP -MF$(call getdepfile,$(1))

getprogs = $(foreach v,$(prog_vars),$(all_$(v)))

# Prepend variable $(2)-y to $(1)-(2)
# e.g. prepend CFLAGS-y to libfoo-CFLAGS
define prepend_flags
$(1)-$(2) := $($(2)-y) $($(1)-$(2))
endef

# Call with $1: object file, $2: src file
define obj_rule
cleanfiles += $(1)
cleanfiles += $(call getdepfile,$(1))
cleanfiles += $(call getcmdfile,$(1))

$(1): $(2)
$(1): $(call getcmdfile,$(1))
endef

define prog_rule
cleanfiles += $(1)
$(1): CPPFLAGS = $(call getvar,$(1),CPPFLAGS)
$(1): CFLAGS = $(call getvar,$(1),CFLAGS)
$(1): CXXFLAGS = $(call getvar,$(1),CXXFLAGS)
$(1): LDFLAGS = $(call getvar,$(1),LDFLAGS)
$(1): COMPILE_FLAGS = $(if $(call is_cxx,$(1)),$(ALL_CXXFLAGS) $(CXXFLAGS),$(ALL_CFLAGS) $(CFLAGS))
$(1): COMPILE = $(call getcc,$(1))
$(1): LINK = $(call getcc,$(1))
$(1): $(call getobj,$(1))
$(1): $(call getdep,$(1))

$(1)-obj += $(call getobj,$(1))

$(foreach f,$(call getsrc,$(1)),$(eval $(call obj_rule,$(call getobjfile,$(f),$(1)),$(f))))
endef

$(foreach dir,$(subdir-y),$(eval $(call inc_subdir,$(dir))))
$(foreach prog,$(all_progs),$(eval $(call prog_rule,$(OUTDIR)$(prog))))
$(foreach lib,$(all_libs),$(eval $(call prog_rule,$(OUTDIR)$(lib))))

changedir = $(if $(OUTDIR),cd $(OUTDIR))
printcmd = $(if $(Q),@printf "  %-7s%s\n" "$(1)" "$(2)")

.PHONY: FORCE all clean install install-progs install-libs install-data

FORCE: ;

all: $(addprefix $(OUTDIR),$(all_libs)) $(addprefix $(OUTDIR),$(all_progs)) ;

clean:
	$(call printcmd,CLEAN,$(cleanfiles))
	$(Q)$(LIBTOOL_RM) $(cleanfiles)

install: install-libs install-progs install-data

install-lib-%: FORCE
	@mkdir -p $(DESTDIR)$($*-dir)
	$(LIBTOOL_INSTALL) $(filter %.la,$(all_$*)) $(DESTDIR)$($*-dir)

install-libs: $(addprefix install-lib-,$(lib_vars))

install-prog-%: FORCE
	@mkdir -p $(DESTDIR)$($*-dir)
	$(LIBTOOL_INSTALL) $(all_$*) $(DESTDIR)$($*-dir)

install-progs: $(addprefix install-prog-,$(prog_vars))

install-data-%: FORCE
	@mkdir -p $(DESTDIR)$($*-dir)
	$(INSTALL_PROGRAM) -t $(DESTDIR)$($*-dir) $(all_$*)

install-data: $(addprefix install-data-,$(data_vars))

$(OUTDIR)%.cmd: FORCE
	$(S)mkdir -p $(dir $@)
	$(Q)(cmd="$(COMPILE) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS)" ; \
	new=$$(echo $$cmd | md5sum | cut -c-32); \
	uptodate= ; \
	if [ -f "$@" ]; then old=$$(cut -c-32 $@); test "$$old" = "$$new" && uptodate=y ; fi ;\
	test -n "$$uptodate" || echo "$$new" - "$$cmd" >$@)

$(OUTDIR)%.o:
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(COMPILE) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(OUTDIR)%.lo:
	$(call printcmd,CC,$<)
	$(S)mkdir -p $(dir $@)/.deps
	$(Q)$(LIBTOOL_COMPILE) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(OUTDIR)%.la:
	$(call printcmd,AR,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LINK)  -rpath $(libdir) $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $+

$(OUTDIR)%.a:
	$(call printcmd,AR,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(AR) rcs $@ $+

$(call getprogs):
	$(call printcmd,LD,$@)
	$(S)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LINK) $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $+

-include $(filter %.d,$(cleanfiles))
