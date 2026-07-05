import json
import sqlite3
from pathlib import Path

import lorehold_mana_base_candidate_materializer as materializer
import lorehold_mana_base_candidate_preflight as preflight
from test_lorehold_mana_base_candidate_materializer import create_fixture_db, create_model_report


def materialized_report(tmp_path: Path) -> tuple[Path, Path]:
    source_db = tmp_path / "knowledge.db"
    model_report = tmp_path / "safe_model.json"
    out_prefix = tmp_path / "materializer_report"
    create_fixture_db(source_db)
    create_model_report(model_report)
    payload = materializer.build_payload(
        source_db=source_db,
        safe_cut_model_path=model_report,
        out_prefix=out_prefix,
    )
    json_path, _md_path = materializer.write_outputs(payload, out_prefix)
    candidate_db = out_prefix.parent / f"{out_prefix.name}_candidate" / "knowledge_candidate.db"
    return json_path, candidate_db


def test_preflight_accepts_single_land_swap_with_anchors_unchanged(tmp_path: Path) -> None:
    report_path, _candidate_db = materialized_report(tmp_path)

    payload = preflight.build_payload(
        materializer_report_path=report_path,
        out_prefix=tmp_path / "preflight_report",
    )

    assert payload["status"] == "battle_smoke_preflight_ready"
    assert payload["summary"]["allow_smoke_battle_gate"] is True
    assert payload["summary"]["allow_promotion_gate"] is False
    checks = payload["preflight_validation"]["checks"]
    assert checks["single_add_single_cut"] is True
    assert checks["expected_add_only"] is True
    assert checks["expected_cut_only"] is True
    assert checks["same_lane_land_swap"] is True
    assert checks["protected_anchors_unchanged"] is True
    assert checks["add_has_active_land_rule"] is True


def test_preflight_blocks_changed_protected_anchor(tmp_path: Path) -> None:
    report_path, candidate_db = materialized_report(tmp_path)
    with sqlite3.connect(candidate_db) as conn:
        conn.execute(
            """
            UPDATE deck_cards
            SET functional_tag='changed_anchor'
            WHERE deck_id=607 AND card_name=?
            """,
            ("Bender's Waterskin",),
        )
        conn.commit()

    payload = preflight.build_payload(
        materializer_report_path=report_path,
        out_prefix=tmp_path / "preflight_report",
    )

    assert payload["status"] == "battle_smoke_preflight_blocked"
    assert payload["summary"]["allow_smoke_battle_gate"] is False
    assert payload["preflight_validation"]["checks"]["protected_anchors_unchanged"] is False
    assert "Bender's Waterskin" in payload["preflight_validation"]["protected_anchor_status"]["changed"]


def test_write_outputs_creates_report_pair(tmp_path: Path) -> None:
    report_path, _candidate_db = materialized_report(tmp_path)
    out_prefix = tmp_path / "preflight_report"
    payload = preflight.build_payload(
        materializer_report_path=report_path,
        out_prefix=out_prefix,
    )
    json_path, md_path = preflight.write_outputs(payload, out_prefix)

    assert json_path.exists()
    assert md_path.exists()
    assert json.loads(json_path.read_text(encoding="utf-8"))["status"] == "battle_smoke_preflight_ready"
    assert "Lorehold Mana Base Candidate Preflight" in md_path.read_text(encoding="utf-8")
