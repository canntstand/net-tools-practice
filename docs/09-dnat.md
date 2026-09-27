# Этап 9. DNAT для External → DMZ

## Логика

    External Client 198.51.100.10
          │  TCP/80 → 172.16.0.2:80
          ▼
    linux-gateway
          │  DNAT
          ▼
    dmz-web-server 10.10.20.10:80

Разделение ответственности:

- PREROUTING — изменить destination (DNAT);
- FORWARD    — решить, разрешён ли транзит;
- POSTROUTING — обработка исходящего (SNAT для LAN).

## Создание цепочки prerouting

    vagrant ssh linux-gateway

    sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority dstnat; policy accept; }'
    sudo nft list table ip nat

## Правило DNAT

    sudo nft add rule ip nat prerouting \
        iifname "enp0s8" \
        ip saddr 198.51.100.0/24 \
        tcp dport 80 \
        dnat to 10.10.20.10:80

    sudo nft list chain ip nat prerouting

## Разрешение трафика в FORWARD

После DNAT destination уже `10.10.20.10`, поэтому в FORWARD
разрешается именно этот адрес:

    sudo nft add rule ip filter forward \
        iifname "enp0s8" \
        oifname "enp0s10" \
        ip saddr 198.51.100.0/24 \
        ip daddr 10.10.20.10 \
        tcp dport 80 \
        ct state new \
        accept

## Проверка

На external-client:

    curl --connect-timeout 5 http://172.16.0.2

Должен вернуться HTML Nginx.

Диагностика на gateway одновременно в двух окнах:

    sudo tcpdump -ni enp0s8 tcp port 80
    sudo tcpdump -ni enp0s10 tcp port 80

На `enp0s8` видим пакет к `172.16.0.2:80`, на `enp0s10` — уже
к `10.10.20.10:80`. Это визуальное подтверждение работы DNAT.

## Сохранение конфигурации

    sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
    sudo chmod 600 /etc/nftables.conf
    sudo nft -c -f /etc/nftables.conf
    sudo systemctl restart nftables

## Модель после этого этапа

    External → Gateway:80
          ↓
       PREROUTING
          ↓
         DNAT
          ↓
       10.10.20.10:80
          ↓
        FORWARD
          ↓
      dmz-web-server