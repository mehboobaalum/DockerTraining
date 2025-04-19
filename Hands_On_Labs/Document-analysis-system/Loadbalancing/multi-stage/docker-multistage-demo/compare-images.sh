#!/bin/bash

echo "Building both Docker images..."
docker build -t demo-single -f Dockerfile.single .
docker build -t demo-multi -f Dockerfile.multi .

echo -e "\nImage size comparison:"
echo -e "====================\n"
docker images | grep demo-

echo -e "\nDetailed inspection of single-stage image:"
docker history demo-single

echo -e "\nDetailed inspection of multi-stage image:"
docker history demo-multi

echo -e "\nVulnerability comparison (if using Docker Desktop):"
echo "docker scout compare demo-single demo-multi"
