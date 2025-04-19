#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Host Network Demonstration ===${NC}"

# Check if port 8080 is available on the host
nc -z localhost 8080 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${RED}Port 8080 is already in use on the host. Please free this port first.${NC}"
    exit 1
fi

# Launch container with host network
echo -e "${BLUE}Starting a container with host networking...${NC}"
docker run -d --name web-host --network host \
  -e NGINX_PORT=8080 demo-web

sleep 2

# Show network details
echo -e "${BLUE}Host network container details:${NC}"
docker inspect --format '{{.NetworkSettings.Networks.host}}' web-host
echo -e "${GREEN}Note: Container shares host's network namespace${NC}"

# Check process on the host
echo -e "${BLUE}Finding nginx processes on the host:${NC}"
ps aux | grep nginx | grep -v grep

# Show listening ports
echo -e "${BLUE}Showing host ports in use by the container:${NC}"
netstat -tulpn 2>/dev/null | grep nginx || lsof -i :8080

# Show accessibility
echo -e "${GREEN}The web service is directly accessible at http://localhost:8080${NC}"
echo -e "Try opening this in your browser or run: curl http://localhost:8080/env"

echo -e "${BLUE}Advantages:${NC}"
echo -e "- Best network performance (no network namespace isolation overhead)"
echo -e "- Can bind to any port on the host directly"
echo -e "- Can use the host's network interfaces directly"

echo -e "${BLUE}Disadvantages:${NC}"
echo -e "- Less isolation (container shares host's network namespace)"
echo -e "- Potential port conflicts with host services"
echo -e "- All ports published by container are exposed on the host"

echo -e "${BLUE}Host network demo completed${NC}"
