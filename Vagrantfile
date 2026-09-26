Vagrant.configure("2") do |config|
  config.vm.box = "cloud-image/ubuntu-24.04"
  config.vm.box_version = "20260814.0.0"

  (1..6).each do |i|
    config.vm.define "node-#{i}" do |subconfig|
      subconfig.vm.hostname = "node-#{i}"
      subconfig.vm.network "private_network", ip: "192.168.56.#{10 + i - 1}"

      subconfig.vm.provider "virtualbox" do |vb|
        vb.name = "node-#{i}"
        vb.cpus = 1
        vb.memory = 512
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        vb.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
      end
    end
  end
end