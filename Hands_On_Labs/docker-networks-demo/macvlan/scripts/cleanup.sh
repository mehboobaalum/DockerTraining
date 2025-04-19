#!/bin/bash
echo "Cleaning up macvlan network resources..."
docker rm -f macvlan-web1 macvlan-web2 2>/dev/null
docker network rm demo-macvlan 2>/dev/null
echo "Cleanup complete"
