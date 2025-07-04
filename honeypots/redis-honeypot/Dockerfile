FROM redis:7.4.4

# Install basic utilities for logging
RUN apt-get update && apt-get install -y \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY redis-logger.sh /usr/local/bin/redis-logger.sh

# Make logger script executable
RUN chmod +x /usr/local/bin/redis-logger.sh

# Create log directory
RUN mkdir -p /var/log/redis

# Expose Redis port
EXPOSE 6379

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD redis-cli ping || exit 1