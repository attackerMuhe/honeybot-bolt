# Production-Grade Honeypot Log Aggregation System

A comprehensive, modular honeypot log aggregation system using the ELK stack with multiple honeypot types for threat detection and analysis.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Honeypots     │    │  Log Processing │    │   Visualization │
│                 │    │                 │    │                 │
│  • Cowrie (SSH) │───▶│  Filebeat       │───▶│  Kibana         │
│  • Dionaea      │    │  Logstash       │    │  Elasticsearch  │
│  • Redis        │    │  Elasticsearch  │    │                 │
│  • SNMP         │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Features

- **Multi-Protocol Honeypots**: SSH, FTP, SMTP, SMB, Redis, SNMP, and more
- **Advanced Threat Detection**: Malicious command detection, GeoIP enrichment, DNS reverse lookups
- **Structured Logging**: All logs converted to JSON format with standardized fields
- **Automated IOC Generation**: Suspicious activities automatically tagged and indexed separately
- **Production Ready**: Health checks, restart policies, resource limits
- **Modular Architecture**: Easy to add new honeypot types

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
- **Cowrie** (SSH honeypot) on ports `2222`, `2223`
- **Dionaea** (multi-protocol) on ports `21`, `25`, `445`, `1433`, `3306`, `5432`
- **Redis honeypot** on port `6379`
- **SNMP honeypot** on port `161/udp`

### 3. Access Kibana Dashboard

1. Open http://localhost:5601
2. Create index patterns for `honeypot-*`
3. View logs and IOCs in real-time

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

## Index Structure

The system creates two main indices:

- **`honeypot-logs-*`**: All honeypot activities
- **`honeypot-iocs-*`**: Suspicious activities and IOCs only

## Monitoring and Health Checks

All services include health checks and will automatically restart on failure:

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f [service_name]
```

## Adding New Honeypots

1. Add the new honeypot service to `honeypots/docker-compose.yml`
2. Configure log output to a mounted volume
3. Add the log path to `infrastructure/filebeat.yml`
4. Add parsing rules to `infrastructure/logstash/pipeline/logstash.conf`
5. Restart services: `docker-compose restart`

## Configuration Files

### Key Configuration Files:
- `infrastructure/filebeat.yml`: Log collection configuration
- `infrastructure/logstash/pipeline/logstash.conf`: Log processing and threat detection
- `honeypots/docker-compose.yml`: Honeypot services configuration

### Log Locations:
- Cowrie: `honeypots/cowrie-logs/`
- Dionaea: `honeypots/dionaea-logs/`
- Redis: `honeypots/redis-logs/`
- SNMP: `honeypots/snmp-logs/`

## Security Considerations

- **Network Isolation**: All services run on the isolated `elastic` network
- **No External Dependencies**: Self-contained system
- **Resource Limits**: Configured memory and CPU limits
- **Log Rotation**: Automatic log cleanup and rotation

## Troubleshooting

### Common Issues:

1. **Port Conflicts**: Ensure ports 5601, 9200, 2222, 2223, 21, 25, 445, 1433, 3306, 5432, 6379, 161 are available
2. **Memory Issues**: Elasticsearch requires at least 2GB RAM
3. **Permission Issues**: Ensure log directories are writable

### Debug Commands:

```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health

# Check Kibana status
curl http://localhost:5601/api/status

# Test log ingestion
tail -f honeypots/cowrie-logs/*.json
```

## Production Deployment

For production use:

1. **Configure SSL/TLS** for Elasticsearch and Kibana
2. **Set up authentication** and access controls
3. **Configure log retention** policies
4. **Set up monitoring** and alerting
5. **Configure backups** for Elasticsearch indices
6. **Tune resource allocation** based on expected log volume

## License

This honeypot system is designed for educational and research purposes. Ensure compliance with local laws and regulations when deploying honeypots.