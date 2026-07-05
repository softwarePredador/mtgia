import sqlite3
from pathlib import Path

import lorehold_brain_entreat_haze_runtime_contract as contract


def make_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
            """
            CREATE TABLE battle_card_rules (
              normalized_name TEXT,
              card_name TEXT,
              logical_rule_key TEXT,
              effect_json TEXT,
              review_status TEXT,
              execution_status TEXT,
              source TEXT
            );
            INSERT INTO battle_card_rules VALUES (
              'storm-kiln artist',
              'Storm-Kiln Artist',
              'battle_rule_v1:storm',
              '{"effect":"creature","battle_model_scope":"creature_body_artifact_power_magecraft_treasure_annotation_v1"}',
              'verified',
              'auto',
              'unit'
            );
            """
        )


def write_runtime_sources(tmp_path: Path) -> dict[str, Path]:
    paths = {
        "Brain in a Jar": tmp_path / "BrainInAJar.java",
        "Entreat the Angels": tmp_path / "EntreatTheAngels.java",
        "Haze of Rage": tmp_path / "HazeOfRage.java",
    }
    paths["Brain in a Jar"].write_text(
        "AddCountersSourceEffect BrainInAJarCastEffect RemoveVariableCountersSourceCost ScryEffect ManaValuePredicate",
        encoding="utf-8",
    )
    paths["Entreat the Angels"].write_text(
        "CreateTokenEffect AngelToken GetXValue MiracleAbility",
        encoding="utf-8",
    )
    paths["Haze of Rage"].write_text(
        "BuybackAbility BoostControlledEffect StormAbility",
        encoding="utf-8",
    )
    paths["storm"] = tmp_path / "StormKilnArtist.java"
    paths["storm"].write_text(
        "MagecraftAbility CreateTokenEffect TreasureToken ArtifactYouControlCount",
        encoding="utf-8",
    )
    return paths


def test_runtime_foundations_detects_existing_surfaces():
    foundations = contract.runtime_foundations(
        "def buyback_runtime_enabled pass\nbuyback_returned_to_hand storm_copies miracle_cast create_creature_token charge_counters scry",
        "MiracleAbility BuybackAbility StormAbility",
    )

    assert foundations["buyback_runtime_enabled"] is True
    assert foundations["storm_copy_event_foundation"] is True
    assert foundations["miracle_casting_path"] is True
    assert foundations["charge_counter_state"] is True
    assert foundations["xmage_storm_hint"] is True


def test_build_payload_prioritizes_entreat_and_keeps_battle_blocked(tmp_path: Path, monkeypatch):
    paths = write_runtime_sources(tmp_path)
    for card_name, path in paths.items():
        if card_name == "storm":
            continue
        patched = dict(contract.RUNTIME_CARDS[card_name])
        patched["xmage_path"] = path
        monkeypatch.setitem(contract.RUNTIME_CARDS, card_name, patched)
    monkeypatch.setattr(contract, "STORM_KILN_PATH", paths["storm"])
    db_path = tmp_path / "knowledge.db"
    make_db(db_path)
    battle_runtime = tmp_path / "battle.py"
    battle_runtime.write_text(
        "def buyback_runtime_enabled(): pass\nbuyback_returned_to_hand storm_copies miracle_cast create_creature_token charge_counters scry",
        encoding="utf-8",
    )
    hints = tmp_path / "hints.py"
    hints.write_text("MiracleAbility BuybackAbility StormAbility", encoding="utf-8")
    split_report = {
        "cards": [
            {"card_name": "Brain in a Jar", "route_class": "runtime_or_manual_review", "lane": "topdeck"},
            {"card_name": "Entreat the Angels", "route_class": "runtime_or_manual_review", "lane": "miracle"},
            {"card_name": "Haze of Rage", "route_class": "combo_runtime_contract", "lane": "combo"},
        ]
    }

    payload = contract.build_payload(
        split_report=split_report,
        split_path=tmp_path / "split.json",
        db_path=db_path,
        battle_runtime_path=battle_runtime,
        hints_path=hints,
    )

    rows = {row["card_name"]: row for row in payload["contracts"]}
    assert payload["status"] == "runtime_contracts_drafted_no_battle_ready_keep_607"
    assert payload["summary"]["best_first_runtime_contract"] == "Entreat the Angels"
    assert payload["summary"]["battle_ready_now_count"] == 0
    assert rows["Entreat the Angels"]["readiness"] == "best_first_runtime_contract_candidate"
    assert rows["Brain in a Jar"]["xmage_signal_hits"]["BrainInAJarCastEffect"] is True
    assert rows["Haze of Rage"]["xmage_signal_hits"]["StormAbility"] is True
    assert payload["storm_kiln_artist_dependency"]["annotation_only"] is True
    assert payload["decision"]["promotion_allowed"] is False
