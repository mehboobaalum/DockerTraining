#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Bridge Network Demonstration ===${NC}"

# Create custom bridge network with specific subnet
echo -e "${BLUE}Creating a custom bridge network...${NC}"

docker network create --driver bridge --subnet=10.10.0.0/16 --gateway=10.10.0.1 --opt "com.docker.network.bridge.name"="docker_demo_bridge" demo-bridge

# Launch containers
echo -e "${BLUE}Starting web service containers on the bridge network...${NC}"
docker run -d --name web1 --network demo-bridge --hostname web1 \
  -e VIRTUAL_HOST=web1.local demo-web
  
docker run -d --name web2 --network demo-bridge --hostname web2 \
  -e VIRTUAL_HOST=web2.local demo-web

docker run -d --name tools --network demo-bridge --hostname tools demo-tools

# Wait for containers to be ready
sleep 2

# Show network details
echo -e "${BLUE}Bridge network details:${NC}"
docker network inspect demo-bridge | grep -A 10 "Containers"

# Test connectivity between containers
echo -e "${BLUE}Testing connectivity from the tools container:${NC}"
echo -e "${GREEN}Pinging web1 by container name:${NC}"
docker exec tools ping -c 2 web1

echo -e "${GREEN}Pinging web2 by container name:${NC}"
docker exec tools ping -c 2 web2

echo -e "${GREEN}Checking HTTP connection to web1:${NC}"
docker exec tools curl -s http://web1/health

echo -e "${GREEN}Checking HTTP connection to web2:${NC}"
docker exec tools curl -s http://web2/health

# Show port forwarding
echo -e "${BLUE}Demonstrating port forwarding:${NC}"
docker stop web1 > /dev/null 2>&1
docker run -d --name web1-published --network demo-bridge -p 8081:80 demo-web

echo -e "${GREEN}Web service is now accessible at http://localhost:8081${NC}"
echo -e "Try opening this in your browser or run: curl http://localhost:8081/env"

# Connection to default bridge network
echo -e "${BLUE}Demonstrating difference between custom bridge and default bridge:${NC}"
docker run -d --name web-default demo-web
docker run -d --name tools-default demo-tools

echo -e "${GREEN}Trying to ping web-default from tools-default (works but requires linking or --link for DNS):${NC}"
docker exec tools-default ping -c 2 $(docker inspect -f '{{.NetworkSettings.IPAddress}}' web-default)

echo -e "${GREEN}DNS resolution not working on default bridge (will fail):${NC}"
docker exec tools-default ping -c 2 web-default || echo "Failed as expected!"

echo -e "${BLUE}Bridge network demo completed${NC}"
