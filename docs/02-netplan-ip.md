# Этап 2. Назначение IP-адресов через Netplan

На этом этапе задаются только IP-адреса лабораторных интерфейсов.
Маршруты, DNS и forwarding не настраиваются.

## linux-gateway

Проверяем содержимое `/etc/netplan/`:

    vagrant ssh linux-gateway
    ls -la /etc/netplan/

Файл `50-cloud-init.yaml` управляет только техническим NAT-интерфейсом
`enp0s3` (DHCP). Лабораторные интерфейсы в нём не описаны, поэтому
добавляем отдельный файл `60-lab.yaml`.

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

Права и применение:

    sudo chmod 600 /etc/netplan/60-lab.yaml
    sudo netplan generate
    sudo netplan apply

Проверка:

    ip -br addr
    ip route

Ожидаем увидеть адреса 172.16.0.2, 10.10.10.1, 10.10.20.1, 10.10.30.1
и connected-маршруты к соответствующим подсетям через `enp0s8`,
`enp0s9`, `enp0s10`, `enp0s16`.

Маршруты через `enp0s3` (NAT) остаются как есть и не затрагиваются.

## upstream-router

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

Проверка: `ip -br addr`, `ip route`.

## lan-workstation

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

## lan-dns-server

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

## dmz-web-server

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

## mgmt-workstation

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

## external-client

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

## Итог этапа

| Узел              | Адрес                        |
|-------------------|------------------------------|
| linux-gateway     | 172.16.0.2, 10.10.10.1, 10.10.20.1, 10.10.30.1 |
| upstream-router   | 172.16.0.1, 198.51.100.1     |
| lan-workstation   | 10.10.10.10                  |
| lan-dns-server    | 10.10.10.53                  |
| dmz-web-server    | 10.10.20.10                  |
| mgmt-workstation  | 10.10.30.10                  |
| external-client   | 198.51.100.10                |