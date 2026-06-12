from __future__ import annotations

from typing import Any


def collection_patterns(
    config: dict[str, Any],
    collection: str,
    default_include: tuple[str, ...],
    default_exclude: tuple[str, ...],
) -> tuple[tuple[str, ...], tuple[str, ...]]:
    collections = config.get("collections", {})
    if not isinstance(collections, dict):
        raise ValueError("RAG collections config field 'collections' must be a mapping")
    settings = collections.get(collection, {})
    if not isinstance(settings, dict):
        raise ValueError(f"RAG collection {collection!r} must be a mapping")
    include_value = settings.get("include", default_include)
    exclude_value = settings.get("exclude", default_exclude)
    if not isinstance(include_value, (list, tuple)) or not isinstance(
        exclude_value, (list, tuple)
    ):
        raise ValueError(f"RAG collection {collection!r} include/exclude must be lists")
    return tuple(include_value), tuple(exclude_value)


def limit_context(
    results: list[dict[str, Any]], max_tokens: int
) -> list[dict[str, Any]]:
    if max_tokens <= 0:
        return []

    remaining_chars = max_tokens * 4
    limited: list[dict[str, Any]] = []
    for result in results:
        content = str(result.get("content", ""))
        if not content:
            limited.append(result)
            continue
        if remaining_chars <= 0:
            break
        if len(content) <= remaining_chars:
            limited.append(result)
            remaining_chars -= len(content)
            continue

        truncated = dict(result)
        truncated["content"] = content[:remaining_chars]
        limited.append(truncated)
        break
    return limited

