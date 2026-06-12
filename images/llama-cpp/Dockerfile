ARG LLAMA_CPP_BASE_IMAGE=ghcr.io/ggml-org/llama.cpp:server
FROM ${LLAMA_CPP_BASE_IMAGE}

COPY entrypoint.sh /usr/local/bin/local-ai-entrypoint.sh
COPY embedding-entrypoint.sh /usr/local/bin/local-ai-embedding-entrypoint.sh
RUN chmod +x \
    /usr/local/bin/local-ai-entrypoint.sh \
    /usr/local/bin/local-ai-embedding-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/local-ai-entrypoint.sh"]
