# DevOps: Virtualization

This directory contains a `Vagrantfile` that is configured to set up an Ubuntu virtual machine (VM).

This VM was created to be used to manage dotfiles in a Windows machine since Windows cannot run Ansible.
The VM also has additional software for convenience.

## Prerequisites

Before you begin, ensure you have met the following requirements installed:

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)

## Usage

To use this project, follow these steps:

- Clone or download this repository to your local machine.
- Navigate to the directory containing the `Vagrantfile`.
- Run the command `vagrant up` to start the virtual machine.
- Once the machine is up and running, you can use `vagrant ssh` to connect to it.
- Go to this repository assuming it is on the host machine at `~/Code/dotfiles-playbook` with `cd ~/Code/dotfiles-playbook`.
- Run `ansible-playbook -i inventory playbook.yml` to run the playbook.
  - If running again the `windows.yml` playbook, get a Windows IP address with `ipconfig` and update the `inventory` file with the IP address.
- When done, use `vagrant halt` to turn off the machine.

## About the Vagrantfile

- Sets up a virtual machine (VM) with Ubuntu
- Installs Ansible in the VM and uses it with a playbook to further set up the VM with software. Ansible can be used to manage dotfiles later.
- For convenience:
  - Copies certain configuration files from the host machine to the VM and mounts dotfiles repositories
  - Installs Nix to allow install other software in the VM and include programs for easier use of a VM
