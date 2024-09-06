#!/bin/bash

echo "Job selections:"
echo "- SSH Service Status: $sshEnable"
echo "- SSH Service Action: $sshStart"
echo "- SSH Firewall Rule: $sshFirewall"
echo ""

if [ $sshEnable = "enable" ]; then
    echo "# Enabling SSH service"
    systemctl enable ssh
elif [ $sshEnable = "disable" ]; then
    echo "# Disabling SSH Service"
    systemctl disable ssh
fi

if [ $sshStart = "start"  ]; then
    echo "# Starting SSH Service"
    systemctl start ssh
elif [ $sshStart = "stop" ]; then
    echo "# Stopping SSH Service"
    systemctl stop ssh
fi

if [ $sshFirewall = "add"  ]; then
    echo "# Adding SSH allow rule to UFW"
    ufw allow "OpenSSH"
elif [ $sshFirewall = "remove" ]; then
    echo "# Removing SSH allow rule from UFW"
    ufw delete allow "OpenSSH"
fi

echo "----------------------"
echo "Current status of SSH service"
systemctl status ssh

echo "----------------------"
echo "Current UFW status"
ufw status