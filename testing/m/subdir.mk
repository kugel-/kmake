submake-y := 1/ 2/
postmake-y := post1/ post2/

generated-y := 1/libmlib.a

$(objdir)1/libmlib.a: submake-all-$(srcdir)1/

tests-y := mtool
mtool-y := mtool.c 1/libmlib.a
