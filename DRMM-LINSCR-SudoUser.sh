#!/bin/bash

if [ $sudo = "Add"  ]; then
    echo "# Adding $username from sudoers group"
    usermod -aG sudo $username
else
    echo "# Removing $username from sudoers group"
    gpasswd -d $username sudo
fi

echo "----------------------"
echo "# Current list of sudoers:"
cat /etc/sudoers