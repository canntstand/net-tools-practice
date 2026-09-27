# Этап 8. SNAT для LAN → External

## Логика

Приватная LAN выходит во внешнюю сеть через один адрес WAN —
`172.16.0.2` на `enp0s8` linux-gateway.

    LAN 10.10.10.10
        │
        ▼
    gateway (10.10.10.1)
        │  SNAT → 172.16.0.2
        ▼
    upstream (172.16.0.1)
        │
        ▼
    external-client (198.51.100.10)

Upstream уже знает маршрут обратно в `10.10.10.0/24` через
`172.16.0.2`, поэтому без NAT трафик тоже мог бы работать.
SNAT добавлен, чтобы воспроизвести типичную схему «приватная
сеть за одним публичным адресом».

## Сохранение текущего рабочего ruleset

До добавления новых правил фиксируем текущее состояние:

    sudo sh -c 'echo "flush ruleset"; nft list ruleset' > /tmp/nftables.conf
    sudo mv /tmp/nftables.conf /etc/nftables.conf
    sudo chmod 600 /etc/nftables.conf
    sudo nft -c -f /etc/nftables.conf

## Разрешение LAN → External в FORWARD

    sudo nft add rule ip filter forward \
        ip saddr 10.10.10.0/24 \
        ip daddr 198.51.100.0/24 \
        ct state new \
        accept

## Создание таблицы nat и цепочки postrouting

    sudo nft add table ip nat

    sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority srcnat; policy accept; }'

## Правило SNAT

    sudo nft add rule ip nat postrouting \
        oifname "enp0s8" \
        ip saddr 10.10.10.0/24 \
        ip daddr 198.51.100.0/24 \
        snat to 172.16.0.2

Проверка:

    sudo nft list table ip nat

## Проверка с tcpdump

На external-client:

    sudo tcpdump -ni enp0s8 icmp

На lan-workstation:

    ping -c 3 198.51.100.10

На стороне external-client видим пакеты именно от `172.16.0.2`:

    11:10:50 IP 172.16.0.2 > 198.51.100.10: ICMP echo request
    11:10:50 IP 198.51.100.10 > 172.16.0.2: ICMP echo reply

## Сохранение конфигурации

    sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
    sudo chmod 600 /etc/nftables.conf
    sudo nft -c -f /etc/nftables.conf
    sudo systemctl restart nftables

Итоговая проверка:

    vagrant ssh lan-workstation -c 'ping -c 3 198.51.100.10'

Ожидаем 0% потерь.