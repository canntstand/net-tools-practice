# Этап 13. Финальная проверка стенда

## Сохранение окончательного ruleset

    vagrant ssh linux-gateway

    sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
    sudo chmod 600 /etc/nftables.conf
    sudo nft -c -f /etc/nftables.conf
    sudo systemctl restart nftables

    sudo nft list ruleset

## Ожидаемая структура

    table ip filter {
        chain input {
            type filter hook input priority filter; policy drop;
            iifname "lo" accept
            ct state established,related accept
            iifname "enp0s3" tcp dport 22 accept
            ip saddr 10.10.30.0/24 tcp dport 22 accept
            ip saddr 10.10.30.0/24 icmp type echo-request accept
        }

        chain forward {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ip saddr 10.10.10.0/24 ip daddr 10.10.20.10 tcp dport 80 ct state new accept
            ip saddr 10.10.10.0/24 ip daddr 198.51.100.0/24 ct state new accept
            iifname "enp0s8" oifname "enp0s10" ip saddr 198.51.100.0/24 ip daddr 10.10.20.10 tcp dport 80 ct state new accept
            iifname "enp0s10" oifname "enp0s9" ip saddr 10.10.20.0/24 ip daddr 10.10.10.53 udp dport 53 ct state new accept
            iifname "enp0s10" oifname "enp0s9" ip saddr 10.10.20.0/24 ip daddr 10.10.10.53 tcp dport 53 ct state new accept
            iifname "enp0s10" oifname "enp0s8" ip saddr 10.10.20.0/24 ip daddr 198.51.100.0/24 tcp dport 80 ct state new accept
            iifname "enp0s10" oifname "enp0s8" ip saddr 10.10.20.0/24 ip daddr 198.51.100.0/24 tcp dport 443 ct state new accept
            iifname "enp0s16" oifname "enp0s9" ip saddr 10.10.30.0/24 ip daddr 10.10.10.0/24 tcp dport 22 ct state new accept
            iifname "enp0s16" oifname "enp0s9" ip saddr 10.10.30.0/24 ip daddr 10.10.10.0/24 icmp type echo-request ct state new accept
            iifname "enp0s16" oifname "enp0s10" ip saddr 10.10.30.0/24 ip daddr 10.10.20.0/24 tcp dport 22 ct state new accept
            iifname "enp0s16" oifname "enp0s10" ip saddr 10.10.30.0/24 ip daddr 10.10.20.0/24 icmp type echo-request ct state new accept
        }

        chain output {
            type filter hook output priority filter; policy accept;
        }
    }

    table ip nat {
        chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname "enp0s8" ip saddr 10.10.10.0/24 ip daddr 198.51.100.0/24 snat to 172.16.0.2
        }

        chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            iifname "enp0s8" ip saddr 198.51.100.0/24 tcp dport 80 dnat to 10.10.20.10:80
        }
    }

## Acceptance-тесты

### LAN → DMZ:80

    vagrant ssh lan-workstation -c \
      'curl --connect-timeout 5 http://10.10.20.10'

Ожидаем 200 OK.

### LAN → External

    vagrant ssh lan-workstation -c \
      'ping -c 3 198.51.100.10'

Ожидаем 0% потерь (SNAT).

### LAN → Gateway:22 (запрещено)

    vagrant ssh lan-workstation -c \
      'nc -vz -w 3 10.10.10.1 22'

Ожидаем timeout.

### External → DMZ через DNAT

    vagrant ssh external-client -c \
      'curl --connect-timeout 5 http://172.16.0.2'

Ожидаем HTML Nginx.

### External → LAN (запрещено)

    vagrant ssh external-client -c \
      'nc -vz -w 3 10.10.10.10 22'

Ожидаем timeout.

### External → MGMT (запрещено)

    vagrant ssh external-client -c \
      'nc -vz -w 3 10.10.30.10 22'

Ожидаем timeout.

### DMZ → LAN (запрещено)

    vagrant ssh dmz-web-server -c 'ping -c 3 10.10.10.10'

Ожидаем 100% packet loss.

### DMZ → DNS:53 (разрешено)

    vagrant ssh dmz-web-server -c 'dig @10.10.10.53 web.lab +short'

Ожидаем `10.10.20.10`.

### DMZ → External:80 (разрешено)

На external-client должен быть запущен HTTP-сервер:

    sudo python3 -m http.server 80 --bind 198.51.100.10

С dmz-web-server:

    vagrant ssh dmz-web-server -c 'curl --connect-timeout 5 http://198.51.100.10'

### MGMT → Gateway

    vagrant ssh mgmt-workstation -c 'ping -c 3 10.10.30.1'

### MGMT → LAN

    vagrant ssh mgmt-workstation -c 'nc -vz -w 3 10.10.10.10 22'

### MGMT → DMZ

    vagrant ssh mgmt-workstation -c 'nc -vz -w 3 10.10.20.10 22'

## Состояние проекта

    Vagrant / VirtualBox        ✓
    Netplan                     ✓
    Routing                     ✓
    IP forwarding               ✓
    Stateful nftables           ✓
    SNAT                        ✓
    DNAT                        ✓
    DMZ isolation               ✓
    MGMT segmentation           ✓
    DNS                         ✓
    Persistence after restart   ✓
    Acceptance test             ✓

## Карта правил (итог)

    table ip filter
    ├── input
    │   ├── loopback
    │   ├── established,related
    │   ├── Vagrant SSH (enp0s3)
    │   └── MGMT → gateway SSH/ICMP
    │
    ├── forward
    │   ├── established,related
    │   ├── LAN → DMZ:80
    │   ├── LAN → External
    │   ├── External → DMZ:80 (после DNAT)
    │   ├── DMZ → DNS:53/udp
    │   ├── DMZ → DNS:53/tcp
    │   ├── DMZ → External:80
    │   ├── DMZ → External:443
    │   ├── MGMT → LAN:22/ICMP
    │   └── MGMT → DMZ:22/ICMP
    │
    └── output → ACCEPT

    table ip nat
    ├── prerouting
    │   └── External:80 → 10.10.20.10:80
    │
    └── postrouting
        └── LAN → External → SNAT 172.16.0.2