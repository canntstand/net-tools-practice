# Этап 4. IP forwarding

Forwarding включается на двух машинах:

- `linux-gateway` — между WAN и внутренними сегментами;
- `upstream-router` — между lab-internet и lab-wan.

Без forwarding пакет не проходит более одного L3-хопа, поэтому
маршрутизация сама по себе работать не будет.

Firewall на этом этапе ещё отсутствует — это сделано специально,
чтобы отдельно зафиксировать рабочую маршрутизацию и уже потом
наложить на неё ограничения Netfilter.

## linux-gateway

    vagrant ssh linux-gateway

    sudo tee /etc/sysctl.d/99-ipforward.conf > /dev/null <<'EOF'
    net.ipv4.ip_forward=1
    EOF

    sudo sysctl --system
    sysctl net.ipv4.ip_forward

Ожидаем `net.ipv4.ip_forward = 1`.

## upstream-router

    vagrant ssh upstream-router

    sudo tee /etc/sysctl.d/99-ipforward.conf > /dev/null <<'EOF'
    net.ipv4.ip_forward=1
    EOF

    sudo sysctl --system
    sysctl net.ipv4.ip_forward

## Базовые проверки связности

Проверка локальных шлюзов:

    # С external-client до upstream
    vagrant ssh external-client -c 'ping -c 3 198.51.100.1'

    # С upstream до gateway
    vagrant ssh upstream-router -c 'ping -c 3 172.16.0.2'

    # С gateway до всех внутренних узлов
    vagrant ssh linux-gateway -c \
      'ping -c 3 10.10.10.10 && \
       ping -c 3 10.10.20.10 && \
       ping -c 3 10.10.30.10 && \
       ping -c 3 172.16.0.1'

## Baseline: маршрутизация без firewall

Сейчас firewall ещё отсутствует, поэтому проверяем end-to-end:

    # External → DMZ
    vagrant ssh external-client -c 'ping -c 3 10.10.20.10'

    # LAN → DMZ
    vagrant ssh lan-workstation -c 'ping -c 3 10.10.20.10'

    # DMZ → LAN и DMZ → MGMT
    vagrant ssh dmz-web-server -c \
      'ping -c 3 10.10.10.10 && ping -c 3 10.10.30.10'

Все проверки должны проходить. Это ожидаемое поведение: мы
зафиксировали рабочую маршрутизацию в чистом виде, до появления
nftables.

## Состояние на конец этапа

    Vagrant topology       ✓
    Interface mapping      ✓
    IP addresses           ✓
    Connected routes       ✓
    Static routes          ✓
    Default gateways       ✓
    IP forwarding          ✓
    nftables               ✗
    SNAT                   ✗
    DNAT                   ✗