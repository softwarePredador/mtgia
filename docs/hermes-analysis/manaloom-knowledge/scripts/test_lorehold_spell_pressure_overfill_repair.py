from pathlib import Path

import lorehold_spell_pressure_overfill_repair as repair


ROOT = Path(__file__).resolve().parents[1]
REPORT_DIR = ROOT.parent / "master_optimizer_reports"


def build_payload():
    return repair.build_payload(
        candidate=repair.read_json(repair.DEFAULT_CANDIDATE),
        matrix=repair.read_json(repair.DEFAULT_MATRIX),
        gate=repair.read_json(repair.DEFAULT_GATE),
        trace=repair.read_json(repair.DEFAULT_TRACE),
        db_path=repair.DEFAULT_DB,
        candidate_path=repair.DEFAULT_CANDIDATE,
        matrix_path=repair.DEFAULT_MATRIX,
        gate_path=repair.DEFAULT_GATE,
        trace_path=repair.DEFAULT_TRACE,
    )


def test_overfill_repair_identifies_apex_for_single_cut():
    payload = build_payload()

    assert payload["status"] == "overfill_repair_plan_ready"
    assert payload["summary"]["top_cut_card"] == "Apex of Power"
    assert payload["top_cut"]["decision"] == "overfill_cut_candidate"
    assert payload["top_cut"]["overfilled_tags"] == [
        "hand_filter",
        "spell_chain_conversion",
        "topdeck_miracle_setup",
    ]
    assert payload["top_cut"]["smoke_event_counts"] == {}
    assert payload["top_cut"]["in_protected_607"] is False
    assert payload["top_cut"]["after_cut_risks"] == []


def test_overfill_repair_prefers_pearl_medallion_as_low_noise_replacement():
    payload = build_payload()

    assert payload["summary"]["top_replacement_card"] == "Pearl Medallion"
    assert payload["top_replacement"]["decision"] == "replacement_candidate"
    assert payload["top_replacement"]["after_replacement_risks"] == []
    assert "ramp" in payload["top_replacement"]["roles"]
    assert "spell_chain_conversion" not in payload["top_replacement"]["tags"]


def test_markdown_surfaces_next_shell_without_promotion():
    markdown = repair.render_markdown(build_payload())

    assert "Lorehold Spell Pressure Overfill Repair" in markdown
    assert "spell_pressure_mana_conversion_deoverfill" in markdown
    assert "promotion_allowed: `false`" in markdown
    assert "EDHREC average optimized spellslinger" in markdown
