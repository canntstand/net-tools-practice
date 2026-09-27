# Network Tools Practice
Создаю изолированный сетевой стенд из нескольких Linux-машин: WAN, LAN, DMZ, MGMT и внешнего клиента, связанный через Linux-шлюз для статьи «Многосегментный Linux-маршрутизатор на Netplan и Nftables: DMZ, SNAT/DNAT, MGMT, диагностика и многое другое» на Хабр.

На практике настраиваю маршрутизацию и firewall с помощью Netplan, nftables и iptables, а затем проверяю работу сети и диагностирую трафик с помощью ip, ss, tcpdump, conntrack и других инструментов.

## Пошаговое руководство

Подробное описание всех этапов построения стенда — в каталоге [`docs/`](docs/).
Файлы упорядочены по номерам, каждый посвящён одному шагу.

| Файл | О чём |
|---|---|
| [`docs/00-overview.md`](docs/00-overview.md) | Обзор стенда: топология, сегменты, роли VM, принципы построения. |
| [`docs/01-vagrant-and-interfaces.md`](docs/01-vagrant-and-interfaces.md) | Проверка `vagrant status`, карта интерфейсов на всех VM, пояснение про `enp0s16` и `auto_config: false`. |
| [`docs/02-netplan-ip.md`](docs/02-netplan-ip.md) | Назначение IP-адресов лабораторным интерфейсам через Netplan на всех 7 машинах. |
| [`docs/03-routing.md`](docs/03-routing.md) | Статические маршруты и шлюзы по умолчанию с учётом метрик Vagrant NAT. |
| [`docs/04-ip-forwarding.md`](docs/04-ip-forwarding.md) | Включение `net.ipv4.ip_forward` на gateway и upstream, baseline-проверки без firewall. |
| [`docs/05-baseline-and-nginx.md`](docs/05-baseline-and-nginx.md) | Установка Nginx в DMZ и фиксация того, что было разрешено до nftables. |
| [`docs/06-nftables-basic.md`](docs/06-nftables-basic.md) | Базовый ruleset: `INPUT DROP`, `FORWARD DROP`, `OUTPUT ACCEPT`, доступ из MGMT и Vagrant NAT. |
| [`docs/07-stateful-conntrack.md`](docs/07-stateful-conntrack.md) | Stateful-фильтрация: `ct state established,related`, наблюдение conntrack, первый разрешённый поток LAN → Web:80. |
| [`docs/08-snat.md`](docs/08-snat.md) | SNAT для LAN → External: `table ip nat`, postrouting, проверка через tcpdump. |
| [`docs/09-dnat.md`](docs/09-dnat.md) | DNAT для External → DMZ: `prerouting`, `dnat to 10.10.20.10:80`, разрешение в FORWARD, диагностика. |
| [`docs/10-dmz-rules.md`](docs/10-dmz-rules.md) | Правила сегмента DMZ: DNS:53, External:80/443, изоляция от LAN и MGMT. |
| [`docs/11-mgmt-access.md`](docs/11-mgmt-access.md) | Доступ MGMT → LAN и MGMT → DMZ (SSH + ICMP), удаление дубликатов правил. |
| [`docs/12-dns.md`](docs/12-dns.md) | Минимальный dnsmasq в LAN, настройка клиента в DMZ, разбор ошибки с обратным маршрутом. |
| [`docs/13-final-acceptance.md`](docs/13-final-acceptance.md) | Итоговый ruleset и полный acceptance-тест всех сценариев стенда. |

## Порядок прохождения

Файлы удобно читать и выполнять последовательно: от `00-overview.md`
до `13-final-acceptance.md`. Каждый шаг опирается на предыдущий,
а промежуточные чек-листы в конце этапов позволяют убедиться, что
состояние стенда соответствует ожидаемому.

## Стек

- Vagrant + VirtualBox
- Ubuntu 24.04 (cloud-image)
- Netplan + systemd-networkd
- nftables + conntrack
- dnsmasq, nginx
- Диагностика: `ip`, `ss`, `tcpdump`, `conntrack`, `dig`, `resolvectl`, `nc`

## Некоторые схемы работы:

![Схема 1](images/1.png)
![Схема 2](images/2.png)
![Схема 3](images/3.png)