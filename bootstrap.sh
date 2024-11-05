#!/usr/bin/env bash

# Script to run on a new Linux system to configure it or
# run on a new WSL Windows system to configure Windows:
# 1. First, check if the Linux distribution is Ubuntu, Fedora, or WSL Ubuntu. If it is not one of those, the script exits.
# 2. Installs any prequisites needed for the Ansible playbook and software more easily installed in command line
# 3. Checks if an SSH RSA key exists. If it doesn't, the create one
# 4. If the bootstrap script has an argument "-r" and there are Ansible requirements, install them
# 5. Run the Ansible playbook.

# Exit immediately if any command the script executes fails (returns a non-zero status).
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
  # shellcheck source=/dev/null
  . /etc/os-release
  if [ "$ID" = "ubuntu" ]; then
    isUbuntu="true"
  fi
fi

if [ -f /mnt/c/Windows/System32/wsl.exe ]; then
  isWSLUbuntu="true"
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
    echo "Ansible is not installed. Installing Ansible using pipx..."

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
    # Add pipx bin path to shell
    echo "export PATH=$PATH:$HOME/.local/bin" >>~/.bashrc
    restartShell="true"

  fi

}

install_nix_home_manager() {

  if [ -x "$(command -v nix-env)" ]; then
    # Install nix home manager per https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
    if ! [ -x "$(command -v home-manager)" ]; then
      echo "Installing Nix: home-manager..."
      if [ "$isMacOS" = "true" ]; then
        if [ -f "$HOME/Code/dotfiles-nix/minimal/home.nix" ]; then
          echo "Symlinking minimal home.nix to ~/.config/home-manager/home.nix"
          ln -s ~/Code/dotfiles-nix/minimal/home.nix ~/.config/home-manager/home.nix
        else
          echo "Download dotfiles-nix's minimal home.nix before the home-manager install, exiting"
          exit 1
        fi
      fi
      scripts/install-nix-home-manager.sh
    fi
  fi

}

# Installs commands that the Ansible playbook needs
install_prequisites() {

  if ! [ -x "$(command -v nix-env)" ]; then
    echo "Nix is not installed, running install"
    scripts/install-nix.sh
    echo "Restart shell and re-run this script"
    exit 1
  fi

  install_ansible

  install_nix_home_manager

  # if restartShell is true, tell user to restart shell and exit script
  if [ "$restartShell" = "true" ]; then
    # Since sourcing does not work for some programs and need shell restart to get PATH changes
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

  if [ "$isArch" = "true" ]; then
    ansible-playbook --diff "$DOTFILES/arch.yml" --ask-become-pass -v --tags 'pacman','nix','repos','emacs','dotfiles'
  fi

  if [ "$isMacOS" = "true" ]; then
    ansible-playbook --diff "$DOTFILES/macos.yml" --ask-become-pass -v
  fi

fi
