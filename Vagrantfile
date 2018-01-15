# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.synced_folder "scripts/", "/home/vagrant/scripts"

  config.vm.provision "shell",
    inline: "sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get dist-upgrade -y"

end
