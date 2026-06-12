import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parents[1] / "src"))

from rag_mcp.policy import collection_patterns, limit_context


class PolicyTests(unittest.TestCase):
    def test_collection_patterns_uses_selected_collection(self) -> None:
        config = {
            "collections": {
                "custom": {"include": ["notes/**"], "exclude": ["notes/tmp/**"]}
            }
        }
        self.assertEqual(
            collection_patterns(config, "custom", ("README*",), (".git/**",)),
            (("notes/**",), ("notes/tmp/**",)),
        )

    def test_collection_patterns_falls_back_to_defaults(self) -> None:
        self.assertEqual(
            collection_patterns({}, "missing", ("README*",), (".git/**",)),
            (("README*",), (".git/**",)),
        )

    def test_collection_patterns_rejects_invalid_config(self) -> None:
        with self.assertRaisesRegex(ValueError, "must be a mapping"):
            collection_patterns({"collections": []}, "memory", (), ())

    def test_limit_context_truncates_final_result(self) -> None:
        results = [{"content": "a" * 12}, {"content": "b" * 12}]
        self.assertEqual(
            limit_context(results, 5),
            [{"content": "a" * 12}, {"content": "b" * 8}],
        )

    def test_limit_context_rejects_non_positive_budget(self) -> None:
        self.assertEqual(limit_context([{"content": "text"}], 0), [])


if __name__ == "__main__":
    unittest.main()

