#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt-get update
apt-get upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
apt-get install -y curl

# Set variables for Pi-hole installation
PIHOLE_INTERFACE="eth0"
PIHOLE_IP=$(hostname -I | awk '{print $1}')
PIHOLE_GATEWAY=$(ip route | grep default | awk '{print $3}')
PIHOLE_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)

# Pre-fill the expected answers for the Pi-hole installer
echo "Preparing unattended install answers..."
cat <<EOF > pihole_setup_vars.conf
PIHOLE_INTERFACE=$PIHOLE_INTERFACE
IPV4_ADDRESS=$PIHOLE_IP
IPV4_GATEWAY=$PIHOLE_GATEWAY
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=8.8.4.4
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
WEBPASSWORD=$PIHOLE_PASSWORD
EOF

# Download and install Pi-hole using unattended mode
echo "Downloading and installing Pi-hole in unattended mode..."
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended --skip-DNS --reconfigure < pihole_setup_vars.conf

# Restart services
echo "Restarting Pi-hole services..."
pihole restartdns

# Output the password to a file
echo "Pi-hole admin interface password: $PIHOLE_PASSWORD" > /etc/pihole_password

echo "Pi-hole installation completed. The password has been saved to /etc/pihole_password."

# Clean up
rm pihole_setup_vars.conf