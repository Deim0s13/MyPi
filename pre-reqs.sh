#!/bin/bash

# Log file path
LOG_FILE="/var/log/setup_script.log"
SUMMARY_FILE="/var/log/setup_summary.log"

# Function to check for root privileges
check_root() {
  if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root"
    exit 1
  fi
}

# Function to log messages
log() {
  local message="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$LOG_FILE"
}

# Function to log actions and outcomes
log_action() {
  local message="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$SUMMARY_FILE"
}

# Function to handle errors
handle_error() {
  local exit_code="$1"
  local message="$2"
  if [ "$exit_code" -ne 0 ]; then
    log "ERROR: $message"
    log_action "FAILURE: $message"
    exit "$exit_code"
  else
    log_action "SUCCESS: $message"
  fi
}

# Function to check if a command needs to be run and run it with error handling
run_command() {
  local check_cmd="$1"
  local exec_cmd="$2"
  local success_msg="$3"
  local fail_msg="$4"

  eval "$check_cmd" &> /dev/null
  if [ $? -eq 0 ]; then
    log "$success_msg"
    log_action "$success_msg"
  else
    eval "$exec_cmd" | tee -a "$LOG_FILE"
    handle_error $? "$fail_msg"
  fi
}

# Set static IP
set_static_ip() {
  local ip_address="$1"
  local routers_ip="$2"
  local dns_server="$3"

  run_command \
    "grep -q 'static ip_address=${ip_address}' /etc/dhcpcd.conf" \
    "echo 'interface eth0
static ip_address=${ip_address}
static routers=${routers_ip}
static domain_name_servers=${dns_server}' > /etc/dhcpcd.conf" \
    "Static IP is already set to ${ip_address}" \
    "Failed to set static IP"
}

# Update and upgrade the system
update_system() {
  run_command \
    "apt-get -s upgrade | grep -q '0 upgraded, 0 newly installed, 0 to remove'" \
    "apt-get update && apt-get dist-upgrade -y" \
    "System is already up to date" \
    "Failed to update and upgrade the system"
}

# Install necessary packages
install_packages() {
  run_command \
    "dpkg -s iptables firewalld ufw" \
    "apt-get install -y iptables firewalld ufw iptables-persistent" \
    "iptables, firewalld, and ufw are already installed" \
    "Failed to install iptables, firewalld, and ufw"
}

# Configure iptables
configure_iptables() {
  local rules=(
    "-s 192.168.0.0/16 -p tcp --dport 80 -j ACCEPT"
    "-s 127.0.0.0/8 -p tcp --dport 53 -j ACCEPT"
    "-s 127.0.0.0/8 -p udp --dport 53 -j ACCEPT"
    "-s 192.168.0.0/16 -p tcp --dport 53 -j ACCEPT"
    "-s 192.168.0.0/16 -p udp --dport 53 -j ACCEPT"
    "-p udp --dport 67:68 --sport 67:68 -j ACCEPT"
    "-p tcp --dport 4711 -i lo -j ACCEPT"
    "-m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  )
  for rule in "${rules[@]}"; do
    run_command \
      "iptables -C INPUT $rule" \
      "iptables -I INPUT 1 $rule && iptables-save > /etc/iptables/rules.v4" \
      "iptables rule '$rule' is already configured" \
      "Failed to configure iptables rule '$rule'"
  done
}

# Configure firewalld
configure_firewalld() {
  run_command \
    "firewall-cmd --state" \
    "systemctl start firewalld && systemctl enable firewalld" \
    "firewalld is already configured" \
    "Failed to start and enable firewalld"

  local services=("http" "dns" "dhcp" "dhcpv6")
  for service in "${services[@]}"; do
    run_command \
      "firewall-cmd --permanent --query-service=$service" \
      "firewall-cmd --permanent --add-service=$service" \
      "firewalld service '$service' is already added" \
      "Failed to add firewalld service '$service'"
  done

  run_command \
    "firewall-cmd --permanent --get-zones | grep -q 'ftl'" \
    "firewall-cmd --permanent --new-zone=ftl && firewall-cmd --permanent --zone=ftl --add-interface=lo && firewall-cmd --permanent --zone=ftl --add-port=4711/tcp && firewall-cmd --reload" \
    "firewalld zone 'ftl' is already configured" \
    "Failed to configure firewalld zone 'ftl'"
}

# Configure ufw
configure_ufw() {
  local rules=("80/tcp" "53/tcp" "53/udp" "67/tcp" "67/udp")
  for rule in "${rules[@]}"; do
    run_command \
      "ufw status | grep -q '$rule'" \
      "ufw allow $rule" \
      "ufw rule '$rule' is already configured" \
      "Failed to allow ufw rule '$rule'"
  done

  run_command \
    "ufw status | grep -q 'Status: active'" \
    "ufw enable" \
    "ufw is already enabled" \
    "Failed to enable ufw"
}

# Main script execution
main() {
  check_root

  local ip_address="<Add IP address>"
  local routers_ip="<Add routers IP address>"
  local dns_server="<Add DNS server>"

  # Uncomment the following lines and provide your values
  # ip_address="192.168.1.100/24"
  # routers_ip="192.168.1.1"
  # dns_server="8.8.8.8 8.8.4.4"

  set_static_ip "$ip_address" "$routers_ip" "$dns_server"
  update_system
  install_packages
  configure_iptables
  configure_firewalld
  configure_ufw

  log "Setup completed."
  log_action "Setup completed successfully."
  echo "Setup completed successfully. See $SUMMARY_FILE for details."
}

main
