# Этап 6. Базовый nftables

На этом этапе устанавливаются политики:

    INPUT   → DROP
    FORWARD → DROP
    OUTPUT  → ACCEPT

Дополнительно явно разрешается доступ через технический
NAT-интерфейс `enp0s3` (SSH), иначе после применения правил
можно потерять `vagrant ssh`.

Управляющий доступ из MGMT-сети (SSH, ICMP) разрешается уже здесь.

## Установка

    vagrant ssh linux-gateway
    sudo apt update
    sudo apt install -y nftables

## Базовый ruleset

    sudo tee /etc/nftables.conf > /dev/null <<'EOF'
    flush ruleset

    table ip filter {

        chain input {
            type filter hook input priority filter; policy drop;

            # Loopback
            iifname "lo" accept

            # Уже установленные соединения
            ct state established,related accept

            # Технический Vagrant NAT (SSH)
            iifname "enp0s3" tcp dport 22 accept

            # Управляющая сеть: SSH и ICMP на шлюз
            ip saddr 10.10.30.0/24 tcp dport 22 accept
            ip saddr 10.10.30.0/24 icmp type echo-request accept
        }

        chain forward {
            type filter hook forward priority filter; policy drop;

            # На этом шаге ни одно новое соединение не разрешено.
        }

        chain output {
            type filter hook output priority filter; policy accept;
        }
    }
    EOF

## Проверка и применение

    sudo nft -c -f /etc/nftables.conf
    sudo nft -f /etc/nftables.conf
    sudo nft list ruleset

## Автозагрузка

    sudo systemctl enable nftables
    sudo systemctl restart nftables
    sudo systemctl status nftables --no-pager

Ожидаем `active (exited)`.

## Что изменилось

FORWARD теперь `policy drop`, поэтому любой форвардинг запрещён:

    LAN      → DMZ       DENY
    LAN      → External  DENY
    DMZ      → LAN       DENY
    DMZ      → External  DENY
    EXTERNAL → DMZ       DENY
    MGMT     → LAN       DENY

При этом сам шлюз доступен:

    Vagrant  → gateway:22    ALLOW
    MGMT     → gateway:22    ALLOW
    MGMT     → gateway:ICMP  ALLOW

## Проверка

    # Должно перестать работать
    vagrant ssh external-client  -c 'curl --connect-timeout 3 http://10.10.20.10'
    vagrant ssh lan-workstation  -c 'curl --connect-timeout 3 http://10.10.20.10'
    vagrant ssh lan-workstation  -c 'ping -c 3 10.10.10.1'

    # Должно продолжать работать
    vagrant ssh mgmt-workstation -c 'ping -c 3 10.10.30.1'
    vagrant ssh mgmt-workstation -c 'nc -vz 10.10.30.1 22'