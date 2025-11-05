# AI Cluster Bootstrap

A single command spins up a self-contained multi-node LLM environment using Docker Compose and ZeroTier networking.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

AI Cluster Bootstrap is a DevOps solution that allows you to quickly deploy a distributed LLM inference environment with minimal setup. With just one command, you can spin up a multi-node cluster that automatically detects GPU/CPU resources, provides secure access through a reverse proxy, and includes monitoring capabilities.

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                          External Access                           │
│                            (HTTPS/8443)                            │
├────────────────────────────────────────────────────────────────────┤
│                      ┌─────────────────────┐                       │
│                      │    Caddy Proxy      │                       │
│                      │   (Optional TLS)    │                       │
│                      └─────────────────────┘                       │
├────────────────────────────────────────────────────────────────────┤
│                        Load Balancer                               │
├────────────────────────────────────────────────────────────────────┤
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐        │
│   │  Node 1      │    │  Node 2      │    │  Node N      │        │
│   │ (LLM Worker) │    │ (LLM Worker) │    │ (LLM Worker) │        │
│   │              │    │              │    │              │        │
│   │ - GPU/CPU    │    │ - GPU/CPU    │    │ - GPU/CPU    │        │
│   │ - ZeroTier   │    │ - ZeroTier   │    │ - ZeroTier   │        │
│   └──────────────┘    └──────────────┘    └──────────────┘        │
├────────────────────────────────────────────────────────────────────┤
│                    ┌─────────────────────┐     Monitoring          │
│                    │  Prometheus/Grafana │  (metrics/dashboard)    │
│                    │                     │                         │
│                    │  - Node Exporter    │                         │
│                    │  - cAdvisor         │                         │
│                    └─────────────────────┘                         │
└────────────────────────────────────────────────────────────────────┘
```

## Features

- **Single Command Deployment**: Spin up an entire LLM cluster with one command
- **Automatic Resource Detection**: Automatically configures nodes based on available CPU/GPU resources
- **ZeroTier Networking**: Secure, private network between all nodes
- **Load Balancing**: Distributes requests across all available nodes
- **Reverse Proxy**: Optional Caddy server with automatic TLS (Let's Encrypt)
- **Monitoring Dashboard**: Prometheus + Grafana for real-time metrics
- **Scalable Architecture**: Easily add/remove nodes as needed

## Quick Start (Under 10 Steps)

### Prerequisites

- Docker and Docker Compose installed
- Git
- A ZeroTier account (free tier available)

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/ai-cluster-bootstrap.git
cd ai-cluster-bootstrap
```

### Step 2: Configure Environment Variables

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

Edit `.env` to set your configuration:
- `ZEROTIER_NETWORK_ID`: Your ZeroTier network ID
- `DOMAIN_NAME`: Your domain for TLS (optional)
- `ADMIN_EMAIL`: Email for Let's Encrypt (if using TLS)

### Step 3: Generate Configuration Files

Run the initialization script to generate node configurations:

```bash
./scripts/init-cluster.sh
```

### Step 4: Join ZeroTier Network

Each node needs to join your ZeroTier network. On each machine:

```bash
zerotier-cli join <NETWORK_ID>
```

Then authorize the nodes in your ZeroTier network admin panel.

### Step 5: Deploy the Cluster

On your main/controller node:

```bash
docker-compose up -d
```

### Step 6: Access Your Services

- **LLM API**: `https://yourdomain.com` or `http://localhost:8000`
- **Grafana Dashboard**: `http://localhost:3000` (admin/admin)
- **Prometheus**: `http://localhost:9090`

### Step 7: Scale Your Workers

To add more worker nodes, simply run on additional machines:

```bash
docker-compose -f docker-compose-worker.yml up -d
```

### Step 8: Monitor Performance

Access the Grafana dashboard to monitor:
- CPU/Memory usage per node
- GPU utilization (if applicable)
- Network traffic
- LLM response times

### Step 9: Update Models (Optional)

To update models, modify the model loading script in `services/llm/models.py` and restart services:

```bash
docker-compose restart llm-workers
```

## Configuration Options

### Environment Variables (.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `ZEROTIER_NETWORK_ID` | ZeroTier network identifier | Required |
| `DOMAIN_NAME` | Domain for TLS certificates | localhost |
| `ADMIN_EMAIL` | Admin email for Let's Encrypt | admin@localhost |
| `WORKER_NODES` | Number of worker nodes to start | 3 |
| `GPU_ENABLED` | Enable GPU support (auto-detected) | auto |

### GPU Support

The system automatically detects NVIDIA GPUs if available. For GPU support:
1. Install NVIDIA Container Toolkit
2. Ensure nvidia-smi works
3. Set `GPU_ENABLED=true` in .env

## Project Structure

```
ai-cluster-bootstrap/
├── docker-compose.yml        # Main cluster configuration
├── docker-compose-worker.yml # Worker-only configuration
├── .env.example             # Example environment variables
├── scripts/
│   ├── init-cluster.sh      # Cluster initialization script
│   └── detect-resources.sh  # Hardware detection
├── services/
│   ├── caddy/
│   │   └── Caddyfile       # Reverse proxy configuration
│   ├── llm/
│   │   ├── Dockerfile      # LLM worker image
│   │   ├── app.py          # Main application
│   │   └── models.py       # Model loading logic
│   ├── prometheus/
│   │   └── prometheus.yml  # Monitoring configuration
│   └── grafana/
│       └── dashboards/     # Preconfigured dashboards
└── README.md
```

## Services Included

1. **LLM Workers**: Run inference models (CPU/GPU)
2. **Caddy Proxy**: HTTPS termination and load balancing
3. **Prometheus**: Metrics collection
4. **Grafana**: Visualization dashboard
5. **Node Exporter**: System metrics
6. **cAdvisor**: Container metrics

## Troubleshooting

### Common Issues

1. **ZeroTier Connection Issues**
   - Ensure all nodes have joined the network
   - Check firewall settings
   - Verify network authorization in ZeroTier admin panel

2. **GPU Detection Failures**
   - Confirm NVIDIA drivers are installed
   - Verify nvidia-docker2 is installed
   - Check that nvidia-smi works outside containers

3. **TLS Certificate Issues**
   - Ensure domain points to your server
   - Check that ports 80 and 443 are accessible
   - Verify email address in configuration

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.