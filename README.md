# Dotfiles-Playbook

Ansible playbooks for Managing my Linux (Ubuntu, Fedora) and Windows Machines

## Usage

Run `bootstrap.sh`.

Script will check the Linux / WSL distribution and run the appropriate Ansible playbook and install required software and Ansible requirements for the target system.

## TODO

- Document overlay using `config.yml` and overlay directory
- Make vars and tasks more flexible instead of hardcoding value with:
  - Use [`ansible.builtin.setup`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/setup_module.html) settings
    - `Ansible_distribution` for conditionals on Fedora and Ubuntu playbook
  - Build on `default_config.yaml` and override for Fedora
- Set up [Ansible logging](https://docs.ansible.com/automation-controller/latest/html/administration/logging.html) to more easily read output outside the terminal