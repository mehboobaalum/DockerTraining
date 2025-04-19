# Docker Networking: A Comprehensive Hands-On Guide

This documentation serves as a practical companion to the video tutorial on Docker networking. It provides detailed, step-by-step instructions for implementing and testing seven different Docker network types, allowing you to follow along with the demonstrations in the video.

## Prerequisites

- Basic knowledge of Docker containers
- A Linux virtual machine with Docker installed (Ubuntu recommended)
- Basic understanding of networking concepts (IP addressing, subnets, etc.)
- For MACVLAN and IPVLAN testing: Access to network configuration on your router/switch
- VirtualBox (recommended for the lab environment otherwise adapt according to your environment)

## Introduction

Docker networking provides the communication framework for Docker containers. When Docker is installed, it automatically creates three default networks: bridge, host, and none. This guide will explore these networks plus additional options, demonstrating their unique characteristics and use cases.

## Environment Setup

1. Create a new Ubuntu virtual machine in VirtualBox
2. Configure the network adapter to use "Bridge Adapter" mode instead of NAT:
   ```
   Settings > Network > Adapter 1 > Attached to: Bridged Adapter
   ```
3. Boot the virtual machine and check network configuration:
   ```bash
   ip address show
   ```
   Take note of your interface name (e.g., enp0s3) and IP address

## 1. Default Bridge Network

The default network for Docker containers creates a virtual bridge (`docker0`) on the host and assigns containers private IP addresses.

### Installation and Verification

1. Install Docker:
   ```bash
   sudo apt update
   sudo apt install docker.io -y
   ```

2. Verify the creation of the Docker bridge interface:
   ```bash
   ip address show
   ```
   Note the new `docker0` interface that appeared after installation

3. Examine Docker's default networks:
   ```bash
   docker network ls
   ```
   You should see three networks: bridge, host, and none

### Testing Default Bridge Functionality

1. Deploy three containers:
   ```bash
   docker run -itd --rm --name thor busybox
   docker run -itd --rm --name frigga busybox
   docker run -itd --rm --name stormbreaker nginx
   ```

2. Verify container creation:
   ```bash
   docker ps
   ```

3. Examine changes to network interfaces:
   ```bash
   ip address show
   ```
   Note the creation of virtual ethernet (veth) interfaces

4. View bridge connections:
   ```bash
   bridge link
   ```
   This shows the veth interfaces connected to docker0

5. Inspect the default bridge network:
   ```bash
   docker inspect bridge
   ```
   Look for the container section showing thor, frigga, and stormbreaker with their IP addresses

6. Test container-to-container communication:
   ```bash
   docker exec -it thor sh
   ip address show
   ping <frigga_ip_address>
   ping google.com
   ip route
   exit
   ```

7. Test external access to the Nginx container:
   ```
   # Try accessing http://<host_ip>:80 from your browser
   # It should not work because ports are not exposed
   ```

8. Redeploy the Nginx container with port mapping:
   ```bash
   docker stop stormbreaker
   docker run -itd --rm -p 80:80 --name stormbreaker nginx
   ```

9. Verify port exposure:
   ```bash
   docker ps
   ```
   Look for the "0.0.0.0:80->80/tcp" in the ports column

10. Test external access again:
    ```
    # Access http://<host_ip>:80 from your browser
    # It should now work
    ```

## 2. User-defined Bridge Network

Custom bridge networks provide better isolation and additional features compared to the default bridge.

### Creating a Custom Bridge Network

1. Create a user-defined bridge:
   ```bash
   docker network create asgard
   ```

2. Verify network creation:
   ```bash
   docker network ls
   ip address show
   ```
   Note the new bridge interface with a different subnet (172.18.0.0/16)

### Testing User-defined Bridge Functionality

1. Deploy containers in the custom network:
   ```bash
   docker run -itd --rm --network asgard --name loki busybox
   docker run -itd --rm --network asgard --name odin busybox
   ```

2. Verify container creation:
   ```bash
   docker ps
   ```

3. Inspect the custom network:
   ```bash
   docker inspect asgard
   ```
   Look for container section showing loki and odin with their IP addresses

4. Test container-to-container communication with DNS resolution:
   ```bash
   docker exec -it loki sh
   ping odin
   exit
   ```
   Note that name resolution works automatically

5. Test isolation between networks:
   ```bash
   docker exec -it thor sh
   ping loki
   ping odin
   exit
   ```
   These pings should fail, demonstrating network isolation

## 3. Host Network

Containers share the host's network namespace, eliminating network isolation but simplifying access.

### Testing Host Network Functionality

1. Stop the previously deployed Nginx container:
   ```bash
   docker stop stormbreaker
   ```

2. Deploy a new Nginx container using the host network:
   ```bash
   docker run -itd --rm --network host --name stormbreaker nginx
   ```

3. Verify container creation:
   ```bash
   docker ps
   ```
   Note that no ports are listed in the output

4. Test direct access:
   ```
   # Access http://<host_ip>:80 from your browser
   # It should work without explicit port mapping
   ```

5. Verify network namespace sharing:
   ```bash
   docker exec -it stormbreaker sh
   ip address show
   exit
   ```
   The network interfaces should be identical to the host

## 4. MACVLAN Network

Allows containers to have their own MAC address and appear as physical devices on your network.

### Setting Up MACVLAN

1. Enable promiscuous mode on your host interface:
   ```bash
   ip link set <interface_name> promisc on
   ```
   Note: For VirtualBox, also enable promiscuous mode in the VM settings:
   ```
   Settings > Network > Advanced > Promiscuous Mode: Allow All
   ```

2. Create a MACVLAN network (using your actual subnet and gateway):
   ```bash
   docker network create -d macvlan \
     --subnet=192.168.205.0/24 \
     --gateway=192.168.205.1 \
     -o parent=enp0s8 \
     new_asgard
   ```

3. Verify network creation:
   ```bash
   docker network ls
   ```

### Testing MACVLAN Functionality

1. Stop existing containers:
   ```bash
   docker stop thor frigga
   ```

2. Deploy containers with specific IPs in the MACVLAN network:
   ```bash
   docker run -itd --rm --network new_asgard --ip=192.168.205.120 --name thor busybox
   docker run -itd --rm --network new_asgard --ip=192.168.205.121 --name frigga busybox
   ```

3. Test container connectivity:
   ```bash
   docker exec -it thor sh
   ip address show
   ping 10.7.0.1  # Gateway
   ping frigga
   exit
   ```
   Note: If connectivity issues persist, try rebooting the host and rerun the promiscuous mode command

4. Deploy a web server container:
   ```bash
   docker run -itd --rm --network new_asgard --ip=192.168.205.196 --name jane_foster nginx
   ```

5. Test direct web access:
   ```
   # Access http://192.168.205.196 from your browser
   # It should work without port mapping
   ```

### MACVLAN with VLAN Support (802.1q)

1. Remove existing MACVLAN network and containers:
   ```bash
   docker stop thor frigga jane_foster
   docker network rm new_asgard
   ```

2. Create a MACVLAN network with VLAN tag:
   ```bash
   docker network create -d macvlan \
     --subnet=192.168.205.0/24 \
     --gateway=192.168.205.1\
     -o parent=enp0s8.20 \
     macvlan_vlan20
   ```
   This creates a subinterface with VLAN 20 tag

## 5. IPVLAN L2 Network

Similar to MACVLAN, but containers share the host's MAC address while having unique IP addresses.

### Setting Up IPVLAN L2

1. Remove previous networks if needed:
   ```bash
   docker network rm macvlan_vlan20
   ```

2. Create an IPVLAN L2 network:
   ```bash
   docker network create -d ipvlan \
     --subnet=192.168.205.0/24 \
     --gateway=10.7.0.1 \
     -o parent=enp0s8 \
     new_asgard
   ```

3. Verify network creation:
   ```bash
   docker network ls
   ```

### Testing IPVLAN L2 Functionality

1. Deploy a container in the IPVLAN network:
   ```bash
   docker run -itd --rm --network new_asgard --ip=192.168.205.192 --name thor busybox
   ```

2. Test container connectivity:
   ```bash
   docker exec -it thor sh
   ip address show
   ping 192.168.205.1  # Gateway
   ping google.com
   exit
   ```

3. Verify MAC address sharing:
   ```bash
   # On the host:
   ip address show <interface_name> | grep ether
   
   # From another device on the network, ping thor's IP and check ARP:
   ping 192.168.205.192
   arp -a
   ```
   The container's IP should be associated with the host's MAC address

## 6. IPVLAN L3 Network

Creates isolated Layer 3 networks with the host acting as a router between container networks and external network.

### Setting Up IPVLAN L3

1. Enable IP forwarding on the host:
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

2. Remove previous networks:
   ```bash
   docker stop thor
   docker network rm new_asgard
   ```

3. Create an IPVLAN L3 network with multiple subnets:
   ```bash
   docker network create -d ipvlan \
     --subnet=192.168.94.0/24 \
     --subnet=192.168.95.0/24 \
     -o parent=enp0s8 \
     -o ipvlan_mode=l3 \
     new_asgard
   ```

4. Verify network creation:
   ```bash
   docker network ls
   docker inspect new_asgard
   ```

### Testing IPVLAN L3 Functionality

1. Deploy containers in different subnets:
   ```bash
   docker run -itd --rm --network new_asgard --ip=192.168.94.7 --name thor busybox
   docker run -itd --rm --network new_asgard --ip=192.168.94.8 --name frigga busybox
   docker run -itd --rm --network new_asgard --ip=192.168.95.7 --name loki busybox
   docker run -itd --rm --network new_asgard --ip=192.168.95.8 --name odin busybox
   ```

2. Test inter-subnet communication:
   ```bash
   docker exec -it thor sh
   ping frigga
   ping loki
   ping odin
   exit
   ```

## 7. Overlay Network

Used for multi-host Docker networking, typically with Docker Swarm.

This network type is intended for multi-host Docker Swarm environments and is beyond the scope of this basic demonstration.

## 8. None Network

Containers have no network connectivity except for the loopback interface.

### Testing None Network

1. Deploy a container with no network connectivity:
   ```bash
   docker run -itd --rm --network none --name gor busybox
   ```

2. Verify network isolation:
   ```bash
   docker exec -it gor sh
   ip address show
   ping 8.8.8.8
   exit
   ```
   The container should only have the loopback interface and no external connectivity

## Network Comparison Table

| Network Type | Isolation | External Access | DNS Resolution | IP Assignment | Promiscuous Mode | Use Cases |
|--------------|-----------|-----------------|----------------|---------------|------------------|-----------|
| Default Bridge | Partial | Port mapping | None | Automatic | No | Development, simple deployments |
| User-defined Bridge | Good | Port mapping | Automatic | Automatic | No | Multi-container applications |
| Host | None | Direct | Host's DNS | Host network | No | High performance, single containers |
| MACVLAN | Good | Direct | External DNS | Manual/Auto | Required | Physical network integration |
| IPVLAN L2 | Good | Direct | External DNS | Manual/Auto | No | Physical network without promiscuous mode |
| IPVLAN L3 | Excellent | Via routing | Internal | Manual/Auto | No | Advanced network isolation |
| Overlay | Excellent | Via ingress | Automatic | Automatic | No | Multi-host Docker Swarm |
| None | Complete | None | None | None | No | Security-critical isolation |

## Practical Example: Multi-tier Application

Here's a practical example showing how to deploy a multi-tier application:

```bash
# Create a user-defined bridge network
docker network create app_network

# Deploy database (no external access needed)
docker run -d --name db --network app_network -e MYSQL_ROOT_PASSWORD=secure_password mysql:5.7

# Deploy backend API (only expose to frontend)
docker run -d --name api --network app_network mybackend:latest

# Deploy frontend (expose to outside world)
docker run -d --name web --network app_network -p 80:80 myfrontend:latest
```

## Troubleshooting

### Common Issues

1. **Default Bridge: Containers Can't Communicate**
   ```bash
   # Check if containers are in the same network
   docker network inspect bridge
   
   # Check container IP addresses
   docker inspect --format='{{.NetworkSettings.IPAddress}}' container_name
   ```

2. **MACVLAN: No Connectivity**
   ```bash
   # Check promiscuous mode
   ip link show <interface_name> | grep PROMISC
   
   # Enable promiscuous mode
   ip link set <interface_name> promisc on
   
   # For VirtualBox users, reboot the VM after changing settings
   ```

3. **IPVLAN L3: No External Connectivity**
   ```bash
   # Verify IP forwarding is enabled
   sysctl net.ipv4.ip_forward
   
   # Enable IP forwarding
   sysctl -w net.ipv4.ip_forward=1
   
   # Verify static routes on the router
   ```

## Cleanup Commands

```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all stopped containers
docker container prune

# Remove a specific network
docker network rm network_name

# Remove all unused networks
docker network prune
```

This comprehensive guide covers all the Docker networking types demonstrated in the video, providing detailed commands and explanations for each step. By following these instructions alongside the video, you'll gain practical experience with Docker networking concepts and be able to implement them in your own projects.