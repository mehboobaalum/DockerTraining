#!/bin/bash
echo "Cleaning up overlay network resources..."
docker service rm overlay-web1 overlay-web2 2>/dev/null
docker rm -f tools-overlay 2>/dev/null
docker network rm demo-overlay 2>/dev/null
echo "Swarm mode is still active. To exit Swarm mode: docker swarm leave --force"
echo "Cleanup complete"
