#!/bin/bash
echo "Cleaning up host network resources..."
docker rm -f web-host 2>/dev/null
echo "Cleanup complete"
