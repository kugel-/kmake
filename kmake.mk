.DEFAULT_GOAL := all

FORCE: ;

AT = @
ifeq ($(V),2)
QQ :=
Q  :=
else ifeq ($(V),1)
QQ := @
Q  :=
else
QQ := @
Q  := @
endif

# COMPILE and LINK are set in per-target rules
CC              := $(CROSS_COMPILE)$(CC)
CXX             := $(CROSS_COMPILE)$(CXX)
AR              := $(CROSS_COMPILE)$(AR)
STRIP           ?= $(CROSS_COMPILE)strip
RM              ?= rm -f
LIBTOOL         ?= libtool
INSTALL_PROGRAM ?= install

LIBTOOL_COMPILE  = $(LIBTOOL) $(if $(Q),--silent) --tag CC --mode=compile $(COMPILE)
LIBTOOL_LINK     = $(LIBTOOL) $(if $(Q),--silent) --tag CC --mode=link $(LINK)
LIBTOOL_RM       = $(LIBTOOL) $(if $(Q),--silent) --mode=clean $(RM)
LIBTOOL_INSTALL  = $(LIBTOOL) $(if $(Q),--silent) --mode=install $(INSTALL_PROGRAM)

DEFAULT_SUFFIX  ?= .c
DEFAULT_DRIVER  ?= "sh -c"

STRIPWD         ?=

ifneq ($(S),)
SRCDIR := $(S)
endif

ifneq ($(SRCDIR),)
SRCDIR := $(SRCDIR)/
endif

ifneq ($(O),)
OUTDIR := $(O)
endif

ifneq ($(OUTDIR),)
OUTDIR := $(OUTDIR)/
endif

ifneq ($(M),)
PARTDIR := $(M)
endif

ifneq ($(PARTDIR),)
PARTDIR := $(PARTDIR)/
endif

KMAKEDIR := $(dir $(lastword $(MAKEFILE_LIST)))
ifeq ($(KMAKEDIR),.)
KMAKEDIR :=
endif

empty :=
space := $(empty) $(empty)

define clearvar
$(1)-y :=

endef

define clearvars
# clear each $xx-y
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(call clearvar,$(v)))
$(foreach v,$(test_vars) $(gen_vars) clean submake,$(call clearvar,$(v)))
$(foreach v,$(flag_names) $(aflag_names),$(call clearvar,$(v)))
extra-progs :=
extra-libs :=
extra-data :=
endef

subdir-y      ?= .
prefix        ?= /usr/local/
bindir        ?= $(prefix)bin
sbindir       ?= $(prefix)sbin
libdir        ?= $(prefix)lib
datadir       ?= $(prefix)share
sysconfdir    ?= $(prefix)etc

prog_vars     := bin sbin
prog_vars     += $(extra-progs)
lib_vars      := libs
lib_vars      += $(extra-libs)
data_vars     := data sysconf
data_vars     += $(extra-data)
test_vars     := tests testscripts
test_vars     += $(extra-tests)
gen_vars      := $(extra-gen)
flag_names    := CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
flag_names    += $(extra-flags)
aflag_names   := DEPS LIBS
aflag_names   += $(extra-append-flags)

bin-dir       := $(bindir)
bin-suffix    := $(DEFAULT_SUFFIX)
sbin-dir      := $(sbindir)
sbin-suffix   := $(DEFAULT_SUFFIX)
libs-dir      := $(libdir)
libs-suffix   := $(DEFAULT_SUFFIX)
data-dir      := $(datadir)
sysconf-dir   := $(sysconfdir)
tests-suffix  := $(DEFAULT_SUFFIX)
tests-driver  := $(DEFAULT_DRIVER)
testscripts-driver  := $(DEFAULT_DRIVER)

KM_CPPFLAGS ?= -I. $(if $(SRCDIR),-I$(SRCDIR))
KM_CFLAGS   ?= -O2 -g
KM_CXXFLAGS ?= -O2 -g

define inc_subdir
srcdir := $(filter-out .,$(1))
objdir := $(OUTDIR)$$(srcdir)
include $(KMAKEDIR)process-subdir.mk
endef

objexts := .la .a .lo .o
objpats := $(addprefix %,$(objexts))

varname = $(foreach x,$(1),$(notdir $(x)))
prefixtarget = $(foreach src,$(1),$(addprefix $(dir $(src))$(2)-,$(basename $(call varname,$(src)))))

# prepend $(dir $(1)) to $(2), except if it's './' or $(2) is an absolute path
addpath = $(patsubst $(dir $(1))/%,/%,$(addprefix $(filter-out ./,$(dir $(1))),$(2)))
getvar = $($(call varname,$(1))$(if $(2),-$(2))-y)
# call with $(1) = target (incl. extension)
getdefsrc = $(if $($(call varname,$(1))-suffix),$(basename $(call varname,$(1)))$($(call varname,$(1))-suffix))
# call with $(1) = target (incl. extension)
getsrc = $(strip $(call addpath,$(1),$(or $(filter-out $(objpats),$(call getvar,$(1))),$(call getdefsrc,$(1)))) $(filter-out $(objpats),$(call getvar,$(1),DEPS)))
# call with $(1) = target (incl. extension)
getnsrc = $(call addpath,$(1),$(filter $(objpats),$(call getvar,$(1)))) $(filter $(objpats),$(call getvar,$(1),DEPS))
# call with $(1) = target (incl. extension)
getobjext = $(if $(filter %.la,$(1)),lo,o)
# call with $(1) = src file, $(2) = target varname
getobjbase = $(call prefixtarget,$(1),$(2))
# call with $(1) = src file, $(2) = target (incl. extension)
getobjfile = $(call getobjbase,$(1),$(call varname,$(2))).$(call getobjext,$(2))
# call with $(1) = target (incl. extension)
# Note this is returns empty if the target has no source files, since it is
# assumed the target already exists (allows to place scripts in $foo-y)
getobj = $(strip $(foreach src,$(call getsrc,$(1)),$(call getobjfile,$(src),$(1))) $(call getnsrc,$(1)))
# call with $(1) = list of source files
is_cxx = $(filter %.cpp,$(1))
# call with $(1) = target (incl. extension)
is_lib = $(filter %.la %.a,$(1))
# call with $(1) = list of source files, returns CXX if one or more C++ files are found, else CC
getcc = $(if $(call is_cxx,$(1)),$(CXX),$(CC))
# call with $(1) = target (incl. extension)
getdepsdir = $(dir $(1)).deps/
# call with $(1) = target (incl. extension)
# Note this is returns empty if the target has no source files, since it is
# assumed the target already exists (allows to place scripts in $foo-y)
getcmdfile = $(call getdepsdir,$(1))$(notdir $(1)).cmd
getdepfile = $(call getdepsdir,$(1))$(notdir $(1)).dep
getdepopt = -MD -MP -MF$(call getdepfile,$(1)) -MQ$(1)

ALL_PROGS  = $(foreach v,$(prog_vars),$(all_$(v)))
ALL_LIBS   = $(foreach v,$(lib_vars),$(all_$(v)))
ALL_DATA   = $(foreach v,$(data_vars),$(all_$(v)))
ALL_GEN    = $(foreach v,$(gen_vars),$(all_$(v)))
ALL_TESTS  = $(foreach v,$(test_vars),$(all_$(v)))

# Prepend variable $(2)-y to $(1)-(2)-y
# e.g. prepend CFLAGS-y to libfoo-CFLAGS-y
define _prepend_flags
$(1)-$(2)-y := $(call getvar,$(2)) $(call getvar,$(1),$(2))
endef
prepend_flags = $(eval $(call _prepend_flags,$(call varname,$(1)),$(2)))

# Append variable $(2)-y to $(1)-(2)
# e.g. prepend LIBS-y to libfoo-LIBS-y
define _append_flags
$(1)-$(2)-y := $(call getvar,$(1),$(2)) $(call getvar,$(2))
endef
append_flags = $(eval $(call _append_flags,$(call varname,$(1)),$(2)))

# https://stackoverflow.com/a/47927343/5126486: Insert a new-line in a Makefile $(foreach ) loop
define newline =


endef

# Call with $1: object file, $2: src file, $3: target that $1 is part of
define obj_rule
cleanfiles += $(OUTDIR)$(1)
cleanfiles += $(OUTDIR)$(call getdepfile,$(1))
cleanfiles += $(OUTDIR)$(call getcmdfile,$(1))

# Use X := X Y notation to append to *FLAGS. For some reason,  += leads to
# KM_LDFLAGS of one target leaking to other targets. I couldn't reproduce it
# with a simplified Makefile yet but I think it's a bug in GNU make
$(OUTDIR)$(1): KM_CPPFLAGS := $(KM_CPPFLAGS) $(KM_CPPFLAGS_$(if $(call is_lib,$(3)),LIB,PROG)) $(call getvar,$(3),CPPFLAGS)
$(OUTDIR)$(1): KM_CFLAGS   := $(KM_CFLAGS)   $(KM_CFLAGS_$(if $(call is_lib,$(3)),LIB,PROG))   $(call getvar,$(3),CFLAGS)
$(OUTDIR)$(1): KM_CXXFLAGS := $(KM_CXXFLAGS) $(KM_CXXFLAGS_$(if $(call is_lib,$(3)),LIB,PROG)) $(call getvar,$(3),CXXFLAGS)
$(OUTDIR)$(1): COMPILE_FLAGS = $(if $(call is_cxx,$(2)),$$(KM_CXXFLAGS) $$(CXXFLAGS),$$(KM_CFLAGS) $(CFLAGS))
$(OUTDIR)$(1): PRINTCMD = $(if $(call is_cxx,$(2)),CXX,CC)
$(OUTDIR)$(1): COMPILE = $(call getcc,$(2))
$(OUTDIR)$(1): CMD = $$(COMPILE) $$(KM_CPPFLAGS) $$(CPPFLAGS) $$(COMPILE_FLAGS)
$(OUTDIR)$(1): $(SRCDIR)$(2)
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))

$(if $(OUTDIR),vpath $(1) $(OUTDIR))
endef

define rpath_rule
$(OUTDIR)$(1): RPATH = $(if $(filter %.la,$(1)),-rpath $(2))
endef

define prog_rule
# if a target has no objects, it is assumed to be a script that does
# not need to be built (as it cannot be built anyway)
cleanfiles += $(if $(call getobj,$(1)),$(OUTDIR)$(1))
cleanfiles += $(if $(call getobj,$(1)),$(OUTDIR)$(call getcmdfile,$(1)))

$(OUTDIR)$(1): KM_LDFLAGS := $(KM_LDFLAGS) $(KM_LDFLAGS_$(if $(call is_lib,$(1)),LIB,PROG)) $(call getvar,$(1),LDFLAGS)
$(OUTDIR)$(1): LINK = $(call getcc,$(call getsrc,$(1)))
$(OUTDIR)$(1): CMD = $$(COMPILE) $$(RPATH) $$(KM_LDFLAGS) $$(LDFLAGS) -- $(call getvar,$(1),LIBS)
$(OUTDIR)$(1): $(addprefix $(OUTDIR),$(call getobj,$(1)))
$(OUTDIR)$(1): $(if $(call getobj,$(1)),$(OUTDIR)$(call getcmdfile,$(1)))

$(if $(OUTDIR),vpath $(1) $(OUTDIR))

$(call varname,$(1))-obj += $(call getobj,$(1))

$(foreach f,$(call getsrc,$(1)),$(call obj_rule,$(call getobjfile,$(f),$(1)),$(f),$(1))$(newline))
endef

define test_rule
run-test-$(call varname,$(1)): $(1)
run-test-$(call varname,$(1)): FORCE
endef

define gen_rule
cleanfiles += $(addprefix $(OUTDIR),$(all_$(1)))

$(foreach f,$(all_$(1)),$(call $(1)_rule,$(f))$(newline))

$(call $(1)_recipe,$(all_$(1)))

$(if $(OUTDIR),vpath $(all_$(1)) $(OUTDIR))
endef

$(foreach dir,$(subdir-y),$(eval $(call inc_subdir,$(dir))))
$(foreach prog,$(ALL_LIBS) $(ALL_PROGS) $(ALL_TESTS),$(eval $(call prog_rule,$(prog))))
$(foreach test,$(ALL_TESTS),$(eval $(call test_rule,$(test))))
$(foreach v,$(gen_vars),$(eval $(call gen_rule,$(v))))
$(foreach v,$(lib_vars),$(foreach lib,$(all_$(v)),$(eval $(call rpath_rule,$(lib),$($(v)-dir)))))

changedir = $(if $(OUTDIR),cd $(OUTDIR))
stripwd = $(if $(STRIPWD),$(patsubst $(OUTDIR)%,%,$(1)),$(1))
printcmd = $(if $(Q),@printf "  %-8s%s\n" "$(1)" "$(call stripwd,$(2))")

sub_targets = all clean install install-strip

.PHONY: FORCE all libs progs data generated check clean
.PHONY: install install-progs install-libs install-data install-strip
.PHONY: submakes $(addprefix submakes-,$(sub_targets))
.PHONY: km-all km-clean km-check km-install km-install-strip

run-test-%:
	$(Q)driver=$($(call varname,$*)-driver); $$driver $(KM_CHECKFLAGS) $<; \
	if [ $$? = 0 ]; then echo PASS: $<; else echo FAIL: $<; fi

# PARTDIR restricts the selected targets to a given directory (partial build)
libs: $(filter $(PARTDIR)%,$(ALL_LIBS))
progs: $(filter $(PARTDIR)%,$(ALL_PROGS))
data: $(filter $(PARTDIR)%,$(ALL_DATA))
generated: $(filter $(PARTDIR)%,$(ALL_GEN))
submakes: submakes-all

# It's crucial that submakes-% depends on km-% if all_submake becomes
# empty due to the PARTDIR filter, otherwise all (etc.) has nothing to do
define submake_rule_dir
submake-$(1)-$(2): TARGET = $(1)
submake-$(1)-$(2): DIR = $(2)
submake-$(1)-$(2): SUBMAKE = $$(dir $$(firstword $$(wildcard $(OUTDIR)$$(DIR)Makefile $$(DIR)Makefile)))
endef

define submake_rule
.PHONY: submakes-$(1)
$(1): submakes-$(1)
submakes-$(1): $(or $(addprefix submake-$(1)-,$(filter $(PARTDIR)%,$(all_submake))),km-$(1))

ifneq ($(all_submake),)
$(foreach d,$(all_submake),$(call submake_rule_dir,$(1),$(d))$(newline))

.PHONY: $(addprefix submake-$(1)-,$(all_submake))
$(addprefix submake-$(1)-,$(all_submake)): km-$(1)
	$(call printcmd,MAKE,$$(SUBMAKE))
	$(Q)$$(MAKE) -C $$(SUBMAKE) $$(TARGET)
endif
endef

# no $(newline) here!
$(foreach t,$(sub_targets),$(eval $(call submake_rule,$(t))))

km-all: libs progs data

km-check: $(addprefix run-test-,$(call varname,$(filter $(PARTDIR)%,$(ALL_TESTS))))
check: km-check

km-clean:
	$(call printcmd,RM,$(cleanfiles) $(addprefix $(OUTDIR),$(all_clean)))
	$(Q)$(LIBTOOL_RM) $(cleanfiles) $(addprefix $(OUTDIR),$(all_clean))

km-install: install-libs install-progs install-data
km-install-strip: LIBTOOL_INSTALL += $(STRIPOPT)
km-install-strip: install

$(addprefix install-lib-,$(lib_vars)): install-lib-%: FORCE
	$(eval LA_LIBS := $(filter %.la,$(addprefix $(OUTDIR),$(all_$*))))
	$(if $(LA_LIBS),$(call printcmd,INSTALL,$(LA_LIBS)))
	$(AT)mkdir -p $(DESTDIR)$($*-dir)
	$(Q)$(if $(LA_LIBS),$(LIBTOOL_INSTALL) $(LA_LIBS) $(DESTDIR)$($*-dir))

install-libs: STRIPOPT = -s
install-libs: $(addprefix install-lib-,$(lib_vars))

$(addprefix install-prog-,$(prog_vars)): install-prog-%: FORCE
	$(if $(all_$*),$(call printcmd,INSTALL,$(addprefix $(OUTDIR),$(all_$*))))
	$(AT)mkdir -p $(DESTDIR)$($*-dir)
	$(if $(all_$*),$(Q)$(LIBTOOL_INSTALL) $(addprefix $(OUTDIR),$(all_$*)) $(DESTDIR)$($*-dir))

install-progs: STRIPOPT = -s --strip-program=$(STRIP)
install-progs: $(addprefix install-prog-,$(prog_vars))

$(addprefix install-data-,$(data_vars)): install-data-%: FORCE
	$(if $(all_$*),$(call printcmd,INSTALL,$(addprefix $(SRCDIR),$(all_$*))))
	$(AT)mkdir -p $(DESTDIR)$($*-dir)
	$(if $(all_$*),$(Q)$(INSTALL_PROGRAM) -D -t $(DESTDIR)$($*-dir) $(addprefix $(SRCDIR),$(all_$*)))

install-data: $(addprefix install-data-,$(data_vars))

$(OUTDIR)%.cmd: FORCE
	$(AT)mkdir -p $(dir $@)
	$(QQ)(cmd="$(CMD)" ; \
	new=$$(echo $$cmd | md5sum | cut -c-32); \
	uptodate= ; \
	if [ -f "$@" ]; then old=$$(cut -c-32 $@); test "$$old" = "$$new" && uptodate=y ; fi ;\
	test -n "$$uptodate" || echo "$$new" - "$$cmd" >$@)

# prevent %.o to become a fallback rule for any file
all_obj = $(filter %.o,$(cleanfiles))
$(all_obj): $(OUTDIR)%.o:
	$(call printcmd,$(PRINTCMD),$@)
	$(AT)mkdir -p $(dir $@)/.deps
	$(Q)$(COMPILE) $(call getdepopt,$@) $(KM_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

# prevent %.lo to become a fallback rule for any file
all_lobj = $(filter %.lo,$(cleanfiles))
$(all_lobj): $(OUTDIR)%.lo:
	$(call printcmd,$(PRINTCMD),$@)
	$(AT)mkdir -p $(dir $@)/.deps
	$(Q)$(LIBTOOL_COMPILE) $(call getdepopt,$@) $(KM_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(addprefix $(OUTDIR),$(filter %.la,$(ALL_LIBS))):
	$(call printcmd,LD,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LINK) $(RPATH) $(KM_LDFLAGS) $(LDFLAGS) -o $@ $(filter-out %.cmd,$+) $(call getvar,$(@),LIBS)

$(addprefix $(OUTDIR),$(filter %.a,$(ALL_LIBS))):
	$(call printcmd,AR,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(AR) rcs $@ $(filter-out %.cmd,$+)

$(addprefix $(OUTDIR),$(ALL_PROGS) $(ALL_TESTS)):
	$(call printcmd,LD,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(if $(filter %.la %.lo,$+),$(LIBTOOL_LINK),$(LINK)) $(KM_LDFLAGS) $(LDFLAGS) -o $@ $(filter-out %.cmd,$+) $(call getvar,$(@),LIBS)

.SUFFIXES: $(objexts) .mk

-include $(filter %.dep,$(cleanfiles))
