# Dotfiles-Playbook

Ansible playbooks for Managing my Linux (Ubuntu, Fedora) and Windows Machines

## Prerequisites

Works on Linux (Fedora, Ubuntu distributions) and Windows Subsystem for Linux (WSL2) Ubuntu.

## Usage

Run `bootstrap.sh`.

Script will check the Linux distribution and run the appropriate Ansible playbook and install required software and Ansible requirements for the target system.

## Roadmap

- Document in usage on how to use overlay directory and `config.yml`
- Make Ansible vars and tasks more flexible instead of hardcoding values with:
  - Use [`ansible.builtin.setup`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/setup_module.html) settings
    - `Ansible_distribution` for conditionals on Fedora and Ubuntu playbook
  - Build on `default_config.yaml` and override for Fedora
- Set up [Ansible logging](https://docs.ansible.com/automation-controller/latest/html/administration/logging.html) to more easily read output outside the terminal

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

### Built With

- [Ansible](https://www.ansible.com/)
- Inspired by [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) and [dotfiles Ansible role](https://github.com/geerlingguy/ansible-role-dotfiles)