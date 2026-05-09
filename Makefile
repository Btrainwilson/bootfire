PREFIX     ?= $(HOME)/.local
INSTALL_DIR := $(PREFIX)/share/bootfire
BIN_DIR     := $(PREFIX)/bin
CONFIG_HOME := $(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(HOME)/.config)
CONFIG_DIR  := $(CONFIG_HOME)/bootfire
FISH_HOOK   := $(CONFIG_HOME)/fish/conf.d/bootfire.fish

.PHONY: install uninstall test

install:
	@mkdir -p $(INSTALL_DIR)/bin $(INSTALL_DIR)/shell $(INSTALL_DIR)/share $(BIN_DIR) $(CONFIG_DIR)
	cp bin/bootfire      $(INSTALL_DIR)/bin/
	cp shell/bootfire.fish    $(INSTALL_DIR)/shell/
	cp shell/bootfire.sh      $(INSTALL_DIR)/shell/
	cp share/default-config   $(INSTALL_DIR)/share/
	cp share/default-ignore   $(INSTALL_DIR)/share/
	chmod +x $(INSTALL_DIR)/bin/bootfire
	ln -sf $(INSTALL_DIR)/bin/bootfire $(BIN_DIR)/bootfire
	@[ -e $(CONFIG_DIR)/config ] || cp share/default-config $(CONFIG_DIR)/config
	@[ -e $(CONFIG_DIR)/ignore ] || cp share/default-ignore $(CONFIG_DIR)/ignore
	@echo
	@echo "Installed bootfire to $(INSTALL_DIR)."
	@echo "To wire the shell hook, add one of these:"
	@echo "  fish:     mkdir -p $(CONFIG_HOME)/fish/conf.d && \\"
	@echo "            printf 'source %s\\n' $(INSTALL_DIR)/shell/bootfire.fish > $(FISH_HOOK)"
	@echo "  bash/zsh: add to ~/.bashrc or ~/.zshrc:"
	@echo "            source $(INSTALL_DIR)/shell/bootfire.sh"

uninstall:
	rm -f $(BIN_DIR)/bootfire
	rm -rf $(INSTALL_DIR)
	rm -f $(FISH_HOOK)
	@echo "Uninstalled. Config preserved at $(CONFIG_DIR)."
	@echo "If you added the source line to ~/.bashrc or ~/.zshrc, remove it manually"
	@echo "(look for the '# >>> bootfire >>>' block if installed via curl | sh)."

test:
	./tests/smoke.sh
