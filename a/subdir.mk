subdir-y := y/ z/

CFLAGS-y := -O1

libs-y   := liba.a libx.a

liba-y   := a.c
liba-CFLAGS := -O2
