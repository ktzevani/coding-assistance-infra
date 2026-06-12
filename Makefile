.PHONY: config up up-nvidia up-amd up-llama up-rag down pull-models smoke endpoints lint

config:
	docker compose -f docker-compose.yml -f docker-compose.cpu.yml config

up:
	./scripts/up.sh cpu

up-nvidia:
	./scripts/up.sh nvidia

up-amd:
	./scripts/up.sh amd

up-llama:
	./scripts/up.sh cpu llama

up-rag:
	./scripts/up.sh cpu rag

down:
	./scripts/down.sh

pull-models:
	./scripts/pull-models.sh

smoke:
	./scripts/smoke-test.sh

endpoints:
	./scripts/print-endpoints.sh

lint:
	shellcheck scripts/*.sh images/*/*.sh
	python3 -m compileall -q images/rag-mcp/src

