# Configuration Guide

## Environment Variables

### Core Configuration

#### Neo4j Database
```bash
NEO4J_URI=bolt://localhost:7687          # Neo4j connection string
NEO4J_USERNAME=neo4j                     # Neo4j username
NEO4J_PASSWORD=smarthome123               # Neo4j password
```

#### Apache Kafka
```bash
KAFKA_BOOTSTRAP_SERVERS=localhost:9092   # Kafka broker endpoints
```

#### Ollama AI Configuration
```bash
OLLAMA_BASE_URL=http://localhost:11434   # Ollama API endpoint
OLLAMA_MODEL=llama3.2:3b                 # Primary LLM model
OLLAMA_EMBED_MODEL=nomic-embed-text       # Embedding model
```

#### Database Configuration
```bash
POSTGRES_HOST=localhost                   # TimescaleDB host
POSTGRES_PORT=5432                        # TimescaleDB port
POSTGRES_DB=smart_home_analytics          # Database name
POSTGRES_USER=postgres                    # Database user
POSTGRES_PASSWORD=smarthome123            # Database password
```

## Home Assistant Integration

### Basic Configuration

Add to your `configuration.yaml`:

```yaml
apache_kafka:
  ip_address: 192.168.1.100  # Your Docker host IP
  port: 9092
  topic: homeassistant_events
```

### Advanced Filtering

```yaml
apache_kafka:
  ip_address: 192.168.1.100
  port: 9092
  topic: homeassistant_events
  
  filter:
    # Include specific domains
    include_domains:
      - sensor
      - binary_sensor
      - light
      - switch
      - climate
      - device_tracker
      
    # Include entities matching patterns
    include_entity_globs:
      - "sensor.*energy*"
      - "sensor.*temperature*"
      - "sensor.*humidity*"
      - "binary_sensor.*motion*"
      - "binary_sensor.*door*"
      
    # Exclude noisy entities
    exclude_entities:
      - sensor.uptime
      - sensor.last_boot
      - sensor.cpu_temperature
      - sensor.memory_use_percent
      - sensor.processor_use
```

## Grafana Dashboard Configuration

### Data Sources

Create `config/grafana/datasources/datasources.yml`:

```yaml
apiVersion: 1

datasources:
  - name: TimescaleDB
    type: postgres
    url: timescaledb:5432
    database: smart_home_analytics
    user: postgres
    secureJsonData:
      password: smarthome123
    jsonData:
      sslmode: disable
      postgresVersion: 1300
      
  - name: Neo4j
    type: neo4j-datasource
    url: bolt://neo4j:7687
    basicAuth: true
    basicAuthUser: neo4j
    secureJsonData:
      basicAuthPassword: smarthome123
```

### Dashboard Provisioning

Create `config/grafana/dashboards/dashboard.yml`:

```yaml
apiVersion: 1

providers:
  - name: 'smart-home-dashboards'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

## Ollama Model Configuration

### Available Models

#### Recommended Models for Smart Home Analytics

```bash
# Lightweight models (4GB RAM)
ollama pull llama3.2:3b          # Primary model
ollama pull phi3:mini             # Alternative lightweight

# Medium models (8GB RAM)
ollama pull llama3.2:7b           # Better accuracy
ollama pull mistral:7b            # Alternative

# Embedding models
ollama pull nomic-embed-text      # Primary embeddings
ollama pull all-minilm:l6-v2      # Alternative embeddings
```

### Custom Model Configuration

Update your `.env` file:

```bash
# For better accuracy (requires more RAM)
OLLAMA_MODEL=llama3.2:7b

# For faster processing (less accuracy)
OLLAMA_MODEL=phi3:mini
```

## Neo4j Optimization

### Memory Configuration

Update `docker-compose.yml`:

```yaml
neo4j:
  environment:
    NEO4J_dbms_memory_heap_initial_size: 2G
    NEO4J_dbms_memory_heap_max_size: 4G
    NEO4J_dbms_memory_pagecache_size: 2G
```

### Indices for Performance

Run in Neo4j Browser:

```cypher
// Create indices for common queries
CREATE INDEX entity_id_index FOR (e:Entity) ON (e.entity_id);
CREATE INDEX entity_type_index FOR (e:Entity) ON (e.type);
CREATE INDEX state_timestamp_index FOR (s:State) ON (s.timestamp);
CREATE INDEX state_value_index FOR (s:State) ON (s.value);

// Create constraints
CREATE CONSTRAINT entity_id_unique FOR (e:Entity) REQUIRE e.entity_id IS UNIQUE;
```

## Kafka Optimization

### Topic Configuration

```bash
# Create topic with custom settings
docker-compose exec kafka kafka-topics.sh \
  --create \
  --topic homeassistant_events \
  --bootstrap-server localhost:9092 \
  --partitions 6 \
  --replication-factor 1 \
  --config retention.ms=604800000  # 7 days
```

### Performance Tuning

Update `docker-compose.yml`:

```yaml
kafka:
  environment:
    KAFKA_NUM_PARTITIONS: 6
    KAFKA_DEFAULT_REPLICATION_FACTOR: 1
    KAFKA_LOG_RETENTION_HOURS: 168  # 7 days
    KAFKA_LOG_SEGMENT_BYTES: 1073741824  # 1GB
```

## Security Configuration

### Enable Authentication (Production)

#### Neo4j Security

```yaml
neo4j:
  environment:
    NEO4J_AUTH: neo4j/your_secure_password
    NEO4J_dbms_security_auth_enabled: true
```

#### Kafka Security

```yaml
kafka:
  environment:
    KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
    KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
    KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
```

### Network Security

```yaml
# Use custom networks
networks:
  smart-home-network:
    driver: bridge
    
services:
  neo4j:
    networks:
      - smart-home-network
    # Remove port exposure for internal-only access
    # ports:
    #   - "7474:7474"
```

## Production Deployment

### Resource Limits

```yaml
services:
  neo4j:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2'
        reservations:
          memory: 2G
          cpus: '1'
          
  ollama:
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4'
        reservations:
          memory: 4G
          cpus: '2'
```

### Backup Configuration

```bash
# Neo4j backup script
#!/bin/bash
docker-compose exec neo4j neo4j-admin dump \
  --database=neo4j \
  --to=/var/lib/neo4j/backups/backup-$(date +%Y%m%d-%H%M%S).dump

# TimescaleDB backup
docker-compose exec timescaledb pg_dump \
  -U postgres smart_home_analytics > backup-$(date +%Y%m%d-%H%M%S).sql
```

### Monitoring Setup

```yaml
# Add to docker-compose.yml
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./config/prometheus:/etc/prometheus
    
node-exporter:
  image: prom/node-exporter:latest
  ports:
    - "9100:9100"
```

## Scaling Configuration

### Multiple Instances

```yaml
# Scale Kafka consumers
graphiti-engine:
  deploy:
    replicas: 3
  environment:
    KAFKA_GROUP_ID: graphiti-analytics-${INSTANCE_ID}
```

### Load Balancing

```yaml
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
  volumes:
    - ./config/nginx:/etc/nginx/conf.d
```

## Troubleshooting Configuration

### Enable Debug Logging

```bash
# Add to .env
LOG_LEVEL=DEBUG
NEO4J_dbms_logs_debug_level=DEBUG
KAFKA_LOG4J_ROOT_LOGLEVEL=DEBUG
```

### Health Checks

```yaml
services:
  neo4j:
    healthcheck:
      test: ["CMD", "cypher-shell", "-u", "neo4j", "-p", "smarthome123", "RETURN 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      
  kafka:
    healthcheck:
      test: kafka-topics.sh --bootstrap-server localhost:9092 --list
      interval: 30s
      timeout: 10s
      retries: 3
```

For more detailed configuration options, see the [API Documentation](API.md) and [Troubleshooting Guide](TROUBLESHOOTING.md).
