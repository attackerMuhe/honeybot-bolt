FROM haproxy:2.8-alpine

# Copy HAProxy configuration
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Create stats socket directory and set proper ownership
RUN mkdir -p /var/lib/haproxy && \
    chown -R haproxy:haproxy /var/lib/haproxy

# Expose ports
EXPOSE 2222 2223 6379 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg || exit 1

# Start HAProxy in foreground mode for Docker
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-db"]