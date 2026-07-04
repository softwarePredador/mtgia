import json
import sqlite3
from pathlib import Path

import lorehold_interaction_resilience_synthesis as synth


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
            oracle_text TEXT
        );
        CREATE TABLE battle_card_rules (
            card_name TEXT,
            normalized_name TEXT,
            execution_status TEXT,
            review_status TEXT,
            effect_json TEXT
        );
        CREATE TABLE card_legalities (
            card_name TEXT,
            format TEXT,
            status TEXT
        );
        """
    )
    current_rows = [
        (607, "Lorehold, the Historian", 1, "engine", '["engine"]', 1, 4, "Legendary Creature", ""),
        (607, "Swords to Plowshares", 1, "removal", '["removal"]', 0, 1, "Instant", ""),
        (607, "Path to Exile", 1, "removal", '["removal"]', 0, 1, "Instant", ""),
        (607, "Generous Gift", 1, "removal", '["removal"]', 0, 3, "Instant", ""),
        (607, "Stroke of Midnight", 1, "removal", '["removal"]', 0, 3, "Instant", ""),
        (607, "Winds of Abandon", 1, "removal", '["removal"]', 0, 2, "Sorcery", ""),
        (607, "Deflecting Swat", 1, "draw", '["draw","protection","redirect_removal"]', 0, 3, "Instant", ""),
        (607, "Tibalt's Trickery", 1, "protection", '["protection"]', 0, 2, "Instant", ""),
        (607, "Teferi's Protection", 1, "protection", '["protection"]', 0, 3, "Instant", ""),
        (607, "Flawless Maneuver", 1, "protection", '["protection"]', 0, 3, "Instant", ""),
        (607, "Dawn's Truce", 1, "protection", '["protection"]', 0, 2, "Instant", ""),
        (607, "Mother of Runes", 1, "protection", '["protection","creature"]', 0, 1, "Creature", ""),
        (607, "Farewell", 1, "board_wipe", '["board_wipe","wipe"]', 0, 6, "Sorcery", ""),
        (612, "Silence", 1, "protection", '["protection"]', 0, 1, "Instant", ""),
        (613, "Silence", 1, "protection", '["protection"]', 0, 1, "Instant", ""),
        (615, "Silence", 1, "protection", '["protection"]', 0, 1, "Instant", ""),
        (615, "Boros Charm", 1, "protection", '["protection"]', 0, 2, "Instant", ""),
        (615, "Grand Abolisher", 1, "protection", '["protection"]', 0, 2, "Creature", ""),
        (613, "Red Elemental Blast", 1, "protection", '["protection"]', 0, 1, "Instant", ""),
        (615, "Reprieve", 1, "protection", '["protection"]', 0, 2, "Instant", ""),
        (614, "Perch Protection", 1, "wincon", '["wincon","protection"]', 0, 6, "Instant", ""),
        (616, "Chaos Warp", 1, "draw", '["draw"]', 0, 3, "Instant", ""),
        (616, "Wear // Tear", 1, "removal", '["removal"]', 0, 2, "Instant", ""),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", current_rows)
    rule_rows = [
        ("Swords to Plowshares", "remove_creature", "swords_to_plowshares_creature_exile_life_equal_power_v1"),
        ("Path to Exile", "remove_creature", "path_to_exile_creature_exile_basic_land_compensation_runtime_v1"),
        ("Generous Gift", "remove_permanent", "destroy_target_permanent_create_3_3_green_elephant_for_controller_v1"),
        ("Stroke of Midnight", "remove_permanent", "destroy_target_nonland_permanent_create_1_1_white_human_for_controller_v1"),
        ("Winds of Abandon", "remove_creature", "winds_of_abandon_opponent_creature_exile_basic_land_compensation_overload_runtime_v1"),
        ("Deflecting Swat", "redirect_removal", "deflecting_swat_control_commander_free_redirect_target_spell_or_ability_runtime_v1"),
        ("Tibalt's Trickery", "counter", "red_counter_random_mill_cast_annotation_v1"),
        ("Teferi's Protection", "phase_out", "teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1"),
        ("Flawless Maneuver", "indestructible", "flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1"),
        ("Dawn's Truce", "gift_hexproof_indestructible", "gift_card_you_and_permanents_hexproof_gifted_indestructible_v1"),
        ("Mother of Runes", "creature", "creature_body_target_creature_protection_from_chosen_color_activation_runtime_v1"),
        ("Farewell", "board_wipe", "modal_exile_wipe_creature_runtime_baseline_v1"),
        ("Silence", "silence_spell", "silence_until_eot_v1"),
        ("Boros Charm", "modal_boros_charm", "boros_charm_choose_one_damage_indestructible_double_strike_v1"),
        ("Grand Abolisher", "silence_opponents", "static_opponent_spell_lock_activated_ability_lock_annotation_v1"),
        ("Red Elemental Blast", "modal_spell", "counter_target_blue_spell_or_destroy_target_blue_permanent_v1"),
        ("Pyroblast", "counter", "blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1"),
        ("Reprieve", "return_target_spell_to_hand", "return_target_spell_to_owners_hand_draw_one_not_counter_v1"),
        ("Perch Protection", "composite_resolution", "create_four_birds_gift_phase_all_life_lock_protection_exile_self_v1"),
        ("Chaos Warp", "remove_permanent", "target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1"),
        ("Wear // Tear", "remove_permanent", "split_artifact_or_enchantment_removal_v1"),
        ("Abrade", "remove_artifact_or_3dmg", "artifact_or_creature_damage_mode_v1"),
    ]
    conn.executemany(
        "INSERT INTO battle_card_rules VALUES (?, ?, 'auto', 'verified', ?)",
        [
            (
                name,
                synth.normalize_name(name),
                json.dumps({"effect": effect, "battle_model_scope": scope}),
            )
            for name, effect, scope in rule_rows
        ],
    )
    for name in set(row[1] for row in current_rows) | {row[0] for row in rule_rows}:
        conn.execute("INSERT INTO card_legalities VALUES (?, 'commander', 'legal')", (name,))
    return conn


def write_json(path: Path, payload) -> Path:
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def write_edhrec(tmp_path: Path) -> Path:
    rows = [
        {"name": "Swords to Plowshares", "inclusion": 5273, "potential_decks": 7651, "pct": 68.9, "synergy": 0.03},
        {"name": "Path to Exile", "inclusion": 4377, "potential_decks": 7651, "pct": 57.2, "synergy": 0},
        {"name": "Deflecting Swat", "inclusion": 2820, "potential_decks": 7651, "pct": 36.9, "synergy": 0.21},
        {"name": "Silence", "inclusion": 501, "potential_decks": 7651, "pct": 6.5, "synergy": 0.01},
        {"name": "Red Elemental Blast", "inclusion": 443, "potential_decks": 7651, "pct": 5.8, "synergy": 0.01},
        {"name": "Perch Protection", "inclusion": 2653, "potential_decks": 7651, "pct": 34.7, "synergy": 0.33},
        {"name": "Chaos Warp", "inclusion": 2973, "potential_decks": 7651, "pct": 38.9, "synergy": 0.09},
    ]
    return write_json(tmp_path / "edhrec.json", rows)


def write_tibalt_decision(tmp_path: Path) -> Path:
    path = tmp_path / "tibalt.md"
    path.write_text(
        "# Lorehold Tibalt Replacement Decision\n\n"
        "- decision: `reject_tested_replacements_keep_deck_607`\n\n"
        "## Confirmed Gates\n\n"
        "`Boros Charm` lost, `Silence` lost, and `Grand Abolisher` was rejected.\n",
        encoding="utf-8",
    )
    return path


def build_payload(tmp_path: Path):
    with make_conn() as conn:
        return synth.build_synthesis(
            conn=conn,
            db_path=Path("memory.db"),
            deck_id=607,
            edhrec_card_data=write_edhrec(tmp_path),
            tibalt_decision_path=write_tibalt_decision(tmp_path),
            variant_deck_ids=range(608, 617),
        )


def test_synthesis_keeps_607_when_tibalt_replacements_were_rejected(tmp_path):
    payload = build_payload(tmp_path)

    assert payload["status"] == "interaction_resilience_no_direct_swap_ready_current_607"
    assert payload["decision"]["keep_607_interaction_resilience_package"] is True
    assert payload["summary"]["direct_swap_ready_count"] == 0
    assert payload["summary"]["prior_tibalt_rejected_count"] == 3
    assert payload["summary"]["current_lane_counts"]["spot_removal"] >= 5

    candidates = {row["card_name"]: row for row in payload["candidate_profiles"]}
    assert candidates["Silence"]["decision"] == "prior_tibalt_replacement_rejected"
    assert "same_function_tibalt_replacement_lost_confirmed_gate" in candidates["Silence"]["decision_reasons"]
    assert candidates["Boros Charm"]["decision"] == "prior_tibalt_replacement_rejected"
    assert candidates["Grand Abolisher"]["decision"] == "prior_tibalt_replacement_rejected"


def test_red_blasts_are_meta_stack_hypotheses_not_blind_swaps(tmp_path):
    payload = build_payload(tmp_path)
    candidates = {row["card_name"]: row for row in payload["candidate_profiles"]}

    assert candidates["Red Elemental Blast"]["battle_rule_summary"]["active_rule_count"] == 1
    assert candidates["Red Elemental Blast"]["decision"] == "meta_stack_candidate_needs_targeted_gate_or_safe_cut"
    assert "narrow_color_hate_requires_meta_or_blue_stack_gate" in candidates["Red Elemental Blast"]["decision_reasons"]
    assert candidates["Pyroblast"]["decision"] == "meta_stack_candidate_needs_targeted_gate_or_safe_cut"


def test_removal_candidates_are_blocked_by_current_removal_floor(tmp_path):
    payload = build_payload(tmp_path)
    candidates = {row["card_name"]: row for row in payload["candidate_profiles"]}

    assert candidates["Chaos Warp"]["decision"] == "blocked_current_removal_floor_sufficient"
    assert "607_already_has_broad_active_spot_removal_floor" in candidates["Chaos Warp"]["decision_reasons"]
    assert candidates["Wear // Tear"]["decision"] == "blocked_current_removal_floor_sufficient"


def test_pressure_protection_candidates_need_new_gate(tmp_path):
    payload = build_payload(tmp_path)
    candidates = {row["card_name"]: row for row in payload["candidate_profiles"]}

    assert candidates["Perch Protection"]["decision"] == "pressure_protection_candidate_needs_gate"
    assert "same_lane_cut_must_preserve_current_protection_floor" in candidates["Perch Protection"]["decision_reasons"]
