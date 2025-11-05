#!/bin/bash

# Test script for AI Cluster Bootstrap

echo "Testing AI Cluster Bootstrap setup..."

echo "1. Checking directory structure..."
if [ -d "services/llm" ] && [ -d "services/nginx" ] && [ -d "services/grafana" ]; then
    echo "   ✓ Directory structure OK"
else
    echo "   ✗ Directory structure incomplete"
    echo "   LLM: $(if [ -d "services/llm" ]; then echo "OK"; else echo "MISSING"; fi)"
    echo "   NGINX: $(if [ -d "services/nginx" ]; then echo "OK"; else echo "MISSING"; fi)"
    echo "   Grafana: $(if [ -d "services/grafana" ]; then echo "OK"; else echo "MISSING"; fi)"
    exit 1
fi

echo "2. Checking required files..."
files=("docker-compose.yml" "docker-compose-worker.yml" ".env.example" "README.md" 
       "services/llm/Dockerfile" "services/llm/requirements.txt" 
       "services/llm/app.py" "services/nginx/nginx.conf")

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "   ✗ Missing file: $file"
        exit 1
    fi
done
echo "   ✓ All required files present"

echo "3. Checking executable scripts..."
if [ -f "scripts/init-cluster.sh" ] && [ -x "scripts/init-cluster.sh" ]; then
    echo "   ✓ Init script present and executable"
else
    echo "   ✗ Init script missing or not executable"
    exit 1
fi

echo "4. Validating docker-compose files..."
if command -v docker-compose &> /dev/null; then
    docker-compose config > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ Main docker-compose file valid"
    else
        echo "   ✗ Main docker-compose file invalid"
        exit 1
    fi
    
    docker-compose -f docker-compose-worker.yml config > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ Worker docker-compose file valid"
    else
        echo "   ✗ Worker docker-compose file invalid"
        exit 1
    fi
else
    echo "   ! docker-compose not found, skipping validation"
fi

echo "\nAll tests passed! Your AI Cluster Bootstrap is ready to deploy."
echo "Next steps:"
echo "1. Run ./scripts/init-cluster.sh"
echo "2. Edit .env with your configuration"
echo "3. Run ./scripts/detect-resources.sh"
echo "4. Run docker-compose up -d"