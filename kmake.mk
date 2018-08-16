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
CC      ?= cc
CXX     ?= c++
AR      ?= ar
RM      ?= rm -f
LIBTOOL ?= libtool

LIBTOOL_COMPILE = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=compile --tag CC $(COMPILE)
LIBTOOL_LINK    = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=link --tag CC $(LINK)
LIBTOOL_RM      = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=clean --tag CC $(RM)
LIBTOOL_INSTALL = $(LIBTOOL) $(LIBTOOL_SILENT) --mode=install --tag CC $(INSTALL_PROGRAM)

DEFAULT_EXT ?= c
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

empty :=
space := $(empty) $(empty)

define clearvar
$(1)-y :=

endef

define clearvars
# clear each $xx-y
$(foreach v,$(prog_vars) $(lib_vars) $(data_vars),$(call clearvar,$(v)))
$(foreach v,CPPFLAGS CFLAGS CXXFLAGS LDFLAGS,$(call clearvar,$(v)))
$(foreach v,DEPS LIBS,$(call clearvar,$(v)))
extra-progs :=
extra-libs :=
extra-data :=
endef

subdir-y    ?=

prog_vars   := bin sbin
lib_vars    := libs
data_vars   := data sysconf

bin-dir     := $(bindir)
sbin-dir    := $(sbindir)
libs-dir    := $(libdir)
data-dir    := $(datadir)
sysconf-dir := $(sysconfdir)

#define reset_vars =
#LOCAL_SRC :=
#LOCAL_CFLAGS :=
#LOCAL_LDFLAGS :=
#LOCAL_LDLIBS :=
#endef                  g

ALL_CPPFLAGS ?= -I. $(if $(SRCDIR),-I$(SRCDIR))
ALL_CFLAGS   ?= -O2 -g
ALL_CXXFLAGS ?= -O2 -g


define inc_subdir
src := $(1)
include $(SRCDIR)process-subdir.mk
endef

varname = $(foreach x,$(1),$(notdir $(basename $(x))))
prefixtarget = $(foreach src,$(1),$(addprefix $(dir $(src))$(2)-,$(call varname,$(src))))

getvar = $($(call varname,$(1))$(if $(2),-$(2))-y)
# call with $(1) = target (incl. extension)
getsrc = $(addprefix $(dir $(1)),$(or $(call getvar,$(1)),$(call varname,$(1)).$(DEFAULT_EXT))) $(call getvar,$(1),ext)
# call with $(1) = target (incl. extension)
getobjext = $(if $(filter %.la,$(1)),lo,o)
# call with $(1) = src file, $(2) = target varname
getobjbase = $(call prefixtarget,$(1),$(2))
# call with $(1) = src file, $(2) = target (incl. extension)
getobjfile = $(call getobjbase,$(1),$(call varname,$(2))).$(call getobjext,$(2))
# call with $(1) = target (incl. extension)
getobj = $(foreach src,$(call getsrc,$(1)),$(call getobjfile,$(src),$(1)))
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

$(OUTDIR)$(1): $(SRCDIR)$(2)
$(OUTDIR)$(1): $(OUTDIR)$(call getcmdfile,$(1))

$(if $(OUTDIR),$(eval $(1): $(OUTDIR)$(1)))
endef

define prog_rule
cleanfiles += $(OUTDIR)$(1)
$(OUTDIR)$(1): CPPFLAGS = $(call getvar,$(1),CPPFLAGS)
$(OUTDIR)$(1): CFLAGS = $(call getvar,$(1),CFLAGS)
$(OUTDIR)$(1): CXXFLAGS = $(call getvar,$(1),CXXFLAGS)
$(OUTDIR)$(1): LDFLAGS = $(call getvar,$(1),LDFLAGS)
$(OUTDIR)$(1): COMPILE_FLAGS = $(if $(call is_cxx,$(1)),$(ALL_CXXFLAGS) $(CXXFLAGS),$(ALL_CFLAGS) $(CFLAGS))
$(OUTDIR)$(1): COMPILE = $(call getcc,$(1))
$(OUTDIR)$(1): LINK = $(call getcc,$(1))
$(OUTDIR)$(1): PRINTCMD = $(if $(call is_cxx,$(1)),CXX,CC)
$(OUTDIR)$(1): $(addprefix $(OUTDIR),$(call getobj,$(1)))
$(OUTDIR)$(1): $(addprefix $(OUTDIR),$(call getvar,$(1),DEPS))

$(if $(OUTDIR),$(eval $(1): $(OUTDIR)$(1)))

$(call varname,$(1))-obj += $(call getobj,$(1))

$(foreach f,$(call getsrc,$(1)),$(eval $(call obj_rule,$(call getobjfile,$(f),$(1)),$(f))))
endef

define test_rule
run-test-$(call varname,$(1)): $(OUTDIR)$(1)
run-test-$(call varname,$(1)): FORCE
endef

$(foreach dir,$(subdir-y),$(eval $(call inc_subdir,$(dir))))
$(foreach prog,$(ALL_LIBS) $(ALL_PROGS) $(ALL_TESTS),$(eval $(call prog_rule,$(prog))))
$(foreach test,$(ALL_TESTS),$(eval $(call test_rule,$(test))))

changedir = $(if $(OUTDIR),cd $(OUTDIR))
stripwd = $(if $(STRIPWD),$(patsubst $(OUTDIR)%,%,$(1)),$(1))
printcmd = $(if $(Q),@printf "  %-8s%s\n" "$(1)" "$(call stripwd,$(2))")

.PHONY: FORCE all check clean install install-progs install-libs install-data

DEFAULT_DRIVER = "sh -c"

run-test-%:
	$(Q)driver=$(or $(call getvar,$*,DRIVER),$(DEFAULT_DRIVER)); $$driver $<; \
	if [ $$?=0 ] ; then echo PASS: $<; else echo FAIL: $<; fi

all: $(addprefix $(OUTDIR),$(ALL_LIBS))
all: $(addprefix $(OUTDIR),$(ALL_PROGS))
#~ check: $(addprefix run-test-,$(call varname,$(ALL_TESTS)))
check: $(addprefix run-test-,$(call varname,$(ALL_TESTS)))

clean:
	$(call printcmd,RM,$(cleanfiles))
	$(Q)$(LIBTOOL_RM) $(cleanfiles)

install: install-libs install-progs install-data

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
	$(Q)$(INSTALL_PROGRAM) -D -t $(DESTDIR)$($*-dir) $(addprefix $(SRCDIR),$(all_$*))

install-data: $(addprefix install-data-,$(data_vars))

$(OUTDIR)%.cmd: FORCE
	$(AT)mkdir -p $(dir $@)
	$(QQ)(cmd="$(COMPILE) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS)" ; \
	new=$$(echo $$cmd | md5sum | cut -c-32); \
	uptodate= ; \
	if [ -f "$@" ]; then old=$$(cut -c-32 $@); test "$$old" = "$$new" && uptodate=y ; fi ;\
	test -n "$$uptodate" || echo "$$new" - "$$cmd" >$@)

$(OUTDIR)%.o:
	$(call printcmd,$(PRINTCMD),$@)
	$(AT)mkdir -p $(dir $@)/.deps
	$(Q)$(COMPILE) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(OUTDIR)%.lo:
	$(call printcmd,$(PRINTCMD),$@)
	$(AT)mkdir -p $(dir $@)/.deps
	$(Q)$(LIBTOOL_COMPILE) $(call getdepopt,$@) $(ALL_CPPFLAGS) $(CPPFLAGS) $(COMPILE_FLAGS) -c -o $@ $<

$(OUTDIR)%.la:
	$(call printcmd,LD,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LINK)  -rpath $(libdir) $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $+ $(call getvar,$(@),LIBS)

$(OUTDIR)%.a:
	$(call printcmd,AR,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(AR) rcs $@ $+

$(addprefix $(OUTDIR),$(ALL_PROGS) $(ALL_TESTS)):
	$(call printcmd,LD,$@)
	$(AT)mkdir -p $(dir $@)
	$(Q)$(LIBTOOL_LINK) $(ALL_LDFLAGS) $(LDFLAGS) -o $@ $+ $(call getvar,$(@),LIBS)

-include $(filter %.d,$(cleanfiles))
