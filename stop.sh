#!/bin/bash

# Stop all honeypot and infrastructure services

echo "🛑 Stopping Honeypot Log Aggregation System"
echo "==========================================="

# Stop honeypots first
echo "🍯 Stopping honeypots..."
cd honeypots
docker-compose down

# Stop infrastructure
echo "🔧 Stopping ELK Stack..."
cd ../infrastructure
docker-compose down

echo "✅ All services stopped successfully!"
echo ""
echo "💾 Data preservation:"
echo "   • Elasticsearch data: preserved in Docker volume"
echo "   • Log files: preserved in local directories"
echo ""
echo "🔄 To restart: ./start.sh"
echo "🗑️  To completely remove: docker-compose down -v (in each directory)"