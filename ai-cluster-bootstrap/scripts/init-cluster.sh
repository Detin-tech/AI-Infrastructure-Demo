#!/bin/bash

# AI Cluster Bootstrap Initialization Script

set -e

echo "Initializing AI Cluster Bootstrap..."

# Create necessary directories
mkdir -p services/caddy
mkdir -p services/llm
mkdir -p services/prometheus
mkdir -p services/grafana/dashboards
mkdir -p services/node-exporter

# Copy example env file if .env doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
fi

# Generate Caddyfile
echo "Generating Caddy configuration..."
cat > services/caddy/Caddyfile << 'EOF'
{
    admin 0.0.0.0:2019
    log {
        level DEBUG
    }
}

{$DOMAIN_NAME} {
    reverse_proxy /api/* http://llm-load-balancer:8000
    reverse_proxy /* http://llm-load-balancer:8000
    
    log {
        output stdout
    }
    
    tls {$ADMIN_EMAIL}
}
EOF

# Generate Prometheus configuration
echo "Generating Prometheus configuration..."
cat > services/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'llm-workers'
    static_configs:
      - targets: ['llm-worker-1:8000', 'llm-worker-2:8000', 'llm-worker-3:8000']
        labels:
          group: 'workers'
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
        
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

# Generate Grafana datasource
echo "Generating Grafana configuration..."
mkdir -p services/grafana/provisioning/datasources
mkdir -p services/grafana/provisioning/dashboards

cat > services/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

cat > services/grafana/provisioning/dashboards/default.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/dashboards
EOF

# Copy Grafana dashboard if it exists
if [ -f services/grafana/dashboards/llm-cluster.json ]; then
    echo "Grafana dashboard will be available after deployment"
fi

# Generate resource detection script
echo "Generating resource detection script..."
cat > scripts/detect-resources.sh << 'EOF'
#!/bin/bash

# Detect system resources for AI Cluster Bootstrap

echo "Detecting system resources..."

echo "--- CPU Information ---"
lscpu | grep -E "^Architecture|^CPU\(s\)|^Model name"

echo "\n--- Memory Information ---"
free -h | grep Mem

echo "\n--- GPU Information ---"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits
    echo "GPU_ENABLED=true" >> ../.env
else
    echo "No NVIDIA GPU detected"
    echo "GPU_ENABLED=false" >> ../.env
fi

echo "\n--- Disk Space ---"
df -h /

echo "\nResource detection complete."
EOF

chmod +x scripts/detect-resources.sh

echo "Initialization complete!"
echo "Please edit the .env file with your configuration and run ./scripts/detect-resources.sh"