libs-y            := libshl.la libshl2.la

libshl-y          := s.c

libshl2-y         := s2.c
libshl2-DEPS-y    := a/libx.la
libshl2-LDFLAGS-y := -no-undefined
