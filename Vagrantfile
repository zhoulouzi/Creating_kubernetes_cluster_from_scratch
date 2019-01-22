# -*- mode: ruby -*-
# vim: ft=ruby

# ---- Configuration variables ----

GUI               = false # Enable/Disable GUI
RAM               = 4096  # Default memory size in MB
CPU 	          = 2
DOCKER_VERSION    = "18.06.1~ce~3-0~ubuntu"
PUB_KEY		  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCt+KAIfIjpJ41HMtjA8YVh7oq37DpoK1my6OZc9HXJfXYVEUva5nkFBc58m+5GA9IossrM5Rx5NDrl8wHbn3OejkFMdimtiJIyepTlWeDremS7qFFSMjxHPm1w6grK4J6ejA8dEOK2kGnehMxGfP6ARxvkGy9kqsx7fXwt4MTOpjD4RYrUGEz17z1LQ6bce4vyzUCtYHAUOqZBsamYWJ1I4p/JNn/FKy0XXCqJHan8eEgO8TZZulziuqcjnCLjpqOVG3yzzhZ5iFRpzobm4LBaS0SvowqttbLVAg8BtAJCpT/QWbDuOAr3grP4NjylWsKgCqDW/w/hduWw+IzrYmar zhouzichen@zhouzichendeMacBook-Pro.local"

# Network configuration
DOMAIN            = ".kubernetes.example.com"
NETWORK           = "192.168.88."
NETMASK           = "255.255.255.0"

# Default Virtualbox .box
BOX               = 'ubuntu/xenial64'


HOSTS = {
   "master1" => [NETWORK+"101", RAM, GUI, BOX, CPU],
   "node1" => [NETWORK+"201", RAM, GUI, BOX, CPU],
}

# ---- Vagrant configuration ----
Vagrant.configure(2) do |config|
  HOSTS.each do | (name, cfg) |
    ipaddr, ram, gui, box, cpu = cfg

    config.vm.define name do |machine|
      machine.vm.box   = box
      machine.disksize.size = '25GB'

      machine.vm.provider "virtualbox" do |vbox|
        vbox.cpus   = cpu
        vbox.gui    = gui
        vbox.memory = ram
        vbox.name = name
      end

      machine.vm.hostname = name + DOMAIN
      machine.vm.network 'private_network', ip: ipaddr, netmask: NETMASK
      machine.vm.provision "shell", inline: "sed 's@127\.0\.1\.1.*kubernetes.*@#{ipaddr} #{name} #{name}#{DOMAIN}@' -i /etc/hosts"
    end
  end # HOSTS-each

  config.vm.provision "shell", env: { "DOCKER_VERSION" => DOCKER_VERSION, "PUB_KEY" => PUB_KEY }, inline: <<-EOF

  #handle ssh
  sudo echo $PUB_KEY >> /root/.ssh/authorized_keys

#  #install docker
#  sudo apt-get remove docker docker-engine docker.io
#  sudo apt-get update
#  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
#  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#  sudo apt-get update
#  sudo apt-get install -y docker-ce=$DOCKER_VERSION

  #install kubelet kubeadm kubectl
#  apt-get update && apt-get install -y apt-transport-https curl
#  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
#  apt-get update
#  apt-get install -y kubelet kubeadm kubectl
#  apt-mark hold kubelet kubeadm kubectl

EOF

end
