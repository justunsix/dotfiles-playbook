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

.ONESHELL:
run-playbook-windows: ## Run playbook for Windows
	# Set config explicitly to avoid error due to world writable file in Vagrant
	export ANSIBLE_CONFIG=ansible.cfg
	# Ensure requirements are installed
	ansible-galaxy collection install -r requirements-windows.yml
	# --ask-pass --ask-become-pass for ssh connection and privilege escalation
	ansible-playbook --diff "windows.yml" --ask-pass --ask-become-pass -v

.ONESHELL:
run-playbook-windows-dotfiles: ## Run dotfiles tasks for Windows
	# Set config explicitly to avoid error due to world writable file in Vagrant
	export ANSIBLE_CONFIG=ansible.cfg
	# --ask-pass --ask-become-pass for ssh connection and privilege escalation
	ansible-playbook --diff "windows.yml" --ask-pass --ask-become-pass -v --tags "dotfiles"

.ONESHELL:
run-playbook-windows-interactive: ## Run playbook with user-specified tags for Windows
	# Set config explicitly to avoid error due to world writable file in Vagrant
	export ANSIBLE_CONFIG=ansible.cfg
	# Prompt the user for the tag they want to run
	read -p "Enter the tag you want to run: " TAG
	# --ask-pass --ask-become-pass for ssh connection and privilege escalation
	ansible-playbook --diff "windows.yml" --ask-pass --ask-become-pass -v --tags "$$TAG"	
