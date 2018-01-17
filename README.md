# Adminsys utils

## Usage

```
usage: sysadmin.sh [-a | -st | -s <service_name>] [-c] [-l <limit>] [-h]

Options (only choose one):
  -s / --service <service_name>   Permet to check a service existance, and / or
                                  configure it
  -st / --stats                   Show some system stats, and start cpu warning
                                  monitoring
  -a / --all                      Show all services, and their characteristics

Other options:
  -c / --cpu-monitoring           Launch the CPU monitoring daemon
  -l / --cpu-limit <limit>        Set the CPU limit for warn of load (1-99). Set
                                  this setting enable cpu monitoring
  -h / --help                     Display this message
```

## Explanations

This is the sample of the school project we need to do to simpligy adminsys life.

**Bash scripts** are in the **scripts** folder, and the two files availables are :
- [sysadmin.sh](scripts/sysadmin.sh) : permet to check the system or a specific program, and install it if needed
- [cpuwarning.sh](scripts/cpuwarning.sh) : permet to launch a process that warn if the cpu usage is too high

Those two files need to be in the **same directory**, and you only need to launch the **sysadmin.sh** script.

CPU warning instance is launched using the command **screen** with the name **cpuwarning**. To reattach to the tab, just do :

```bash
screen -r cpuwarning

```
(To quit without destroying the session, press CTRL-A then CTRL-D)

> Those scripts were tested only on Ubuntu 16.04

**Default text editor** for configurations files is **vim**, you can set-up another (such nano) by setting-up an environment variable called **EDITOR** like in this example :

```bash
EDITOR=nano ./sysadmin.sh -s apache2
```

> If you set another file editor, you need it to be able to edit **multiple files** simultaneously

## Vagrant

A [Vagrantfile](Vagrantfile) for [Vagrant](https://www.vagrantup.com) is available to simplify test of this script (for [Virtualbox](https://www.virtualbox.org/) provider).

To use Vagrant, just type the following in a terminal :

```bash
# Create the VM and / or launch it
vagrant up

# Connect to the VM with ssh
vagrant ssh
```

**Scripts folder** is available in **default user home** : **/home/vagrant/scripts**
