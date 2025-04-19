#!/bin/bash
echo "Cleaning up bridge network resources..."
docker rm -f web1 web2 tools web1-published web-default tools-default 2>/dev/null
docker network rm demo-bridge 2>/dev/null
echo "Cleanup complete"
