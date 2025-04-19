# Docker Compose Cheatsheet

## Basic Structure

```yaml
# docker-compose.yml
version: '3'  # Most current version

services:
  web:
    build:
      context: ./Path
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    volumes:
      - .:/code
  redis:
    image: redis
```

## Version Differences

Docker Compose is now integrated into the official Docker installation:
- V1: `docker-compose ARG`
- V2: `docker compose ARG`

## Essential Commands

### Basic Operations
```sh
docker compose version      # Show version information
docker compose config       # Validate and view the configuration

docker compose up           # Create and start containers
docker compose up -d        # Create and start containers in detached mode
docker compose down         # Stop and remove containers, networks, images, and volumes

docker compose start        # Start existing containers
docker compose stop         # Stop running containers
docker compose restart      # Restart containers
```

### Container Management
```sh
docker compose create       # Create containers without starting them
docker compose run          # Run a one-time command against a service
docker compose exec         # Execute a command in a running container
docker compose pause        # Pause services
docker compose unpause      # Unpause services
docker compose attach       # Attach to a running container
docker compose wait         # Block until containers stop
```

### Monitoring
```sh
docker compose ps           # List containers
docker compose top          # Display running processes
docker compose events       # Receive real-time events from containers
docker compose logs         # View output from containers
```

### Image Management
```sh
docker compose images       # List images used by created containers
docker compose build        # Build or rebuild services
docker compose push         # Push service images
docker compose pull         # Pull service images
docker compose cp           # Copy files/folders between containers and local filesystem
```

## Configuration Reference

### Building Services

```yaml
services:
  web:
    # Build from Dockerfile in current directory
    build: .
    
    # With build arguments
    build:
      context: ./dir
      dockerfile: Dockerfile.dev
      args:
        APP_HOME: app
        
    # Or use existing image
    image: ubuntu:20.04
```

### Ports and Networking

```yaml
services:
  web:
    ports:
      - "3000"                # Random host port
      - "8000:80"             # Specific host:container mapping
      - "127.0.0.1:8001:80"   # Bind to specific interface
    
    expose:
      - "3000"                # Expose ports only to linked services
      
    networks:
      - frontend              # Attach to specific network
```

### Commands and Execution

```yaml
services:
  web:
    # Command to execute when container starts
    command: bundle exec thin -p 3000
    command: [bundle, exec, thin, -p, 3000]  # Array format
    
    # Override the entrypoint
    entrypoint: /app/start.sh
    entrypoint: [php, -d, vendor/bin/phpunit]
```

### Environment Configuration

```yaml
services:
  web:
    # Environment variables
    environment:
      RACK_ENV: development
      DEBUG: 'true'
    
    # Or as array
    environment:
      - RACK_ENV=development
      - DEBUG=true
    
    # From file
    env_file: .env
    env_file: [.env, .development.env]
```

### Dependencies

```yaml
services:
  web:
    # Service links (legacy, use networks instead)
    links:
      - db:database
      - redis
    
    # Start order
    depends_on:
      - db
    
    # Health check dependencies
    depends_on:
      db:
        condition: service_healthy
      db-init:
        condition: service_completed_successfully
```

### Volumes and Storage

```yaml
services:
  db:
    volumes:
      - db-data:/var/lib/postgresql/data    # Named volume
      - ./_data:/backup                     # Bind mount
      - /tmp:/tmp                           # Host path

volumes:
  db-data:    # Define named volume
```

### Restart Policies

```yaml
services:
  web:
    restart: unless-stopped
    # Options: no (default), always, on-failure, unless-stopped
```

## Advanced Features

### Labels

```yaml
services:
  web:
    labels:
      com.example.description: "Web application"
      com.example.environment: "production"
```

### DNS Configuration

```yaml
services:
  web:
    dns:
      - 8.8.8.8
      - 8.8.4.4
    dns_search:
      - dc1.example.com
```

### Device Access

```yaml
services:
  hardware:
    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"
      - "/dev/sda:/dev/xvda:rwm"
```

### Health Checks

```yaml
services:
  web:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Custom Hosts

```yaml
services:
  web:
    extra_hosts:
      - "host.docker.internal:host-gateway"
      - "servicehost:192.168.1.100"
```

### Network Configuration

```yaml
services:
  web:
    networks:
      frontend:
        ipv4_address: 172.16.238.10

networks:
  frontend:
    driver: bridge
    
  backend:
    driver: bridge
    internal: true  # No external connectivity
    
  existing_network:
    external: true  # Use pre-existing network
```

### Resource Constraints

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Complete Example

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - app
    networks:
      - frontend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  app:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        APP_ENV: development
    expose:
      - "8000"
    environment:
      - DB_HOST=db
      - DB_NAME=myapp
      - DB_USER=appuser
      - DB_PASSWORD=apppass
      - REDIS_HOST=redis
    volumes:
      - ./app:/code
      - app-uploads:/app/uploads
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - frontend
      - backend
    restart: unless-stopped

  db:
    image: postgres:13
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=appuser
      - POSTGRES_PASSWORD=apppass
    ports:
      - "5432:5432"
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    restart: unless-stopped

  redis:
    image: redis:alpine
    networks:
      - backend
    restart: unless-stopped
    volumes:
      - redis-data:/data

volumes:
  db-data:
  app-uploads:
  redis-data:

networks:
  frontend:
  backend:
    internal: true
```

This comprehensive cheatsheet covers the most important Docker Compose features and commands, providing a quick reference for configuring and managing multi-container applications.