# Этап 12. DNS-сервер в LAN

Цель — компактный DNS-сервер, который отдаёт только несколько
локальных записей. Полноценный DNS-проект не требуется.

## Установка dnsmasq на lan-dns-server

    vagrant ssh lan-dns-server
    sudo apt update
    sudo apt install -y dnsmasq

## Конфигурация

    sudo tee /etc/dnsmasq.d/lab.conf > /dev/null <<'EOF'
    # Слушать только интерфейс LAN
    interface=enp0s8
    listen-address=10.10.10.53
    bind-interfaces

    port=53
    no-resolv

    # Локальные записи
    address=/web.lab/10.10.20.10
    address=/gateway.lab/10.10.10.1
    EOF

Здесь намеренно нет upstream DNS: создаётся автономная зона
для лаборатории.

## Запуск

    sudo systemctl restart dnsmasq
    sudo systemctl enable dnsmasq
    sudo systemctl status dnsmasq --no-pager
    sudo ss -lntup | grep ':53'

## Локальная проверка резолвинга

    dig @10.10.10.53 web.lab +short
    dig @10.10.10.53 gateway.lab +short

Ожидаемые ответы: `10.10.20.10` и `10.10.10.1`.

## Настройка клиента: dmz-web-server

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

          nameservers:
            addresses:
              - 10.10.10.53
    EOF

    sudo netplan generate
    sudo netplan apply

Проверка:

    resolvectl status enp0s8

Ожидаем `DNS Servers: 10.10.10.53`.

## Проверка резолвинга на клиенте

    resolvectl query web.lab
    resolvectl query gateway.lab
    dig @10.10.10.53 web.lab +short
    curl http://web.lab

## Возможная ошибка: нет маршрута обратно в DMZ

Если на lan-dns-server не настроен маршрут по умолчанию через
linux-gateway, ответы будут уходить через Vagrant NAT (`10.0.2.2`),
и клиент из DMZ не получит ответ.

Симптом: пакет DMZ → DNS:53 доходит до сервера (видно tcpdump на
linux-gateway), но ответ не приходит.

Проверка на lan-dns-server:

    ip route

Если в выводе нет default via 10.10.10.1 — добавить его:

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2

      ethernets:
        enp0s8:
          addresses:
            - 10.10.10.53/24

          routes:
            - to: default
              via: 10.10.10.1
              metric: 50
    EOF

    sudo netplan generate
    sudo netplan apply

После этого проверки с dmz-web-server должны проходить.

## Итог этапа

    web.lab       → 10.10.20.10
    gateway.lab   → 10.10.10.1

Доступ DMZ → DNS:53 уже разрешён правилами в FORWARD
(см. `10-dmz-rules.md`).