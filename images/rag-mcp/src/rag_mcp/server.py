from __future__ import annotations

import fnmatch
import os
import uuid
from pathlib import Path
from typing import Any

import httpx
from mcp.server.fastmcp import FastMCP
from qdrant_client import QdrantClient, models

MCP = FastMCP("local-ai-project-memory", host="0.0.0.0", port=8765)
QDRANT = QdrantClient(url=os.getenv("QDRANT_URL", "http://qdrant:6333"))
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
EMBED_MODEL = os.getenv("EMBED_MODEL_OLLAMA", "qwen3-embedding:0.6b")
DEFAULT_COLLECTION = os.getenv("QDRANT_COLLECTION", "project_memory")
EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "1024"))
TOP_K = int(os.getenv("RAG_TOP_K", "8"))
MAX_CHUNK_TOKENS = int(os.getenv("RAG_MAX_CHUNK_TOKENS", "600"))
WORKSPACE_ROOT = Path(os.getenv("WORKSPACE_ROOT", "/workspaces")).resolve()

INCLUDE = (
    "README*",
    "docs/**",
    "adr/**",
    "architecture/**",
    "AGENTS.md",
    "CHANGELOG*",
    "CONTRIBUTING*",
)
EXCLUDE = (
    ".git/**",
    ".venv/**",
    "node_modules/**",
    "build/**",
    "dist/**",
    "target/**",
    ".cache/**",
    "__pycache__/**",
    "*.png",
    "*.jpg",
    "*.jpeg",
    "*.gif",
    "*.pdf",
    "*.zip",
    "*.tar",
    "*.gz",
    "*.bin",
    "*.onnx",
    "*.pt",
    "*.safetensors",
)


def _project_path(project: str) -> Path:
    path = (WORKSPACE_ROOT / project).resolve()
    if path != WORKSPACE_ROOT and WORKSPACE_ROOT not in path.parents:
        raise ValueError("project must resolve inside WORKSPACE_ROOT")
    if not path.is_dir():
        raise ValueError(f"project directory does not exist: {project}")
    return path


def _is_curated(relative: str) -> bool:
    return any(fnmatch.fnmatch(relative, rule) for rule in INCLUDE) and not any(
        fnmatch.fnmatch(relative, rule) for rule in EXCLUDE
    )


def _chunks(text: str) -> list[str]:
    # Four characters per token is a conservative-enough approximation for v1.
    size = MAX_CHUNK_TOKENS * 4
    return [text[start : start + size] for start in range(0, len(text), size)]


def _embed(texts: list[str]) -> list[list[float]]:
    response = httpx.post(
        f"{OLLAMA_URL}/api/embed",
        json={"model": EMBED_MODEL, "input": texts},
        timeout=300,
    )
    response.raise_for_status()
    return response.json()["embeddings"]


def _ensure_collection(collection: str) -> None:
    if not QDRANT.collection_exists(collection):
        QDRANT.create_collection(
            collection_name=collection,
            vectors_config=models.VectorParams(
                size=EMBEDDING_DIM,
                distance=models.Distance.COSINE,
            ),
        )


@MCP.tool()
def index_project_docs(project: str, collection: str = DEFAULT_COLLECTION) -> dict[str, Any]:
    """Index curated documentation from one mounted project directory."""
    root = _project_path(project)
    documents: list[tuple[str, str]] = []
    for path in root.rglob("*"):
        relative = path.relative_to(root).as_posix()
        if path.is_file() and _is_curated(relative):
            try:
                for index, chunk in enumerate(_chunks(path.read_text(encoding="utf-8"))):
                    if chunk.strip():
                        documents.append((f"{relative}#{index}", chunk))
            except UnicodeDecodeError:
                continue

    _ensure_collection(collection)
    vectors = _embed([content for _, content in documents]) if documents else []
    points = [
        models.PointStruct(
            id=str(uuid.uuid5(uuid.NAMESPACE_URL, f"{project}/{name}")),
            vector=vector,
            payload={"project": project, "path": name, "content": content},
        )
        for (name, content), vector in zip(documents, vectors, strict=True)
    ]
    if points:
        QDRANT.upsert(collection_name=collection, points=points, wait=True)
    return {"project": project, "collection": collection, "chunks_indexed": len(points)}


@MCP.tool()
def search_project_memory(
    query: str,
    project: str | None = None,
    collection: str = DEFAULT_COLLECTION,
    top_k: int = TOP_K,
) -> list[dict[str, Any]]:
    """Search indexed project documentation using an Ollama embedding."""
    query_filter = None
    if project:
        query_filter = models.Filter(
            must=[models.FieldCondition(key="project", match=models.MatchValue(value=project))]
        )
    result = QDRANT.query_points(
        collection_name=collection,
        query=_embed([query])[0],
        query_filter=query_filter,
        limit=top_k,
        with_payload=True,
    )
    return [
        {"score": point.score, **(point.payload or {})}
        for point in result.points
    ]


@MCP.tool()
def list_collections() -> list[str]:
    """List available Qdrant collections."""
    return [collection.name for collection in QDRANT.get_collections().collections]


@MCP.tool()
def delete_project_index(project: str, collection: str = DEFAULT_COLLECTION) -> dict[str, str]:
    """Delete one project's indexed documentation from a collection."""
    QDRANT.delete(
        collection_name=collection,
        points_selector=models.FilterSelector(
            filter=models.Filter(
                must=[
                    models.FieldCondition(
                        key="project",
                        match=models.MatchValue(value=project),
                    )
                ]
            )
        ),
        wait=True,
    )
    return {"project": project, "collection": collection, "status": "deleted"}


if __name__ == "__main__":
    MCP.run(transport="streamable-http")

