bin-y           := c clc csh cxx candcxx cxxcc a/b/subc a/b/subc0

c-INCLUDES-y    := a/
clc-INCLUDES-y  := a/

c-CFLAGS-y      := -O1

c-y             := c.c
c-DEPS-y        := a/liba.a

clc-y           := c.c
clc-CPPFLAGS-y  := -DREQUIRE_CLANG
clc-compiler    := clang
clc-DEPS-y      := a/liba.a

csh-DEPS-y      := s/libshl.la
csh-DEPS-y      += s/libshl2.la
csh-DEPS-y      += a/y/liby.la

cxx-y           := cxx.cpp

candcxx-y       := cxx1.cpp c1.c

cxxcc-y         := cc.cpp
cxxcc-compiler  := $(CC)
cxxcc-DEPS-y    := s/libshl2.la

subc0-y         := a/b/subc.c
