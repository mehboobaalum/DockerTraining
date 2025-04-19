# Docker Installation & Configuration Deep Dive
## Comprehensive Technical Manual

*Prepared by: Choudhry Shehryar, MLOps Engineer*

## Introduction

This manual provides comprehensive instructions for installing and configuring Docker in various enterprise environments. Docker provides container virtualization, allowing applications to run in isolated environments with consistent behavior across development, testing, and production.

## Docker Architecture Overview

Before installation, it's important to understand Docker's architectural components:

- **Docker Engine**: The core runtime that builds and runs containers
  - **dockerd**: The Docker daemon that manages Docker objects
  - **Docker REST API**: API interface for interacting with the daemon
  - **Docker CLI**: Command line interface for sending commands
  
- **containerd**: Container runtime that manages container lifecycle
- **runc**: Low-level container runtime (OCI compliant)

![Docker Architecture](https://k21academy.com/wp-content/uploads/2020/05/2020-05-12-16_36_49-PowerPoint-Slide-Show-Azure_AZ104_M01_Compute_ed1-1.png)

### For windows users only.
```bash
Install using Command Prompt
Step 1: Start CMD with administrative privileges.
Step 2:Execute "wsl --install" command.
Step 3:Run "wsl -l -o" to list other Linux releases.
Step 4:You can install your favorite Linux distribution, use "wsl --install -d NameofLinuxDistro."
```
### Docker Desktop installation
https://docs.docker.com/get-started/get-docker/

### DOcker Engine installation
https://docs.docker.com/engine/install/

## Post-Installation Configuration

## Docker Daemon Configuration

### Configuration File

The Docker daemon configuration file location varies by platform:

- **Linux**: `/etc/docker/daemon.json`
- **Windows Server**: `C:\ProgramData\docker\config\daemon.json`
- **Docker Desktop**: Settings/Preferences -> Docker Engine

## Registry Configuration
- [configuration](https://stackoverflow.com/questions/38247362/how-i-can-use-docker-registry-with-login-password/)

### Private Registry Authentication

Create or update `~/.docker/config.json` (Linux/Mac) or `%USERPROFILE%\.docker\config.json` (Windows):

```json
{
  "auths": {
    "registry.example.com": {
      "auth": "dXNlcm5hbWU6cGFzc3dvcmQ="
    }
  }
}
```

The `auth` value is Base64 encoded `username:password`.

You can login to a registry using the Docker CLI:
```bash
docker login registry.example.com
```

### Registry Mirrors

Configure registry mirrors to improve pull performance:

```json
{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://registry-1.docker.io"
  ]
}
```

### Insecure Registries

For testing purposes or internal registries without HTTPS:

```json
{
  "insecure-registries": [
    "10.10.10.10:5000",
    "registry.internal:5000"
  ]
}
```

⚠️ **Warning**: Only use insecure registries in testing environments or isolated networks.

## Performance Tuning

### Resource Limits

Configure default resource limits for containers:

```json
{
  "default-shm-size": "64M",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 32000
    },
    "memlock": {
      "Name": "memlock",
      "Hard": -1,
      "Soft": -1
    }
  }
}
```
### CPU and Memory Allocation (Docker Desktop)

For Docker Desktop, allocate resources through the UI:
1. Open Docker Desktop
2. Go to Settings/Preferences -> Resources
3. Adjust CPUs, Memory, Swap, and Disk image size

### DNS Configuration

If experiencing DNS issues, configure DNS settings:

```json
{
  "dns": ["8.8.8.8", "8.8.4.4"],
  "dns-opts": ["timeout:2", "attempts:3"],
  "dns-search": ["example.com", "test.example.com"]
}
```

## Installation Verification

### Basic Verification

Check Docker version and info:
```bash
docker --version
docker version
docker info
```

Run a test container:
```bash
docker run hello-world
```

## Troubleshooting Guide

### Common Installation Issues

#### Permission Denied Errors

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply without logout
newgrp docker
```

#### Daemon Not Starting

```bash
# Check Docker daemon logs
sudo journalctl -u docker.service

# Check for configuration errors
sudo dockerd --validate

# Start daemon manually to see errors
sudo dockerd
```

#### Port Conflicts

```bash
# Check for port usage
sudo netstat -tulpn | grep LISTEN

# Change Docker daemon port
sudo tee /etc/docker/daemon.json <<EOF
{
  "hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"]
}
EOF
```
### Restart Procedures

```bash
# Linux
sudo systemctl restart docker

# Windows
Restart-Service Docker
```

## Security Configuration

### Rootless Mode
- [configuration](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)


## Hands-On Exercises

### Exercise 1: Basic Docker Installation and Verification

1. Install Docker using your platform's appropriate method
2. Verify installation with `docker version` and `docker info`
3. Run a test container with `docker run hello-world`
4. Identify where Docker is storing data using `docker info`

### Exercise 2: Docker Daemon Configuration

1. Create a basic `daemon.json` file with:
   - Specified log driver (json-file)
   - Log rotation configuration
   - Storage driver specification

2. Restart Docker and verify configuration took effect

3. Test container logs with:
```bash
docker run --name logtest alpine sh -c "while true; do echo 'Test log message'; sleep 1; done"
# In another terminal
docker logs logtest
# Cleanup
docker stop logtest
docker rm logtest
```

### Exercise 3: Registry Configuration

1. Set up authentication for Docker Hub:
```bash
docker login
```

2. Create a `daemon.json` with registry mirror configuration (if available)

3. Test pulling an image:
```bash
docker pull nginx:latest
```

### Exercise 4: Troubleshooting Practice

1. Intentionally create an error in `daemon.json`
2. Attempt to restart Docker
3. Examine the error logs
4. Fix the configuration and restart Docker

### Exercise 5: Security Configuration

1. Configure Docker to run with limited capabilities
2. Add your user to the docker group
3. Verify you can run Docker commands without sudo
4. Test container isolation

## References

- [Official Docker Installation Documentation](https://docs.docker.com/engine/install/)
- [Docker Daemon Configuration](https://docs.docker.com/engine/reference/commandline/dockerd/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Docker Storage Drivers](https://docs.docker.com/storage/storagedriver/select-storage-driver/)
- [Docker Registry Configuration](https://docs.docker.com/registry/configuration/)