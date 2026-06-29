#!/usr/bin/env python3
from __future__ import annotations

import tempfile
from pathlib import Path

import mtg_battle_external_source_audit as audit


REPO_ROOT = Path(__file__).resolve().parents[4]


def test_source_inventory_anchors_authoritative_rules_and_external_logs() -> None:
    by_id = {source.id: source for source in audit.SOURCE_INVENTORY}

    assert by_id["wotc_comprehensive_rules_20260619"].reliability == "authoritative"
    assert by_id["wotc_mtga_detailed_logs"].source_type == "official_telemetry_availability"
    assert by_id["gathering_gg_mtga_parser"].source_type == "open_source_log_parser_reference"
    assert by_id["scryfall_api"].source_type == "card_oracle_api"
    assert by_id["seventeenlands_public_datasets"].source_type == "public_game_history_corpus"
    assert by_id["forge_rules_engine"].source_type == "independent_open_engine"


def test_requirement_status_distinguishes_covered_partial_and_gap() -> None:
    requirement = audit.BattleRequirement(
        id="fixture_requirement",
        area="fixture",
        source_ids=("wotc_comprehensive_rules_20260619",),
        required_for_gate=True,
        expected_globs=("a.py", "b.py"),
        keyword_groups=(("alpha",), ("beta",), ("gamma",)),
        rationale="fixture",
        missing_recommendation="fixture",
    )
    with tempfile.TemporaryDirectory() as tmp_name:
        repo_root = Path(tmp_name)
        (repo_root / "a.py").write_text("alpha beta", encoding="utf-8")
        partial = audit.audit_requirement(repo_root, requirement)
        assert partial["status"] == "partial"
        assert partial["missing_globs"] == ["b.py"]
        assert partial["missing_keyword_groups"] == [["gamma"]]

        (repo_root / "b.py").write_text("gamma", encoding="utf-8")
        covered = audit.audit_requirement(repo_root, requirement)
        assert covered["status"] == "covered"
        assert covered["missing_globs"] == []
        assert covered["missing_keyword_groups"] == []

    with tempfile.TemporaryDirectory() as tmp_name:
        gap = audit.audit_requirement(Path(tmp_name), requirement)
        assert gap["status"] == "gap"


def test_real_repo_external_battle_source_audit_has_no_required_gaps() -> None:
    report = audit.build_audit(REPO_ROOT)
    requirements = {item["id"]: item for item in report["requirements"]}

    assert report["postgres_writes"] is False
    assert report["summary"]["required_gap_count"] == 0
    assert report["summary"]["optional_gap_count"] == 0
    assert report["summary"]["gate_status"] == "pass"
    assert requirements["priority_stack_and_resolution"]["status"] != "gap"
    assert requirements["combat_step_model"]["status"] != "gap"
    assert requirements["seventeenlands_history_learning"]["status"] != "gap"
    assert requirements["mtga_player_log_ingestion"]["required_for_gate"] is False
    assert requirements["mtga_player_log_ingestion"]["status"] == "covered"
    assert requirements["independent_engine_crosscheck_beyond_xmage"]["required_for_gate"] is False
    assert requirements["independent_engine_crosscheck_beyond_xmage"]["status"] == "covered"


if __name__ == "__main__":
    test_source_inventory_anchors_authoritative_rules_and_external_logs()
    test_requirement_status_distinguishes_covered_partial_and_gap()
    test_real_repo_external_battle_source_audit_has_no_required_gaps()
    print("3 tests passed")
