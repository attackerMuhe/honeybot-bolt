#!/bin/bash

# Production-Grade Honeypot Log Aggregation System Startup Script

set -e

echo "🍯 Starting Production-Grade Honeypot Log Aggregation System"
echo "============================================================"

# Create log directories
echo "📁 Creating log directories..."
mkdir -p honeypots/cowrie-logs
mkdir -p honeypots/dionaea-logs
mkdir -p honeypots/redis-logs
mkdir -p honeypots/snmp-logs

# Set proper permissions for honeypot scripts and configs
echo "🔧 Setting permissions..."
chmod +x honeypots/redis-honeypot/redis-logger.sh
chmod 644 honeypots/cowrie/cowrie.cfg
chmod 644 honeypots/redis-honeypot/redis.conf

# Fix Logstash config permissions
echo "🔧 Setting Logstash config permissions..."
sudo chown -R 1000:1000 infrastructure/logstash/config/
sudo chmod -R 755 infrastructure/logstash/config/

# Start infrastructure first
echo "🔧 Starting ELK Stack infrastructure..."
cd infrastructure
docker-compose up -d

echo "⏳ Waiting for Elasticsearch to be ready..."
while ! curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
    echo "   Waiting for Elasticsearch..."
    sleep 5
done

echo "✅ Elasticsearch is ready!"

echo "⏳ Waiting for Kibana to be ready..."
while ! curl -s http://localhost:5601/api/status | grep -q '"overall":{"level":"available"}'; do
    echo "   Waiting for Kibana..."
    sleep 5
done

echo "✅ Kibana is ready!"

# Build and start honeypots
echo "🍯 Building and starting honeypots..."
cd ../honeypots

# Build HAProxy image
echo "🔧 Building HAProxy load balancer..."
docker-compose build haproxy

# Start all services
docker-compose up -d

# Wait for backend services to be healthy before checking HAProxy
echo "⏳ Waiting for Cowrie to be ready..."
while ! docker-compose exec -T cowrie netstat -tuln | grep -q ":2222.*LISTEN"; do
    echo "   Waiting for Cowrie SSH service..."
    sleep 3
done

echo "✅ Cowrie is ready!"

echo "⏳ Waiting for Redis honeypot to be ready..."
while ! docker-compose exec -T redis-honeypot redis-cli ping 2>/dev/null | grep -q "PONG"; do
    echo "   Waiting for Redis service..."
    sleep 3
done

echo "✅ Redis honeypot is ready!"

echo "⏳ Waiting for HAProxy to be ready..."
sleep 5
while ! curl -s http://localhost:8404/stats > /dev/null 2>&1; do
    echo "   Waiting for HAProxy..."
    sleep 5
done

echo "✅ HAProxy is ready!"

# Verify backend connectivity
echo "🔍 Verifying HAProxy backend connectivity..."
sleep 10

# Check HAProxy stats for backend health
if curl -s http://localhost:8404/stats | grep -q "cowrie.*UP"; then
    echo "✅ Cowrie backend is healthy in HAProxy"
else
    echo "⚠️  Cowrie backend may still be initializing..."
fi

if curl -s http://localhost:8404/stats | grep -q "redis.*UP"; then
    echo "✅ Redis backend is healthy in HAProxy"
else
    echo "⚠️  Redis backend may still be initializing..."
fi

echo ""
echo "🎉 System startup complete!"
echo ""
echo "📊 Kibana Dashboard: http://localhost:5601"
echo "🔍 Elasticsearch API: http://localhost:9200"
echo "📈 HAProxy Stats: http://localhost:8404/stats"
echo ""
echo "🍯 Active Honeypots (with External IP Capture):"
echo "   TCP Services (via HAProxy + PROXY Protocol):"
echo "   • SSH (Cowrie):      localhost:2222, localhost:2223"
echo "   • Redis:             localhost:6379"
echo ""
echo "   Direct Host Network Services (UDP + Multi-Protocol):"
echo "   • FTP (Dionaea):     localhost:21"
echo "   • SMTP (Dionaea):    localhost:25"
echo "   • TFTP (Dionaea):    localhost:69/udp"
echo "   • MS-RPC (Dionaea):  localhost:135"
echo "   • SMB (Dionaea):     localhost:445"
echo "   • MSSQL (Dionaea):   localhost:1433"
echo "   • MySQL (Dionaea):   localhost:3306"
echo "   • PostgreSQL (Dionaea): localhost:5432"
echo "   • SNMP:              localhost:161/udp"
echo ""
echo "📝 Log locations:"
echo "   • Cowrie logs:   honeypots/cowrie-logs/"
echo "   • Dionaea logs:  honeypots/dionaea-logs/"
echo "   • Redis logs:    honeypots/redis-logs/"
echo "   • SNMP logs:     honeypots/snmp-logs/"
echo ""
echo "🔍 To view logs in real-time:"
echo "   docker-compose logs -f [service_name]"
echo ""
echo "🔧 Architecture Notes:"
echo "   • HAProxy handles TCP services with PROXY protocol"
echo "   • Dionaea and SNMP use host networking for UDP traffic"
echo "   • All services now capture real external IP addresses"
echo ""
echo "📈 Monitoring:"
echo "   • HAProxy stats available at http://localhost:8404/stats"
echo "   • Health checks configured for all services"
echo ""
echo "🚀 Adding New Honeypots:"
echo "   • TCP services: Add to HAProxy config + docker-compose"
echo "   • UDP services: Use network_mode: host"
echo "   • Update Filebeat and Logstash configs for log processing"
echo ""
echo "⚠️  Security Notice: This system deploys multiple honeypots"
echo "   • Some services use host networking (reduced isolation)"
echo "   • Ensure you understand the security implications"
echo "   • Comply with local laws and regulations"
echo ""
echo "🔧 Troubleshooting:"
echo "   • If backends show as DOWN in HAProxy stats, wait a few more seconds"
echo "   • Services may take additional time to fully initialize"
echo "   • Check individual service logs: docker-compose logs [service_name]"