.PHONY: help init test deploy worker clean status logs

help:
	@echo "AI Cluster Bootstrap Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make init          Initialize cluster configuration"
	@echo "  make test          Test cluster setup"
	@echo "  make deploy        Deploy the main cluster"
	@echo "  make worker        Deploy a worker node"
	@echo "  make status        Show cluster status"
	@echo "  make logs          Show cluster logs"
	@echo "  make clean         Stop and remove cluster"

init:
	@echo "Initializing cluster..."
	./scripts/init-cluster.sh
	@echo "Initialization complete. Please edit .env with your configuration."

test:
	@echo "Testing cluster setup..."
	./test-cluster.sh

deploy:
	@echo "Deploying cluster..."
	docker-compose up -d
	@echo "Cluster deployed!"
	@echo "API available at http://localhost:8000"
	@echo "Grafana at http://localhost:3000 (admin/admin)"

worker:
	@echo "Deploying worker node..."
	docker-compose -f docker-compose-worker.yml up -d
	@echo "Worker node deployed!"

clean:
	@echo "Cleaning up cluster..."
	docker-compose down -v
	docker-compose -f docker-compose-worker.yml down -v
	@echo "Cluster cleaned up."

status:
	@echo "Cluster status:"
	docker-compose ps

logs:
	@echo "Cluster logs:"
	docker-compose logs --tail=20