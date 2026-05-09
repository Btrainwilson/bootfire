PREFIX     ?= $(HOME)/.local
INSTALL_DIR := $(PREFIX)/share/bootfire
BIN_DIR     := $(PREFIX)/bin
CONFIG_DIR  := $(if $(XDG_CONFIG_HOME),$(XDG_CONFIG_HOME),$(HOME)/.config)/bootfire

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
	@echo "Add one of these to your shell rc:"
	@echo "  fish:     source $(INSTALL_DIR)/shell/bootfire.fish"
	@echo "  bash/zsh: source $(INSTALL_DIR)/shell/bootfire.sh"

uninstall:
	rm -f $(BIN_DIR)/bootfire
	rm -rf $(INSTALL_DIR)
	@echo "Uninstalled. Config preserved at $(CONFIG_DIR)."
	@echo "Frecency data at $(HOME)/.local/share/bootfire (remove manually if desired)."

test:
	./tests/frecency.sh
	./tests/smoke.sh
