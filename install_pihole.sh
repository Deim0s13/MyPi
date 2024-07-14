#!/bin/bash

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt-get update
apt-get upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
apt-get install -y curl

# Download and install Pi-hole
echo "Downloading and installing Pi-hole..."
curl -sSL https://install.pi-hole.net | bash

# Restart services
echo "Restarting Pi-hole services..."
pihole restartdns

echo "Pi-hole installation completed."