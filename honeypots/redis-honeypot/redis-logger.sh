#!/bin/sh

# Redis Honeypot Logger
# Monitors Redis log and converts to structured JSON format

LOG_FILE="/var/log/redis/redis.log"
JSON_LOG="/var/log/redis/redis-honeypot.json"

echo "Starting Redis honeypot logger..."

# Function to extract client info and log as JSON
tail -F "$LOG_FILE" 2>/dev/null | while read line; do
    if echo "$line" | grep -q "Accepted\|Client"; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        # Extract IP address
        src_ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        
        # Extract port if available
        port=$(echo "$line" | grep -oE ':([0-9]+)' | cut -d':' -f2 | head -1)
        
        # Determine action type
        if echo "$line" | grep -q "Accepted"; then
            action="connection_accepted"
        else
            action="client_activity"
        fi
        
        # Create JSON log entry
        json_entry="{\"timestamp\":\"$timestamp\",\"service\":\"redis\",\"src_ip\":\"${src_ip:-unknown}\",\"src_port\":\"${port:-unknown}\",\"action\":\"$action\",\"raw_log\":\"$line\",\"honeypot\":\"redis\"}"
        
        echo "$json_entry" >> "$JSON_LOG"
    fi
    
    # Log Redis commands
    if echo "$line" | grep -qE "(GET|SET|DEL|FLUSHALL|CONFIG|EVAL)"; then
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        command=$(echo "$line" | grep -oE "(GET|SET|DEL|FLUSHALL|CONFIG|EVAL)[^\"]*" | head -1)
        src_ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
        
        json_entry="{\"timestamp\":\"$timestamp\",\"service\":\"redis\",\"src_ip\":\"${src_ip:-unknown}\",\"command\":\"$command\",\"action\":\"command_execution\",\"raw_log\":\"$line\",\"honeypot\":\"redis\"}"
        
        echo "$json_entry" >> "$JSON_LOG"
    fi
done