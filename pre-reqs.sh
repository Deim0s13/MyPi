#!/bin/bash

# Set a static IP
echo "Setting static IP..."
cat <<EOF > /etc/dhcpcd.conf
interface eth0
static ip_address= <Add IP address>
static routers= <Add routers IP address>
static domain_name_servers= <Add DNS server>
EOF

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt-get update
apt-get upgrade -y

# Install iptables, firewalld, and ufw
echo "Installing iptables, firewalld, and ufw..."
apt-get install -y iptables firewalld ufw

# Configure iptables
echo "Configuring iptables..."
iptables -I INPUT 1 -s 192.168.0.0/16 -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT 1 -s 127.0.0.0/8 -p tcp -m tcp --dport 53 -j ACCEPT
iptables -I INPUT 1 -s 127.0.0.0/8 -p udp -m udp --dport 53 -j ACCEPT
iptables -I INPUT 1 -s 192.168.0.0/16 -p tcp -m tcp --dport 53 -j ACCEPT
iptables -I INPUT 1 -s 192.168.0.0/16 -p udp -m udp --dport 53 -j ACCEPT
iptables -I INPUT 1 -p udp --dport 67:68 --sport 67:68 -j ACCEPT
iptables -I INPUT 1 -p tcp -m tcp --dport 4711 -i lo -j ACCEPT
iptables -I INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Configure firewalld
echo "Configuring firewalld..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-service=dhcpv6
firewall-cmd --permanent --new-zone=ftl
firewall-cmd --permanent --zone=ftl --add-interface=lo
firewall-cmd --permanent --zone=ftl --add-port=4711/tcp
firewall-cmd --reload

# Configure ufw
echo "Configuring ufw..."
ufw allow 80/tcp
ufw allow 53/tcp
ufw allow 53/udp
ufw allow 67/tcp
ufw allow 67/udp
ufw enable

echo "Setup completed."