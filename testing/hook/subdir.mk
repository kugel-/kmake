HOOK_FILE := $(objdir)file

generated-y := file

$(HOOK_FILE):
	@mkdir -p $(@D)
	touch $@

$(all-hook): $(HOOK_FILE)

$(clean-hook):
	rm -f $(HOOK_FILE)

$(install-hook):
	cp $(HOOK_FILE) $(DESTDIR)$(sysconfdir)/

$(foo-hook):
	@echo FOO
