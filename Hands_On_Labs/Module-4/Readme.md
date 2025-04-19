# Docker Images & Registries
## Comprehensive Technical Manual

*Prepared by: Choudhry Shehryar, MLOps Engineer*

## Table of Contents

1. [Introduction](#introduction)
2. [Docker Image Architecture](#docker-image-architecture)
   - [Image Layers](#image-layers)
   - [Image Manifests](#image-manifests)
   - [Union Filesystem](#union-filesystem)
3. [Working with Docker Images](#working-with-docker-images)
   - [Pulling Images](#pulling-images)
   - [Listing Images](#listing-images)
   - [Inspecting Images](#inspecting-images)
   - [Saving and Loading Images](#saving-and-loading-images)
4. [Image Size Optimization](#image-size-optimization)
   - [Base Image Selection](#base-image-selection)
   - [Layer Minimization](#layer-minimization)
   - [Multi-stage Builds](#multi-stage-builds)
   - [.dockerignore File](#dockerignore-file)
   - [Image Analysis Tools](#image-analysis-tools)
5. [Docker Registry Ecosystem](#docker-registry-ecosystem)
   - [Registry Types](#registry-types)
   - [Registry Architecture](#registry-architecture)
   - [Storage Backends](#storage-backends)
6. [Docker Hub In-Depth](#docker-hub-in-depth)
   - [Account Setup and Management](#account-setup-and-management)
   - [Repository Management](#repository-management)
   - [Organizations and Teams](#organizations-and-teams)
   - [Docker Hub API](#docker-hub-api)
7. [Private Registry Setup](#private-registry-setup)
   - [Docker Registry Deployment](#docker-registry-deployment)
   - [Registry Configuration](#registry-configuration)
   - [Garbage Collection](#garbage-collection)
   - [Registry Notifications](#registry-notifications)
8. [Registry Security](#registry-security)
   - [Authentication Options](#authentication-options)
   - [Transport Layer Security (TLS)](#transport-layer-security-tls)
   - [Image Signing with Docker Content Trust](#image-signing-with-docker-content-trust)
   - [Role-Based Access Control](#role-based-access-control)
9. [Enterprise Registry Solutions](#enterprise-registry-solutions)
   - [Harbor](#harbor)
   - [JFrog Artifactory](#jfrog-artifactory)
   - [Nexus Repository](#nexus-repository)
   - [Cloud Provider Registries](#cloud-provider-registries)
10. [Image Management Workflow](#image-management-workflow)
    - [Tagging Convention](#tagging-convention)
    - [Promotion Strategy](#promotion-strategy)
    - [Image Lifecycle Management](#image-lifecycle-management)
11. [Image Distribution Optimization](#image-distribution-optimization)
    - [Registry Mirrors](#registry-mirrors)
    - [Pull-Through Cache](#pull-through-cache)
    - [Offline Environments](#offline-environments)
12. [Hands-On Exercises](#hands-on-exercises)
13. [Troubleshooting](#troubleshooting)
14. [References](#references)

## Introduction

Docker images are the foundation of containerization, providing a portable and consistent environment for applications. This manual explores Docker image architecture, management techniques, registry options, and enterprise best practices for maintaining a secure and efficient image ecosystem.

## Docker Image Architecture

A Docker image is a read-only template used to create Docker containers. Understanding the image architecture is crucial for effective management and optimization.

### Image Layers

Docker images consist of multiple read-only layers stacked on top of each other using a Union File System. Each layer represents a set of filesystem changes from the previous layer.

**Key Characteristics**:
- **Immutability**: Layers are immutable once built
- **Reusability**: Layers are shared between images
- **Caching**: Unchanged layers are cached during builds
- **Minimal Transfer**: Only changed layers are transferred during push/pull operations

**Layer Creation**:
Each instruction in a Dockerfile typically creates a new layer:

```dockerfile
FROM ubuntu:20.04           # Base layer
RUN apt-get update          # Creates layer 1
RUN apt-get install nginx   # Creates layer 2
COPY . /app                 # Creates layer 3
CMD ["nginx", "-g", "daemon off;"]  # Metadata, not a separate layer
```

**Viewing Layers**:
```bash
# View image history showing layers
docker image history nginx:latest

# More detailed layer info with formatting
docker image history --no-trunc --format "{{.CreatedBy}}: {{.Size}}" nginx:latest
```

### Image Manifests

The image manifest is a JSON file that describes the image contents and metadata. It defines how to assemble the image from its component layers.

**Manifest Structure**:
- Image configuration
- Layer references (digests)
- Architecture and OS information
- Annotations and metadata

**Inspecting Manifests**:
```bash
# Pull an image first
docker pull nginx:latest

# Save the image as a tar file
docker save nginx:latest -o nginx.tar

# Extract and examine the manifest
mkdir nginx-contents
tar -xf nginx.tar -C nginx-contents
cat nginx-contents/manifest.json
```

**OCI Image Specification**:
Docker images adhere to the Open Container Initiative (OCI) Image Specification, ensuring portability across container runtimes.

### Union Filesystem

Docker uses Union File Systems to layer the image and provide a unified view of all layers to containers.

**Common Storage Drivers**:
- **overlay2**: Default for most Linux distributions
- **btrfs**: Used with Btrfs filesystems
- **zfs**: Used with ZFS filesystems
- **devicemapper**: Used on older systems
- **aufs**: Legacy driver, mostly deprecated

**Checking Current Storage Driver**:
```bash
docker info | grep "Storage Driver"
```

**Container Layers**:
When a container starts, Docker adds a writable layer on top of the image layers. This is called the "container layer" and is where all changes are stored during the container's lifetime.

## Working with Docker Images

### Pulling Images

```bash
# Basic pull syntax
docker pull [OPTIONS] NAME[:TAG|@DIGEST]

# Pull latest tag (default)
docker pull nginx

# Pull specific tag
docker pull nginx:1.21

# Pull by digest (for exact image version)
docker pull nginx@sha256:123abc...

# Pull from a specific registry
docker pull myregistry.example.com/myteam/myapp:v1.2.3
```

**Authentication for Private Registries**:
```bash
# Login to a registry
docker login [SERVER]

# Login with credentials
docker login -u username -p password registry.example.com

# Use access tokens (more secure)
docker login -u username --password-stdin registry.example.com < token.txt
```

### Listing Images

```bash
# List all images
docker image ls

# List with specific format
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Filter images
docker image ls --filter "reference=nginx:*"
docker image ls --filter "before=nginx:latest"
docker image ls --filter "since=ubuntu:20.04"
docker image ls --filter "label=maintainer=username"

# Show image digests
docker image ls --digests
```

### Inspecting Images

```bash
# Basic inspection
docker image inspect nginx:latest

# Get specific properties
docker image inspect --format "{{.Config.Env}}" nginx:latest
docker image inspect --format "{{.Config.ExposedPorts}}" nginx:latest
docker image inspect --format "{{.RepoDigests}}" nginx:latest
```

**Advanced Inspection**:
```bash
# List all environment variables
docker image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' nginx:latest

# Get all labels
docker image inspect --format '{{json .Config.Labels}}' nginx:latest | jq

# View entrypoint and default command
docker image inspect --format '{{.Config.Entrypoint}} | {{.Config.Cmd}}' nginx:latest
```

### Saving and Loading Images

**Saving Images to Files**:
```bash
# Save a single image to a tar file
docker save nginx:latest -o nginx.tar

# Save multiple images
docker save ubuntu:20.04 nginx:latest -o images.tar
```

**Loading Images from Files**:
```bash
# Load image from tar file
docker load -i nginx.tar

# Load with progress output
docker load --input images.tar
```

**Transferring Images Between Hosts**:
```bash
# On source host
docker save myapp:latest | gzip > myapp.tar.gz

# Transfer the file to target host (example using scp)
scp myapp.tar.gz user@target-host:/tmp/

# On target host
gunzip -c /tmp/myapp.tar.gz | docker load
```

## Image Size Optimization

Optimizing Docker image size is crucial for faster deployments, reduced storage costs, and improved security.

### Base Image Selection

The base image significantly impacts your final image size. Choose the smallest base image that satisfies your requirements.

**Common Base Images by Size**:
1. **Scratch** (~0 MB): Empty image, requires statically compiled applications
2. **Alpine** (~5 MB): Minimal Linux distribution
3. **Debian Slim** (~50-80 MB): Smaller Debian-based images
4. **Ubuntu/Debian** (~100-200 MB): Full distributions
5. **Language-specific** (varies): Optimized for specific languages (e.g., node:alpine)

**Examples**:
```dockerfile
# Large base image
FROM ubuntu:20.04  # ~80MB+

# Medium base image
FROM python:3.9-slim  # ~40-60MB

# Small base image
FROM python:3.9-alpine  # ~15-20MB

# Minimal base image (for Go)
FROM golang:1.17-alpine AS builder
RUN go build -o app .
FROM scratch  # ~0MB
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

### Layer Minimization

Reduce the number of layers and combine related operations.

**Bad Practice**:
```dockerfile
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
RUN pip install requests
RUN pip install flask
RUN apt-get clean
```

**Good Practice**:
```dockerfile
FROM ubuntu:20.04
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip install requests flask && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Multi-stage Builds

Use multiple stages to separate build dependencies from runtime dependencies.

**Example for a Go Application**:
```dockerfile
# Build stage
FROM golang:1.17 AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# Runtime stage
FROM alpine:3.14
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/app .
CMD ["./app"]
```

**Example for a Node.js Application**:
```dockerfile
# Build stage
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage
FROM node:16-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production
CMD ["npm", "start"]
```

### .dockerignore File

Use a `.dockerignore` file to exclude unnecessary files from the build context.

**Example .dockerignore**:
```
# Version control
.git
.gitignore

# Build artifacts
/node_modules
/dist
/build
/.next
*.log

# Development files
/.vscode
/.idea
*.md
/tests
/doc

# Environment
.env*
*.env
*.pem
*.key

# Large binaries
*.gz
*.tar
*.zip
```

### Image Analysis Tools

**Dive**: Interactive tool for exploring image layers

```bash
# Install Dive (Linux)
wget https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb
sudo apt install ./dive_0.10.0_linux_amd64.deb

# Analyze an image
dive nginx:latest
```

**docker-slim**: Automatically optimize and secure your Docker containers

```bash
# Install docker-slim
curl -sL https://raw.githubusercontent.com/docker-slim/docker-slim/master/scripts/install-dockerslim.sh | sudo -E bash -

# Optimize an image
docker-slim build --http-probe your-image:tag
```

**Trivy**: Vulnerability scanner for containers and other artifacts

```bash
# Install Trivy
sudo apt-get install -y trivy

# Scan an image
trivy image nginx:latest
```

## Docker Registry Ecosystem

Docker registries store and distribute Docker images, enabling collaboration and deployment across environments.

### Registry Types

**Public Registries**:
- **Docker Hub**: Default registry for Docker images
- **GitHub Container Registry (GHCR)**: Integrated with GitHub repositories
- **Quay.io**: Red Hat's container registry service

**Private Registry Options**:
- **Self-hosted**: Docker Registry, Harbor, Nexus Repository
- **Cloud Provider Solutions**: Amazon ECR, Google Container Registry, Azure Container Registry

### Registry Architecture

The Docker Registry follows a RESTful API design for image storage and retrieval.

**Key Components**:
- **Storage Backend**: Where blobs and manifests are stored
- **API Frontend**: Handles REST requests for push/pull operations
- **Authentication System**: Controls access to repositories
- **Notification System**: Triggers webhooks on registry events

**Common Operations**:
- **Push**: Upload images to a registry
- **Pull**: Download images from a registry
- **Delete**: Remove images from a registry
- **Catalog**: List available images

### Storage Backends

Docker Registry supports various storage options for different scalability and durability needs.

**Supported Backends**:
- **Filesystem**: Local disk storage (default)
- **S3**: Amazon S3 or compatible services
- **Azure**: Azure Blob Storage
- **Google Cloud Storage**: GCS
- **Swift**: OpenStack Swift storage
- **HDFS**: Hadoop Distributed File System

**Storage Configuration Example** (using S3):
```yaml
# config.yml for Docker Registry
storage:
  s3:
    accesskey: awsaccesskey
    secretkey: awssecretkey
    region: us-west-1
    bucket: docker-registry
    secure: true
    v4auth: true
    chunksize: 5242880
    rootdirectory: /registry
```

## Docker Hub In-Depth

Docker Hub is Docker's official registry service and the default registry for Docker commands.

### Account Setup and Management

```bash
# Sign up for Docker Hub (interactive)
docker login

# Login with credentials
docker login -u username -p password

# Create access token (preferred over password)
# 1. Go to Docker Hub > Account Settings > Security > New Access Token
# 2. Login with token
docker login -u username --password-stdin < token.txt
```

**Best Practices**:
- Use access tokens instead of passwords
- Create tokens with limited scope and expiration
- Rotate tokens regularly
- Store tokens securely in secrets management

### Repository Management

```bash
# Tag an image for Docker Hub
docker tag myapp:latest username/myapp:latest

# Push image to Docker Hub
docker push username/myapp:latest

# Pull image from Docker Hub
docker pull username/myapp:latest
```

**Automated Builds**:
Docker Hub can automatically build images from a Git repository.
1. Connect GitHub/BitBucket account in Docker Hub
2. Create automated build repository
3. Configure build rules based on branches/tags
4. Push to Git repository to trigger builds

**Repository Visibility Options**:
- **Public**: Available to everyone
- **Private**: Available only to you and collaborators
- **Organization**: Available to organization members based on permissions

### Organizations and Teams

**Organization Management**:
1. Create an organization in Docker Hub
2. Add members to the organization
3. Create teams within the organization
4. Assign permissions to teams
5. Add repositories to teams

**Permission Levels**:
- **Read**: Pull images
- **Write**: Pull and push images
- **Admin**: Full repository management

**CLI Commands for Organizations**:
```bash
# Login as organization member
docker login

# Tag image for organization repository
docker tag myapp:latest orgname/reponame:latest

# Push to organization repository
docker push orgname/reponame:latest
```

### Docker Hub API

Docker Hub provides a REST API for automation and integration.

**API Authentication**:
```bash
# Get JWT token
curl -s -H "Content-Type: application/json" \
     -X POST \
     -d '{"username": "username", "password": "password"}' \
     https://hub.docker.com/v2/users/login/ | jq -r .token
```

**Repository Operations**:
```bash
# List repositories (with token from above)
curl -s -H "Authorization: JWT $TOKEN" \
     https://hub.docker.com/v2/repositories/username/ | jq .

# Get repository details
curl -s -H "Authorization: JWT $TOKEN" \
     https://hub.docker.com/v2/repositories/username/reponame/ | jq .
```

**Webhooks**:
Docker Hub webhooks can trigger notifications on push events, useful for CI/CD pipelines.

## Private Registry Setup

### Docker Registry Deployment

**Basic Deployment**:
```bash
# Run registry container
docker run -d -p 5000:5000 --name registry registry:2

# Test the registry
docker pull ubuntu:latest
docker tag ubuntu:latest localhost:5000/ubuntu:latest
docker push localhost:5000/ubuntu:latest
```

**Persistent Storage**:
```bash
# Run with volume mount
docker run -d -p 5000:5000 --name registry \
  -v /var/lib/registry:/var/lib/registry \
  registry:2
```

**Production Deployment with TLS**:
```bash
# Create directory for certificates
mkdir -p /opt/registry/certs

# Generate self-signed certificates
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/domain.key \
  -x509 -days 365 \
  -out /opt/registry/certs/domain.crt

# Run registry with TLS
docker run -d -p 5000:5000 --name registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

### Registry Configuration

Docker Registry is configured using a YAML file or environment variables.

**Basic Configuration File** (`config.yml`):
```yaml
version: 0.1
log:
  level: info
  formatter: text
  fields:
    service: registry
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

**Running with Configuration File**:
```bash
docker run -d -p 5000:5000 --name registry \
  -v /opt/registry/config.yml:/etc/docker/registry/config.yml \
  registry:2
```

**Using Environment Variables**:
```bash
docker run -d -p 5000:5000 --name registry \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
  registry:2
```

### Garbage Collection

Registry garbage collection reclaims storage by removing unreferenced blobs.

**Garbage Collection Process**:
```bash
# Stop registry first (for safety)
docker stop registry

# Run garbage collection
docker run --rm \
  -v /opt/registry:/var/lib/registry \
  registry:2 garbage-collect /etc/docker/registry/config.yml

# Restart registry
docker start registry
```

**Online Garbage Collection** (Registry v2.7+):
```yaml
# In config.yml
storage:
  delete:
    enabled: true
```

### Registry Notifications

Configure the registry to send webhook notifications for events.

**Example Configuration**:
```yaml
# In config.yml
notifications:
  endpoints:
    - name: webhook
      url: https://webhook.example.com/notify
      headers:
        Authorization: [Bearer <token>]
      timeout: 500ms
      threshold: 5
      backoff: 1s
      events:
        - push
        - pull
```

## Registry Security

### Authentication Options

**Basic Authentication**:
```bash
# Create htpasswd file
mkdir -p /opt/registry/auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn username password > /opt/registry/auth/htpasswd

# Run registry with authentication
docker run -d -p 5000:5000 --name registry \
  -v /opt/registry/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  registry:2
```

**Token Authentication**:
For more advanced authentication scenarios, use token-based authentication with an external authentication service.

```yaml
# In config.yml
auth:
  token:
    realm: https://auth.example.com/token
    service: container_registry
    issuer: auth_service
    rootcertbundle: /path/to/auth.crt
```

### Transport Layer Security (TLS)

**Self-Signed Certificates**:
```bash
# Generate CA key and certificate
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt

# Generate server key
openssl genrsa -out registry.key 4096

# Generate CSR
openssl req -new -key registry.key -out registry.csr

# Create config file for SAN
cat > registry.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = registry.example.com
DNS.2 = registry
IP.1 = 192.168.1.10
EOF

# Generate certificate
openssl x509 -req -in registry.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out registry.crt -days 365 \
  -extfile registry.cnf -extensions v3_req
```

**Client Configuration**:
```bash
# Create client certificates directory
sudo mkdir -p /etc/docker/certs.d/registry.example.com:5000

# Copy CA certificate
sudo cp ca.crt /etc/docker/certs.d/registry.example.com:5000/ca.crt
```

### Image Signing with Docker Content Trust

Docker Content Trust (DCT) implements the Notary service for signing and verifying Docker images.

**Enable Content Trust**:
```bash
# Enable globally
export DOCKER_CONTENT_TRUST=1

# Use for a single command
docker push --disable-content-trust=false username/image:tag
```

**Key Management**:
DCT uses two key types:
- **Root Key**: Long-term identity key for the repository
- **Repository Key**: Per-repository signing key

```bash
# Initialize trust for a repository
docker trust init username/image

# Sign an image when pushing
docker trust sign username/image:tag

# Inspect trust data
docker trust inspect username/image:tag
```

### Role-Based Access Control

For enterprises, implement RBAC using an identity provider and token-based authentication.

**Common RBAC Patterns**:
- **Organizations and Teams**: Group users and assign repository permissions
- **Repository-specific Roles**: Read, Write, Admin permissions
- **CI/CD Service Accounts**: Limited-scope accounts for automation

## Enterprise Registry Solutions

### Harbor

Harbor is an open-source container registry that extends the Docker Registry with additional features.

**Key Features**:
- RBAC with LDAP/AD integration
- Image vulnerability scanning
- Content signing and validation
- Replication between registries
- Project-based image management
- Auditing and logging
- Helm chart repository support

**Installation (using Docker Compose)**:
```bash
# Download Harbor installer
wget https://github.com/goharbor/harbor/releases/download/v2.5.0/harbor-online-installer-v2.5.0.tgz
tar xzvf harbor-online-installer-v2.5.0.tgz
cd harbor

# Edit configuration
cp harbor.yml.tmpl harbor.yml
# Edit harbor.yml to configure hostname, certificates, storage, etc.

# Run the installer
sudo ./install.sh
```

**Basic Harbor Configuration** (`harbor.yml`):
```yaml
hostname: harbor.example.com
http:
  port: 80
https:
  port: 443
  certificate: /your/certificate/path
  private_key: /your/private/key/path
harbor_admin_password: Harbor12345
database:
  password: root123
  max_idle_conns: 100
  max_open_conns: 900
data_volume: /data
```

### JFrog Artifactory

Artifactory is a universal artifact repository manager that includes Docker registry functionality.

**Key Features**:
- Multi-repository support (Docker, Maven, npm, etc.)
- Fine-grained access control
- Advanced security features
- Build integration
- Custom metadata and properties
- High availability options

**Installation with Docker**:
```bash
# Pull and run Artifactory
docker run --name artifactory -d \
  -p 8081:8081 -p 8082:8082 \
  -v /data/artifactory:/var/opt/jfrog/artifactory \
  docker.bintray.io/jfrog/artifactory-pro:latest
```

**Using Artifactory as Docker Registry**:
```bash
# Login to Artifactory Docker registry
docker login myartifactory.example.com:8082

# Tag and push image
docker tag myapp:latest myartifactory.example.com:8082/docker-local/myapp:latest
docker push myartifactory.example.com:8082/docker-local/myapp:latest
```

### Nexus Repository

Sonatype Nexus Repository is a repository manager that supports multiple formats, including Docker.

**Key Features**:
- Multi-format repository manager
- Proxy and caching for Docker Hub
- RBAC with LDAP integration
- Component lifecycle policies
- Security vulnerability monitoring
- Repository health check

**Installation with Docker**:
```bash
# Pull and run Nexus
docker run -d --name nexus \
  -p 8081:8081 -p 8082:8082 -p 8083:8083 \
  -v /data/nexus:/nexus-data \
  sonatype/nexus3:latest
```

**Configuring Docker Repositories in Nexus**:
1. Login to Nexus UI (default: admin/admin123)
2. Create repositories:
   - docker-hosted: Private Docker repository
   - docker-proxy: Proxy to Docker Hub
   - docker-group: Group combining hosted and proxy

**Using Nexus as Docker Registry**:
```bash
# Login to Nexus Docker registry
docker login mynexus.example.com:8082

# Tag and push image
docker tag myapp:latest mynexus.example.com:8082/myapp:latest
docker push mynexus.example.com:8082/myapp:latest
```

### Cloud Provider Registries

Major cloud providers offer managed container registry services.

**Amazon Elastic Container Registry (ECR)**:
```bash
# Install AWS CLI and configure credentials
aws configure

# Create ECR repository
aws ecr create-repository --repository-name myapp

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com

# Tag and push image
docker tag myapp:latest ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/myapp:latest
docker push ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/myapp:latest
```

**Google Container Registry (GCR)**:
```bash
# Install gcloud CLI and configure
gcloud auth login
gcloud auth configure-docker

# Tag and push image
docker tag myapp:latest gcr.io/PROJECT_ID/myapp:latest
docker push gcr.io/PROJECT_ID/myapp:latest
```

**Azure Container Registry (ACR)**:
```bash
# Install Azure CLI and login
az login

# Create container registry
az acr create --resource-group myResourceGroup --name myregistry --sku Basic

# Login to ACR
az acr login --name myregistry

# Tag and push image
docker tag myapp:latest myregistry.azurecr.io/myapp:latest
docker push myregistry.azurecr.io/myapp:latest
```

## Image Management Workflow

Effective image management workflows enable consistent, secure, and efficient container deployments.

### Tagging Convention

A consistent tagging strategy ensures proper versioning and traceability.

**Common Tagging Patterns**:

1. **Semantic Versioning**:
```bash
# Major.Minor.Patch
docker tag myapp:latest myapp:1.2.3

# Major.Minor only
docker tag myapp:latest myapp:1.2
```

2. **Git-based Tagging**:
```bash
# By commit hash (short)
docker tag myapp:latest myapp:git-$(git rev-parse --short HEAD)

# By branch name
docker tag myapp:latest myapp:branch-$(git rev-parse --abbrev-ref HEAD)
```

3. **Build Information**:
```bash
# Build number (CI/CD)
docker tag myapp:latest myapp:build-123

# Date-based
docker tag myapp:latest myapp:$(date +%Y%m%d)
```

4. **Environment-specific**:
```bash
# Environment name
docker tag myapp:1.2.3 myapp:1.2.3-dev
docker tag myapp:1.2.3 myapp:1.2.3-staging
docker tag myapp:1.2.3 myapp:1.2.3-prod
```

**Automated Tagging Script**:
```bash
#!/bin/bash
# Script to generate a comprehensive tag set

# Required variables
APP_NAME="myapp"
VERSION="1.2.3"
GIT_HASH=$(git rev-parse --short HEAD)
BUILD_NUM=${CI_BUILD_NUMBER:-local}
DATE=$(date +%Y%m%d)
ENV=${DEPLOY_ENV:-dev}

# Generate tag set
docker tag ${APP_NAME}:latest ${APP_NAME}:${VERSION}
docker tag ${APP_NAME}:latest ${APP_NAME}:${VERSION}-${ENV}
docker tag ${APP_NAME}:latest ${APP_NAME}:${VERSION}-${GIT_HASH}
docker tag ${APP_NAME}:latest ${APP_NAME}:${DATE}-${BUILD_NUM}

# Push tags to registry
for tag in ${VERSION} ${VERSION}-${ENV} ${VERSION}-${GIT_HASH} ${DATE}-${BUILD_NUM}; do
    docker push ${APP_NAME}:${tag}
done
```

### Promotion Strategy

Image promotion is the process of moving an image from one environment to another after validation.

**Typical Promotion Flow**:
1. **Build**: Create image with unique tag
2. **Test**: Validate in development/test environment
3. **Promote**: Re-tag for staging environment
4. **Validate**: Test in staging environment
5. **Release**: Re-tag for production environment

**Promotion Approaches**:

1. **Tag-based Promotion**:
```bash
# Original build
docker build -t registry.example.com/myapp:build-123 .
docker push registry.example.com/myapp:build-123

# Promote to staging
docker pull registry.example.com/myapp:build-123
docker tag registry.example.com/myapp:build-123 registry.example.com/myapp:staging
docker push registry.example.com/myapp:staging

# Promote to production
docker pull registry.example.com/myapp:staging
docker tag registry.example.com/myapp:staging registry.example.com/myapp:production
docker push registry.example.com/myapp:production
```

2. **Repository-based Promotion**:
```bash
# Original build to dev repository
docker build -t registry.example.com/dev/myapp:1.2.3 .
docker push registry.example.com/dev/myapp:1.2.3

# Promote to staging repository
docker pull registry.example.com/dev/myapp:1.2.3
docker tag registry.example.com/dev/myapp:1.2.3 registry.example.com/staging/myapp:1.2.3
docker push registry.example.com/staging/myapp:1.2.3

# Promote to production repository
docker pull registry.example.com/staging/myapp:1.2.3
docker tag registry.example.com/staging/myapp:1.2.3 registry.example.com/production/myapp:1.2.3
docker push registry.example.com/production/myapp:1.2.3
```

3. **Immutable Tags with Registry Replication**:
Use immutable tags (e.g., SHA-based) and replicate between registries for different environments.

### Image Lifecycle Management

Effective lifecycle management prevents registry bloat and ensures compliance with retention policies.

**Retention Policies**:
1. **Time-based**: Remove images older than a certain period
2. **Count-based**: Keep only N most recent versions
3. **Usage-based**: Remove images not used recently
4. **Tag-based**: Remove specific tag patterns (e.g., old build tags)

**Implementing Retention with Scripts**:

```bash
#!/bin/bash
# Simple retention script for Docker Hub

# Configuration
REPOSITORY="username/myapp"
MAX_TAGS=10
EXCLUDE_TAGS="latest|prod|v[0-9]+\.[0-9]+\.[0-9]+"

# Get all tags
ALL_TAGS=$(curl -s "https://hub.docker.com/v2/repositories/${REPOSITORY}/tags/?page_size=100" | jq -r '.results[].name')

# Filter out excluded tags
DELETABLE_TAGS=$(echo "$ALL_TAGS" | grep -v -E "${EXCLUDE_TAGS}")

# Sort by creation date (requires additional API calls)
# Keep only tags exceeding the maximum
TAGS_TO_DELETE=$(echo "$DELETABLE_TAGS" | sort | head -n -${MAX_TAGS})

# Delete tags
for TAG in $TAGS_TO_DELETE; do
    echo "Deleting ${REPOSITORY}:${TAG}"
    curl -s -X DELETE -H "Authorization: JWT ${TOKEN}" \
         "https://hub.docker.com/v2/repositories/${REPOSITORY}/tags/${TAG}/"
done
```

**Harbor Retention Policy**:
Harbor provides built-in retention policy configuration:
1. Navigate to Projects > Your_Project > Configuration
2. Under Tag Retention, click "Add Rule"
3. Configure retention criteria (e.g., retain last 10 tags matching "release-*")
4. Set rule scope and schedule

## Image Distribution Optimization

Optimizing image distribution reduces download times and bandwidth usage.

### Registry Mirrors

Registry mirrors cache images locally to reduce external bandwidth usage.

**Setting Up a Registry Mirror**:
```bash
# Run registry as a pull-through cache
docker run -d -p 5000:5000 --name registry-mirror \
  -v /data/registry:/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2
```

**Configure Docker to Use Mirror**:
```json
// /etc/docker/daemon.json
{
  "registry-mirrors": ["http://localhost:5000"]
}
```

**Restart Docker**:
```bash
sudo systemctl restart docker
```

### Pull-Through Cache

A pull-through cache retrieves and stores images from upstream registries on demand.

**Creating a Multi-Registry Pull-Through Cache**:
```yaml
# /etc/docker/registry/config.yml
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
proxy:
  remoteurl: https://registry-1.docker.io
  username: [username]  # Optional
  password: [password]  # Optional
http:
  addr: :5000
```

**Advanced Configuration with Multiple Upstreams**:
Use Nexus or Harbor for multiple upstream registries (Docker Hub, GCR, ECR, etc.)

### Offline Environments

For air-gapped environments, images must be transferred without internet access.

**Process**:
1. **Export Images**: Create tar archives from online environment
2. **Transfer Files**: Securely move files to offline environment
3. **Import Images**: Load images into offline registry

**Export Script**:
```bash
#!/bin/bash
# Export required images for offline use

# List of images
IMAGES=(
  "nginx:1.21"
  "redis:6.2"
  "postgres:13"
  "myapp:1.2.3"
)

# Create export directory
EXPORT_DIR="docker-images-export"
mkdir -p ${EXPORT_DIR}

# Export each image
for IMAGE in "${IMAGES[@]}"; do
  FILENAME=$(echo ${IMAGE} | tr '/:' '_')
  echo "Exporting ${IMAGE} to ${EXPORT_DIR}/${FILENAME}.tar"
  docker pull ${IMAGE}
  docker save ${IMAGE} -o ${EXPORT_DIR}/${FILENAME}.tar
done

# Create archive
tar -czf docker-images.tar.gz ${EXPORT_DIR}
echo "Created archive: docker-images.tar.gz"
```

**Import Script**:
```bash
#!/bin/bash
# Import images to offline registry

# Extract archive
tar -xzf docker-images.tar.gz

# Registry information
REGISTRY="localhost:5000"

# Import each image
for IMAGE_FILE in docker-images-export/*.tar; do
  echo "Loading ${IMAGE_FILE}"
  docker load -i ${IMAGE_FILE}
  
  # Get image name
  IMAGE_NAME=$(docker images --format "{{.Repository}}:{{.Tag}}" | head -1)
  
  # Tag for local registry
  NEW_TAG="${REGISTRY}/${IMAGE_NAME}"
  echo "Tagging ${IMAGE_NAME} as ${NEW_TAG}"
  docker tag ${IMAGE_NAME} ${NEW_TAG}
  
  # Push to local registry
  echo "Pushing ${NEW_TAG}"
  docker push ${NEW_TAG}
done

echo "Import complete"
```

## Hands-On Exercises

### Exercise 1: Image Analysis

**Objective**: Analyze Docker image structure and identify optimization opportunities.

**Steps**:
1. Pull a sample image:
```bash
docker pull node:14
```

2. View image history:
```bash
docker image history node:14
```

3. Inspect image details:
```bash
docker image inspect node:14
```

4. Use Dive tool to analyze layers:
```bash
dive node:14
```

5. Compare with optimized image:
```bash
docker pull node:14-alpine
dive node:14-alpine
```

6. Document size differences and layer composition.

### Exercise 2: Setting Up a Private Registry

**Objective**: Deploy and configure a secure private Docker registry.

**Steps**:
1. Generate TLS certificates:
```bash
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/domain.key -x509 -days 365 \
  -out certs/domain.crt
```

2. Create authentication file:
```bash
mkdir -p auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn username password > auth/htpasswd
```

3. Create registry configuration:
```bash
mkdir -p config
cat > config/config.yml <<EOF
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
auth:
  htpasswd:
    realm: Registry Realm
    path: /auth/htpasswd
http:
  addr: :5000
  tls:
    certificate: /certs/domain.crt
    key: /certs/domain.key
EOF
```

4. Start the registry:
```bash
docker run -d -p 5000:5000 --name registry \
  -v $(pwd)/config:/etc/docker/registry \
  -v $(pwd)/auth:/auth \
  -v $(pwd)/certs:/certs \
  -v $(pwd)/data:/var/lib/registry \
  registry:2
```

5. Configure Docker client:
```bash
# Copy certificate to Docker certs directory
sudo mkdir -p /etc/docker/certs.d/localhost:5000
sudo cp certs/domain.crt /etc/docker/certs.d/localhost:5000/ca.crt
```

6. Test registry:
```bash
docker login localhost:5000 -u username -p password
docker pull alpine:latest
docker tag alpine:latest localhost:5000/alpine:latest
docker push localhost:5000/alpine:latest
docker rmi localhost:5000/alpine:latest
docker pull localhost:5000/alpine:latest
```

### Exercise 3: Image Optimization

**Objective**: Optimize a Docker image for size and security.

**Sample Application**:
1. Create a simple Python web application:
```bash
mkdir -p app
cat > app/app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, Docker Workshop!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

cat > app/requirements.txt <<EOF
flask==2.0.1
EOF
```

2. Create initial Dockerfile:
```bash
cat > app/Dockerfile.original <<EOF
FROM ubuntu:20.04
RUN apt-get update
RUN apt-get install -y python3 python3-pip
WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY . .
EXPOSE 8080
CMD ["python3", "app.py"]
EOF
```

3. Build and analyze original image:
```bash
cd app
docker build -t myapp:original -f Dockerfile.original .
docker images myapp:original
```

4. Create optimized Dockerfile:
```bash
cat > Dockerfile.optimized <<EOF
FROM python:3.9-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.9-alpine
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8080
USER nobody
CMD ["python", "app.py"]
EOF
```

5. Build and analyze optimized image:
```bash
docker build -t myapp:optimized -f Dockerfile.optimized .
docker images myapp:optimized
```

6. Compare and document size reduction:
```bash
docker images | grep myapp
```

## Troubleshooting

### Common Registry Issues

1. **Authentication Problems**:
```bash
# Error: unauthorized: authentication required
# Solution: Ensure credentials are correct
docker logout registry.example.com
docker login registry.example.com
```

2. **Certificate Issues**:
```bash
# Error: x509: certificate signed by unknown authority
# Solution: Add certificate to Docker trust store
sudo mkdir -p /etc/docker/certs.d/registry.example.com:5000
sudo cp ca.crt /etc/docker/certs.d/registry.example.com:5000/ca.crt
```

3. **Network Connectivity**:
```bash
# Test registry connection
curl -v https://registry.example.com:5000/v2/
```

4. **Storage Issues**:
```bash
# Check registry logs
docker logs registry

# Check disk space
df -h /var/lib/registry
```

### Image Pull/Push Problems

1. **Rate Limiting**:
Docker Hub enforces rate limits for anonymous and free authenticated users.

```bash
# Error: toomanyrequests: Too Many Requests.
# Solution: Authenticate or use registry mirror
docker login
```

2. **Layer Already Exists**:
```bash
# Error: layer already exists
# Solution: Usually harmless, can ignore
```

3. **Insufficient Disk Space**:
```bash
# Error: no space left on device
# Solution: Clean up images and containers
docker system prune -a
```

4. **Image Digest Mismatch**:
```bash
# Error: image digest mismatch
# Solution: Retry push/pull; check for corruption
docker pull --no-cache image:tag
```

## References

- [Docker Registry Documentation](https://docs.docker.com/registry/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/)
- [Harbor Documentation](https://goharbor.io/docs/)
- [Registry API Specification](https://docs.docker.com/registry/spec/api/)
- [OCI Image Specification](https://github.com/opencontainers/image-spec)
- [Docker Storage Drivers](https://docs.docker.com/storage/storagedriver/)
- [Dive Image Analysis Tool](https://github.com/wagoodman/dive)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)