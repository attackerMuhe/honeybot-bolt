FROM redis:7.4.4

# Install stunnel for PROXY protocol handling
RUN apt-get update && apt-get install -y stunnel4 && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY stunnel.conf /etc/stunnel/stunnel.conf
COPY redis-logger.sh /usr/local/bin/redis-logger.sh

# Make logger script executable
RUN chmod +x /usr/local/bin/redis-logger.sh

# Create log directory
RUN mkdir -p /var/log/redis

# Expose port 6379 (stunnel will listen here)
EXPOSE 6379

# Start both stunnel and Redis
CMD ["sh", "-c", "redis-server /usr/local/etc/redis/redis.conf & stunnel /etc/stunnel/stunnel.conf & /usr/local/bin/redis-logger.sh & wait"]