#!/bin/bash

LOGFILE="/var/log/firstboot.log"
TTY="/dev/tty1"

# Function to log messages to both the logfile and TTY1
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOGFILE > $TTY
}

firstboot() {
    log "Starting first boot script"
    sleep 10
    
    echo "postfix postfix/mailname string my.hostname.example" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
    apt install postfix -y >> $LOGFILE 2>&1 | tee -a $TTY
    
    log "Updating /etc/hosts"
    sed -i 's/127.0.1.1/10.71.6.25/' /etc/hosts

    log "Updating package lists"
    apt update >> $LOGFILE 2>&1 | tee -a $TTY

    log "Upgrading packages"
    apt full-upgrade -y >> $LOGFILE 2>&1 | tee -a $TTY

    log "Installing Proxmox VE"
    apt install proxmox-ve -y >> $LOGFILE 2>&1 | tee -a $TTY
       
    log "Removing unused Linux images"
    apt remove linux-image-amd64 'linux-image-6.1*' -y >> $LOGFILE 2>&1 | tee -a $TTY
    sudo echo "LC_ALL=en_US.UTF-8" >> /etc/environment
    sudo echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    sudo echo "LANG=en_US.UTF-8" > /etc/locale.conf
    sudo locale-gen en_US.UTF-8

    log "Removing os-prober"
    apt remove os-prober -y >> $LOGFILE 2>&1 | tee -a $TTY

    log "Running autoremove"
    apt autoremove -y >> $LOGFILE 2>&1 | tee -a $TTY

    log "Updating GRUB"
    update-grub >> $LOGFILE 2>&1 | tee -a $TTY

    log "Cleaning up and removing firstboot script"
    rm /root/firstboot.sh
    rm /etc/systemd/system/firstboot.service

    log "Reloading systemd daemon"
    systemctl daemon-reload

    log "Removing Nag Message"
    NAGTOKEN="data.status.toLowerCase() !== 'active'"
    NAGFILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
    sed -i.orig "s/$NAGTOKEN/false/g" "$NAGFILE"

    log "Setting permissions for secondboot script and service"
    chmod 744 /root/secondboot.sh
    chmod 664 /etc/systemd/system/secondboot.service

    log "Enabling secondboot service"
    systemctl enable secondboot.service >> $LOGFILE 2>&1 | tee -a $TTY

    log "Removing firstboot script and rebooting"
    rm -- "$0"
    reboot
}

firstboot
