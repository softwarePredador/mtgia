import json
import sqlite3
from pathlib import Path

import lorehold_mana_sequence_policy_synthesis as synth


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
        CREATE TABLE card_legalities (
            card_name TEXT,
            format TEXT,
            status TEXT,
            scryfall_id TEXT
        );
        CREATE TABLE format_staples (
            card_name TEXT,
            format TEXT,
            archetype TEXT,
            category TEXT,
            color_identity TEXT,
            edhrec_rank INTEGER,
            scryfall_id TEXT,
            is_banned INTEGER
        );
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT
        );
        """
    )
    deck_rows = [
        (607, "Lorehold, the Historian", 1, "engine", "[]", 1, 5, "Legendary Creature", "", None),
        (607, "Command Tower", 1, "land", "[]", 0, 0, "Land", "{T}: Add one mana of any color in your commander's color identity.", None),
        (607, "Ancient Tomb", 1, "land", "[]", 0, 0, "Land", "{T}: Add {C}{C}. This land deals 2 damage to you.", None),
        (607, "Elegant Parlor", 1, "land", "[]", 0, 0, "Land - Mountain Plains", "This land enters tapped. {T}: Add {R} or {W}.", None),
        (607, "Arcane Signet", 1, "ramp", "[]", 0, 2, "Artifact", "{T}: Add one mana of any color in your commander's color identity.", None),
        (607, "Bender's Waterskin", 1, "ramp", "[]", 0, 3, "Artifact", "Untap this artifact during each other player's untap step. {T}: Add one mana of any color.", None),
        (607, "Victory Chimes", 1, "ramp", "[]", 0, 3, "Artifact", "Untap this artifact during each other player's untap step. {T}: A player of your choice adds {C}.", None),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
    oracle_rows = [
        ("Mana Vault", "{1}", "Artifact", "This artifact doesn't untap during your untap step. {T}: Add {C}{C}{C}.", 1, "[]"),
        ("Chrome Mox", "{0}", "Artifact", "Imprint. {T}: Add one mana of any of the exiled card's colors.", 0, "[]"),
        ("City of Traitors", "", "Land", "{T}: Add {C}{C}. When you play another land, sacrifice City of Traitors.", 0, "[]"),
        ("Mana Crypt", "{0}", "Artifact", "{T}: Add {C}{C}.", 0, "[]"),
        ("Talisman of Conviction", "{2}", "Artifact", "{T}: Add {C}. {T}: Add {R} or {W}.", 2, "[]"),
    ]
    for name, mana_cost, type_line, oracle, cmc, colors in oracle_rows:
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, NULL)",
            (synth.normalize_name(name), name, mana_cost, type_line, oracle, cmc, colors),
        )
    for name, status in [
        ("Mana Vault", "legal"),
        ("Chrome Mox", "legal"),
        ("City of Traitors", "legal"),
        ("Mana Crypt", "banned"),
        ("Talisman of Conviction", "legal"),
    ]:
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', ?, NULL)", (name, status))
    for name, rank in [
        ("Mana Vault", 144),
        ("Chrome Mox", 142),
        ("City of Traitors", 420),
        ("Talisman of Conviction", 95),
    ]:
        conn.execute(
            "INSERT INTO format_staples VALUES (?, 'commander', 'ramp', '', '', ?, NULL, 0)",
            (name, rank),
        )
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', ?)",
            (name, synth.normalize_name(name), json.dumps({"battle_model_scope": "test_scope"})),
        )
    return conn


def write_report(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def build_payload(tmp_path: Path) -> dict:
    mana = write_report(
        tmp_path / "mana.json",
        {"status": "mana_foundation_pass_with_watch_items", "summary": {"blocker_count": 0, "watch_item_count": 2}},
    )
    staple = write_report(
        tmp_path / "staple.json",
        {
            "candidate_staple_backlog": [
                {"card_name": "Chrome Mox", "lane": "ramp", "decision": "policy_blocked_no_premium_mox", "decision_reasons": ["premium_mox_policy_blocker"]},
            ]
        },
    )
    ramp = write_report(tmp_path / "ramp.json", {"packages": []})
    vault = write_report(
        tmp_path / "vault.json",
        {"summary": {"promotion_allowed": False, "latest_gate_delta_pp": -66.67}},
    )
    with make_conn() as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            mana_foundation_report_path=mana,
            staple_policy_report_path=staple,
            ramp_package_report_path=ramp,
            mana_vault_report_path=vault,
            candidate_names=[
                "Ancient Tomb",
                "Bender's Waterskin",
                "Mana Vault",
                "Chrome Mox",
                "City of Traitors",
                "Mana Crypt",
                "Talisman of Conviction",
            ],
        )


def test_mana_sequence_keeps_607_when_candidates_lack_gate(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["status"] == "mana_sequence_no_direct_auto_upgrade_current_607"
    assert payload["decision"]["keep_607_mana_sequence_policy"] is True
    assert payload["summary"]["land_count"] == 3
    assert payload["summary"]["ramp_count"] == 3
    assert payload["summary"]["candidate_decision_counts"]["blocked_prior_gate_rejected"] == 1


def test_candidate_decisions_preserve_legality_policy_and_same_lane_gates(tmp_path):
    payload = build_payload(tmp_path)
    rows = {row["card_name"]: row for row in payload["candidate_mana_backlog"]}

    assert rows["Ancient Tomb"]["decision"] == "already_in_607_protected_mana_foundation"
    assert rows["Bender's Waterskin"]["decision"] == "already_in_607_protected_turn_cycle_miracle_mana"
    assert rows["Mana Vault"]["decision"] == "blocked_prior_gate_rejected"
    assert rows["Chrome Mox"]["decision"] == "policy_blocked_no_premium_mox"
    assert rows["City of Traitors"]["decision"] == "candidate_land_requires_named_land_cut_and_equal_gate"
    assert rows["Mana Crypt"]["decision"] == "blocked_commander_banned_or_not_accessible"
    assert rows["Talisman of Conviction"]["decision"] == "candidate_requires_same_lane_cut_and_sequence_gate"


def test_markdown_surfaces_turn_cycle_policy_and_sources(tmp_path):
    payload = build_payload(tmp_path)
    markdown = synth.render_markdown(payload)

    assert "keep_607_mana_sequence_policy: `true`" in markdown
    assert "opponents' turns" in markdown
    assert "Card Kingdom Lorehold synergy article" in markdown
