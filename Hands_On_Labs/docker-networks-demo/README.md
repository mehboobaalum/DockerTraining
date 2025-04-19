# Docker Networking Comprehensive Demo

This project demonstrates all Docker network types with practical examples using Alpine Linux containers.

## Network Types Covered

1. **Bridge Network** - Default network type, private internal network for containers
2. **Host Network** - Containers share the host's network namespace
3. **None Network** - Containers have no network connectivity
4. **Overlay Network** - Multi-host networking for Docker Swarm
5. **Macvlan Network** - Assigns a MAC address to containers, making them appear as physical devices on the network

## Setup

- Each directory contains example scripts for a specific network type
- The `demo.sh` script in the root directory runs all examples sequentially
- Use `./inspect-networks.sh` to see detailed information about created networks

## Requirements

- Docker Engine 20.10+ (for all features)
- Docker Swarm enabled (for overlay network examples)
- Root privileges may be required for some network operations
