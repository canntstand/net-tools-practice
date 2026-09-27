# Этап 10. Правила сегмента DMZ

## Целевая политика

    DMZ → LAN            DENY (default drop)
    DMZ → MGMT           DENY (default drop)
    DMZ → DNS:53         ALLOW
    DMZ → External:80    ALLOW
    DMZ → External:443   ALLOW

Отдельные правила `drop` для DMZ → LAN и DMZ → MGMT не нужны:
в FORWARD уже стоит `policy drop`, поэтому любой поток без явного
`accept` блокируется автоматически.

## Разрешение DMZ → DNS

DNS может использовать UDP и TCP. Открываем оба:

    vagrant ssh linux-gateway

    sudo nft add rule ip filter forward \
        iifname "enp0s10" \
        oifname "enp0s9" \
        ip saddr 10.10.20.0/24 \
        ip daddr 10.10.10.53 \
        udp dport 53 \
        ct state new \
        accept

    sudo nft add rule ip filter forward \
        iifname "enp0s10" \
        oifname "enp0s9" \
        ip saddr 10.10.20.0/24 \
        ip daddr 10.10.10.53 \
        tcp dport 53 \
        ct state new \
        accept

## Разрешение DMZ → External:80

    sudo nft add rule ip filter forward \
        iifname "enp0s10" \
        oifname "enp0s8" \
        ip saddr 10.10.20.0/24 \
        ip daddr 198.51.100.0/24 \
        tcp dport 80 \
        ct state new \
        accept

## Разрешение DMZ → External:443

    sudo nft add rule ip filter forward \
        iifname "enp0s10" \
        oifname "enp0s8" \
        ip saddr 10.10.20.0/24 \
        ip daddr 198.51.100.0/24 \
        tcp dport 443 \
        ct state new \
        accept

## Проверка порядка правил

    sudo nft list chain ip filter forward

Ожидаемая структура:

    ct state established,related accept
    LAN → DMZ:80
    LAN → External
    External → DMZ:80
    DMZ → DNS:53/udp
    DMZ → DNS:53/tcp
    DMZ → External:80
    DMZ → External:443
    policy drop

## Проверка запретов

    # DMZ → LAN — должно быть заблокировано
    vagrant ssh dmz-web-server -c 'ping -c 3 10.10.10.10'
    vagrant ssh dmz-web-server -c 'nc -vz -w 3 10.10.10.10 22'

Ожидаем 100% packet loss и timeout.

## Проверка разрешения DMZ → External:80

На external-client временно поднимаем HTTP-сервер:

    sudo python3 -m http.server 80 --bind 198.51.100.10

С dmz-web-server:

    curl http://198.51.100.10

Должен прийти ответ. SNAT для DMZ при этом не нужен:
upstream знает маршрут `10.10.20.0/24 via 172.16.0.2`, поэтому
`198.51.100.10` вернёт ответ напрямую через upstream.

## Модель DMZ

    DMZ
     │
     ├── DNS:53/udp/tcp        → 10.10.10.53      ALLOW
     ├── HTTP:80               → 198.51.100.0/24  ALLOW
     ├── HTTPS:443             → 198.51.100.0/24  ALLOW
     └── всё остальное         → DROP (default)