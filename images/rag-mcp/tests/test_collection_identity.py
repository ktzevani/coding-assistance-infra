import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from rag_mcp.collection_identity import identity_payload, validate_identity


class CollectionIdentityTests(unittest.TestCase):
    def test_matching_identity_is_allowed(self) -> None:
        payload = identity_payload("llama-cpp", "qwen3-embedding")
        validate_identity("memory", payload, "llama-cpp", "qwen3-embedding")

    def test_different_model_is_rejected(self) -> None:
        payload = identity_payload("llama-cpp", "old-model")
        with self.assertRaisesRegex(ValueError, "belongs to embedding backend/model"):
            validate_identity("memory", payload, "llama-cpp", "new-model")

    def test_different_backend_is_rejected(self) -> None:
        payload = identity_payload("ollama", "shared-name")
        with self.assertRaises(ValueError):
            validate_identity("memory", payload, "llama-cpp", "shared-name")

    def test_payload_without_identity_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "without embedding identity"):
            validate_identity("memory", {"project": "legacy"}, "ollama", "model")


if __name__ == "__main__":
    unittest.main()

