#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Overlay Network Demonstration ===${NC}"

# Check if Swarm is initialized
docker info | grep -q "Swarm: active"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Initializing Docker Swarm mode...${NC}"
    docker swarm init --advertise-addr 127.0.0.1 > /dev/null 2>&1 || {
        echo -e "${RED}Failed to initialize Docker Swarm. Please check Docker installation.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Docker Swarm is already active.${NC}"
fi

# Create an overlay network
echo -e "${BLUE}Creating overlay network...${NC}"
docker network create --driver overlay \
  --subnet=10.10.0.0/16 \
  --gateway=10.10.0.1 \
  --attachable \
  demo-overlay

# Launch service on overlay network
echo -e "${BLUE}Creating services on the overlay network...${NC}"
docker service create --name overlay-web1 \
  --network demo-overlay \
  --replicas 2 \
  demo-web

docker service create --name overlay-web2 \
  --network demo-overlay \
  --replicas 2 \
  demo-web

# Wait for services to be ready
echo -e "${BLUE}Waiting for services to be ready...${NC}"
sleep 5

# Show service details
echo -e "${BLUE}Service details:${NC}"
docker service ls

# Launch a standalone container on the overlay network
echo -e "${BLUE}Launching a standalone container on the overlay network...${NC}"
docker run -d --name tools-overlay \
  --network demo-overlay \
  demo-tools

sleep 2

# Test connectivity between containers
echo -e "${BLUE}Testing connectivity in the overlay network:${NC}"
echo -e "${GREEN}Pinging overlay-web1 service:${NC}"
docker exec tools-overlay ping -c 2 overlay-web1

echo -e "${GREEN}Service discovery in action - accessing overlay-web1:${NC}"
docker exec tools-overlay curl -s http://overlay-web1/env

echo -e "${GREEN}Demonstrating load balancing - multiple requests to overlay-web1:${NC}"
for i in {1..4}; do
    echo "Request $i:"
    docker exec tools-overlay curl -s http://overlay-web1/env | grep "Hostname"
done

# Explain overlay network
echo -e "${BLUE}Overlay Network Explained:${NC}"
echo -e "- Spans multiple Docker hosts in a Swarm cluster"
echo -e "- Enables container-to-container communication across hosts"
echo -e "- Provides built-in service discovery and load balancing"
echo -e "- Uses VXLAN encapsulation for overlay traffic"
echo -e "- Control plane is encrypted by default"
echo -e "- Data plane can be encrypted with --opt encrypted=true"

echo -e "${BLUE}Overlay network demo completed${NC}"
