.DEFAULT_GOAL := all

FORCE: ;

AT = @
ifeq ($(V),2)
QQ :=
Q  :=
LIBTOOL_SILENT :=
else ifeq ($(V),1)
QQ := @
Q  :=
LIBTOOL_SILENT :=
else
QQ := @
Q  := @
LIBTOOL_SILENT := --silent
endif

# COMPILE and LINK are set in per-target rules
CC      ?= $(CROSS_COMPILE)cc
CXX     ?= $(CROSS_COMPILE)c++
AR      ?= $(CROSS_COMPILE)ar
RM      ?= rm -f
LIBTOOL ?= libtool

LIBTOOL_COMPILE = $(LIBTOOL) $(LIBTOOL_SILENT) --tag CC --mode=compile $(COMPILE)
LIBTOOL_LINK    = $(LIBTOOL) $(LIBTOOL_SILENT) --tag CC --mode=link $(LINK)
LIBTOOL_RM      = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=clean $(RM)
LIBTOOL_INSTALL = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=install $(INSTALL_PROGRAM)

DEFAULT_SUFFIX ?= .c
STRIPWD     ?=

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
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars) $(gen_vars),$(call clearvar,$(v)))
$(foreach v,$(flag_names) $(aflag_names),$(call clearvar,$(v)))
$(foreach v,tests clean,$(call clearvar,$(v)))
extra-progs :=
extra-libs :=
extra-data :=
endef

subdir-y    ?= .

prog_vars     := bin sbin
prog_vars     += $(extra-progs)
lib_vars      := libs
lib_vars      += $(extra-libs)
data_vars     := data sysconf
data_vars     += $(extra-data)
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
getsrc = $(call addpath,$(1),$(or $(filter-out $(objpats),$(call getvar,$(1))),$(call getdefsrc,$(1)))) $(filter-out $(objpats),$(call getvar,$(1),DEPS))
# call with $(1) = target (incl. extension)
getnsrc = $(call addpath,$(1),$(filter $(objpats),$(call getvar,$(1)))) $(filter $(objpats),$(call getvar,$(1),DEPS))
# call with $(1) = target (incl. extension)
getobjext = $(if $(filter %.la,$(1)),lo,o)
# call with $(1) = src file, $(2) = target varname
getobjbase = $(call prefixtarget,$(1),$(2))
# call with $(1) = src file, $(2) = target (incl. extension)
getobjfile = $(call getobjbase,$(1),$(call varname,$(2))).$(call getobjext,$(2))
# call with $(1) = target (incl. extension)
getobj = $(foreach src,$(call getsrc,$(1)),$(call getobjfile,$(src),$(1))) $(call getnsrc,$(1))
# call with $(1) = target (incl. extension)
# use libtool if building a shared library
is_cxx = $(filter %.cpp,$(call getsrc,$(1)))
getcc = $(if $(call is_cxx,$(1)),$(CXX),$(CC))
# call with $(1) = obj file
getdepsdir = $(dir $(1)).deps/
# call with $(1) = obj file
getcmdfile = $(call getdepsdir,$(1))$(notdir $(1)).cmd
getdepfile = $(call getdepsdir,$(1))$(notdir $(1)).dep
getdepopt = -MD -MP -MF$(call getdepfile,$(1))

ALL_PROGS  = $(foreach v,$(prog_vars),$(all_$(v)))
ALL_LIBS   = $(foreach v,$(lib_vars),$(all_$(v)))
ALL_DATA   = $(foreach v,$(data_vars),$(all_$(v)))
ALL_GEN    = $(foreach v,$(gen_vars),$(all_$(v)))
ALL_TESTS  = $(all_tests)

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

# Call with $1: object file, $2: src file
define obj_rule
cleanfiles += $(OUTDIR)$(1)
cleanfiles += $(OUTDIR)$(call getdepfile,$(1))
cleanfiles += $(OUTDIR)$(call getcmdfile,$(1))

$(OUTDIR)$(1): CMD = $$(COMPILE) $$(KM_CPPFLAGS) $$(CPPFLAGS) $$(COMPILE_FLAGS)
$(OUTDIR)$(1): $(SRCDIR)$(2)
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))

$(if $(OUTDIR),$(eval vpath $(1) $(OUTDIR)))
endef

define rpath_rule
$(OUTDIR)$(1): RPATH = $(if $(filter %.la,$(1)),-rpath $(2))
endef

define prog_rule
cleanfiles += $(OUTDIR)$(1)
$(OUTDIR)$(1): KM_CPPFLAGS += $(call getvar,$(1),CPPFLAGS)
$(OUTDIR)$(1): KM_CFLAGS += $(call getvar,$(1),CFLAGS)
$(OUTDIR)$(1): KM_CXXFLAGS += $(call getvar,$(1),CXXFLAGS)
$(OUTDIR)$(1): KM_LDFLAGS += $(call getvar,$(1),LDFLAGS)
$(OUTDIR)$(1): COMPILE_FLAGS = $(if $(call is_cxx,$(1)),$$(KM_CXXFLAGS) $$(CXXFLAGS),$$(KM_CFLAGS) $(CFLAGS))
$(OUTDIR)$(1): COMPILE = $(call getcc,$(1))
$(OUTDIR)$(1): LINK = $(call getcc,$(1))
$(OUTDIR)$(1): CMD = $$(COMPILE) $$(RPATH) $$(KM_LDFLAGS) $$(LDFLAGS) -- $(call getvar,$(1),LIBS)
$(OUTDIR)$(1): PRINTCMD = $(if $(call is_cxx,$(1)),CXX,CC)
$(OUTDIR)$(1): $(addprefix $(OUTDIR),$(call getobj,$(1)))
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))

$(if $(OUTDIR),$(eval vpath $(1) $(OUTDIR)))

$(call varname,$(1))-obj += $(call getobj,$(1))

$(foreach f,$(call getsrc,$(1)),$(eval $(call obj_rule,$(call getobjfile,$(f),$(1)),$(f))))
endef

define test_rule
run-test-$(call varname,$(1)): $(OUTDIR)$(1)
run-test-$(call varname,$(1)): FORCE
endef

define gen_recipe
$(call $(1)_recipe,$(all_$(1)))

$(if $(OUTDIR),$(eval vpath $(all_$(1)) $(OUTDIR)))
endef

$(foreach dir,$(subdir-y),$(eval $(call inc_subdir,$(dir))))
$(foreach prog,$(ALL_LIBS) $(ALL_PROGS) $(ALL_TESTS),$(eval $(call prog_rule,$(prog))))
$(foreach test,$(ALL_TESTS),$(eval $(call test_rule,$(test))))
$(foreach v,$(lib_vars),$(foreach lib,$(all_$(v)),$(eval $(call rpath_rule,$(lib),$($(v)-dir)))))

$(foreach v,$(gen_vars),$(foreach gen,$(all_$(v)),$(eval $(call $(v)_rule,$(gen)))))
$(foreach v,$(gen_vars),$(eval $(if $(all_$(v)),$(call gen_recipe,$(v)))))

changedir = $(if $(OUTDIR),cd $(OUTDIR))
stripwd = $(if $(STRIPWD),$(patsubst $(OUTDIR)%,%,$(1)),$(1))
printcmd = $(if $(Q),@printf "  %-8s%s\n" "$(1)" "$(call stripwd,$(2))")

.PHONY: FORCE all libs progs data generated check clean install install-progs install-libs install-data

DEFAULT_DRIVER = "sh -c"

run-test-%:
	$(Q)driver=$(or $(call getvar,$*,DRIVER),$(DEFAULT_DRIVER)); $$driver $<; \
	if [ $$?=0 ] ; then echo PASS: $<; else echo FAIL: $<; fi

# PARTDIR restricts the selected targets to a given directory (partial build)
libs: $(filter $(PARTDIR)%,$(ALL_LIBS))
progs: $(filter $(PARTDIR)%,$(ALL_PROGS))
data: $(filter $(PARTDIR)%,$(ALL_DATA))
generated: $(filter $(PARTDIR)%,$(ALL_GEN))

all: libs progs data
#~ check: $(addprefix run-test-,$(call varname,$(ALL_TESTS)))
check: $(addprefix run-test-,$(call varname,$(filter $(PARTDIR)%,$(ALL_TESTS))))

clean:
	$(call printcmd,RM,$(cleanfiles) $(addprefix $(OUTDIR),$(all_clean)))
	$(Q)$(LIBTOOL_RM) $(cleanfiles) $(addprefix $(OUTDIR),$(all_clean))

install: install-libs install-progs install-data
install-strip: LIBTOOL_INSTALL += -s --strip-program=$(STRIP)
install-strip: install

install-lib-%: FORCE
	$(if $(filter %.la,$(all_$*)),$(call printcmd,INSTALL,$(filter %.la,$(addprefix $(OUTDIR),$(all_$*)))))
	$(AT)mkdir -p $(DESTDIR)$($*-dir)
	$(Q)$(if $(filter %.la,$(all_$*)),$(LIBTOOL_INSTALL) $(filter %.la,$(addprefix $(OUTDIR),$(all_$*))) $(DESTDIR)$($*-dir))

install-libs: $(addprefix install-lib-,$(lib_vars))

install-prog-%: FORCE
	$(if $(all_$*),$(call printcmd,INSTALL,$(addprefix $(OUTDIR),$(all_$*))))
	$(AT)mkdir -p $(DESTDIR)$($*-dir)
	$(if $(all_$*),$(Q)$(LIBTOOL_INSTALL) $(addprefix $(OUTDIR),$(all_$*)) $(DESTDIR)$($*-dir))

install-progs: $(addprefix install-prog-,$(prog_vars))

install-data-%: FORCE
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

$(OUTDIR)%.o:
	$(call printcmd,$(PRINTCMD),$@)
	$(AT)mkdir -p $(dir $@)/.deps
	$(Q)$(COMPILE) $(call getdepopt,$@) $(KM_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(OUTDIR)%.lo:
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
	$(Q)$(LIBTOOL_LINK) $(KM_LDFLAGS) $(LDFLAGS) -o $@ $(filter-out %.cmd,$+) $(call getvar,$(@),LIBS)

.SUFFIXES: $(objexts) .mk

-include $(filter %.d,$(cleanfiles))
