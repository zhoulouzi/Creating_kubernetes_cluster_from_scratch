# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define "machine1" do |machine1|
    machine1.vm.box = "ubuntu/xenial64"
    machine1.vm.network :private_network, ip: "172.16.0.101"
  end

  config.vm.define "machine2" do |machine2|
    machine2.vm.box = "ubuntu/xenial64"
    machine2.vm.network :private_network, ip: "172.16.0.102"
  end

  config.vm.define "machine3" do |machine3|
    machine3.vm.box = "ubuntu/xenial64"
    machine3.vm.network :private_network, ip: "172.16.0.103"
  end

end
