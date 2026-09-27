# Этап 5. Baseline без firewall и веб-сервис в DMZ

## Установка Nginx на dmz-web-server

    vagrant ssh dmz-web-server
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl status nginx --no-pager
    ss -tulpn | grep ':80'

Nginx слушает `0.0.0.0:80`.

## Проверка доступности Nginx до firewall

    # С lan-workstation
    vagrant ssh lan-workstation -c 'curl http://10.10.20.10'

    # С external-client
    vagrant ssh external-client -c 'curl http://10.10.20.10'

Оба запроса должны вернуть HTML Nginx.

## Какая политика действует сейчас

Так как Netfilter ещё не настроен:

    INPUT    → разрешено
    FORWARD  → разрешено
    OUTPUT   → разрешено

Поэтому фактически разрешены:

    LAN      → DMZ       ✓
    DMZ      → LAN       ✓
    EXTERNAL → DMZ       ✓
    MGMT     → LAN       ✓
    MGMT     → DMZ       ✓

Baseline зафиксирован. На следующем этапе поверх этой работающей
маршрутизации накладываются ограничения nftables.