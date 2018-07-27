subdir-y := y/ z/

CFLAGS-y := -O1

libs-y   := liba.a libx.la

liba-y   := a.c
liba-CFLAGS := -O2
