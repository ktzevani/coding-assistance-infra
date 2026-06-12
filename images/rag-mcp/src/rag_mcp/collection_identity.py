from __future__ import annotations

from typing import Any

COLLECTION_METADATA_KIND = "collection_metadata"


def identity_payload(backend: str, model: str) -> dict[str, str]:
    return {
        "record_kind": COLLECTION_METADATA_KIND,
        "embedding_backend": backend,
        "embedding_model": model,
    }


def validate_identity(
    collection: str,
    payload: dict[str, Any],
    backend: str,
    model: str,
) -> None:
    existing_backend = payload.get("embedding_backend")
    existing_model = payload.get("embedding_model")
    if existing_backend is None or existing_model is None:
        raise ValueError(
            f"Collection {collection!r} contains points without embedding identity. "
            "Use a new collection or delete and rebuild the existing index."
        )
    if existing_backend != backend or existing_model != model:
        raise ValueError(
            f"Collection {collection!r} belongs to embedding backend/model "
            f"{existing_backend!r}/{existing_model!r}, not {backend!r}/{model!r}. "
            "Use a new collection or delete and rebuild the existing index."
        )

