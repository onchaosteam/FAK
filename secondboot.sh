#!/bin/bash

LOGFILE="/var/log/secondboot.log"
TTY="/dev/tty1"

# Function to log messages to both the logfile and TTY1
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE > $TTY
}

secondboot() {
    VMID=9001
    STORAGE=local
    BRIDGE=vmbr0

    set -x

    log "Sleeping for 1 minutes to wait for Proxmox to start up"
    sleep 1m >> $LOGFILE 2>&1 | tee -a $TTY
    
    log "Installing Ansible"
    apt install ansible -y >> $LOGFILE 2>&1 | tee -a $TTY
    
    log "Downloading Ubuntu cloud image"
    wget -qN https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -O noble-server-cloudimg-amd64.img >> $LOGFILE 2>&1 | tee -a $TTY

    log "Resizing image"
    qemu-img resize noble-server-cloudimg-amd64.img 10G >> $LOGFILE 2>&1 | tee -a $TTY

    log "Destroying existing VM with VMID $VMID if exists"
    qm destroy $VMID >> $LOGFILE 2>&1 | tee -a $TTY

    log "Creating new VM with VMID $VMID"
    qm create $VMID --name "ubuntu-2404-template" --ostype l26 \
        --memory 2048 --balloon 0 \
        --agent 1 \
        --cpu host --cores 2 --numa 1 \
        --vga serial0 --serial0 socket \
        --net0 virtio,bridge=$BRIDGE,mtu=1 >> $LOGFILE 2>&1 | tee -a $TTY

    log "Importing disk image"
    qm importdisk $VMID noble-server-cloudimg-amd64.img $STORAGE >> $LOGFILE 2>&1 | tee -a $TTY

    log "Setting VM configuration"
    qm set $VMID --scsihw virtio-scsi-pci --virtio0 $STORAGE:9001/vm-$VMID-disk-0.raw,discard=on >> $LOGFILE 2>&1 | tee -a $TTY
    qm set $VMID --boot order=virtio0 >> $LOGFILE 2>&1 | tee -a $TTY
    qm set $VMID --ide2 $STORAGE:cloudinit >> $LOGFILE 2>&1 | tee -a $TTY

    log "Cleaning up downloaded image"
    rm -rf noble-server-cloudimg-amd64.img

    log "Creating cloud-init configuration"
    mkdir -p /var/lib/vz/snippets
    cat << EOF | tee /var/lib/vz/snippets/ubuntu.yaml
#cloud-config
runcmd:
    - apt-get update
    - apt-get install -y qemu-guest-agent
    - systemctl enable ssh
    - reboot
EOF

    log "Configuring cloud-init"
    qm set $VMID --cicustom "vendor=local:snippets/ubuntu.yaml" >> $LOGFILE 2>&1 | tee -a $TTY
    qm set $VMID --ciuser $USER >> $LOGFILE 2>&1 | tee -a $TTY
    qm set $VMID --sshkeys ~/.ssh/authorized_keys >> $LOGFILE 2>&1 | tee -a $TTY
    qm set $VMID --ipconfig0 ip=dhcp >> $LOGFILE 2>&1 | tee -a $TTY

    log "Converting VM to template"
    qm template $VMID >> $LOGFILE 2>&1 | tee -a $TTY

    log "Cleaning up and removing secondboot script"
    rm /root/secondboot.sh
    rm /etc/systemd/system/secondboot.service

    log "Reloading systemd daemon"
    systemctl daemon-reload

    qm clone $VMID 101 --full false --name Splunk
    qm clone $VMID 102 --full false --name Velociraptor
    qm clone $VMID 103 --full false --name Nessus
    qm clone $VMID 104 --full false --name NextCloud
    qm clone $VMID 105 --full false --name CapeV2

    qm start 101

    log "Second boot process completed"
}

secondboot
