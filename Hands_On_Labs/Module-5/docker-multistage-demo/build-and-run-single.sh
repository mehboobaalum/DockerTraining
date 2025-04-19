#!/bin/bash

echo "Building single-stage Docker image..."
docker build -t demo-single -f Dockerfile.single .

echo "Running container from single-stage image..."
docker run -d -p 8081:8080 --name demo-single demo-single

echo "Single-stage container is running at http://localhost:8081"
echo "Check image size with: docker images | grep demo-single"
echo "Check logs with: docker logs demo-single"
