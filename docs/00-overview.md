# Network Tools Practice — обзор стенда

Изолированный сетевой стенд на базе Vagrant + VirtualBox.
Состоит из 7 Linux-машин (Ubuntu 24.04), связанных через Linux-шлюз
и эмулируемого «провайдера» (upstream-router).

## Топология

    external-client (198.51.100.10)
            |
            | lab-internet 198.51.100.0/24
            |
    upstream-router (198.51.100.1 / 172.16.0.1)
            |
            | lab-wan 172.16.0.0/24
            |
    linux-gateway (172.16.0.2)
       |         |         |
       |         |         |
    lab-lan   lab-dmz   lab-mgmt
   10.10.10.0 10.10.20.0 10.10.30.0
       |         |         |
    lan-*     dmz-web   mgmt-workstation
    dns-*

## Сегменты

| Сегмент      | Подсеть          | Шлюз          |
|--------------|------------------|---------------|
| lab-internet | 198.51.100.0/24  | 198.51.100.1  |
| lab-wan      | 172.16.0.0/24    | 172.16.0.1    |
| lab-lan      | 10.10.10.0/24    | 10.10.10.1    |
| lab-dmz      | 10.10.20.0/24    | 10.10.20.1    |
| lab-mgmt     | 10.10.30.0/24    | 10.10.30.1    |

## Узлы

| VM                | Роль                                |
|-------------------|-------------------------------------|
| upstream-router   | Имитация провайдера (2 L3-интерфейса) |
| linux-gateway     | Основной шлюз + firewall            |
| lan-workstation   | Рабочая станция в LAN               |
| lan-dns-server    | DNS-сервер в LAN                    |
| dmz-web-server    | Nginx в DMZ                         |
| mgmt-workstation  | Админская станция                   |
| external-client   | Внешний клиент                      |

## Технический интерфейс Vagrant NAT

На каждой VM первый NIC (`enp0s3`) — это NAT-интерфейс VirtualBox.
Он используется только для `vagrant ssh` и не входит в проектную
топологию. Маршрут по умолчанию через `10.0.2.2` сохраняется на
всех VM, чтобы доступ по SSH не пропадал.

## Принципы построения

- В `Vagrantfile` не задаются IP-адреса интерфейсов — только NIC
  с `auto_config: false`. Адресация полностью настраивается через
  Netplan внутри гостевых систем.
- Маршрутизация и firewall строятся пошагово, чтобы на каждом этапе
  было видно, какой механизм за что отвечает.
- Firewall — stateful (nftables + conntrack).
- NAT разделён на SNAT (LAN → External) и DNAT (External → DMZ).