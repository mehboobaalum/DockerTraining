#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Docker Network Inspection ===${NC}"

# List all networks
echo -e "${BLUE}Available Docker networks:${NC}"
docker network ls

# Get the network ID to inspect
if [ -z "$1" ]; then
    echo -e "${GREEN}Enter the network name to inspect (or 'all' for all networks):${NC}"
    read NETWORK
else
    NETWORK=$1
fi

if [ "$NETWORK" == "all" ]; then
    for NET in $(docker network ls --format "{{.Name}}"); do
        echo -e "${BLUE}=============================${NC}"
        echo -e "${BLUE}Details for network: $NET${NC}"
        echo -e "${BLUE}=============================${NC}"
        docker network inspect $NET | jq '.[0] | {Name:.Name, Driver:.Driver, Scope:.Scope, Subnet:.IPAM.Config[0].Subnet, Gateway:.IPAM.Config[0].Gateway, Containers:.Containers}'
        echo ""
    done
else
    # Check if network exists
    docker network ls | grep -q $NETWORK
    if [ $? -ne 0 ]; then
        echo -e "${RED}Network $NETWORK not found.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}=============================${NC}"
    echo -e "${BLUE}Details for network: $NETWORK${NC}"
    echo -e "${BLUE}=============================${NC}"
    docker network inspect $NETWORK | jq '.[0] | {Name:.Name, Driver:.Driver, Scope:.Scope, Subnet:.IPAM.Config[0].Subnet, Gateway:.IPAM.Config[0].Gateway, Containers:.Containers}'
fi
