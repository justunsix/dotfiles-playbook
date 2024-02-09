#!/usr/bin/env bash

# Script to run on a new Linux system to configure it or
# run on a new WSL Windows system to configure Windows:
# 1. First, check if the Linux distribution is Ubuntu, Fedora, or WSL Ubuntu. If it is not one of those, the script exits.
# 2. Installs any prequisites needed for the Ansible playbook and software more easily installed in command line
# 3. Checks if an SSH RSA key exists. If it doesn't, the create one
# 4. If the bootstrap script has an argument "-r" and there are Ansible requirements, install them
# 5. Run the Ansible playbook.

set -e

##########################################
## Variables
##########################################

DOTFILES="$HOME/Code/dotfiles-playbook"
DOTSSH="$HOME/.ssh"

# System Flag
isUbuntu="false"
isFedora="false"
isWSLUbuntu="false"
isArch="false"
isMacOS="false"

# Restart shell flag
restartShell="false"

# If Linux distribution is Ubuntu, set isUbuntu variable to "true"
if [ -f /etc/os-release ]; then
	# Get os-release variables
	. /etc/os-release
	if [ "$ID" = "ubuntu" ]; then
		isUbuntu="true"
	fi
fi

# If file exist at /mnt/c, it is WSL
if [ -f /mnt/c/Windows/System32/wsl.exe ]; then
	isWSLUbuntu="true"
	isUbuntu="false"
fi

# If Linux distribution is Fedora, set isFedora variable to "true"
if [ -f /etc/fedora-release ]; then
	isFedora="true"
fi

# If Linux distribution is Arch, set isArch variable to "true"
if [ -f /etc/arch-release ]; then
	isArch="true"
fi

# Detect MacOS
if [[ "$OSTYPE" == "darwin"* ]]; then
	isMacOS="true"
fi

# If Linux distribution supported distributions, exit
if [ "$isUbuntu" = "false" ] && [ "$isFedora" = "false" ] && [ "$isWSLUbuntu" = "false" ] && [ "$isArch" = "false" ] && [ "$isMacOS" = "false" ]; then
	echo "This Linux/Unix distribution is not supported by this script."
	exit 1
fi

##########################################
## Functions
##########################################

install_ansible() {

	# Check if Ansible if installed
	# If Ansible is not installed, install it, assumes python3/python is installed already
	# per https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
	# as of 2023-03-25
	if ! [ -x "$(command -v ansible)" ]; then
		echo "Ansible is not installed. Installing Ansible using pip/x..."

		if [ "$isWSLUbuntu" = "true" ]; then
			sudo apt install python3-pip -y
			python3 -m pip install --user pywinrm ansible
		else

			if [ "$isUbuntu" = "true" ]; then
				sudo apt install pipx -y
			fi

			if [ "$isArch" = "true" ]; then
				sudo pacman -S --noconfirm python python-pipx
			fi

			if [ "$isFedora" = "true" ]; then
				sudo dnf install pipx -y
			fi

			if [ "$isMacOS" = "true" ]; then

				echo "Installing Homebrew and pipx"
				echo "*** Run last commands in Homebrew install manually to add it to path ***"
				# Install Brew package manager
				/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

				# from https://github.com/pypa/pipx
				brew install pipx
				pipx ensurepath
			fi

			pipx install --include-deps ansible
		fi

		restartShell="true"

	fi

}

# Install software that is easier to install in command line
install_software_command_line() {

	# Check if Starship is installed
	if ! [ -x "$(command -v starship)" ]; then
		if [ "$isFedora" = "true" ]; then
			# Install starship
			# per https://starship.rs/guide/#%F0%9F%9A%80-installation
			# as of 2023-03-25
			echo "Installing Starship..."
			curl -sS https://starship.rs/install.sh | sh
		fi
	fi

	# Check if deb-get is installed for Ubuntu native
	if [[ "$isUbuntu" = "true" && "$isWSLUbuntu" = "false" ]]; then
		if ! [ -x "$(command -v deb-get)" ]; then
			# Install deb-get
			# per https://github.com/wimpysworld/deb-get
			# as of 2023-03-25
			echo "deb-get is not installed. Installing deb-get..."
			sudo apt install curl
			curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
		fi
	fi

	# Check rustup is installed
	# if ! [ -x "$(command -v rustup)" ]; then
	#  	echo "Installing Rustup..."
	#	# Install Rustup
	#	# per https://www.rust-lang.org/tools/install
	#	# as of 2023-02-20
	#	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	#	restartShell="true"
	# fi

}

# Installs commands that the Ansible playbook needs
install_prequisites() {

	install_ansible

	# Install software from command line except for Arch
	if [ "$isArch" = "false" ]; then
		install_software_command_line
	fi

	# Install Nix
	if [[ "$isWSLUbuntu" = "false" ]]; then

		# Check nix is installed
		if ! [ -x "$(command -v nix-env)" ]; then

			if [ "$isMacOS" = "true" ]; then

				# Install nix multi user installation, there is no single user installation for MacOS
				# per https://nixos.org/download#nix-install-macos
				sh <(curl -L https://nixos.org/nix/install) --daemon

			else # Linux

				echo "Installing Nix..."
				# Install Nix multi user installation
				# per https://nix.dev/install-nix.html
				# as of 2024-02-08
				curl -L https://nixos.org/nix/install | sh -s -- --daemon

				# Add Ansible and Nix bin to PATH
				echo "export PATH=$PATH:$HOME/.nix-profile/bin/:$HOME/.local/bin" >>~/.bashrc
				echo "source $HOME/.nix-profile/etc/profile.d/nix.sh" >>~/.bashrc

			fi

			restartShell="true"

		fi

		# Check nix home manager is installed
		if ! [ -x "$(command -v home-manager)" ]; then
				echo "Installing Nix: home-manager..."
				nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
				nix-channel --update
				nix-shell '<home-manager>' -A install
		fi

	fi

	# if restartShell is true, tell user to restart shell and exit script
	if [ "$restartShell" = "true" ]; then
		# Since sourcing does not work for nix and rust requires shell restart to get PATH changes
		echo "Restart shell to get PATH changes"
		echo "and re-run with bootstrap.sh -r"
		exit 0
	fi

}

# Install Ansible requirements in directory
install_ansible_requirements() {
	if [ -f requirements.yml ]; then
		echo "Ansible requirements exist. Installing Ansible requirements..."
		if [ "$isWSLUbuntu" = "true" ]; then
			ansible-galaxy install -r requirements-windows.yml
			# else install requirements.yml
		else
			ansible-galaxy install -r requirements.yml
		fi
	fi
}

setup_RSA_key() {

	# Check if SSH RSA key exists
	# If SSH RSA key does not exist, create it
	# Ensure keys are are only readable by user
	if [ ! -f "$DOTSSH/id_rsa" ]; then
		echo "SSH RSA key does not exist. Creating SSH RSA key..."
		mkdir -p "$DOTSSH"
		chmod 700 "$DOTSSH"
		ssh-keygen -b 4096 -t rsa -f "$DOTSSH/id_rsa" -N "" -C "$USER@$HOSTNAME"
		cat "$DOTSSH/id_rsa.pub" >>"$DOTSSH/authorized_keys"
		chmod 600 "$DOTSSH/authorized_keys"
	fi

}

#################################
## Main Start of Script
#################################

install_prequisites
# Check if shell script has an argument "-r" (has requirements), if yes, check requirements
if [ "$1" = "-r" ]; then
	install_ansible_requirements
fi

setup_RSA_key

cd "$DOTFILES"

# ==== Run Ansible Playbook ====

if [ -f "$DOTFILES/vault-password.txt" ]; then
	ansible-playbook --diff --vault-password-file "$DOTFILES/vault-password.txt" "$DOTFILES/ubuntu.yml" -v
else

	if [ "$isUbuntu" = "true" ]; then
		# per https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html
		# --diff : when changing files/templates, show the differences in files
		# --ask-become-pass : ask for privilege escalation password
		# -v : low verbose mode, can increase with -vvv...
		ansible-playbook --diff "$DOTFILES/ubuntu.yml" --ask-become-pass -v
	fi

	if [ "$isFedora" = "true" ]; then
		ansible-playbook --diff "$DOTFILES/fedora.yml" --ask-become-pass -v
	fi

	if [ "$isWSLUbuntu" = "true" ]; then
		ansible-playbook --diff "$DOTFILES/windows.yml" --ask-pass -v
	fi

	if [ "$isArch" = "true" ]; then
		ansible-playbook --diff "$DOTFILES/arch.yml" --ask-become-pass -v --tags 'pacman','nix','repos','emacs','dotfiles'
	fi

	if [ "$isMacOS" = "true" ]; then
		ansible-playbook --diff "$DOTFILES/macos.yml" --ask-become-pass -v
	fi

fi
