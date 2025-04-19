#!/bin/bash

echo "Building multi-stage Docker image..."
docker build -t demo-multi -f Dockerfile.multi .

echo "Running container from multi-stage image..."
docker run -d -p 8080:8080 --name demo-multi demo-multi

echo "Multi-stage container is running at http://localhost:8080"
echo "Check image size with: docker images | grep demo-multi"
echo "Check logs with: docker logs demo-multi"
