CFLAGS-y     := -O2

subdir-y     := 1/

bin-y        := x y

x-y          := x.c
x-y          += ../a.c

y-y          := y.c
y-DEPS-y     := a/a.c
y-CFLAGS-y   := -O1
y-LIBS-y     := -lz

libs-y       := liby.la
