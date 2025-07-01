#!/usr/bin/env python3
"""
SNMP Honeypot Server
Listens on UDP port 161 and logs all incoming SNMP requests
"""

import json
import socket
import threading
import time
from datetime import datetime
import os
import sys

LOG_FILE = "/var/log/snmp/snmp-honeypot.json"

def setup_logging():
    """Ensure log directory exists"""
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

def log_snmp_request(src_ip, src_port, data):
    """Log SNMP request in structured JSON format"""
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    log_entry = {
        "timestamp": timestamp,
        "service": "snmp",
        "honeypot": "snmp",
        "src_ip": src_ip,
        "src_port": src_port,
        "protocol": "udp",
        "action": "snmp_request",
        "data_length": len(data),
        "data_hex": data.hex(),
        "data_preview": data[:50].hex() if len(data) > 50 else data.hex()
    }
    
    try:
        # Try to decode basic SNMP info
        if data.startswith(b'\x30'):  # SNMP messages typically start with SEQUENCE tag
            log_entry["snmp_detected"] = True
            
            # Try to extract version (very basic parsing)
            if b'\x02\x01\x00' in data:  # SNMPv1
                log_entry["snmp_version"] = "1"
            elif b'\x02\x01\x01' in data:  # SNMPv2c
                log_entry["snmp_version"] = "2c"
            elif b'\x02\x01\x03' in data:  # SNMPv3
                log_entry["snmp_version"] = "3"
                
            # Check for common community strings
            if b'public' in data:
                log_entry["community_string"] = "public"
            elif b'private' in data:
                log_entry["community_string"] = "private"
                
        # Detect common SNMP operations
        if b'\xa0' in data:  # GetRequest
            log_entry["snmp_operation"] = "GetRequest"
        elif b'\xa1' in data:  # GetNextRequest
            log_entry["snmp_operation"] = "GetNextRequest"
        elif b'\xa2' in data:  # Response
            log_entry["snmp_operation"] = "Response"
        elif b'\xa3' in data:  # SetRequest
            log_entry["snmp_operation"] = "SetRequest"
        elif b'\xa5' in data:  # GetBulkRequest
            log_entry["snmp_operation"] = "GetBulkRequest"
            
    except Exception as e:
        log_entry["parsing_error"] = str(e)
    
    # Write to log file
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
            f.flush()
    except Exception as e:
        print(f"Error writing to log file: {e}", file=sys.stderr)

def send_fake_response(sock, addr, original_data):
    """Send a fake SNMP response to make the honeypot more convincing"""
    try:
        # Very basic SNMP response - just echo back with response type
        if len(original_data) > 10:
            # Create a simple error response
            response = b'\x30\x1a\x02\x01\x00\x04\x06public\xa2\x0d\x02\x01\x00\x02\x01\x02\x02\x01\x00\x30\x00'
            sock.sendto(response, addr)
    except Exception as e:
        print(f"Error sending response: {e}", file=sys.stderr)

def snmp_server():
    """Main SNMP server loop"""
    setup_logging()
    
    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        sock.bind(('0.0.0.0', 161))
        print("SNMP Honeypot listening on UDP port 161")
        
        while True:
            try:
                data, addr = sock.recvfrom(4096)
                src_ip, src_port = addr
                
                print(f"SNMP request from {src_ip}:{src_port} - {len(data)} bytes")
                
                # Log the request
                log_snmp_request(src_ip, src_port, data)
                
                # Send fake response in a separate thread to avoid blocking
                threading.Thread(
                    target=send_fake_response,
                    args=(sock, addr, data),
                    daemon=True
                ).start()
                
            except socket.error as e:
                print(f"Socket error: {e}", file=sys.stderr)
                time.sleep(1)
            except Exception as e:
                print(f"Unexpected error: {e}", file=sys.stderr)
                time.sleep(1)
                
    except Exception as e:
        print(f"Failed to bind to port 161: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        sock.close()

if __name__ == "__main__":
    print("Starting SNMP Honeypot Server...")
    try:
        snmp_server()
    except KeyboardInterrupt:
        print("\nShutting down SNMP honeypot...")
    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        sys.exit(1)