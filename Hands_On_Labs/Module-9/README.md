# Hands-on Exercise: Docker Volume Management & Data Persistence

## Overview
This exercise demonstrates basic Docker volume management for data persistence using a simple web application scenario.

## Objective
Learn how to create and use Docker volumes to persist data across container lifecycles.

## Tasks

### Task 1: Create and Manage Docker Volumes

```bash
# Create a named volume for our application data
docker volume create app-data

# List all volumes to verify creation
docker volume ls

# Inspect volume details
docker volume inspect app-data

# Create a directory with some test content
mkdir -p test-content
echo "This is test content for our Docker volume" > test-content/test.txt
```

### Task 2: Use Volumes with Containers

```bash
# Run a container that uses the volume and copies test content to it
docker run --name data-loader \
  -v app-data:/app/data \
  -v $(pwd)/test-content:/source \
  alpine:latest \
  sh -c "cp /source/* /app/data/ && echo 'Data copied to volume'"

# Verify data was copied to the volume
docker run --rm -v app-data:/data alpine ls -la /data
docker run --rm -v app-data:/data alpine cat /data/test.txt

# Run a web server container using the same volume
docker run -d --name web-server \
  -v app-data:/usr/share/nginx/html \
  -p 8080:80 \
  nginx:alpine

# Test that the web server can access the data
echo "You can now visit http://localhost:8080/test.txt in your browser"
```

### Task 3: Backup and Restore Volume Data

```bash
# Create a backup directory
mkdir -p volume-backups

# Create a backup of the volume data
docker run --rm \
  -v app-data:/source:ro \
  -v $(pwd)/volume-backups:/backup \
  alpine:latest \
  tar -czf /backup/app-data-backup.tar.gz -C /source .

# Verify backup file was created
ls -la volume-backups/

# Simulate data loss
docker run --rm -v app-data:/data alpine sh -c "rm -rf /data/*"
docker run --rm -v app-data:/data alpine ls -la /data

# Restore data from backup
docker run --rm \
  -v app-data:/destination \
  -v $(pwd)/volume-backups:/backup \
  alpine:latest \
  sh -c "tar -xzf /backup/app-data-backup.tar.gz -C /destination"

# Verify data is restored
docker run --rm -v app-data:/data alpine ls -la /data
docker run --rm -v app-data:/data alpine cat /data/test.txt

# Clean up
docker stop web-server
docker rm web-server data-loader
# Optional: docker volume rm app-data
```

## Key Concepts

- **Volume Creation and Management**: Creating named volumes and inspecting their properties
- **Data Persistence**: Keeping data intact even when containers are destroyed
- **Backup and Restore**: Safely backing up volume data and restoring it when needed

## Next Steps

After completing this exercise, you should be able to use Docker volumes for persistent storage in your applications, ensuring data survives container lifecycle events.
