FROM haproxy:2.8-alpine

# Copy HAProxy configuration
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Create stats socket directory
RUN mkdir -p /var/lib/haproxy

# Expose ports
EXPOSE 2222 2223 6379 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg || exit 1

# Start HAProxy
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]