# ? Troubleshooting Guide

This guide helps you resolve common issues with the Smart Home Analytics AI platform.

## ? Common Issues & Solutions

### 1. Neo4j Fails to Start

**Symptoms:**
- Neo4j container keeps restarting
- Error: "Unrecognized setting. No declared setting with name: dbms.memory.heap.max.size"

**Solution:**
```bash
# Check Neo4j logs
docker-compose logs neo4j

# The issue is fixed in the new docker-compose.yml
# Update to use the correct environment variables:
# NEO4J_server_memory_heap_max_size=2G (not dbms.memory.heap.max.size)

# If still having issues, disable strict validation:
docker-compose exec neo4j sh -c 'echo "server.config.strict_validation.enabled=false" >> /var/lib/neo4j/conf/neo4j.conf'
docker-compose restart neo4j
```

### 2. Graphiti Engine Missing main.py

**Symptoms:**
- Graphiti Engine container restarting
- Error: "python: can't open file '/app/scripts/main.py': [Errno 2] No such file or directory"

**Solution:**
```bash
# Check if scripts directory exists and has main.py
ls -la scripts/

# If missing, the repository now includes the complete main.py
# Pull the latest code:
git pull origin main

# Or manually create the scripts directory and copy the main.py from this repository
```

### 3. Ollama Models Not Downloaded

**Symptoms:**
- Ollama WebUI shows no models
- AI functionality not working

**Solution:**
```bash
# Check if models are downloaded
docker exec -it ollama ollama list

# Download required models manually
docker exec -it ollama ollama pull llama3.2:3b
docker exec -it ollama ollama pull nomic-embed-text

# For lighter systems, use smaller model:
docker exec -it ollama ollama pull llama3.2:1b
```

### 4. High Memory Usage

**Symptoms:**
- System becomes slow
- Out of memory errors
- Containers being killed

**Solution:**
```bash
# Check memory usage
docker stats

# Reduce memory allocation in .env:
NEO4J_server_memory_heap_max_size=1G
# For very limited systems:
NEO4J_server_memory_heap_max_size=512M

# Use smaller Ollama model:
OLLAMA_MODEL=llama3.2:1b

# Restart with new settings:
docker-compose down
docker-compose up -d
```

### 5. Port Conflicts

**Symptoms:**
- Error: "Port already in use"
- Services fail to start

**Solution:**
```bash
# Check what's using the ports
netstat -tulpn | grep :3000  # Grafana
netstat -tulpn | grep :7474  # Neo4j
netstat -tulpn | grep :8080  # Kafka UI

# Change ports in docker-compose.yml if needed:
# For example, change Grafana from 3000:3000 to 3001:3000
```

### 6. Kafka Connection Issues

**Symptoms:**
- Data not flowing through system
- Kafka-related errors in logs

**Solution:**
```bash
# Check Kafka logs
docker-compose logs kafka

# Verify Kafka topics
docker exec -it kafka kafka-topics.sh --list --bootstrap-server localhost:9092

# Create topics manually if needed
docker exec -it kafka kafka-topics.sh --create --topic sensor_data --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

### 7. Grafana Dashboard Access Issues

**Symptoms:**
- Can't access Grafana
- Login failures

**Solution:**
```bash
# Check Grafana logs
docker-compose logs grafana

# Reset admin password
docker exec -it grafana grafana-cli admin reset-admin-password newpassword

# Check generated passwords file
cat .passwords
```

### 8. Database Connection Failures

**Symptoms:**
- Applications can't connect to databases
- Connection timeout errors

**Solution:**
```bash
# Check if databases are running
docker-compose ps

# Test Neo4j connection
docker exec -it neo4j cypher-shell -u neo4j -p smarthome123

# Test PostgreSQL connection
docker exec -it timescaledb psql -U postgres -d smarthome

# Check network connectivity
docker network ls
docker network inspect smart-home-analytics-ai_default
```

## ? Diagnostic Commands

### Check Service Status
```bash
# Overview of all services
docker-compose ps

# Detailed status
docker-compose top

# Resource usage
docker stats --no-stream
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs graphiti-engine
docker-compose logs neo4j

# Follow logs in real-time
docker-compose logs -f

# Last 50 lines
docker-compose logs --tail=50
```

### System Health Check
```bash
# Check system resources
free -h
df -h

# Check Docker system
docker system df
docker system info

# Check network
docker network ls
```

## ?? Performance Optimization

### For Low-Memory Systems (< 8GB RAM)

1. **Use lighter AI models:**
```bash
# In .env file:
OLLAMA_MODEL=llama3.2:1b
```

2. **Reduce database memory:**
```bash
# In .env file:
NEO4J_server_memory_heap_max_size=512M
NEO4J_server_memory_heap_initial_size=256M
```

3. **Limit concurrent processing:**
```bash
# In .env file:
WORKER_THREADS=2
MAX_CONCURRENT_REQUESTS=25
```

### For High-Performance Systems (16GB+ RAM)

1. **Use more capable models:**
```bash
# In .env file:
OLLAMA_MODEL=llama3.2:7b
```

2. **Increase database memory:**
```bash
# In .env file:
NEO4J_server_memory_heap_max_size=4G
NEO4J_server_memory_heap_initial_size=2G
```

3. **Enable more workers:**
```bash
# In .env file:
WORKER_THREADS=8
MAX_CONCURRENT_REQUESTS=200
```

## ? Security Issues

### Update Default Passwords
```bash
# Use the setup script to generate secure passwords
chmod +x setup.sh
./setup.sh

# Or manually update .env file with strong passwords
```

### SSL/TLS Configuration
```bash
# For production, enable SSL for web interfaces
# Add SSL certificates to config/ssl/ directory
# Update docker-compose.yml with SSL settings
```

## ? Data Issues

### Reset All Data
```bash
# WARNING: This will delete all data!
docker-compose down -v
docker-compose up -d
```

### Backup Data
```bash
# Neo4j backup
docker exec neo4j neo4j-admin database dump neo4j /tmp/neo4j-backup.dump
docker cp neo4j:/tmp/neo4j-backup.dump ./backups/

# PostgreSQL backup
docker exec timescaledb pg_dump -U postgres smarthome > backups/postgres-backup.sql
```

### Restore Data
```bash
# Neo4j restore
docker cp ./backups/neo4j-backup.dump neo4j:/tmp/
docker exec neo4j neo4j-admin database load neo4j /tmp/neo4j-backup.dump --overwrite-destination

# PostgreSQL restore
docker exec -i timescaledb psql -U postgres smarthome < backups/postgres-backup.sql
```

## ? Getting Help

### Collect System Information
```bash
# Run this script to collect diagnostic info
cat > collect-info.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
uname -a
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Docker Version ==="
docker --version
docker-compose --version
echo ""

echo "=== Container Status ==="
docker-compose ps
echo ""

echo "=== Resource Usage ==="
docker stats --no-stream
echo ""

echo "=== Recent Logs ==="
docker-compose logs --tail=20
EOF

chmod +x collect-info.sh
./collect-info.sh > diagnostic-info.txt
```

### Contact Support

For enterprise support or complex issues:
- **GitHub Issues**: [Create an issue](https://github.com/bader1919/smart-home-analytics-ai/issues)
- **Email**: Contact BY MB Consultancy for professional support
- **Documentation**: Check the full README.md for detailed information

### Community Support

- Share your diagnostic information when asking for help
- Include relevant log excerpts
- Describe what you were trying to do when the issue occurred
- Mention your system specifications (RAM, CPU, OS)

---

**? Pro Tip**: Most issues can be resolved by checking the logs first. Always start with `docker-compose logs [service-name]` to understand what's happening.
