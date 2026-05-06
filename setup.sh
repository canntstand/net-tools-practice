#!/bin/bash
sudo cp netplan/01-netcfg.yaml /etc/netplan/
sudo netplan apply

echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-forwarding.conf
sudo sysctl -p /etc/sysctl.d/99-forwarding.conf

sudo apt update && sudo apt install -y nftables
sudo cp nftables/main.nft /etc/nftables.conf
sudo systemctl enable --now nftables
