# Этап 3. Маршрутизация

На этом этапе строятся статические маршруты и шлюзы по умолчанию.
IP forwarding и nftables ещё не трогаем.

## Важный нюанс с Vagrant NAT

На всех VM уже есть default-маршрут через `10.0.2.2` (NAT),
полученный по DHCP. Чтобы проектный шлюз имел приоритет, ему
назначается меньшая метрика (50), чем у DHCP-маршрута (100).
Маршрут к `10.0.2.0/24` остаётся напрямую через `enp0s3`, поэтому
`vagrant ssh` продолжает работать.

## linux-gateway

    vagrant ssh linux-gateway

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2
      renderer: networkd
      ethernets:
        enp0s8:
          addresses:
            - 172.16.0.2/24
          routes:
            # Маршрут к внешней сети через upstream-router
            - to: 198.51.100.0/24
              via: 172.16.0.1
        enp0s9:
          addresses:
            - 10.10.10.1/24
        enp0s10:
          addresses:
            - 10.10.20.1/24
        enp0s16:
          addresses:
            - 10.10.30.1/24
    EOF

    sudo netplan generate
    sudo netplan apply

Проверка `ip route`: должны появиться connected-маршруты к
LAN/DMZ/MGMT/WAN и статический маршрут `198.51.100.0/24 via 172.16.0.1`.

## upstream-router

Upstream знает, что все внутренние подсети находятся за gateway
(`172.16.0.2` на `enp0s8`).

    vagrant ssh upstream-router

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2

      ethernets:
        enp0s8:
          addresses:
            - 172.16.0.1/24
          routes:
            # Внутренние подсети за linux-gateway
            - to: 10.10.10.0/24
              via: 172.16.0.2
            - to: 10.10.20.0/24
              via: 172.16.0.2
            - to: 10.10.30.0/24
              via: 172.16.0.2

        enp0s9:
          addresses:
            - 198.51.100.1/24
    EOF

    sudo netplan generate
    sudo netplan apply

Проверка `ip route`: три статических маршрута через `172.16.0.2`.

## lan-workstation

    vagrant ssh lan-workstation

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2

      ethernets:
        enp0s8:
          addresses:
            - 10.10.10.10/24
          routes:
            # Проектный шлюз — linux-gateway
            - to: default
              via: 10.10.10.1
              metric: 50
    EOF

    sudo netplan generate
    sudo netplan apply

## dmz-web-server

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
    EOF

    sudo netplan generate
    sudo netplan apply

## mgmt-workstation

    vagrant ssh mgmt-workstation

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2

      ethernets:
        enp0s8:
          addresses:
            - 10.10.30.10/24
          routes:
            - to: default
              via: 10.10.30.1
              metric: 50
    EOF

    sudo netplan generate
    sudo netplan apply

## external-client

    vagrant ssh external-client

    sudo tee /etc/netplan/60-lab.yaml > /dev/null <<'EOF'
    network:
      version: 2

      ethernets:
        enp0s8:
          addresses:
            - 198.51.100.10/24
          routes:
            - to: default
              via: 198.51.100.1
              metric: 50
    EOF

    sudo netplan generate
    sudo netplan apply

## lan-dns-server

Для DNS-сервера на этом этапе достаточно default-шлюза через
linux-gateway — он понадобится позже, когда DNS начнёт отвечать
клиентам из DMZ.

    vagrant ssh lan-dns-server

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

## Итог этапа

- Все узлы знают свой проектный default gateway.
- linux-gateway знает маршрут к внешней сети.
- upstream-router знает маршруты ко всем внутренним подсетям.
- IP forwarding ещё выключен, firewall ещё отсутствует.