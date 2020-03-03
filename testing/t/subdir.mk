extra-tests := testpy

tests-y   := t1 t2 test3.py

t1-y      := t1.c
t2-y      := t2.c

testpy-y  := test.py test2.py
testpy-driver := python3
test3.py-driver := python3

tests-y  += test2.py

t2-DEPS-y := a/liba.a
