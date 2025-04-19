#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Macvlan Network Demonstration ===${NC}"

# Detect host's network interface
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}Could not detect default network interface.${NC}"
    echo -e "${YELLOW}Please specify your network interface manually in this script.${NC}"
    exit 1
fi

echo -e "${GREEN}Using network interface: $INTERFACE${NC}"

# Get host's network details
SUBNET=$(ip -o -4 addr show dev $INTERFACE | awk '{print $4}' | head -1)
GATEWAY=$(ip -o -4 route show to default | awk '{print $3}' | head -1)

if [ -z "$SUBNET" ] || [ -z "$GATEWAY" ]; then
    echo -e "${RED}Could not detect subnet or gateway.${NC}"
    echo -e "${YELLOW}Please specify your subnet and gateway manually in this script.${NC}"
    exit 1
fi

echo -e "${GREEN}Host subnet: $SUBNET, Gateway: $GATEWAY${NC}"

echo -e "${YELLOW}NOTE: Macvlan requires root privileges and direct access to host's network interfaces.${NC}"
echo -e "${YELLOW}This demo may not work in nested virtualization environments or some cloud providers.${NC}"

# Create macvlan network
echo -e "${BLUE}Creating macvlan network...${NC}"
docker network create --driver macvlan \
  --subnet=$SUBNET \
  --gateway=$GATEWAY \
  -o parent=$INTERFACE \
  demo-macvlan

# Launch containers
echo -e "${BLUE}Starting containers on macvlan network...${NC}"
echo -e "${YELLOW}Note: These containers will receive their own IP addresses from your network.${NC}"

# Get network prefix for IP allocation
PREFIX=$(echo $SUBNET | cut -d'/' -f2)
NETWORK=$(echo $SUBNET | cut -d'/' -f1 | cut -d'.' -f1-3)
LAST_OCTET=$(echo $SUBNET | cut -d'/' -f1 | cut -d'.' -f4)

# Calculate safe IPs to use (usually .100+ range is safe to avoid conflicts)
IP1="${NETWORK}.100"
IP2="${NETWORK}.101"

docker run -d --name macvlan-web1 \
  --network demo-macvlan \
  --ip=$IP1 \
  demo-web

docker run -d --name macvlan-web2 \
  --network demo-macvlan \
  --ip=$IP2 \
  demo-tools

# Wait for containers to be ready
sleep 2

# Show network details
echo -e "${BLUE}Macvlan network details:${NC}"
docker network inspect demo-macvlan | grep -A 20 "Containers"

echo -e "${BLUE}Container network information:${NC}"
docker exec macvlan-web1 ip addr show eth0
docker exec macvlan-web2 ip addr show eth0

# Test connectivity
echo -e "${BLUE}Testing connectivity:${NC}"
echo -e "${GREEN}Pinging from macvlan-web2 to macvlan-web1:${NC}"
docker exec macvlan-web2 ping -c 2 $IP1

echo -e "${GREEN}Checking HTTP connection:${NC}"
docker exec macvlan-web2 curl -s http://$IP1/health

# Important note about host connectivity
echo -e "${RED}Note: By default, containers on a macvlan network cannot directly communicate${NC}"
echo -e "${RED}with the Docker host due to a design limitation.${NC}"

echo -e "${BLUE}Macvlan Network Explained:${NC}"
echo -e "- Assigns a MAC address to each container (appears as a physical device on the network)"
echo -e "- Containers receive their own IP address from the underlying network"
echo -e "- No port mapping needed - services use their actual port on their own IP"
echo -e "- Provides nearly native network performance"
echo -e "- Useful for legacy applications that expect to be directly connected to the physical network"
echo -e "- Requires promiscuous mode on the network interface (may not work in some environments)"

echo -e "${BLUE}Macvlan network demo completed${NC}"
