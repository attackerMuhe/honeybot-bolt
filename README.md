# Production-Grade Honeypot Log Aggregation System

A comprehensive, modular honeypot log aggregation system using the ELK stack with multiple honeypot types for threat detection and analysis. **Now with external IP capture for all honeypots!**

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    External Network                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                 HAProxy Load Balancer                           │
│            (PROXY Protocol Support)                             │
│  • SSH (2222, 2223) → Cowrie                                   │
│  • Redis (6379) → Redis Honeypot                               │
│  • Stats Interface (8404)                                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                   Honeypots                                     │
│                                                                 │
│  TCP Services (via HAProxy):        Host Network Services:      │
│  • Cowrie (SSH)                    • Dionaea (Multi-protocol)  │
│  • Redis Honeypot                  • SNMP Honeypot             │
│                                                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                Log Processing                                   │
│                                                                 │
│  Filebeat → Logstash → Elasticsearch → Kibana                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 New Features: External IP Capture

### Hybrid Architecture for Complete IP Visibility

**TCP Services (HAProxy + PROXY Protocol):**
- **Cowrie (SSH)**: Ports 2222, 2223
- **Redis**: Port 6379
- Uses HAProxy with PROXY protocol to preserve original client IPs
- Centralized load balancing and monitoring

**Host Network Services (Direct Binding):**
- **Dionaea**: FTP(21), SMTP(25), TFTP(69), MS-RPC(135), SMB(445), MSSQL(1433), MySQL(3306), PostgreSQL(5432)
- **SNMP**: Port 161/UDP
- Uses `network_mode: host` for direct external IP capture
- Essential for UDP traffic and multi-protocol services

## Features

- **🌐 External IP Capture**: All honeypots now capture real external IP addresses
- **🔄 Future-Proof Architecture**: Easy to add new honeypots with proper IP capture
- **📊 HAProxy Load Balancer**: Centralized TCP traffic management with stats
- **🛡️ Multi-Protocol Honeypots**: SSH, FTP, SMTP, SMB, Redis, SNMP, and more
- **🔍 Advanced Threat Detection**: Malicious command detection, GeoIP enrichment, DNS reverse lookups
- **📝 Structured Logging**: All logs converted to JSON format with standardized fields
- **🚨 Automated IOC Generation**: Suspicious activities automatically tagged and indexed separately
- **💪 Production Ready**: Health checks, restart policies, resource limits
- **🔧 Modular Architecture**: Easy to add new honeypot types

## Quick Start

### 1. Start the Infrastructure (ELK Stack)

```bash
cd infrastructure
docker-compose up -d
```

This starts:
- **Elasticsearch** on port `9200`
- **Kibana** on port `5601`
- **Logstash** on port `5044`
- **Filebeat** for log collection

### 2. Start the Honeypots

```bash
cd honeypots
docker-compose up -d
```

This starts:
- **HAProxy** on ports `2222`, `2223`, `6379`, `8404` (stats)
- **Cowrie** (SSH honeypot) behind HAProxy
- **Dionaea** (multi-protocol) with host networking
- **Redis honeypot** behind HAProxy
- **SNMP honeypot** with host networking

### 3. Access Dashboards

1. **Kibana Dashboard**: http://localhost:5601
2. **HAProxy Stats**: http://localhost:8404/stats
3. **Elasticsearch API**: http://localhost:9200

## 🔧 External IP Capture Implementation

### TCP Services (HAProxy + PROXY Protocol)

```yaml
# HAProxy forwards with PROXY protocol header
frontend ssh_2222
    bind *:2222
    default_backend cowrie_2222

backend cowrie_2222
    server cowrie1 cowrie:2222 check send-proxy
```

### UDP Services (Host Networking)

```yaml
# Direct host network access for UDP traffic
snmp-honeypot:
    network_mode: host  # Captures real external IPs
```

### Configuration Files

- **HAProxy**: `honeypots/haproxy/haproxy.cfg`
- **Cowrie**: `honeypots/cowrie/cowrie.cfg` (PROXY protocol enabled)
- **Redis**: `honeypots/redis-honeypot/redis.conf` (PROXY protocol enabled)

## 🚀 Adding New Honeypots

### For TCP Services:

1. **Add to HAProxy config** (`honeypots/haproxy/haproxy.cfg`):
```haproxy
frontend new_service_PORT
    bind *:PORT
    default_backend new_service_backend

backend new_service_backend
    server service1 service-name:PORT check send-proxy
```

2. **Configure honeypot** to accept PROXY protocol
3. **Add to docker-compose.yml** without direct port mapping
4. **Update log processing** in Filebeat and Logstash

### For UDP Services:

1. **Add to docker-compose.yml** with `network_mode: host`
2. **Configure direct port binding** in the service
3. **Update log processing** configurations

## Threat Detection Features

### Automatic IOC Detection

The system automatically detects and categorizes threats:

- **Malicious Commands**: `wget`, `curl`, `chmod`, `bash`, `sudo`, `rm -rf`
- **Download Attempts**: HTTP/HTTPS download commands
- **Privilege Escalation**: `sudo`, `su`, `chmod +x`
- **Authentication Attacks**: Brute force login attempts
- **Database Attacks**: Malicious Redis commands
- **Network Reconnaissance**: SNMP enumeration, port scanning

### Data Enrichment

All logs are enriched with:
- **GeoIP Location**: Country, city, coordinates
- **DNS Reverse Lookup**: Hostname resolution
- **Threat Classification**: Risk level and category
- **Service Metadata**: Honeypot type, protocol information
- **PROXY Protocol Status**: Whether external IP was captured via PROXY protocol

## Index Structure

The system creates two main indices:

- **`honeypot-logs-*`**: All honeypot activities
- **`honeypot-iocs-*`**: Suspicious activities and IOCs only

## Monitoring and Health Checks

### HAProxy Stats Dashboard
- **URL**: http://localhost:8404/stats
- **Features**: Real-time connection stats, backend health, traffic metrics

### Service Health Checks
```bash
# Check all services
docker-compose ps

# View HAProxy logs
docker-compose logs -f haproxy

# View specific honeypot logs
docker-compose logs -f cowrie
```

## Configuration Files

### Key Configuration Files:
- `honeypots/haproxy/haproxy.cfg`: Load balancer and PROXY protocol config
- `honeypots/cowrie/cowrie.cfg`: SSH honeypot with PROXY protocol support
- `honeypots/redis-honeypot/redis.conf`: Redis with PROXY protocol support
- `infrastructure/filebeat.yml`: Log collection configuration
- `infrastructure/logstash/pipeline/logstash.conf`: Log processing and threat detection

### Log Locations:
- Cowrie: `honeypots/cowrie-logs/`
- Dionaea: `honeypots/dionaea-logs/`
- Redis: `honeypots/redis-logs/`
- SNMP: `honeypots/snmp-logs/`

## Security Considerations

- **Network Isolation**: Most services run on isolated `elastic` network
- **Host Network Services**: Dionaea and SNMP use host networking (reduced isolation)
- **PROXY Protocol**: Secure method for IP preservation in TCP services
- **Resource Limits**: Configured memory and CPU limits
- **Log Rotation**: Automatic log cleanup and rotation

## Architecture Benefits

### 🔄 Scalability
- **Centralized TCP Management**: HAProxy handles load balancing and SSL termination
- **Modular Design**: Easy to add new honeypots
- **Resource Efficiency**: Shared infrastructure components

### 🛡️ Security
- **Real IP Capture**: No more internal Docker IPs in logs
- **Protocol Preservation**: PROXY protocol maintains connection integrity
- **Isolated Networks**: Most services remain network-isolated

### 📊 Monitoring
- **Centralized Stats**: HAProxy provides comprehensive metrics
- **Health Checks**: All services monitored for availability
- **Log Aggregation**: Unified logging pipeline

## Troubleshooting

### Common Issues:

1. **Port Conflicts**: Ensure ports 5601, 9200, 2222, 2223, 21, 25, 69, 135, 445, 1433, 3306, 5432, 6379, 161, 8404 are available
2. **Memory Issues**: Elasticsearch requires at least 2GB RAM
3. **Permission Issues**: Ensure log directories are writable
4. **HAProxy Issues**: Check HAProxy stats at http://localhost:8404/stats

### Debug Commands:

```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health

# Check Kibana status
curl http://localhost:5601/api/status

# Check HAProxy stats
curl http://localhost:8404/stats

# Test external IP capture
ssh -p 2222 root@localhost  # Check Cowrie logs for real IP
redis-cli -h localhost -p 6379 ping  # Check Redis logs for real IP

# View real-time logs
tail -f honeypots/cowrie-logs/*.json
tail -f honeypots/redis-logs/*.json
```

## Production Deployment

For production use:

1. **Configure SSL/TLS** for Elasticsearch, Kibana, and HAProxy
2. **Set up authentication** and access controls
3. **Configure log retention** policies
4. **Set up monitoring** and alerting for HAProxy and services
5. **Configure backups** for Elasticsearch indices
6. **Tune resource allocation** based on expected log volume
7. **Review host networking** security implications for Dionaea and SNMP
8. **Configure firewall rules** for exposed honeypot ports

## License

This honeypot system is designed for educational and research purposes. Ensure compliance with local laws and regulations when deploying honeypots.

---

**🎯 Now with complete external IP visibility across all honeypot services!**