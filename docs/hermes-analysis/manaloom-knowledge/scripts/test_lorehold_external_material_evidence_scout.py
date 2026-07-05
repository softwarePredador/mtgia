import sqlite3
from pathlib import Path

import lorehold_external_material_evidence_scout as scout


def make_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
          id INTEGER PRIMARY KEY,
          deck_id INTEGER,
          card_name TEXT NOT NULL,
          quantity INTEGER DEFAULT 1
        );
        CREATE TABLE battle_card_rules (
          normalized_name TEXT NOT NULL,
          logical_rule_key TEXT NOT NULL,
          card_name TEXT NOT NULL,
          effect_json TEXT DEFAULT '{}',
          deck_role_json TEXT DEFAULT '{}',
          source TEXT DEFAULT 'curated',
          confidence REAL DEFAULT 1.0,
          review_status TEXT DEFAULT 'verified',
          execution_status TEXT DEFAULT 'auto',
          rule_version INTEGER DEFAULT 1,
          created_at TEXT DEFAULT '2026-07-05T00:00:00Z',
          updated_at TEXT DEFAULT '2026-07-05T00:00:00Z',
          PRIMARY KEY (normalized_name, logical_rule_key)
        );
        """
    )
    conn.executemany(
        "INSERT INTO deck_cards (deck_id, card_name, quantity) VALUES (?, ?, 1)",
        [
            (607, "Lorehold, the Historian"),
            (607, "Creative Technique"),
            (608, "Storm-Kiln Artist"),
            (616, "Possibility Storm"),
            (617, "Brallin, Skyshark Rider"),
        ],
    )
    conn.executemany(
        """
        INSERT INTO battle_card_rules (
          normalized_name, logical_rule_key, card_name, review_status, execution_status
        ) VALUES (?, ?, ?, 'verified', 'auto')
        """,
        [
            ("storm-kiln artist", "storm_kiln_runtime_v1", "Storm-Kiln Artist"),
            ("karmic guide", "karmic_guide_runtime_v1", "Karmic Guide"),
            ("possibility storm", "possibility_storm_runtime_v1", "Possibility Storm"),
        ],
    )
    return conn


def build_payload() -> dict:
    conn = make_conn()
    return scout.build_payload(
        conn,
        db_path=Path("/tmp/knowledge.db"),
        pressure_report={
            "status": "pressure_cut_expansion_no_seed_safe_cut_keep_607",
            "summary": {"seed_safe_cut_ready_count": 0, "gate_ready_package_count": 0},
        },
        same_lane_report={
            "status": "same_lane_static_ready_prior_natural_rejected_keep_607",
            "summary": {"prior_natural_reject_count": 2},
        },
        value_model={
            "status": "lorehold_value_model_ready_607_remains_protected",
            "summary": {"quantity_total": 100},
        },
        source_paths={
            "pressure_report": Path("/tmp/pressure.json"),
            "same_lane_report": Path("/tmp/same_lane.json"),
            "value_model": Path("/tmp/value.json"),
        },
    )


def test_external_material_keeps_607_without_gate_ready_package():
    payload = build_payload()

    assert payload["status"] == "external_material_evidence_found_but_no_gate_ready_keep_607"
    assert payload["summary"]["promotion_allowed"] is False
    assert payload["summary"]["natural_battle_allowed_now"] is False
    assert payload["decision"]["keep_607_as_protected_baseline"] is True


def test_classifies_local_variant_missing_and_rule_known_material():
    payload = build_payload()
    rows = {row["card_name"]: row for row in payload["candidate_classifications"]}

    assert rows["Storm-Kiln Artist"]["classification"] == "local_lorehold_variant_candidate_not_in_607"
    assert rows["Storm-Kiln Artist"]["lorehold_variant_deck_ids"] == [608]
    assert rows["Haze of Rage"]["classification"] == "external_missing_from_local_deck_pool"
    assert rows["Karmic Guide"]["classification"] == "rule_known_external_not_in_lorehold_candidate_pool"
    assert rows["Karmic Guide"]["actionability"] == "archetype_fork_only_requires_full_shell_contract"


def test_combo_package_is_research_only_when_one_half_is_missing():
    payload = build_payload()
    packages = {row["package_key"]: row for row in payload["package_assessments"]}
    storm_haze = packages["storm_kiln_artist_haze_of_rage_combo"]

    assert storm_haze["status"] == "research_only_mixed_local_and_missing_material"
    assert storm_haze["gate_ready"] is False
    assert storm_haze["natural_battle_allowed_now"] is False


def test_archetype_forks_are_not_one_for_one_cut_routes():
    payload = build_payload()
    packages = {row["package_key"]: row for row in payload["package_assessments"]}

    assert packages["white_reanimator_lorehold_shell"]["status"] == "archetype_fork_only_requires_full_shell_contract"
    assert packages["voltron_or_token_closure_shell"]["gate_ready"] is False


def test_markdown_surfaces_external_and_local_decision_sections():
    markdown = scout.render_markdown(build_payload())

    assert "Lorehold External Material Evidence Scout" in markdown
    assert "External Source Lanes" in markdown
    assert "Candidate Classification" in markdown
    assert "Package Assessments" in markdown
    assert "Storm-Kiln Artist" in markdown
