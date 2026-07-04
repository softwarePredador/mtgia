import json
import sqlite3
from pathlib import Path

import lorehold_staple_policy_synthesis as synth


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
            review_status TEXT
        );
        CREATE TABLE lorehold_variant_deck_cards (
            deck_hash TEXT,
            card_name TEXT,
            normalized_name TEXT
        );
        """
    )
    deck_rows = [
        (607, "Lorehold, the Historian", 1, "engine", "[]", 1, 5, "Legendary Creature", "", None),
        (607, "Sol Ring", 1, "ramp", "[]", 0, 1, "Artifact", "{T}: Add {C}{C}.", None),
        (607, "Arcane Signet", 1, "ramp", "[]", 0, 2, "Artifact", "Tap: Add any color.", None),
        (607, "Swords to Plowshares", 1, "removal", "[]", 0, 1, "Instant", "Exile target creature.", None),
        (607, "Sensei's Divining Top", 1, "draw", "[]", 0, 1, "Artifact", "Look at top cards.", None),
        (607, "Library of Leng", 1, "engine", "[]", 0, 1, "Artifact", "Discard to top.", None),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
    staples = [
        ("Sol Ring", "ramp", "", 1, ""),
        ("Arcane Signet", "ramp", "", 3, ""),
        ("Swords to Plowshares", "removal", "W", 11, "W"),
        ("Mana Vault", "ramp", "", 144, ""),
        ("The One Ring", "draw", "", 180, ""),
        ("Chrome Mox", "ramp", "", 142, ""),
        ("Thought Vessel", "ramp", "", 21, ""),
        ("Evolving Wilds", "combo", "", 16, ""),
        ("Counterspell", "blue", "U", 17, "U"),
    ]
    for name, archetype, color_identity, rank, colors in staples:
        conn.execute(
            "INSERT INTO format_staples VALUES (?, 'commander', ?, '', ?, ?, NULL, 0)",
            (name, archetype, color_identity, rank),
        )
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, ?, ?, ?, NULL)",
            (
                synth.normalize_name(name),
                name,
                "{1}" if "Mox" in name or name == "Mana Vault" else "",
                "Land" if name == "Evolving Wilds" else "Artifact",
                "Search your library for a basic land." if name == "Evolving Wilds" else "Add mana. Draw cards.",
                0 if name == "Evolving Wilds" else 2,
                json.dumps([colors] if colors else []),
            ),
        )
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal', NULL)", (name,))
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified')",
            (name, synth.normalize_name(name)),
        )
    conn.execute(
        "INSERT INTO lorehold_variant_deck_cards VALUES ('v615', 'Mana Vault', ?)",
        (synth.normalize_name("Mana Vault"),),
    )
    return conn


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def write_reports(tmp_path: Path) -> dict[str, Path]:
    mana = write_json(
        tmp_path / "mana.json",
        {
            "status": "mana_foundation_pass_with_watch_items",
            "summary": {"blocker_count": 0, "watch_item_count": 3},
        },
    )
    gap = write_json(
        tmp_path / "gap.json",
        {"summary": {"rows_considered": 5, "not_in_current_lorehold_package_defs": 4}},
    )
    profile = write_json(
        tmp_path / "profile.json",
        {
            "summary": {"preflight_ready_pair_count": 0},
            "top_pair_evaluations": [
                {
                    "candidate": "Chrome Mox",
                    "cut": "Bender's Waterskin",
                    "status": "blocked",
                    "score": 96,
                    "blockers": ["candidate_policy_blocked_no_premium_mox"],
                },
                {
                    "candidate": "Thought Vessel",
                    "cut": "Bender's Waterskin",
                    "status": "blocked",
                    "score": 80,
                    "blockers": ["candidate_role_mismatch:ramp"],
                },
            ],
        },
    )
    vault = write_json(
        tmp_path / "vault.json",
        {
            "summary": {
                "promotion_allowed": False,
                "latest_gate_delta_pp": -66.67,
            }
        },
    )
    payoff = write_json(
        tmp_path / "payoff.json",
        {
            "candidate_cards": [
                {
                    "card_name": "The One Ring",
                    "decision": "blocked_existing_package_rejected",
                    "decision_reasons": ["one_ring_prior_package_lost"],
                }
            ]
        },
    )
    empty = write_json(tmp_path / "empty.json", {})
    summary = tmp_path / "summary.md"
    summary.write_text("Decision: no_new_card_promoted\n", encoding="utf-8")
    return {
        "mana": mana,
        "gap": gap,
        "profile": profile,
        "vault": vault,
        "payoff": payoff,
        "empty": empty,
        "summary": summary,
    }


def build_payload(tmp_path: Path) -> dict:
    reports = write_reports(tmp_path)
    with make_conn() as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            mana_foundation_report_path=reports["mana"],
            staple_gap_report_path=reports["gap"],
            staple_summary_report_path=reports["summary"],
            profiled_cut_report_path=reports["profile"],
            mana_vault_report_path=reports["vault"],
            selection_report_path=reports["empty"],
            interaction_report_path=reports["empty"],
            payoff_report_path=reports["payoff"],
            rank_limit=750,
            candidate_limit=20,
        )


def test_staple_policy_keeps_607_when_staples_lack_cut_proof(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["status"] == "staple_policy_no_direct_auto_include_current_607"
    assert payload["decision"]["keep_607_staple_policy"] is True
    assert payload["summary"]["current_structural_foundation_count"] == 3
    assert payload["summary"]["current_contextual_staple_count"] == 2
    assert payload["summary"]["mana_foundation_status"] == "mana_foundation_pass_with_watch_items"


def test_candidate_staples_are_split_by_policy_and_evidence(tmp_path):
    payload = build_payload(tmp_path)
    candidates = {row["card_name"]: row for row in payload["candidate_staple_backlog"]}

    assert "Counterspell" not in candidates
    assert candidates["Mana Vault"]["decision"] == "blocked_prior_gate_rejected"
    assert candidates["The One Ring"]["lane"] == "card_draw_selection"
    assert candidates["The One Ring"]["decision"] == "blocked_existing_package_rejected"
    assert candidates["Chrome Mox"]["decision"] == "policy_blocked_no_premium_mox"
    assert candidates["Evolving Wilds"]["decision"] == "generic_land_staple_requires_mana_base_cut"
    assert candidates["Thought Vessel"]["decision"] == "candidate_requires_same_lane_cut_and_gate"


def test_markdown_surfaces_backlog_lanes_and_sources(tmp_path):
    payload = build_payload(tmp_path)
    markdown = synth.render_markdown(payload)

    assert "keep_607_staple_policy: `true`" in markdown
    assert "Candidate Staple Backlog" in markdown
    assert "EDHREC Lorehold cEDH average deck" in markdown
