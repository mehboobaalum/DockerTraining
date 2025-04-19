#!/bin/bash
echo "Cleaning up none network resources..."
docker rm -f none-network 2>/dev/null
echo "Cleanup complete"
