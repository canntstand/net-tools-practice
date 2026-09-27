Vagrant.configure("2") do |config|
  config.vm.box = "cloud-image/ubuntu-24.04"
  config.vm.box_version = "20260814.0.0"

  config.vm.define "upstream-router" do |vm|
    vm.vm.hostname = "upstream"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-wan",
      auto_config: false

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-internet",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "upstream"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "linux-gateway" do |vm|
    vm.vm.hostname = "gateway"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-wan",
      auto_config: false

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-lan",
      auto_config: false

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-dmz",
      auto_config: false

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-mgmt",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "gateway"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "lan-workstation" do |vm|
    vm.vm.hostname = "workstation"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-lan",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "workstation"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "lan-dns-server" do |vm|
    vm.vm.hostname = "dns"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-lan",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "dns"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "dmz-web-server" do |vm|
    vm.vm.hostname = "web"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-dmz",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "web"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "mgmt-workstation" do |vm|
    vm.vm.hostname = "admin"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-mgmt",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "admin"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end

  config.vm.define "external-client" do |vm|
    vm.vm.hostname = "external-client"

    vm.vm.network "private_network",
      virtualbox__intnet: "lab-internet",
      auto_config: false

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "external-client"
      vb.cpus = 2
      vb.memory = 1024
      vb.gui = false
      vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
    end
  end
end