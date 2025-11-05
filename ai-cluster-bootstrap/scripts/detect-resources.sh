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
