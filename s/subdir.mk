libs-y               := libshl.la libshl2.la

libshl.la-y          := s.c

libshl2.la-y         := s2.c
libshl2.la-DEPS-y    := a/libx.la
libshl2.la-LDFLAGS-y := -no-undefined
