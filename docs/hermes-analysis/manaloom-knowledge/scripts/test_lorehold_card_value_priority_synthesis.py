import json
import sqlite3
from pathlib import Path

import lorehold_card_value_priority_synthesis as synth


def make_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.executescript(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            functional_tags_json TEXT,
            is_commander INTEGER,
            cmc REAL,
            type_line TEXT,
            oracle_text TEXT,
            card_id TEXT
        );
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT,
            mana_cost TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            color_identity_json TEXT,
            card_id TEXT
        );
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT,
            deck_role_json TEXT
        );
        """
    )
    rows = [
        (607, "Lorehold, the Historian", 1, "engine", "[]", 1, 5, "Legendary Creature", "Each instant and sorcery card in your hand has miracle {2}.", None),
        (607, "Library of Leng", 1, "engine", "[]", 0, 1, "Artifact", "If an effect causes you to discard a card, you may put it on top of your library.", None),
        (607, "Bender's Waterskin", 1, "ramp", "[]", 0, 3, "Artifact", "Untap this artifact during each other player's untap step. {T}: Add one mana of any color.", None),
        (607, "Sol Ring", 1, "ramp", "[]", 0, 1, "Artifact", "{T}: Add {C}{C}.", None),
        (607, "Redirect Lightning", 1, "draw", "[]", 0, 1, "Instant", "Change the target of target spell or ability.", None),
        (607, "Storm Herd", 1, "wincon", "[]", 0, 10, "Sorcery", "Create X 1/1 white Pegasus creature tokens with flying, where X is your life total.", None),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", rows)
    for name in [row[1] for row in rows]:
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', ?, ?)",
            (
                name,
                synth.normalize_name(name),
                json.dumps({"battle_model_scope": "test_scope"}),
                json.dumps({"category": "test"}),
            ),
        )
    return conn


def write(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def reports(tmp_path: Path, *, ready_candidate: bool = False) -> dict[str, Path]:
    mana = write(
        tmp_path / "mana.json",
        {
            "status": "mana_sequence_no_direct_auto_upgrade_current_607",
            "current_mana_package": [
                {"card_name": "Bender's Waterskin", "lane": "turn_cycle_miracle_mana", "policy_class": "protected_turn_cycle_miracle_mana"},
                {"card_name": "Sol Ring", "lane": "early_colorless_burst", "policy_class": "protected_current_mana_foundation"},
            ],
            "candidate_mana_backlog": [],
        },
    )
    staple = write(
        tmp_path / "staple.json",
        {
            "status": "staple_policy_no_direct_auto_include_current_607",
            "current_staple_floor": [
                {"card_name": "Sol Ring", "policy_class": "structural_foundation"},
            ],
            "candidate_staple_backlog": [],
        },
    )
    selection = write(
        tmp_path / "selection.json",
        {
            "status": "selection_access_no_swap_ready_current_607",
            "current_access_anchors": [
                {"card_name": "Library of Leng", "edhrec_lorehold": {"pct": 77.7}},
            ],
            "candidate_access_cards": [
                {"card_name": "Brainstone", "decision": "runtime_ready_but_no_seed_safe_cut"},
            ],
        },
    )
    interaction = write(
        tmp_path / "interaction.json",
        {
            "status": "interaction_resilience_no_direct_swap_ready_current_607",
            "current_floor_profiles": [
                {"card_name": "Redirect Lightning", "lane": "stack_or_spell_protection"},
            ],
            "candidate_profiles": [
                {"card_name": "Boros Charm", "decision": "prior_tibalt_replacement_rejected"},
            ],
        },
    )
    payoff = write(
        tmp_path / "payoff.json",
        {
            "status": "payoff_finisher_recursion_no_direct_swap_ready_current_607",
            "current_payoff_anchors": [
                {"card_name": "Storm Herd"},
            ],
            "candidate_cards": [
                {
                    "card_name": "Replacement",
                    "decision": "direct_swap_ready" if ready_candidate else "candidate_hypothesis_requires_named_cut_and_equal_gate",
                }
            ],
        },
    )
    return {"mana": mana, "staple": staple, "selection": selection, "interaction": interaction, "payoff": payoff}


def build_payload(tmp_path: Path, *, ready_candidate: bool = False) -> dict:
    paths = reports(tmp_path, ready_candidate=ready_candidate)
    with make_conn() as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            mana_report_path=paths["mana"],
            staple_report_path=paths["staple"],
            selection_report_path=paths["selection"],
            interaction_report_path=paths["interaction"],
            payoff_report_path=paths["payoff"],
        )


def test_card_value_priority_protects_current_anchors_and_structural_floor(tmp_path):
    payload = build_payload(tmp_path)
    rows = {row["card_name"]: row for row in payload["current_card_priorities"]}

    assert payload["decision"]["keep_607_card_value_policy"] is True
    assert rows["Library of Leng"]["priority_class"] == "protected_topdeck_access_anchor"
    assert rows["Bender's Waterskin"]["priority_class"] == "protected_turn_cycle_miracle_mana"
    assert rows["Sol Ring"]["priority_class"] == "structural_foundation"
    assert rows["Storm Herd"]["priority_class"] == "protected_payoff_finisher_anchor"


def test_role_mapping_watch_flags_interaction_hidden_under_draw_tag(tmp_path):
    payload = build_payload(tmp_path)
    rows = {row["card_name"]: row for row in payload["current_card_priorities"]}

    assert "draw_tag_masks_interaction_or_protection_function" in rows["Redirect Lightning"]["role_mapping_watch"]
    assert rows["Redirect Lightning"]["cut_policy"] == "same_lane_only_with_card_use_and_equal_gate"
    assert payload["status"] == "card_value_priority_keep_607_with_role_watch_items"


def test_ready_candidate_changes_status_without_cutting_current_card(tmp_path):
    payload = build_payload(tmp_path, ready_candidate=True)

    assert payload["status"] == "card_value_priority_candidate_requires_gate_review"
    assert payload["summary"]["ready_replacement_candidate_count"] == 1


def test_markdown_surfaces_policy_and_external_sources(tmp_path):
    payload = build_payload(tmp_path)
    markdown = synth.render_markdown(payload)

    assert "keep_607_card_value_policy: `true`" in markdown
    assert "Role Mapping Watch" in markdown
    assert "Card Kingdom staples article" in markdown
