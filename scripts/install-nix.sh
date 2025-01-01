#!/bin/bash
set -e

# Check if nix already installed, if not, do install
if ! command -v nix &>/dev/null; then

  # Install nix
  sudo apt install curl -y
  # multi user installation with --daemon
  # --yes is to automatically agree to the installation
  sh <(curl -L https://nixos.org/nix/install) --daemon --yes

  # Source to enable nix for later commands
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi

fi

echo -e "-- nix Installed"
