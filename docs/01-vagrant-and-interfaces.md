# Этап 1. Проверка топологии и карта интерфейсов

## Проверка состояния машин

    vagrant status

Ожидаемые состояния: все 7 машин `running`.

## Просмотр интерфейсов на всех VM

Имена лабораторных интерфейсов зависят от PCI-раскладки VirtualBox
и не обязаны совпадать с порядком NIC в Vagrantfile. Поэтому
карта интерфейсов снимается с каждой машины отдельно.

    for vm in upstream-router linux-gateway lan-workstation lan-dns-server \
              dmz-web-server mgmt-workstation external-client; do
        echo "===== $vm ====="
        vagrant ssh "$vm" -c 'ip -br link'
    done

## Карта интерфейсов

| VM                | enp0s3            | enp0s8   | enp0s9        | enp0s10 | enp0s16 |
|-------------------|-------------------|----------|---------------|---------|---------|
| upstream-router   | Vagrant NAT       | lab-wan  | lab-internet  | —       | —       |
| linux-gateway     | Vagrant NAT       | lab-wan  | lab-lan       | lab-dmz | lab-mgmt|
| lan-workstation   | Vagrant NAT       | lab-lan  | —             | —       | —       |
| lan-dns-server    | Vagrant NAT       | lab-lan  | —             | —       | —       |
| dmz-web-server    | Vagrant NAT       | lab-dmz  | —             | —       | —       |
| mgmt-workstation  | Vagrant NAT       | lab-mgmt | —             | —       | —       |
| external-client   | Vagrant NAT       | lab-internet | —         | —       | —       |

### Замечание про enp0s16

На `linux-gateway` четвёртый лабораторный интерфейс получил имя
`enp0s16`, а не `enp0s11`. Это нормально: имя интерфейса в Linux
определяется PCI-слотом виртуального устройства. Важна роль NIC,
а не его порядковый номер.

## Состояние лабораторных интерфейсов

Так как в Vagrantfile у них выставлено `auto_config: false`,
до настройки Netplan они находятся в состоянии `DOWN`:

    enp0s8   DOWN
    enp0s9   DOWN
    enp0s10  DOWN
    enp0s16  DOWN

Это ожидаемо: адреса будут назначены на следующем этапе.