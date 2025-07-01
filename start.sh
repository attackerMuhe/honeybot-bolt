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

# Set proper permissions for honeypot scripts
chmod +x honeypots/redis-honeypot/redis-logger.sh

# Fix Logstash config permissions
echo "🔧 Setting Logstash config permissions..."
sudo chown -R 1000:1000 infrastructure/logstash/config/
sudo chmod -R 644 infrastructure/logstash/config/

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

# Start honeypots
echo "🍯 Starting honeypots..."
cd ../honeypots
docker-compose up -d

echo ""
echo "🎉 System startup complete!"
echo ""
echo "📊 Kibana Dashboard: http://localhost:5601"
echo "🔍 Elasticsearch API: http://localhost:9200"
echo ""
echo "🍯 Active Honeypots:"
echo "   • SSH (Cowrie):      localhost:2222, localhost:2223"
echo "   • FTP (Dionaea):     localhost:21"
echo "   • SMTP (Dionaea):    localhost:25"
echo "   • SMB (Dionaea):     localhost:445"
echo "   • MSSQL (Dionaea):   localhost:1433"
echo "   • MySQL (Dionaea):   localhost:3306"
echo "   • PostgreSQL (Dionaea): localhost:5432"
echo "   • Redis:             localhost:6379"
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
echo "⚠️  Security Notice: This system deploys multiple honeypots"
echo "   Ensure you understand the security implications and comply"
echo "   with local laws and regulations."