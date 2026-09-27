# Этап 11. Доступ из MGMT-сегмента

## Целевая политика

    MGMT → Gateway   SSH + ICMP
    MGMT → LAN       SSH + ICMP
    MGMT → DMZ       SSH + ICMP

Обратный доступ (LAN/DMZ → MGMT) не разрешается.
Доступ MGMT → Gateway (SSH/ICMP) уже настроен в цепочке INPUT
на предыдущем шаге.

## MGMT → LAN

    vagrant ssh linux-gateway

    # SSH
    sudo nft add rule ip filter forward \
        iifname "enp0s16" \
        oifname "enp0s9" \
        ip saddr 10.10.30.0/24 \
        ip daddr 10.10.10.0/24 \
        tcp dport 22 \
        ct state new \
        accept

    # ICMP
    sudo nft add rule ip filter forward \
        iifname "enp0s16" \
        oifname "enp0s9" \
        ip saddr 10.10.30.0/24 \
        ip daddr 10.10.10.0/24 \
        icmp type echo-request \
        ct state new \
        accept

## MGMT → DMZ

    # SSH
    sudo nft add rule ip filter forward \
        iifname "enp0s16" \
        oifname "enp0s10" \
        ip saddr 10.10.30.0/24 \
        ip daddr 10.10.20.0/24 \
        tcp dport 22 \
        ct state new \
        accept

    # ICMP
    sudo nft add rule ip filter forward \
        iifname "enp0s16" \
        oifname "enp0s10" \
        ip saddr 10.10.30.0/24 \
        ip daddr 10.10.20.0/24 \
        icmp type echo-request \
        ct state new \
        accept

## Проверка

    vagrant ssh mgmt-workstation -c \
      'ping -c 3 10.10.30.1 && ping -c 3 10.10.10.10 && ping -c 3 10.10.20.10'

    vagrant ssh mgmt-workstation -c \
      'nc -vz -w 3 10.10.30.1 22 && nc -vz -w 3 10.10.10.10 22 && nc -vz -w 3 10.10.20.10 22'

Ожидаем все шесть успешных проверок.

Проверка изоляции: с lan-workstation доступ к MGMT не должен
проходить.

    vagrant ssh lan-workstation -c 'nc -vz -w 3 10.10.30.10 22'

Ожидаем timeout.

## Удаление случайного дубликата

При ручном вводе правил легко создать дубликат. Посмотреть handles:

    sudo nft -a list chain ip filter forward

Удалить лишнее правило по handle:

    sudo nft delete rule ip filter forward handle <N>