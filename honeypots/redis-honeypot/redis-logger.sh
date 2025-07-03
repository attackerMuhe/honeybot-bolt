#!/bin/sh

# Redis Honeypot Logger - Standard TCP logging
# Monitors Redis log and converts to structured JSON format

LOG_FILE="/var/log/redis/redis.log"
JSON_LOG="/var/log/redis/redis-honeypot.json"

echo "Starting Redis honeypot logger..."

# Function to extract client info and log as JSON
tail -F "$LOG_FILE" 2>/dev/null | while read line; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi
    
    # Process connection events
    if echo "$line" | grep -q "Accepted\|Client\|Connection"; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        # Extract IP address from standard Redis logs
        src_ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        port=$(echo "$line" | grep -oE ':([0-9]+)' | cut -d':' -f2 | head -1)
        
        # Determine action type
        if echo "$line" | grep -q "Accepted"; then
            action="connection_accepted"
        elif echo "$line" | grep -q "closed connection"; then
            action="connection_closed"
        else
            action="client_activity"
        fi
        
        # Skip localhost connections (health checks)
        if [ "$src_ip" = "127.0.0.1" ] || [ "$src_ip" = "localhost" ]; then
            continue
        fi
        
        # Create JSON log entry
        json_entry="{\"timestamp\":\"$timestamp\",\"service\":\"redis\",\"src_ip\":\"${src_ip:-unknown}\",\"src_port\":\"${port:-unknown}\",\"action\":\"$action\",\"raw_log\":\"$(echo "$line" | sed 's/"/\\"/g')\",\"honeypot\":\"redis\"}"
        
        echo "$json_entry" >> "$JSON_LOG"
    fi
    
    # Log Redis commands with enhanced detection
    if echo "$line" | grep -qE "(GET|SET|DEL|FLUSHALL|CONFIG|EVAL|PING|INFO|KEYS|SCAN|HGET|HSET|LPUSH|RPUSH|SADD|ZADD)"; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        # Extract command more precisely
        command=$(echo "$line" | grep -oE "(GET|SET|DEL|FLUSHALL|CONFIG|EVAL|PING|INFO|KEYS|SCAN|HGET|HSET|LPUSH|RPUSH|SADD|ZADD)[^\"]*" | head -1)
        
        # Extract IP from standard Redis logs
        src_ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        
        # Skip localhost connections (health checks)
        if [ "$src_ip" = "127.0.0.1" ] || [ "$src_ip" = "localhost" ]; then
            continue
        fi
        
        # Determine threat level based on command
        threat_level="low"
        if echo "$command" | grep -qE "(FLUSHALL|CONFIG|EVAL|KEYS)"; then
            threat_level="high"
        elif echo "$command" | grep -qE "(SET|DEL|HSET|LPUSH|RPUSH|SADD|ZADD)"; then
            threat_level="medium"
        fi
        
        json_entry="{\"timestamp\":\"$timestamp\",\"service\":\"redis\",\"src_ip\":\"${src_ip:-unknown}\",\"command\":\"$command\",\"action\":\"command_execution\",\"threat_level\":\"$threat_level\",\"raw_log\":\"$(echo "$line" | sed 's/"/\\"/g')\",\"honeypot\":\"redis\"}"
        
        echo "$json_entry" >> "$JSON_LOG"
    fi
    
    # Log authentication attempts
    if echo "$line" | grep -qE "(AUTH|HELLO)"; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        # Extract IP from standard Redis logs
        src_ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        
        # Skip localhost connections
        if [ "$src_ip" = "127.0.0.1" ] || [ "$src_ip" = "localhost" ]; then
            continue
        fi
        
        json_entry="{\"timestamp\":\"$timestamp\",\"service\":\"redis\",\"src_ip\":\"${src_ip:-unknown}\",\"action\":\"authentication_attempt\",\"threat_level\":\"medium\",\"raw_log\":\"$(echo "$line" | sed 's/"/\\"/g')\",\"honeypot\":\"redis\"}"
        
        echo "$json_entry" >> "$JSON_LOG"
    fi
done