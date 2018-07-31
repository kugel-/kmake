progs-y   := c csh cxx

c-CFLAGS  := -O1

c-y       := c.c
c-deps-y  := a/liba.a

csh-deps-y  := s/libshl.la
csh-deps-y  += s/libshl2.la

cxx-y     := cxx.cpp
