# Adminsys utils

This is the sample of the school project we need to do to simpligy adminsys life.

**Bash scripts** are in the **scripts** folder, and the two files availables are :
- [sysadmin.sh](scripts/sysadmin.sh) : permet to check the system or a specific program, and install it if needed
- [cpuwarning.sh](scripts/cpuwarning.sh) : permet to launch a process that warn if the cpu usage is too high

> Those scripts were tested only on Ubuntu 16.04

A [Vagrantfile](https://www.vagrantup.com) is available to simplify test of this script (for [Virtualbox](https://www.virtualbox.org/) provider).

To use Vagrant, just type the following in a terminal :

```bash
# Create the VM and / or launch it
vagrant up

# Connect to the VM with ssh
vagrant ssh
```

**Scripts folder** is available in **default user home** : **/home/vagrant/scripts**
