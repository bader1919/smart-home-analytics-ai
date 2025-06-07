#!/bin/bash
# Smart Home Analytics AI - Quick Setup Script
# This script sets up the complete platform with sensible defaults

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check available memory
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 8 ]; then
        log_warning "Less than 8GB RAM detected. Platform may run slowly."
        log_warning "Recommended: 16GB+ RAM for optimal performance."
    fi
    
    # Check available disk space
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 50 ]; then
        log_warning "Less than 50GB disk space available."
        log_warning "Platform requires significant storage for data and logs."
    fi
    
    log_success "Prerequisites check completed"
}

# Setup environment
setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        cp .env.example .env
        log_success "Created .env file from template"
        log_warning "Please review and update .env file with your specific configurations"
    else
        log_info ".env file already exists, skipping creation"
    fi
    
    # Create necessary directories
    mkdir -p logs
    mkdir -p data/backups
    mkdir -p config
    
    log_success "Environment setup completed"
}

# Generate secure passwords
generate_passwords() {
    log_info "Generating secure passwords..."
    
    # Generate random passwords
    NEO4J_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    POSTGRES_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    GRAFANA_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
    
    # Update .env file
    sed -i "s/NEO4J_PASSWORD=smarthome123/NEO4J_PASSWORD=$NEO4J_PASS/" .env
    sed -i "s/POSTGRES_PASSWORD=smarthome123/POSTGRES_PASSWORD=$POSTGRES_PASS/" .env
    sed -i "s/GRAFANA_ADMIN_PASSWORD=smarthome123/GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASS/" .env
    sed -i "s/JWT_SECRET_KEY=your-super-secret-jwt-key-change-this/JWT_SECRET_KEY=$JWT_SECRET/" .env
    
    # Save passwords to a secure file
    cat > .passwords << EOF
# Smart Home Analytics AI - Generated Passwords
# KEEP THIS FILE SECURE AND DO NOT COMMIT TO VERSION CONTROL

Neo4j Password: $NEO4J_PASS
PostgreSQL Password: $POSTGRES_PASS
Grafana Admin Password: $GRAFANA_PASS
JWT Secret Key: $JWT_SECRET

# Access URLs after startup:
# Grafana: http://localhost:3000 (admin/$GRAFANA_PASS)
# Neo4j: http://localhost:7474 (neo4j/$NEO4J_PASS)
# Kafka UI: http://localhost:8080
# Ollama WebUI: http://localhost:8081
EOF
    
    chmod 600 .passwords
    
    log_success "Secure passwords generated and saved to .passwords file"
    log_warning "IMPORTANT: Keep the .passwords file secure!"
}

# Pull Docker images
pull_images() {
    log_info "Pulling Docker images (this may take a while)..."
    
    docker-compose pull
    
    log_success "Docker images pulled successfully"
}

# Start services
start_services() {
    log_info "Starting Smart Home Analytics AI platform..."
    
    # Start core services first
    log_info "Starting core infrastructure services..."
    docker-compose up -d zookeeper kafka timescaledb neo4j
    
    # Wait for core services to be ready
    log_info "Waiting for core services to initialize..."
    sleep 30
    
    # Start AI services
    log_info "Starting AI services..."
    docker-compose up -d ollama ollama-init
    
    # Wait for Ollama to be ready
    log_info "Waiting for Ollama to initialize..."
    sleep 20
    
    # Start application services
    log_info "Starting application services..."
    docker-compose up -d graphiti-engine grafana kafka-ui ollama-webui portainer
    
    log_success "All services started successfully"
}

# Check service health
check_health() {
    log_info "Checking service health..."
    
    # Wait a bit for services to fully start
    sleep 10
    
    # Check if all containers are running
    failed_services=()
    
    services=("zookeeper" "kafka" "timescaledb" "neo4j" "ollama" "grafana" "graphiti-engine")
    
    for service in "${services[@]}"; do
        if ! docker-compose ps "$service" | grep -q "Up"; then
            failed_services+=("$service")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All services are running properly"
    else
        log_warning "Some services may have issues: ${failed_services[*]}"
        log_info "Check logs with: docker-compose logs [service_name]"
    fi
}

# Display access information
show_access_info() {
    log_success "? Smart Home Analytics AI Platform is ready!"
    
    echo ""
    echo "? Access your services:"
    echo "?????????????????????????????????????????????????????????????????????????????"
    echo "? Grafana Dashboard:    http://localhost:3000"
    echo "??  Neo4j Browser:       http://localhost:7474"
    echo "? Kafka UI:            http://localhost:8080"
    echo "? Ollama WebUI:        http://localhost:8081"
    echo "? Portainer:           https://localhost:9443"
    echo "?????????????????????????????????????????????????????????????????????????????"
    echo ""
    echo "? Login credentials are saved in the .passwords file"
    echo "? For detailed documentation, see README.md"
    echo ""
    echo "??  Common commands:"
    echo "   View logs:          docker-compose logs -f"
    echo "   Stop platform:      docker-compose down"
    echo "   Restart service:     docker-compose restart [service_name]"
    echo "   Update platform:     git pull && docker-compose pull && docker-compose up -d"
    echo ""
}

# Main setup function
main() {
    echo "? Smart Home Analytics AI Platform Setup"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    setup_environment
    
    # Ask user if they want to generate new passwords
    read -p "Generate secure passwords? (recommended for production) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        generate_passwords
    fi
    
    pull_images
    start_services
    check_health
    show_access_info
    
    log_success "Setup completed successfully! ?"
}

# Handle script interruption
trap 'log_error "Setup interrupted. You can run this script again to continue."; exit 1' INT

# Run main function
main "$@"
