В Vagrantfile ip интерфейсов и в целом ничего лишнего не настраиваем, чтобы настройка с нуля была честной

vagrant status
    Current machine states:
    upstream-router           running (virtualbox)
    linux-gateway             running (virtualbox)
    lan-workstation           running (virtualbox)
    lan-dns-server            running (virtualbox)
    dmz-web-server            running (virtualbox)
    mgmt-workstation          running (virtualbox)
    external-client           running (virtualbox)

Сначала хочу зафиксировать ещё одну проверку: убедиться, что такая же ожидаемая нумерация действительно используется на остальных пяти VM.

    for vm in upstream-router linux-gateway lan-workstation lan-dns-server dmz-web-server mgmt-workstation external-client; do
        echo "===== $vm ====="
        vagrant ssh "$vm" -c 'ip -br link'
    done

        ===== upstream-router =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:e7:4d:fd <BROADCAST,MULTICAST> 
        enp0s9           DOWN           08:00:27:8e:66:79 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:2b:39:3a <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== linux-gateway =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:80:3c:49 <BROADCAST,MULTICAST> 
        enp0s9           DOWN           08:00:27:53:c7:a1 <BROADCAST,MULTICAST> 
        enp0s10          DOWN           08:00:27:7f:36:0c <BROADCAST,MULTICAST> 
        enp0s16          DOWN           08:00:27:a0:37:59 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:5d:a0:ce <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== lan-workstation =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:62:e0:e8 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:41:0f:15 <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== lan-dns-server =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:d1:20:b7 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:45:59:f8 <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== dmz-web-server =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:67:25:87 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:64:96:3a <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== mgmt-workstation =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:f8:3b:f8 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:cc:d1:00 <BROADCAST,MULTICAST,UP,LOWER_UP> 
        ===== external-client =====
        lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
        enp0s8           DOWN           08:00:27:b1:84:61 <BROADCAST,MULTICAST> 
        enp0s3           UP             08:00:27:11:62:3c <BROADCAST,MULTICAST,UP,LOWER_UP>

По Vagrantfile и полученным данным выведем такую ситуацию (на примерен 2 виртуалок):

upstream-router	
    enp0s3	Vagrant NAT, технический
	enp0s8	lab-wan
	enp0s9	lab-internet
linux-gateway	
    enp0s3	Vagrant NAT, технический
	enp0s8	lab-wan
	enp0s9	lab-lan
	enp0s10	lab-dmz
	enp0s16	lab-mgmt

Почему enp0s16, а не enp0s11 — здесь ничего подозрительного нет. Имя интерфейса Linux зависит от PCI-раскладки виртуального устройства, поэтому последовательность имён не обязана совпадать с порядковым номером NIC в Vagrant.

Так как в Vagrantfile было указано auto_config: false
    enp0s8   DOWN
    enp0s9   DOWN
    enp0s10  DOWN
    enp0s16  DOWN

Теперь настройка netplan. Пока что только IP

vagrant ssh linux-gateway
    ls -la /etc/netplan/

        total 12
        drwxr-xr-x   2 root root 4096 Sep 27 08:10 .
        drwxr-xr-x 106 root root 4096 Sep 27 08:11 ..
        -rw-------   1 root root  161 Sep 27 08:10 50-cloud-init.yaml

        Смотрим текущую netplan конфигурацию, чтобы ничего лишнего не сломать

        sudo cat /etc/netplan/*.yaml

            network:
            version: 2
            ethernets:
                enp0s3:
                match:
                    macaddress: "08:00:27:5d:a0:ce"
                dhcp4: true
                dhcp6: true
                set-name: "enp0s3"
        
        То есть 50-cloud-init.yaml управляет только техническим Vagrant NAT-интерфейсом enp0s3. Лабораторные интерфейсы (enp0s8, enp0s9, enp0s10, enp0s16) вообще не описаны — именно их мы сейчас добавим отдельным файлом. Это хорошо соответствует нашей архитектуре: Vagrant создаёт NIC, а Netplan задаёт их адреса.

        На gateway пока не задаём ни default route, ни DNS, ни forwarding. Только IP-адреса.
        sudo nano /etc/netplan/60-lab.yaml

            network:
              version: 2

              ethernets:
                enp0s8:
                addresses:
                  - 172.16.0.2/24

                enp0s9:
                addresses:
                  - 10.10.10.1/24

                enp0s10:
                addresses:
                  - 10.10.20.1/24

                enp0s16:
                addresses:
                  - 10.10.30.1/24
        
        Права:
        sudo chmod 600 /etc/netplan/60-lab.yaml

        Перед применением проверяем netplan
        sudo netplan generate

        Применяем
        sudo netplan apply

        Проверяем результат
        $ ip -br addr
        ip route
        lo               UNKNOWN        127.0.0.1/8 ::1/128 
        enp0s8           UNKNOWN        172.16.0.2/24 fe80::a00:27ff:fe80:3c49/64 
        enp0s9           UNKNOWN        10.10.10.1/24 fe80::a00:27ff:fe53:c7a1/64 
        enp0s10          UNKNOWN        10.10.20.1/24 fe80::a00:27ff:fe7f:360c/64 
        enp0s16          UNKNOWN        10.10.30.1/24 fe80::a00:27ff:fea0:3759/64 
        enp0s3           UP             10.0.2.15/24 metric 100 fd17:625c:f037:2:a00:27ff:fe5d:a0ce/64 fe80::a00:27ff:fe5d:a0ce/64 
        $ default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
        10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
        10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
        10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
        10.10.10.0/24 dev enp0s9 proto kernel scope link src 10.10.10.1 
        10.10.20.0/24 dev enp0s10 proto kernel scope link src 10.10.20.1 
        10.10.30.0/24 dev enp0s16 proto kernel scope link src 10.10.30.1 
        172.16.0.0/24 dev enp0s8 proto kernel scope link src 172.16.0.2 
        192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 

        Сейчас gateway имеет именно те адреса, которые мы запланировали:
        enp0s8   172.16.0.2/24    WAN
        enp0s9   10.10.10.1/24    LAN
        enp0s10  10.10.20.1/24    DMZ
        enp0s16  10.10.30.1/24    MGMT

        Маршруты к этим четырём подсетям тоже появились:

        172.16.0.0/24  → enp0s8
        10.10.10.0/24  → enp0s9
        10.10.20.0/24  → enp0s10
        10.10.30.0/24  → enp0s16

        Это именно то, чего мы хотели на данном этапе.

        Есть ещё:

        default via 10.0.2.2 dev enp0s3

        и несколько дополнительных маршрутов через enp0s3. Это маршруты Vagrant/cloud-init для технического NAT-интерфейса. Мы их сейчас не трогаем: они не являются частью нашей проектной WAN-топологии.

Теперь идём по этапу 3 дальше и настраиваем upstream-router.
vagrant ssh upstream-router
    sudo nano /etc/netplan/60-lab.yaml
        network:
          version: 2

          ethernets:
            enp0s8:
              addresses:
                - 172.16.0.1/24

            enp0s9:
              addresses:
                - 198.51.100.1/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply

    $ ip -br addr
        lo               UNKNOWN        127.0.0.1/8 ::1/128 
        enp0s8           UNKNOWN        172.16.0.1/24 fe80::a00:27ff:fee7:4dfd/64 
        enp0s9           UNKNOWN        198.51.100.1/24 fe80::a00:27ff:fe8e:6679/64 
        enp0s3           UP             10.0.2.15/24 metric 100 fd17:625c:f037:2:a00:27ff:fe2b:393a/64 fe80::a00:27ff:fe2b:393a/64
    $ ip route
        default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
        10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
        10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
        10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
        172.16.0.0/24 dev enp0s8 proto kernel scope link src 172.16.0.1 
        192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
        198.51.100.0/24 dev enp0s9 proto kernel scope link src 198.51.100.1

Теперь быстро закончим базовую настройку на остальных пяти машинах:

vagrant ssh lan-workstation
    sudo nano /etc/netplan/60-lab.yaml
        network:
          version: 2

          ethernets:
            enp0s8:
              addresses:
                - 10.10.10.10/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply
    ip -br addr
    ip route

vagrant ssh lan-dns-server
    sudo nano /etc/netplan/60-lab.yaml
        network:
          version: 2

          ethernets:
            enp0s8:
              addresses:
                - 10.10.10.53/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply
    ip -br addr
    ip route

vagrant ssh dmz-web-server
sudo nano /etc/netplan/60-lab.yaml
    network:
    version: 2

    ethernets:
      enp0s8:
        addresses:
          - 10.10.20.10/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply
    ip -br addr
    ip route

vagrant ssh mgmt-workstation
    sudo nano /etc/netplan/60-lab.yaml
        network:
        version: 2

        ethernets:
          enp0s8:
            addresses:
              - 10.10.30.10/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply
    ip -br addr

vagrant ssh external-client
    sudo nano /etc/netplan/60-lab.yaml
        network:
        version: 2

        ethernets:
          enp0s8:
            addresses:
              - 198.51.100.10/24
    
    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply
    ip -br addr
    ip route

Да. Теперь переходим к этапу 4 — Routing. На этом этапе мы только строим таблицы маршрутизации. ip_forward и nftables пока не трогаем.

Есть важный нюанс с Vagrant NAT: на конечных VM уже существует default route через enp0s3. Поэтому для проектного default gateway мы зададим меньший metric (50), чем у Vagrant DHCP-маршрута (100). При этом маршрут к 10.0.2.0/24 останется напрямую через enp0s3, так что vagrant ssh продолжит работать.

vagrant ssh linux-gateway

sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
        - 172.16.0.2/24
      routes:
        - to: 198.51.100.0/24
          via: 172.16.0.1
    enp0s9:
      addresses:
        - 10.10.10.1/24
    enp0s10:
      addresses:
        - 10.10.20.1/24
    enp0s16:
      addresses:
        - 10.10.30.1/24
EOF

sudo netplan generate
sudo netplan apply

ip route
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.10.10.0/24 dev enp0s9 proto kernel scope link src 10.10.10.1 
10.10.20.0/24 dev enp0s10 proto kernel scope link src 10.10.20.1 
10.10.30.0/24 dev enp0s16 proto kernel scope link src 10.10.30.1 
172.16.0.0/24 dev enp0s8 proto kernel scope link src 172.16.0.2 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
198.51.100.0/24 via 172.16.0.1 dev enp0s8 proto static

vagrant ssh upstream-router

sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2

  ethernets:
    enp0s8:
      addresses:
        - 172.16.0.1/24
      routes:
        - to: 10.10.10.0/24
          via: 172.16.0.2

        - to: 10.10.20.0/24
          via: 172.16.0.2

        - to: 10.10.30.0/24
          via: 172.16.0.2

    enp0s9:
      addresses:
        - 198.51.100.1/24
EOF

sudo netplan generate
sudo netplan apply

$ ip route
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.10.10.0/24 via 172.16.0.2 dev enp0s8 proto static 
10.10.20.0/24 via 172.16.0.2 dev enp0s8 proto static 
10.10.30.0/24 via 172.16.0.2 dev enp0s8 proto static 
172.16.0.0/24 dev enp0s8 proto kernel scope link src 172.16.0.1 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
198.51.100.0/24 dev enp0s9 proto kernel scope link src 198.51.100.1

Upstream теперь знает, что все внутренние сети находятся за gateway.

vagrant ssh lan-workstation
sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2

  ethernets:
    enp0s8:
      addresses:
        - 10.10.10.10/24
      routes:
        - to: default
          via: 10.10.10.1
          metric: 50
EOF

sudo netplan generate
sudo netplan apply

ip route
default via 10.10.10.1 dev enp0s8 proto static metric 50 
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.10.10.0/24 dev enp0s8 proto kernel scope link src 10.10.10.10 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 

vagrant ssh dmz-web-server
sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2

  ethernets:
    enp0s8:
      addresses:
        - 10.10.20.10/24
      routes:
        - to: default
          via: 10.10.20.1
          metric: 50
EOF

sudo netplan generate
sudo netplan apply

ip route
default via 10.10.20.1 dev enp0s8 proto static metric 50 
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.10.20.0/24 dev enp0s8 proto kernel scope link src 10.10.20.10 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100

vagrant ssh mgmt-workstation
sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2

  ethernets:
    enp0s8:
      addresses:
        - 10.10.30.10/24
      routes:
        - to: default
          via: 10.10.30.1
          metric: 50
EOF

sudo netplan generate
sudo netplan apply

ip route
default via 10.10.30.1 dev enp0s8 proto static metric 50 
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.10.30.0/24 dev enp0s8 proto kernel scope link src 10.10.30.10 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100

vagrant ssh external-client
sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
network:
  version: 2

  ethernets:
    enp0s8:
      addresses:
        - 198.51.100.10/24
      routes:
        - to: default
          via: 198.51.100.1
          metric: 50
EOF

sudo netplan generate
sudo netplan apply

ip route
default via 198.51.100.1 dev enp0s8 proto static metric 50 
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.8.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
192.168.0.1 via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
198.51.100.0/24 dev enp0s8 proto kernel scope link src 198.51.100.10 

На lan-workstation и остальных VM ещё не настроен DNS через 10.10.10.53. Это нормально: мы пока занимаемся routing, а DNS-сервис будет отдельным функциональным слоем.

На данный момент

Vagrant topology      ✓
Interface mapping     ✓
IP addresses          ✓
Connected routes      ✓
Static routes         ✓
Default gateways      ✓

IP forwarding         ✗
nftables              ✗
SNAT                   ✗
DNAT                   ✗

Дополнительные проверки
На external-client: ping -c 3 198.51.100.1
На upstream-router: ping -c 3 172.16.0.2
На linux-gateway: ping -c 3 10.10.10.10 && ping -c 3 10.10.20.10  && ping -c 3 10.10.30.10 && ping -c 3 172.16.0.1

Все должно проходить

