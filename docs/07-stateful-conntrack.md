# Этап 7. Stateful-фильтрация и conntrack

Ключевой принцип stateful firewall:

- правило `ct state new` разрешает инициировать соединение;
- правило `ct state established,related accept` автоматически
  пропускает ответный трафик.

Отдельное правило для обратного направления не требуется.

## Добавление stateful-правила в FORWARD

    vagrant ssh linux-gateway
    sudo nft add rule ip filter forward ct state established,related accept
    sudo nft list chain ip filter forward

Ожидаем увидеть в цепочке forward:

    chain forward {
        type filter hook forward priority filter; policy drop;
        ct state established,related accept
    }

## Разрешение одного нового потока: LAN → Web:80

    sudo nft add rule ip filter forward \
        ip saddr 10.10.10.0/24 \
        ip daddr 10.10.20.10 \
        tcp dport 80 \
        ct state new \
        accept

    sudo nft list chain ip filter forward

Порядок правил:

    1. ct state established,related accept
    2. LAN → Web:80, ct state new accept
    3. policy drop

## Проверка

    vagrant ssh lan-workstation -c 'curl http://10.10.20.10'

Nginx должен ответить.

## Наблюдение за conntrack

В отдельном окне на gateway:

    sudo apt install -y conntrack
    sudo conntrack -E

При запросе с lan-workstation увидим последовательность:

    [NEW]       SYN_SENT
    [UPDATE]    SYN_RECV
    [UPDATE]    ESTABLISHED   (ASSURED)
    [UPDATE]    FIN_WAIT
    [UPDATE]    LAST_ACK
    [UPDATE]    TIME_WAIT

Это подтверждает: ответный трафик Web → LAN проходит не по
отдельному правилу, а как `established` в рамках уже разрешённого
соединения.

## Итог этапа

Stateful-фильтрация работает. Правила `ct state new` разрешают
инициирование, а `ct state established,related` — ответ.