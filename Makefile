.PHONY: config up up-nvidia up-amd up-llama up-rag up-rag-gguf down pull-models smoke endpoints lint

config:
	docker compose -f docker-compose.yml -f docker-compose.cpu.yml config

up:
	./scripts/linux/up.sh cpu

up-nvidia:
	./scripts/linux/up.sh nvidia

up-amd:
	./scripts/linux/up.sh amd

up-llama:
	./scripts/linux/up.sh cpu llama

up-rag:
	./scripts/linux/up.sh cpu rag

up-rag-gguf:
	./scripts/linux/up.sh cpu rag gguf-embeddings

down:
	./scripts/linux/down.sh

pull-models:
	./scripts/linux/pull-models.sh

smoke:
	./scripts/linux/smoke-test.sh

endpoints:
	./scripts/linux/print-endpoints.sh

lint:
	shellcheck scripts/linux/*.sh images/*/*.sh
	python3 -m compileall -q images/rag-mcp/src
