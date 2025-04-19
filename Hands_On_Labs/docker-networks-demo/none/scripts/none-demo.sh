#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== None Network Demonstration ===${NC}"

# Launch container with no network
echo -e "${BLUE}Starting a container with no networking...${NC}"
docker run -d --name none-network --network none alpine:3.18 tail -f /dev/null

sleep 2

# Show network details
echo -e "${BLUE}None network container details:${NC}"
docker inspect --format '{{.NetworkSettings.Networks}}' none-network

# Check if any network interfaces exist in the container (except lo)
echo -e "${BLUE}Network interfaces inside the container:${NC}"
docker exec none-network ip addr show

# Try to access internet
echo -e "${BLUE}Trying to access the internet from the container:${NC}"
docker exec none-network ping -c 2 8.8.8.8 || echo -e "${RED}Failed as expected - no network access${NC}"

# Try DNS resolution
echo -e "${BLUE}Trying to resolve domain names:${NC}"
docker exec none-network nslookup google.com || echo -e "${RED}Failed as expected - no DNS service${NC}"

echo -e "${BLUE}Advantages:${NC}"
echo -e "- Maximum network isolation"
echo -e "- Security for sensitive containers"
echo -e "- Prevents unauthorized data exfiltration"

echo -e "${BLUE}Disadvantages:${NC}"
echo -e "- Cannot communicate with other containers or networks"
echo -e "- No internet access"
echo -e "- Requires other methods (e.g., volumes) to exchange data"

echo -e "${BLUE}None network demo completed${NC}"
