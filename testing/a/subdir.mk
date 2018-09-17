subdir-y          := y/ z/

CFLAGS-y          := -O1

libs-y            := liba.a libx.la

liba.a-y          := a.c
liba.a-CFLAGS-y   := -O2
