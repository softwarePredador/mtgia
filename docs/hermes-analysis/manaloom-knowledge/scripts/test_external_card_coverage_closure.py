#!/usr/bin/env python3

from __future__ import annotations

import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import external_card_coverage_closure as closure


class FakeClient:
    def __init__(self, support: dict[str, set[str]]) -> None:
        self.support = support
        self.calls: list[tuple[str, list[str]]] = []

    def post(self, url, payload, timeout):
        engine = "xmage" if "xmage" in url else "forge"
        cards = payload["cards"]
        self.calls.append((engine, [card["name"] for card in cards]))
        unsupported = []
        for index, card in enumerate(cards):
            if closure.normalize_name(card["name"]) not in self.support[engine]:
                unsupported.append(
                    {
                        "input_index": index,
                        "card_id": card.get("card_id"),
                        "name": card["name"],
                    }
                )
        return closure.HttpResult(
            200,
            {
                "engine": engine,
                "engine_version": "test",
                "engine_commit": f"{engine}-sha",
                "total": len(cards),
                "supported": len(cards) - len(unsupported),
                "unsupported": len(unsupported),
                "unsupported_cards": unsupported,
            },
        )


class ExternalCardCoverageClosureTest(unittest.TestCase):
    def test_missing_name_and_duplicate_key_fail_closed(self):
        client = FakeClient({"xmage": set(), "forge": set()})
        with self.assertRaisesRegex(ValueError, "has no name"):
            closure.build_closure(
                [{"id": "1", "name": ""}],
                xmage_url="http://xmage",
                forge_url="http://forge",
                client=client,
            )
        with self.assertRaisesRegex(ValueError, "duplicate card key"):
            closure.build_closure(
                [
                    {"id": "1", "name": "First"},
                    {"id": "1", "name": "Second"},
                ],
                xmage_url="http://xmage",
                forge_url="http://forge",
                client=client,
            )

    def test_malformed_coverage_counts_fail_closed(self):
        class MalformedClient:
            def post(self, url, payload, timeout):
                return closure.HttpResult(
                    200,
                    {
                        "total": len(payload["cards"]),
                        "supported": len(payload["cards"]),
                        "unsupported": 1,
                        "unsupported_cards": [],
                    },
                )

        with self.assertRaisesRegex(RuntimeError, "counts do not reconcile"):
            closure.build_closure(
                [{"id": "1", "name": "Card"}],
                xmage_url="http://xmage",
                forge_url="http://forge",
                client=MalformedClient(),
            )

    def test_engine_order_native_and_explicit_residual(self):
        cards = [
            {"id": "1", "name": "XMage Card", "layout": "normal", "oracle_text": "Draw a card."},
            {"id": "2", "name": "Forge Card", "layout": "normal", "oracle_text": "Gain life."},
            {"id": "3", "name": "Native Card", "layout": "normal", "oracle_text": "Add mana."},
            {
                "id": "4",
                "name": "Front / Back",
                "layout": "split",
                "oracle_text": "Split effect.",
                "card_faces": [{"name": "Front"}, {"name": "Back"}],
            },
            {
                "id": "5",
                "name": "Unknown Card",
                "layout": "normal",
                "type_line": "Sorcery",
                "oracle_text": "Draw two cards.",
            },
        ]
        client = FakeClient(
            {
                "xmage": {"xmage card", "front"},
                "forge": {"forge card"},
            }
        )
        payload = closure.build_closure(
            cards,
            xmage_url="http://xmage",
            forge_url="http://forge",
            native_names={"native card"},
            batch_size=2,
            client=client,
        )

        self.assertEqual(
            payload["summary"]["lane_counts"],
            {
                "forge_exact": 1,
                "identity_reconciliation_required": 1,
                "native_verified": 1,
                "unresolved": 1,
                "xmage_exact": 1,
            },
        )
        self.assertEqual(payload["summary"]["covered"], 3)
        self.assertEqual(payload["summary"]["residual"], 2)
        alias = next(row for row in payload["ledger"] if row["name"] == "Front / Back")
        self.assertFalse(alias["covered"])
        self.assertEqual(alias["engine_name_candidate"], "Front")
        self.assertTrue(
            all(gate["promotion_allowed"] is False for gate in payload["family_gates"])
        )
        self.assertEqual(
            payload["summary"]["residual_semantic_family_counts"]["draw_selection_topdeck"],
            1,
        )

    def test_card_keys_keep_duplicate_printings_distinct(self):
        cards = [
            {"id": "printing-a", "oracle_id": "identity", "name": "Same Card"},
            {"id": "printing-b", "oracle_id": "identity", "name": "Same Card"},
        ]
        client = FakeClient({"xmage": {"same card"}, "forge": set()})
        payload = closure.build_closure(
            cards,
            xmage_url="http://xmage",
            forge_url="http://forge",
            client=client,
        )
        self.assertEqual(payload["summary"]["total"], 2)
        self.assertEqual(len({row["key"] for row in payload["ledger"]}), 2)
        self.assertEqual(payload["summary"]["total_identities"], 1)
        self.assertEqual(payload["summary"]["fully_covered_identities"], 1)

    def test_missing_oracle_is_classified_not_silently_dropped(self):
        client = FakeClient({"xmage": set(), "forge": set()})
        payload = closure.build_closure(
            [{"id": "token", "name": "Special Object", "layout": "token"}],
            xmage_url="http://xmage",
            forge_url="http://forge",
            client=client,
        )
        self.assertEqual(payload["summary"]["residual"], 1)
        self.assertEqual(
            payload["ledger"][0]["residual_family"],
            "missing_oracle_or_nonstandard_object::token",
        )
        self.assertEqual(
            payload["ledger"][0]["residual_execution_scope"],
            "auxiliary_game_object",
        )

    def test_residual_keeps_routing_metadata_and_execution_scope(self):
        client = FakeClient({"xmage": set(), "forge": set()})
        payload = closure.build_closure(
            [
                {
                    "id": "digital",
                    "oracle_id": "digital-identity",
                    "name": "Digital Card",
                    "set_code": "ydmu",
                    "set_type": "alchemy",
                    "is_online_only": True,
                    "type_line": "Sorcery",
                    "oracle_text": "Draw two cards.",
                }
            ],
            xmage_url="http://xmage",
            forge_url="http://forge",
            client=client,
        )
        residual = payload["ledger"][0]
        self.assertEqual(residual["set_code"], "ydmu")
        self.assertEqual(residual["type_line"], "Sorcery")
        self.assertEqual(residual["oracle_text"], "Draw two cards.")
        self.assertEqual(residual["residual_execution_scope"], "digital_only_ruleset")
        self.assertEqual(
            payload["summary"]["residual_execution_scope_counts"],
            {"digital_only_ruleset": 1},
        )

    def test_challenge_deck_and_playtest_products_are_not_conventional(self):
        self.assertEqual(
            closure.residual_execution_scope(
                {
                    "name": "Challenge Card",
                    "set_code": "tfth",
                    "set_type": "memorabilia",
                    "type_line": "Sorcery",
                    "oracle_text": "Destroy target Head.",
                }
            ),
            "scenario_or_challenge_deck_ruleset",
        )
        self.assertEqual(
            closure.residual_execution_scope(
                {
                    "name": "Convention Card",
                    "set_code": "pf25",
                    "set_type": "promo",
                    "type_line": "Enchantment",
                    "oracle_text": "The top card of your library is a Food token.",
                }
            ),
            "nonstandard_or_playtest_ruleset",
        )


if __name__ == "__main__":
    unittest.main()
