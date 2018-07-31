libs-y := libshl.la libshl2.la

libshl-y := s.c

libshl2-y := s2.c
libshl2-deps-y := a/libx.la
libshl2-LDFLAGS := -no-undefined
