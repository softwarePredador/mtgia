#!/usr/bin/env python3
"""Unit coverage for the read-only learned deck coherence audit helpers."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
AUDIT_PATH = REPO_ROOT / "server/bin/learned_deck_coherence_audit.py"


def load_audit_module():
    spec = importlib.util.spec_from_file_location(
        "learned_deck_coherence_audit",
        AUDIT_PATH,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {AUDIT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


audit = load_audit_module()


def nonzero_core_metadata(extra: dict | None = None) -> dict:
    metadata = {key: 1 for key in audit.CORE_METADATA_KEYS}
    if extra:
        metadata.update(extra)
    return metadata


def identity(
    name: str,
    colors: list[str],
    oracle_text: str = "Rules text",
    legalities: dict[str, str] | None = None,
) -> object:
    return audit.CardIdentity(
        card_id=name,
        canonical_name=name,
        type_line="Creature",
        cmc=1.0,
        oracle_id=f"oracle-{audit.normalize_name(name)}",
        oracle_text=oracle_text,
        color_identity=colors,
        legalities={"commander": "legal"} if legalities is None else legalities,
        function_tags=[],
        battle_rule_count=0,
        verified_battle_rule_count=0,
        source_coverage={},
    )


class LearnedDeckCoherenceAuditTest(unittest.TestCase):
    def test_parse_card_list_supports_text_lines(self) -> None:
        cards = audit.parse_card_list(
            """
            1 Lorehold, the Historian
            - 1 Command Tower # fixing
            x2 Mountain (M21) 312
            """
        )

        self.assertEqual(
            [(card.name, card.quantity) for card in cards],
            [
                ("Lorehold, the Historian", 1),
                ("Command Tower", 1),
                ("Mountain", 2),
            ],
        )

    def test_parse_card_list_supports_json_array_payloads(self) -> None:
        cards = audit.parse_card_list(
            """[{"name":"Lim-Dûl's Vault","quantity":1},
            {"card_name":"Troll of Khazad-dûm","qty":2}]"""
        )

        self.assertEqual(
            [(card.name, card.quantity) for card in cards],
            [("Lim-Dûl's Vault", 1), ("Troll of Khazad-dûm", 2)],
        )

    def test_normalize_name_handles_accents_and_apostrophes(self) -> None:
        self.assertEqual(
            audit.normalize_name("Lim-Dûl’s Vault"),
            audit.normalize_name("Lim-Dul's Vault"),
        )
        self.assertEqual(
            audit.normalize_name("Lórien Revealed"),
            audit.normalize_name("Lorien Revealed"),
        )

    def test_lookup_alias_prefers_lower_match_priority_for_conflicting_aliases(
        self,
    ) -> None:
        lookup: dict[str, object] = {}
        lookup_rank: dict[str, tuple[int, str, str]] = {}

        audit.add_lookup_alias(
            lookup,
            lookup_rank,
            "Vendetta",
            identity("Vengeance", ["W"]),
            priority=1,
        )
        audit.add_lookup_alias(
            lookup,
            lookup_rank,
            "Vendetta",
            identity("Vendetta", ["B"]),
            priority=0,
        )
        audit.add_lookup_alias(
            lookup,
            lookup_rank,
            "Endurance",
            identity("Endure", ["W"]),
            priority=1,
        )
        audit.add_lookup_alias(
            lookup,
            lookup_rank,
            "Endurance",
            identity("Endurance", ["G"]),
            priority=0,
        )

        self.assertEqual(
            lookup[audit.normalize_name("Vendetta")].canonical_name,
            "Vendetta",
        )
        self.assertEqual(
            lookup[audit.normalize_name("Vendetta")].color_identity,
            ["B"],
        )
        self.assertEqual(
            lookup[audit.normalize_name("Endurance")].canonical_name,
            "Endurance",
        )
        self.assertEqual(
            lookup[audit.normalize_name("Endurance")].color_identity,
            ["G"],
        )

    def test_lorehold_strategy_checks_package_minimums_and_forbidden_mox(self) -> None:
        cards = [
            "Lorehold, the Historian",
            "Dualcaster Mage",
            "Twinflame",
            "Heat Shimmer",
            "Molten Duplication",
            "Sensei's Divining Top",
            "Scroll Rack",
            "Land Tax",
            "Faithless Looting",
            "Mizzix's Mastery",
            "Past in Flames",
            "Wheel of Fortune",
            "Rise of the Eldrazi",
            "Storm Herd",
            "Worldfire",
            "Blasphemous Act",
            "Silence",
            "Orim's Chant",
            "Grand Abolisher",
            "Ranger-Captain of Eos",
            "Deflecting Swat",
            "Teferi's Protection",
            "Sol Ring",
            "Mana Vault",
            "Lotus Petal",
            "Mox Amber",
            "Arcane Signet",
            "Boros Signet",
            "Fellwar Stone",
            "Talisman of Conviction",
            "Ruby Medallion",
            "Rite of Flame",
        ]

        passing = audit.evaluate_lorehold_strategy(cards)
        self.assertTrue(passing["passed"])

        failing = audit.evaluate_lorehold_strategy(cards + ["Chrome Mox"])
        self.assertFalse(failing["passed"])
        self.assertEqual(failing["forbidden_present"], ["Chrome Mox"])
        self.assertIn(
            "lorehold_premium_mox_policy_violation",
            {issue["code"] for issue in failing["issues"]},
        )

    def test_lorehold_strategy_accepts_defense_variant_closing_conversion(self) -> None:
        cards = [
            "Lorehold, the Historian",
            "Dualcaster Mage",
            "Twinflame",
            "Heat Shimmer",
            "Molten Duplication",
            "Sensei's Divining Top",
            "Scroll Rack",
            "Land Tax",
            "Faithless Looting",
            "Mizzix's Mastery",
            "Past in Flames",
            "Wheel of Fortune",
            "Wheel of Misfortune",
            "Blasphemous Act",
            "Approach of the Second Sun",
            "Silence",
            "Orim's Chant",
            "Grand Abolisher",
            "Ranger-Captain of Eos",
            "Deflecting Swat",
            "Teferi's Protection",
            "Sol Ring",
            "Mana Vault",
            "Lotus Petal",
            "Mox Amber",
            "Arcane Signet",
            "Boros Signet",
            "Fellwar Stone",
            "Talisman of Conviction",
            "Ruby Medallion",
            "Rite of Flame",
        ]

        result = audit.evaluate_lorehold_strategy(cards)
        closing = {
            package["key"]: package
            for package in result["packages"]
        }["closing_conversion"]

        self.assertTrue(result["passed"])
        self.assertTrue(closing["passed"])
        self.assertEqual(closing["present_count"], 6)
        self.assertNotIn(
            "lorehold_strategy_closing_conversion_gap",
            {issue["code"] for issue in result["issues"]},
        )

    def test_lorehold_strategy_source_prefers_pg_runtime_deck(self) -> None:
        source, names = audit.lorehold_strategy_source(
            ["Generous Gift", "Guttersnipe"],
            ["Silent Arbiter", "Windborn Muse"],
            ["Brainstone", "Silent Arbiter"],
        )

        self.assertEqual(source, "pg_saved_deck")
        self.assertEqual(names, ["Brainstone", "Silent Arbiter"])

        source, names = audit.lorehold_strategy_source(
            ["Generous Gift"],
            ["Silent Arbiter"],
            [],
        )

        self.assertEqual(source, "sqlite_deck")
        self.assertEqual(names, ["Silent Arbiter"])

    def test_derive_metadata_uses_commander_specific_color_identity(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("Lorehold, the Historian"),
                identity=identity("Lorehold, the Historian", ["R", "W"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Silence"),
                identity=identity("Silence", ["W"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Counterspell"),
                identity=identity("Counterspell", ["U"]),
            ),
        ]

        metadata = audit.derive_metadata(resolved, allowed_colors={"R", "W"})

        self.assertEqual(metadata["commander_color_identity"], ["R", "W"])
        self.assertEqual(metadata["off_color_candidates"], ["Counterspell"])

    def test_commander_staple_legality_override_is_explicit(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("Command Tower"),
                identity=identity("Command Tower", [], legalities={}),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Sol Ring"),
                identity=identity("Sol Ring", [], legalities={}),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Mystery Staple"),
                identity=identity("Mystery Staple", [], legalities={}),
            ),
        ]

        metadata = audit.derive_metadata(resolved, allowed_colors={"R", "W"})

        self.assertEqual(metadata["missing_legalities"], ["Mystery Staple"])
        self.assertEqual(
            [
                assumption["name"]
                for assumption in metadata["commander_legality_assumptions"]
            ],
            ["Command Tower", "Sol Ring"],
        )
        self.assertTrue(
            all(
                assumption["reason"]
                == "commander_staple_missing_pg_legalities_assumed_legal"
                for assumption in metadata["commander_legality_assumptions"]
            )
        )

    def test_accepted_empty_oracle_text_is_not_missing_oracle_text(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("Memnite"),
                identity=identity("Memnite", [], oracle_text=""),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Mystery Vanilla"),
                identity=identity("Mystery Vanilla", [], oracle_text=""),
            ),
        ]

        metadata = audit.derive_metadata(resolved, allowed_colors={"R", "W"})

        self.assertEqual(metadata["missing_oracle_text"], ["Mystery Vanilla"])
        self.assertEqual(metadata["missing_oracle_text_quantity"], 1)
        self.assertEqual(metadata["accepted_empty_oracle_text_quantity"], 1)
        self.assertEqual(
            metadata["accepted_empty_oracle_text"][0]["name"],
            "Memnite",
        )
        self.assertEqual(
            metadata["accepted_empty_oracle_text"][0]["source"],
            "scryfall_exact_2026_06_19",
        )

    def test_commander_deck_shape_checks_quantity_and_commander_count(self) -> None:
        cards = [audit.CardLine("Lorehold, the Historian")]
        cards.extend(audit.CardLine(f"Card {index}") for index in range(98))
        metadata = {
            "total_lands": 33,
            "missing_legalities": [],
            "missing_oracle_text_quantity": 0,
            "unresolved_quantity": 0,
            "off_color_candidates": [],
        }

        shape = audit.evaluate_commander_deck_shape(
            "Lorehold, the Historian",
            cards,
            metadata,
        )

        self.assertEqual(shape["parsed_quantity"], 99)
        self.assertEqual(shape["commander_quantity"], 1)
        self.assertFalse(shape["passes_shape"])
        self.assertIn("wrong_card_quantity", shape["critical_flags"])

    def test_partner_identity_context_reduces_partner_false_off_color(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("Kraum, Ludevic's Opus"),
                identity=identity("Kraum, Ludevic's Opus", ["R", "U"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Tymna the Weaver"),
                identity=identity("Tymna the Weaver", ["B", "W"], "Partner"),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Ad Nauseam"),
                identity=identity("Ad Nauseam", ["B"]),
            ),
        ]
        metadata = audit.derive_metadata(resolved, allowed_colors={"R", "U"})

        metadata.update(
            audit.infer_partner_identity_context(
                "Kraum, Ludevic's Opus",
                "Kraum, Ludevic's Opus",
                resolved,
                {"R", "U"},
            )
        )

        self.assertEqual(metadata["off_color_candidates"], ["Ad Nauseam", "Tymna the Weaver"])
        self.assertEqual(metadata["combined_commander_color_identity"], ["B", "R", "U", "W"])
        self.assertEqual(metadata["off_color_after_partner_inference"], [])
        self.assertEqual(
            [candidate["name"] for candidate in metadata["partner_identity_candidates"]],
            ["Tymna the Weaver"],
        )
        model = audit.build_commander_identity_model(
            "Kraum, Ludevic's Opus",
            "Kraum, Ludevic's Opus + Tymna the Weaver",
            "learned_deck:89",
            resolved,
            {"R", "U"},
            {
                "partner_identity_candidates": metadata["partner_identity_candidates"],
                "combined_commander_color_identity": metadata[
                    "combined_commander_color_identity"
                ],
            },
        )
        self.assertEqual(model["status"], "combined_identity_inferred")
        self.assertTrue(model["requires_first_class_persistence"])
        self.assertEqual(model["combined_color_identity"], ["B", "R", "U", "W"])
        self.assertEqual(model["identity_components"][0]["name"], "Tymna the Weaver")

    def test_manual_combined_identity_model_for_k9_review(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("K-9, Mark I"),
                identity=identity("K-9, Mark I", ["U"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("The Fourteenth Doctor"),
                identity=identity("The Fourteenth Doctor", ["G", "R", "U", "W"]),
            ),
        ]

        model = audit.build_commander_identity_model(
            "K-9, Mark I",
            "K-9, Mark I + The Fourteenth Doctor",
            "learned_deck:116",
            resolved,
            {"U"},
            {
                "partner_identity_candidates": [],
                "combined_commander_color_identity": ["U"],
            },
        )

        self.assertEqual(model["status"], "combined_identity_manual_review")
        self.assertEqual(model["source"], "manual_off_color_review")
        self.assertEqual(model["combined_color_identity"], ["G", "R", "U", "W"])
        self.assertEqual(
            [component["name"] for component in model["identity_components"]],
            ["K-9, Mark I", "The Fourteenth Doctor"],
        )

    def test_deck_name_component_infers_k9_fourteenth_doctor_identity(self) -> None:
        resolved = [
            audit.ResolvedCard(
                line=audit.CardLine("K-9, Mark I"),
                identity=identity("K-9, Mark I", ["U"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("The Fourteenth Doctor"),
                identity=identity("The Fourteenth Doctor", ["G", "R", "U", "W"]),
            ),
            audit.ResolvedCard(
                line=audit.CardLine("Deflecting Swat"),
                identity=identity("Deflecting Swat", ["R"]),
            ),
        ]
        metadata = audit.derive_metadata(resolved, allowed_colors={"U"})

        metadata.update(
            audit.infer_partner_identity_context(
                "K-9, Mark I",
                "K-9, Mark I + The Fourteenth Doctor",
                resolved,
                {"U"},
            )
        )

        self.assertEqual(
            metadata["partner_identity_candidates"],
            [
                {
                    "name": "The Fourteenth Doctor",
                    "color_identity": ["G", "R", "U", "W"],
                    "reason": "deck_name_commander_component",
                }
            ],
        )
        self.assertEqual(metadata["combined_commander_color_identity"], ["G", "R", "U", "W"])
        self.assertEqual(metadata["off_color_after_partner_inference"], [])

        model = audit.build_commander_identity_model(
            "K-9, Mark I",
            "K-9, Mark I + The Fourteenth Doctor",
            "learned_deck:116",
            resolved,
            {"U"},
            {
                "partner_identity_candidates": metadata["partner_identity_candidates"],
                "combined_commander_color_identity": metadata[
                    "combined_commander_color_identity"
                ],
            },
        )

        self.assertEqual(model["status"], "combined_identity_inferred")
        self.assertEqual(model["source"], "deck_name_commander_component")
        self.assertEqual(model["combined_color_identity"], ["G", "R", "U", "W"])

    def partner_identity_audit(
        self,
        metadata_model: dict | None,
    ) -> object:
        model = {
            "status": "combined_identity_inferred",
            "source": "partner_text",
            "requires_first_class_persistence": True,
            "primary_commander_name": "Kraum, Ludevic's Opus",
            "declared_deck_name": "Kraum, Ludevic's Opus + Tymna the Weaver",
            "base_color_identity": ["R", "U"],
            "combined_color_identity": ["B", "R", "U", "W"],
            "identity_components": [
                {
                    "name": "Tymna the Weaver",
                    "color_identity": ["B", "W"],
                    "source": "partner_text",
                }
            ],
        }
        metadata = nonzero_core_metadata({"total_lands": 1})
        if metadata_model is not None:
            metadata["commander_identity_model"] = metadata_model
        return audit.LearnedDeckAudit(
            commander_name="Kraum, Ludevic's Opus",
            deck_name="Kraum, Ludevic's Opus + Tymna the Weaver",
            source_system="pg_meta_decks",
            source_ref="learned_deck:89",
            row_id="kraum-tymna-row",
            card_count_declared=0,
            metadata=metadata,
            parsed_cards=[],
            resolved_cards=[],
            derived_metadata={
                "total_lands": 1,
                "missing_oracle_id_quantity": 0,
                "missing_oracle_text_quantity": 0,
                "off_color_candidates": ["Ad Nauseam", "Tymna the Weaver"],
                "partner_identity_candidates": [
                    {
                        "name": "Tymna the Weaver",
                        "color_identity": ["B", "W"],
                        "reason": "partner_text",
                    }
                ],
                "off_color_after_partner_inference": [],
                "commander_identity_model": model,
                "commander_deck_shape": {
                    "parsed_quantity": audit.COMMANDER_EXPECTED_QUANTITY,
                    "commander_quantity": 1,
                    "review_flags": [],
                },
            },
        )

    def test_compare_metadata_reports_unpersisted_partner_identity_model(self) -> None:
        learned_deck = self.partner_identity_audit(metadata_model=None)

        audit.compare_metadata(learned_deck)

        self.assertIn(
            "partner_identity_not_modeled",
            [issue["code"] for issue in learned_deck.issues],
        )

    def test_compare_metadata_respects_persisted_partner_identity_model(self) -> None:
        learned_deck = self.partner_identity_audit(metadata_model=None)
        model = learned_deck.derived_metadata["commander_identity_model"]
        learned_deck.metadata["commander_identity_model"] = model

        audit.compare_metadata(learned_deck)

        self.assertNotIn(
            "partner_identity_not_modeled",
            [issue["code"] for issue in learned_deck.issues],
        )

    def test_active_metadata_gate_fails_required_invariant_codes(self) -> None:
        payload = {
            "decks": [
                {
                    "row_id": "f46c0421-71b4-4de3-bb79-05a916b4988b",
                    "source_ref": "learned_deck:82",
                    "commander_name": "Lorehold, the Historian",
                    "deck_name": "Lorehold Learned Control",
                    "issues": [
                        {
                            "code": "metadata_total_lands_mismatch",
                            "message": "Cached total_lands differs.",
                            "expected": 33,
                            "actual": 30,
                        },
                        {
                            "code": "unresolved_card_names",
                            "message": "Unresolved cards.",
                            "expected": 0,
                            "actual": 1,
                        },
                        {
                            "code": "some_core_metadata_zero",
                            "message": "Review-only partial zero metadata.",
                        },
                    ],
                },
                {
                    "row_id": "zeroed-row",
                    "source_ref": "learned_deck:zeroed",
                    "commander_name": "Zeroed Commander",
                    "deck_name": "Zeroed Active Deck",
                    "issues": [
                        {
                            "code": "all_core_metadata_zero",
                            "message": "All core metadata counters are zero.",
                        },
                        {
                            "code": "metadata_zero_lands",
                            "message": "Metadata reports zero lands.",
                        },
                    ],
                },
            ],
        }

        gate = audit.active_learned_deck_metadata_gate_summary(payload)

        self.assertEqual(gate["status"], "fail")
        self.assertEqual(gate["failure_count"], 4)
        self.assertEqual(
            gate["failing_issue_codes"],
            {
                "all_core_metadata_zero": 1,
                "metadata_total_lands_mismatch": 1,
                "metadata_zero_lands": 1,
                "unresolved_card_names": 1,
            },
        )
        self.assertNotIn(
            "some_core_metadata_zero",
            {failure["code"] for failure in gate["failures"]},
        )

    def test_active_metadata_gate_passes_without_required_invariants(self) -> None:
        payload = {
            "decks": [
                {
                    "row_id": "review-only-row",
                    "source_ref": "learned_deck:review",
                    "issues": [
                        {
                            "code": "missing_oracle_text",
                            "message": "Backfill oracle text separately.",
                        },
                        {
                            "code": "some_core_metadata_zero",
                            "message": "Review-only partial zero metadata.",
                        },
                    ],
                },
            ],
        }

        gate = audit.active_learned_deck_metadata_gate_summary(payload)

        self.assertEqual(gate["status"], "pass")
        self.assertEqual(gate["failure_count"], 0)

    def test_markdown_recommendation_uses_current_lorehold_source_ref(self) -> None:
        payload = {
            "generated_at": "now",
            "aggregate": {
                "summary": {"active_learned_decks": 1},
                "severity_counts": {},
                "by_source": {"manaloom_candidate_gate": {"active": 1}},
            },
            "postgres_oracle_inventory": {
                "total_cards": 1,
                "oracle_structured_cards": 1,
                "oracle_structured_rate": 1.0,
                "missing_oracle_id": 0,
                "missing_oracle_text": 0,
                "missing_type_line": 0,
                "sample_unstructured_cards": [],
            },
            "off_color_resolution_plan": {"entries": []},
            "decks": [
                {
                    "commander_name": "Lorehold, the Historian",
                    "source_ref": "lorehold_candidate_607_v615_mana_engine_v1",
                    "issues": [],
                    "derived_metadata": {},
                    "manual_off_color_review": None,
                }
            ],
            "lorehold": {
                "active_learned_deck": {},
                "sqlite_deck": {},
                "pg_saved_deck": {},
                "name_match": {},
                "no_premium_mox_present": [],
                "strategy_source": "active_learned_deck",
                "strategy_checks": {"passed": True, "packages": []},
            },
        }

        markdown = audit.markdown_report(payload)

        self.assertIn(
            "Keep Lorehold active learned deck `lorehold_candidate_607_v615_mana_engine_v1`",
            markdown,
        )
        self.assertNotIn("learned deck 82", markdown)

    def test_audit_json_includes_manual_off_color_review(self) -> None:
        learned_deck = audit.LearnedDeckAudit(
            commander_name="K-9, Mark I",
            deck_name="K-9, Mark I + The Fourteenth Doctor",
            source_system="pg_meta_decks",
            source_ref="learned_deck:116",
            row_id="421b13ef-c325-42e4-821c-8123dea59d15",
            card_count_declared=100,
            metadata={},
            parsed_cards=[],
            resolved_cards=[],
            derived_metadata={
                "resolved_quantity": 100,
                "off_color_after_partner_inference": ["Deflecting Swat"],
            },
            issues=[
                {
                    "severity": "high",
                    "code": "off_color_cards",
                    "message": "Resolved card list includes cards outside commander color identity.",
                },
            ],
        )

        payload = audit.audit_to_json(learned_deck)

        self.assertEqual(
            payload["manual_off_color_review"]["classification"],
            "combined_commander_identity_not_modeled",
        )
        self.assertEqual(
            payload["manual_off_color_review"]["decision"],
            "move_to_combined_commander_identity_modeling",
        )

    def test_off_color_resolution_plan_detects_identity_bridge_misresolution(self) -> None:
        learned_deck = audit.LearnedDeckAudit(
            commander_name="Rowan, Scion of War",
            deck_name="Rowan Learned Deck",
            source_system="pg_meta_decks",
            source_ref="learned_deck:114",
            row_id="rowan-row",
            card_count_declared=100,
            metadata={},
            parsed_cards=[
                audit.CardLine("Vendetta"),
            ],
            resolved_cards=[
                audit.ResolvedCard(
                    line=audit.CardLine("Vendetta"),
                    identity=identity("Vengeance", ["W"]),
                ),
            ],
            derived_metadata={
                "resolved_quantity": 100,
                "commander_color_identity": ["B", "R"],
                "commander_identity_model": {
                    "combined_color_identity": ["B", "R"],
                },
                "off_color_after_partner_inference": ["Vengeance"],
            },
        )
        lookup = {
            audit.normalize_name("Vengeance"): identity("Vengeance", ["W"]),
        }

        plan = audit.build_off_color_resolution_plan([learned_deck], lookup)

        self.assertEqual(plan["status"], "ready_for_review")
        self.assertFalse(plan["db_mutations"])
        self.assertTrue(plan["apply_requires_explicit_approval"])
        self.assertEqual(plan["entry_count"], 1)
        entry = plan["entries"][0]
        self.assertEqual(entry["source_ref"], "learned_deck:114")
        self.assertEqual(entry["allowed_color_identity"], ["B", "R"])
        self.assertEqual(entry["classification"], "identity_bridge_misresolution")
        card = entry["cards"][0]
        self.assertEqual(card["raw_card_list_name"], "Vendetta")
        self.assertEqual(card["quantity_in_card_list"], 1)
        self.assertEqual(card["currently_resolved_as"], "Vengeance")
        self.assertEqual(card["expected_color_identity"], ["B"])
        self.assertEqual(card["current_resolved_color_identity"], ["W"])
        self.assertTrue(card["expected_in_commander_identity"])
        self.assertTrue(card["resolved_as_off_color"])
        self.assertIn("SELECT id, commander_name", entry["suggested_review_sql"])

    def test_off_color_resolution_plan_omits_inactive_manual_reviews(self) -> None:
        learned_deck = audit.LearnedDeckAudit(
            commander_name="Rowan, Scion of War",
            deck_name="Rowan Learned Deck",
            source_system="pg_meta_decks",
            source_ref="learned_deck:114",
            row_id="rowan-row",
            card_count_declared=100,
            metadata={},
            parsed_cards=[
                audit.CardLine("Vendetta"),
            ],
            resolved_cards=[
                audit.ResolvedCard(
                    line=audit.CardLine("Vendetta"),
                    identity=identity("Vendetta", ["B"]),
                ),
            ],
            derived_metadata={
                "resolved_quantity": 100,
                "commander_color_identity": ["B", "R"],
                "commander_identity_model": {
                    "combined_color_identity": ["B", "R"],
                },
                "off_color_after_partner_inference": [],
            },
        )

        plan = audit.build_off_color_resolution_plan([learned_deck], {})

        self.assertEqual(plan["status"], "no_current_off_color_manual_entries")
        self.assertEqual(plan["entry_count"], 0)


if __name__ == "__main__":
    unittest.main()
