import json
import sqlite3
from pathlib import Path

import lorehold_payoff_finisher_recursion_synthesis as synth


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
            card_id TEXT,
            color_identity_json TEXT
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
            confidence REAL,
            deck_role_json TEXT,
            effect_json TEXT
        );
        CREATE TABLE lorehold_variant_deck_cards (
            deck_hash TEXT,
            card_name TEXT,
            normalized_name TEXT
        );
        """
    )
    deck_rows = [
        (607, "Lorehold, the Historian", 1, "engine", '["engine"]', 1, 5, "Legendary Creature", "", None),
        (607, "Approach of the Second Sun", 1, "wincon", '["wincon"]', 0, 7, "Sorcery", "", None),
        (607, "Mizzix's Mastery", 1, "wincon", '["wincon","overload_recursion"]', 0, 4, "Sorcery", "", None),
        (607, "Surge to Victory", 1, "wincon", '["wincon"]', 0, 6, "Sorcery", "", None),
        (607, "Insurrection", 1, "wincon", '["wincon"]', 0, 8, "Sorcery", "", None),
        (607, "Storm Herd", 1, "wincon", '["wincon"]', 0, 10, "Sorcery", "", None),
        (607, "Rise of the Eldrazi", 1, "wincon", '["wincon","removal"]', 0, 12, "Sorcery", "", None),
        (607, "Creative Technique", 1, "draw", '["draw"]', 0, 5, "Sorcery", "", None),
        (607, "Hit the Mother Lode", 1, "draw", '["draw","ramp"]', 0, 7, "Sorcery", "", None),
        (607, "Call Forth the Tempest", 1, "board_wipe", '["board_wipe"]', 0, 8, "Sorcery", "", None),
        (607, "Molecule Man", 1, "draw", '["draw"]', 0, 6, "Creature", "", None),
        (607, "Furygale Flocking", 1, "wincon", '["wincon"]', 0, 10, "Sorcery", "", None),
        (607, "Prismari Pianist", 1, "wincon", '["wincon"]', 0, 3, "Creature", "", None),
        (607, "Reforge the Soul", 1, "draw", '["draw"]', 0, 5, "Sorcery", "", None),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", deck_rows)
    oracle_rows = {
        "Soulfire Eruption": ("{6}{R}{R}{R}", "Sorcery", 9, "R"),
        "Twinflame Tyrant": ("{3}{R}{R}", "Creature - Dragon", 5, "R"),
        "Possibility Storm": ("{3}{R}{R}", "Enchantment", 5, "R"),
        "Restoration Seminar": ("{5}{W}{W}", "Sorcery - Lesson", 0, "W"),
        "Volcanic Vision": ("{5}{R}{R}", "Sorcery", 7, "R"),
        "Underworld Breach": ("{1}{R}", "Enchantment", 2, "R"),
        "Past in Flames": ("{3}{R}", "Sorcery", 4, "R"),
        "Wheel of Fortune": ("{2}{R}", "Sorcery", 3, "R"),
        "Apex of Power": ("{7}{R}{R}{R}", "Sorcery", 10, "R"),
        "Dance with Calamity": ("{7}{R}", "Sorcery", 8, "R"),
        "Storm-Kiln Artist": ("{3}{R}", "Creature", 4, "R"),
        "Brass's Bounty": ("{6}{R}", "Sorcery", 7, "R"),
        "Mana Vault": ("{1}", "Artifact", 1, ""),
        "The One Ring": ("{4}", "Legendary Artifact", 4, ""),
    }
    for name, (mana_cost, type_line, cmc, colors) in oracle_rows.items():
        conn.execute(
            "INSERT INTO card_oracle_cache VALUES (?, ?, ?, ?, '', ?, NULL, ?)",
            (synth.normalize_name(name), name, mana_cost, type_line, cmc, json.dumps([colors] if colors else [])),
        )
    for name in [*oracle_rows, "Approach of the Second Sun", "Mizzix's Mastery"]:
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal', NULL)", (name,))
        conn.execute(
            "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', 0.95, ?, '{}')",
            (
                name,
                synth.normalize_name(name),
                json.dumps({"category": "wincon" if name in {"Approach of the Second Sun", "Mizzix's Mastery"} else "candidate"}),
            ),
        )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Mana Vault', 'commander', 'ramp', '', '', 144, NULL, 0)"
    )
    conn.execute(
        "INSERT INTO format_staples VALUES ('Underworld Breach', 'commander', 'red', '', 'R', 400, NULL, 0)"
    )
    for name in ["Soulfire Eruption", "Restoration Seminar", "Possibility Storm", "Twinflame Tyrant"]:
        conn.execute(
            "INSERT INTO lorehold_variant_deck_cards VALUES ('variant-a', ?, ?)",
            (name, synth.normalize_name(name)),
        )
    return conn


def write_json(path: Path, payload: dict) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def write_reports(tmp_path: Path) -> dict[str, Path]:
    soulfire = write_json(
        tmp_path / "soulfire.json",
        {
            "status": "blocked_existing_soulfire_shell_underperformed",
            "summary": {
                "existing_soulfire_negative_vs_607_count": 7,
                "trace_use_event_count": 116,
            },
        },
    )
    recursion = write_json(
        tmp_path / "recursion.json",
        {
            "summary": {
                "preflight_benchmark_ready_count": 0,
                "recommended_next_action": "do_not_gate_recursion_without_non_squee_cut_or_multi_card_package",
            },
            "guardrails": [
                {
                    "guardrail_key": "exclude_nonbaseline_squee_cut_options",
                    "reason": "Squee is not present in the loaded baseline deck.",
                }
            ],
        },
    )
    restoration = write_json(
        tmp_path / "restoration.json",
        {
            "status": "blocked_no_current_target_graveyard_trace",
            "summary": {
                "target_graveyard_event_count": 0,
                "preflight_ready_count_from_recursion_model": 0,
            },
        },
    )
    profiled_cut = write_json(
        tmp_path / "profiled.json",
        {
            "summary": {
                "preflight_ready_pair_count": 1,
                "recommended_next_action": "run_profiled_cut_benchmark_preflight",
                "selected_packages": [
                    {
                        "card_added": "Possibility Storm",
                        "card_removed": "Creative Technique",
                    }
                ],
            }
        },
    )
    mana_vault = write_json(
        tmp_path / "mana_vault.json",
        {
            "summary": {
                "decision": "reject_current_pair",
                "latest_gate_delta_pp": -66.67,
                "promotion_allowed": False,
            }
        },
    )
    twinflame = write_json(
        tmp_path / "twinflame.json",
        {
            "packages": [
                {
                    "adds": ["Twinflame Tyrant"],
                    "cuts": ["Thor, God of Thunder"],
                    "cut_safety": {"status": "override_locked_cut_safety"},
                    "gate_summary": {
                        "baseline": {"win_rate": 77.78},
                        "candidate": {"win_rate": 44.44},
                    },
                }
            ]
        },
    )
    notes = tmp_path / "notes.md"
    notes.write_text(
        "\n".join(
            [
                "Mana Vault is accessible and powerful, but not currently better than the protected slot.",
                "The One Ring is accessible, but not a generic auto-include for protected 607.",
                "Restoration Seminar is not gate-ready.",
                "Soulfire Eruption evidence is negative for broad inclusion.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    return {
        "soulfire": soulfire,
        "recursion": recursion,
        "restoration": restoration,
        "profiled_cut": profiled_cut,
        "mana_vault": mana_vault,
        "twinflame": twinflame,
        "notes": notes,
    }


def build_payload(tmp_path: Path) -> dict:
    reports = write_reports(tmp_path)
    with make_conn() as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            soulfire_report_path=reports["soulfire"],
            recursion_report_path=reports["recursion"],
            restoration_report_path=reports["restoration"],
            profiled_cut_report_path=reports["profiled_cut"],
            mana_vault_report_path=reports["mana_vault"],
            twinflame_report_path=reports["twinflame"],
            candidate_notes_path=reports["notes"],
        )


def test_synthesis_keeps_607_when_no_candidate_has_equal_gate(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["status"] == "payoff_finisher_recursion_no_direct_swap_ready_current_607"
    assert payload["decision"]["keep_607_payoff_finisher_recursion_package"] is True
    assert payload["summary"]["current_payoff_anchor_count"] == len(synth.CURRENT_PAYOFF_ANCHORS)
    assert payload["summary"]["current_squee_in_607"] is False
    assert payload["summary"]["soulfire_negative_vs_607_count"] == 7
    assert payload["summary"]["recursion_preflight_ready_count"] == 0


def test_nonbaseline_squee_assumption_is_flagged(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["divergences"][0]["key"] == "nonbaseline_squee_recursion_assumption"
    assert payload["divergences"][0]["cards"] == ["Squee, Goblin Nabob"]


def test_candidates_are_classified_by_evidence_not_popularity(tmp_path):
    payload = build_payload(tmp_path)
    candidates = {row["card_name"]: row for row in payload["candidate_cards"]}

    assert candidates["Soulfire Eruption"]["decision"] == "blocked_existing_soulfire_shell_underperformed"
    assert candidates["Restoration Seminar"]["decision"] == "blocked_no_current_target_graveyard_trace"
    assert candidates["Possibility Storm"]["decision"] == "preflight_hypothesis_not_promotion"
    assert candidates["Twinflame Tyrant"]["decision"] == "blocked_prior_twinflame_gate_lost_locked_cut"
    assert candidates["Mana Vault"]["decision"] == "blocked_prior_mana_vault_pair_rejected"
    assert candidates["The One Ring"]["decision"] == "blocked_existing_package_rejected"
    assert candidates["Underworld Breach"]["decision"] == "candidate_hypothesis_requires_named_cut_and_equal_gate"


def test_render_markdown_includes_decision_and_sources(tmp_path):
    payload = build_payload(tmp_path)
    markdown = synth.render_markdown(payload)

    assert "keep_607_payoff_finisher_recursion_package: `true`" in markdown
    assert "EDHREC Lorehold cEDH average deck" in markdown
    assert "Commander Spellbook Underworld Breach search" in markdown
