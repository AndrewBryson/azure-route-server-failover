#!/bin/bash

VIP=10.1.0.5

# Install node.js (web server) and ExaBGP
sudo apt update
sudo apt install -y exabgp
curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install -y nodejs

# Loopback VIP configuration
sudo ip link add name vip type dummy 
sudo ifconfig vip $VIP netmask 255.255.255.255 up

## Start ExaBGP
exabgp ./conf.ini