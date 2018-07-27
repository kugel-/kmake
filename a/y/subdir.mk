subdir-y     := 1/

progs-y      := x y

x-y          := x.c
x-y          += ../a.c

y-y          := y.c
y-deps-y     := a/a.c
