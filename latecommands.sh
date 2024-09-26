#!/bin/bash

latecommands() {

    # Modify Hosts file
    sed -i 's/127.0.1.1/10.71.6.25/' /etc/hosts

    # Add PVE Repository to install PVE Kernel package
    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
    apt update
    apt install proxmox-default-kernel -y

    # Download systemd component and PVE install script
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/firstboot.sh' -o "/root/firstboot.sh"
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/firstboot.service' -o "/etc/systemd/system/firstboot.service"

    # Download and configure Setup Bridge
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/interfaces' -o "/etc/network/interfaces"
    
    # "Downloading second boot script for later"
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/secondboot.sh' -o "/root/secondboot.sh" 
    curl -sSL 'https://raw.githubusercontent.com/onchaosteam/FAK/refs/heads/main/secondboot.service' -o "/etc/systemd/system/secondboot.service"
    
    # Enable systemd to run PVE install script on boot
    chmod 744 /root/firstboot.sh
    chmod 664 /etc/systemd/system/firstboot.service
    chmod 664 /etc/network/interfaces
    systemctl enable firstboot.service

}

latecommands
