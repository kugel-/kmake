subdir-y          := y/ z/

CFLAGS-y          := -O1

libs-y            := liba.a libx.la

liba.a-y          := a.c a.h
liba.a-CFLAGS-y   := -O2

subdir-CPPFLAGS-y := -DSRCDIR=\"$$(srcdir)\"
subdir-CFLAGS-y   := -O3
subdir-LIBS-y     := -lc
