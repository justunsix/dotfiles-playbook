SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

run: ## Run playbook depending on system
	./bootstrap.sh

run-dotfiles: ## Run playbook on dotfiles tag
	ansible-playbook --diff "ubuntu.yml" --ask-become-pass -v --tags "dotfiles"

run-nix: ## Run playbook on nix tag
	ansible-playbook --diff "ubuntu.yml" --ask-become-pass -v --tags "nix"

run-flatpak: ## Run playbook on flatpak tag
	ansible-playbook --diff "ubuntu.yml" --ask-become-pass -v --tags "flatpak"
