#!/bin/bash
firstboot() {
    sed -i 's/127.0.1.1/192.168.2.19/' /etc/hosts
    apt update
    apt full-upgrade -y
    apt install proxmox-ve -y
    apt remove linux-image-amd64 'linux-image-6.1*' -y
    apt remove os-prober -y
    apt autoremove -y
    update-grub
    rm /root/firstboot.sh
    rm /etc/systemd/system/firstboot.service
    systemctl daemon-reload
    rm -- "$0"
    reboot
}
firstboot
