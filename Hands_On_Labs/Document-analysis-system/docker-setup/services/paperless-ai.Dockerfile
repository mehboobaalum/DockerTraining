# Use a multi-architecture compatible Node.js (LTS) image as base
FROM --platform=linux/amd64 node:22-slim

WORKDIR /app

# Install system dependencies and clean up in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    gcc \
    curl \
    sqlite3 \
    libsqlite3-dev \
    libc6-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PM2 process manager globally
RUN npm install pm2 -g

# Copy package files for dependency installation
COPY package*.json ./

# Set environment variables to help with native module rebuilding
ENV CFLAGS="-fPIC"
ENV CXXFLAGS="-fPIC"
ENV npm_config_build_from_source=true
ENV npm_config_sqlite=/usr/bin

# Install node dependencies with clean install and rebuild native modules with proper flags
RUN npm ci --only=production && \
    npm rebuild better-sqlite3 --build-from-source --target_arch=x64 --target_platform=linux && \
    npm cache clean --force

# Copy application source code
COPY . .

# Configure persistent data volume
VOLUME ["/app/data"]

# Configure application port
EXPOSE ${PAPERLESS_AI_PORT:-3000}

# Add health check with dynamic port
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PAPERLESS_AI_PORT:-3000}/health || exit 1

# Set production environment
ENV NODE_ENV=production

# Start application with PM2 with user node
CMD ["pm2-runtime", "ecosystem.config.js"]