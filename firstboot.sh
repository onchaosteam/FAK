#!/bin/bash
firstboot() {
    sed -i 's/127.0.1.1/10.71.6.98/' /etc/hosts
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
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/secondboot.sh' -o "/root/secondboot.sh"
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/secondboot.service' -o "/etc/systemd/system/secondboot.service"
    chmod 744 /root/secondboot.sh
    chmod 664 /etc/systemd/system/secondboot.service
    systemctl enable secondboot.service
    rm -- "$0"
    reboot
}
firstboot
