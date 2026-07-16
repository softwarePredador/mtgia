#!/usr/bin/env python3
"""Focused token lifecycle contract regressions for the active battle engine."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

MODULE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
SPEC = importlib.util.spec_from_file_location("battle_token_lifecycle_under_test", MODULE_PATH)
battle = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(battle)


TOKEN_MARKERS = [
    pytest.param({"token": True}, id="token_bool"),
    pytest.param({"is_token": True}, id="is_token_bool"),
    pytest.param({"tag": "token"}, id="tag_token"),
    pytest.param({"type_line": "Creature Token - Spirit"}, id="type_line_token"),
]


@pytest.fixture
def event_log():
    events = []
    previous_handler = battle.REPLAY_EVENT_HANDLER
    previous_turn = battle.CURRENT_REPLAY_TURN
    battle.CURRENT_REPLAY_TURN = 17
    battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
    try:
        yield events
    finally:
        battle.REPLAY_EVENT_HANDLER = previous_handler
        battle.CURRENT_REPLAY_TURN = previous_turn


def make_player(name="Token Owner", library=None):
    return battle.Player(name, None, list(library or []), strategy="midrange")


def make_token(name, marker, *, type_line="Creature - Spirit", **extra):
    card = {
        "name": name,
        "type_line": type_line,
        "effect": "creature" if "creature" in type_line.lower() else "permanent",
        "power": 1,
        "toughness": 1,
        **marker,
        **extra,
    }
    return card


def events_named(events, event_name, *, token=None, card=None):
    rows = [data for event, data in events if event == event_name]
    if token is not None:
        rows = [data for data in rows if data.get("token") == token]
    if card is not None:
        rows = [data for data in rows if data.get("card") == card]
    return rows


def assert_canonical_cease_payload(data, *, zone, reason):
    assert data["to_zone"] == zone
    assert data["zone"] == zone
    assert data["destination"] == zone
    assert data["result"] == "ceased_to_exist"
    assert data["reason"] == reason
    assert data["turn"] == 17


@pytest.mark.parametrize("marker", TOKEN_MARKERS)
@pytest.mark.parametrize("wrapper_name", ["creature", "permanent"])
def test_graveyard_wrappers_recognize_all_token_markers_and_emit_once(
    marker,
    wrapper_name,
    event_log,
):
    owner = make_player(library=[{"name": "Dies Draw", "type_line": "Instant"}])
    token = make_token(
        f"{wrapper_name} {next(iter(marker))}",
        marker,
        draw_cards_when_this_dies=1,
    )
    owner.battlefield = [token]
    wrapper = (
        battle.move_creature_from_battlefield
        if wrapper_name == "creature"
        else battle.move_permanent_from_battlefield
    )

    destination = wrapper(
        owner,
        token,
        reason="sacrifice_token_matrix",
        source={"name": "Matrix Source"},
        all_players=[owner],
    )

    assert destination == "graveyard"
    assert token not in owner.battlefield
    assert token not in owner.graveyard
    assert [card["name"] for card in owner.hand] == ["Dies Draw"]
    cease = events_named(event_log, "token_ceased_to_exist", token=token["name"])
    moved = events_named(event_log, "permanent_moved_from_battlefield", card=token["name"])
    dies = events_named(event_log, "dies_draw_resolved", card=token["name"])
    assert len(moved) == len(cease) == len(dies) == 1
    assert moved[0]["destination"] == "graveyard"
    assert cease[0]["from_zone"] == "battlefield"
    assert cease[0]["source"] == "Matrix Source"
    assert_canonical_cease_payload(cease[0], zone="graveyard", reason="sacrifice_token_matrix")
    names = [event for event, _data in event_log]
    assert names.index("permanent_moved_from_battlefield") < names.index("token_ceased_to_exist")
    assert names.index("token_ceased_to_exist") < names.index("dies_draw_resolved")
    assert len(owner.sacrificed_permanents_this_turn) == 1


ZONE_TRANSITIONS = [
    pytest.param("hand", id="hand"),
    pytest.param("library_top", id="library_top"),
    pytest.param("library_bottom", id="library_bottom"),
    pytest.param("exile", id="exile"),
]


@pytest.mark.parametrize("marker", TOKEN_MARKERS)
@pytest.mark.parametrize("destination", ZONE_TRANSITIONS)
def test_non_graveyard_wrappers_return_real_zone_without_persisting_token(
    marker,
    destination,
    event_log,
):
    owner = make_player()
    token = make_token(f"{destination} {next(iter(marker))}", marker)
    owner.battlefield = [token]
    source = {"name": "Zone Matrix Source"}

    if destination == "hand":
        actual = battle.move_permanent_from_battlefield_to_hand(
            owner,
            token,
            reason="matrix_to_hand",
            source=source,
            turn=17,
        )
        reason = "matrix_to_hand"
    elif destination == "exile":
        actual = battle.move_permanent_from_battlefield_to_exile(
            owner,
            token,
            reason="matrix_to_exile",
            source=source,
            turn=17,
        )
        reason = "matrix_to_exile"
    else:
        actual = battle.move_permanent_from_battlefield_to_library(
            owner,
            token,
            destination=destination,
            reason="matrix_to_library",
            source=source,
            turn=17,
        )
        reason = "matrix_to_library"

    assert actual == destination
    for zone in (owner.battlefield, owner.graveyard, owner.hand, owner.library, owner.exile):
        assert token not in zone
    moved = events_named(event_log, "permanent_moved_from_battlefield", card=token["name"])
    cease = events_named(event_log, "token_ceased_to_exist", token=token["name"])
    assert len(moved) == len(cease) == 1
    assert moved[0]["destination"] == destination
    assert cease[0]["from_zone"] == "battlefield"
    assert cease[0]["source"] == "Zone Matrix Source"
    assert_canonical_cease_payload(cease[0], zone=destination, reason=reason)


@pytest.mark.parametrize("marker", TOKEN_MARKERS)
@pytest.mark.parametrize("zone_name", ["graveyard", "exile", "hand", "library", "command_zone"])
def test_sba_removes_stale_tokens_from_every_nonbattlefield_zone_once(
    marker,
    zone_name,
    event_log,
):
    owner = make_player()
    token = make_token(f"stale {zone_name} {next(iter(marker))}", marker)
    getattr(owner, zone_name).append(token)

    assert battle.check_token_lifecycle([owner]) is True
    assert token not in getattr(owner, zone_name)
    assert battle.check_token_lifecycle([owner]) is False

    cease = events_named(event_log, "token_ceased_to_exist", token=token["name"])
    assert len(cease) == 1
    assert cease[0]["from_zone"] == zone_name
    assert_canonical_cease_payload(cease[0], zone=zone_name, reason="state_based_action")


@pytest.mark.parametrize("sba_kind", ["aura", "saga", "planeswalker", "battle", "zero_toughness"])
def test_special_state_based_actions_use_the_token_pipeline(sba_kind, event_log):
    owner = make_player()
    if sba_kind == "aura":
        token = make_token(
            "Illegal Aura Token",
            {"token": True},
            type_line="Enchantment - Aura",
        )
        owner.battlefield = [token]
        assert battle.check_illegal_attachments([owner]) is True
        expected_zone = "graveyard"
    elif sba_kind == "saga":
        token = make_token(
            "Final Saga Token",
            {"token": True},
            type_line="Enchantment - Saga",
            final_chapter=3,
            lore_counters=3,
        )
        owner.battlefield = [token]
        assert battle.check_saga_final_chapter([owner]) is True
        expected_zone = "graveyard"
    elif sba_kind == "planeswalker":
        token = make_token(
            "Zero Loyalty Token",
            {"is_token": True},
            type_line="Legendary Planeswalker",
            loyalty=0,
        )
        owner.battlefield = [token]
        battle.check_sbas_until_stable([owner])
        expected_zone = "graveyard"
    elif sba_kind == "battle":
        token = make_token(
            "Defeated Battle Token",
            {"tag": "token"},
            type_line="Battle - Siege",
            defense=0,
            back_face={"name": "Must Not Return"},
        )
        owner.battlefield = [token]
        battle.check_sbas_until_stable([owner])
        expected_zone = "exile"
        assert all(card.get("name") != "Must Not Return" for card in owner.battlefield)
    else:
        token = make_token(
            "Zero Toughness Token",
            {"token": True},
            toughness=0,
            battle_model_scope=battle.STATIC_GRAVEYARD_COUNT_POWER_TOUGHNESS_SCOPE,
        )
        owner.battlefield = [token]
        assert battle.move_zero_toughness_graveyard_count_creature_to_graveyard(
            owner,
            token,
            turn=17,
            phase="sba",
            emit_event=True,
        ) is True
        expected_zone = "graveyard"

    assert token not in owner.battlefield
    assert token not in owner.graveyard
    assert token not in owner.exile
    cease = events_named(event_log, "token_ceased_to_exist", token=token["name"])
    assert len(cease) == 1
    assert cease[0]["destination"] == expected_zone


def test_land_token_does_not_trigger_land_card_entered_graveyard_effect(event_log):
    owner = make_player()
    trigger_source = {
        "name": "Sand Scout Fixture",
        "type_line": "Creature - Scout",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "land_cards_to_your_graveyard_create_token": True,
        "land_graveyard_token_name": "Sand Warrior",
    }
    land_token = make_token(
        "Animated Land Token",
        {"token": True},
        type_line="Land",
    )
    owner.battlefield = [trigger_source, land_token]

    assert battle.move_permanent_from_battlefield(
        owner,
        land_token,
        reason="sacrifice_land_token",
        source=trigger_source,
        all_players=[owner],
    ) == "graveyard"

    assert all(card.get("name") != "Sand Warrior" for card in owner.battlefield)
    assert not any(
        event == "trigger_resolved" and data.get("trigger") == "land_cards_to_your_graveyard"
        for event, data in event_log
    )
    assert len(events_named(event_log, "token_ceased_to_exist", token=land_token["name"])) == 1


@pytest.mark.parametrize("replacement", ["regeneration", "shield"])
def test_destroy_replacement_keeps_token_on_battlefield_without_cease(replacement, event_log):
    owner = make_player()
    extra = {"regeneration_shields": 1} if replacement == "regeneration" else {"shield_counters": 1}
    token = make_token("Protected Token", {"token": True}, **extra)
    owner.battlefield = [token]

    destination = battle.move_creature_from_battlefield(
        owner,
        token,
        reason="destroy",
        source={"name": "Destroy Fixture"},
        all_players=[owner],
    )

    assert destination == "battlefield"
    assert token in owner.battlefield
    assert not events_named(event_log, "token_ceased_to_exist", token=token["name"])


def test_end_step_pipeline_has_one_aggregate_and_one_cease_per_token(event_log):
    owner = make_player(library=[{"name": "End Step Draw", "type_line": "Instant"}])
    sacrifice_a = make_token(
        "End Step Sacrifice A",
        {"token": True},
        sacrifice_at_end_step=True,
        draw_cards_when_this_dies=1,
    )
    sacrifice_b = make_token(
        "End Step Sacrifice B",
        {"is_token": True},
        sacrifice_at_end_step=True,
    )
    exile_token = make_token(
        "End Step Exile Token",
        {"tag": "token"},
        exile_at_end_step=True,
    )
    real_card = {
        "name": "End Step Exile Card",
        "type_line": "Creature - Human",
        "effect": "creature",
        "power": 2,
        "toughness": 2,
        "exile_at_end_step": True,
    }
    owner.battlefield = [sacrifice_a, sacrifice_b, exile_token, real_card]

    processed = battle.process_end_step_token_sacrifices(owner, 17)

    assert len(processed) == 4
    assert real_card in owner.exile
    for token in (sacrifice_a, sacrifice_b, exile_token):
        assert token not in owner.battlefield
        assert token not in owner.graveyard
        assert token not in owner.exile
        assert len(events_named(event_log, "token_ceased_to_exist", token=token["name"])) == 1
    assert len(events_named(event_log, "end_step_token_sacrificed")) == 1
    assert len(events_named(event_log, "end_step_token_exiled")) == 1
    assert len(events_named(event_log, "dies_draw_resolved", card=sacrifice_a["name"])) == 1
    assert len(owner.sacrificed_permanents_this_turn) == 2
    assert battle.check_token_lifecycle([owner]) is False
    assert len(events_named(event_log, "token_ceased_to_exist")) == 3


def test_direct_damage_outlet_uses_token_marker_and_counts_sacrifice_once(event_log):
    owner = make_player(library=[{"name": "Outlet Draw", "type_line": "Sorcery"}])
    opponent = make_player("Opponent")
    outlet = {
        "name": "Goblin Bombardment Fixture",
        "type_line": "Enchantment",
        "effect": "sacrifice_damage_outlet",
        "damage": 1,
    }
    token = make_token(
        "Copy Token Without Token Type",
        {"token": True},
        draw_cards_when_this_dies=1,
    )
    owner.battlefield = [outlet, token]
    life_before = opponent.life

    activated = battle.activate_sacrifice_damage_outlets(
        owner,
        [opponent],
        [owner, opponent],
        17,
        None,
    )

    assert activated == 1
    assert opponent.life == life_before - 1
    assert token not in owner.battlefield and token not in owner.graveyard
    assert [card["name"] for card in owner.hand] == ["Outlet Draw"]
    assert len(owner.sacrificed_permanents_this_turn) == 1
    assert len(events_named(event_log, "token_ceased_to_exist", token=token["name"])) == 1
    assert len(events_named(event_log, "dies_draw_resolved", card=token["name"])) == 1


@pytest.mark.parametrize("is_token", [False, True])
def test_activation_sacrifice_helper_records_exactly_once(is_token, event_log):
    owner = make_player()
    permanent = {
        "name": "Activation Cost Fixture",
        "type_line": "Artifact",
        "effect": "artifact",
        **({"token": True} if is_token else {}),
    }
    owner.battlefield = [permanent]

    assert battle.sacrifice_permanent_for_activation(owner, permanent, 17) is True
    assert permanent not in owner.battlefield
    assert (permanent not in owner.graveyard) is is_token
    assert len(owner.sacrificed_permanents_this_turn) == 1
    assert len(events_named(event_log, "token_ceased_to_exist", token=permanent["name"])) == int(is_token)


def test_stale_token_reference_cannot_consume_an_identical_token(event_log):
    owner = battle.Player("Token Owner", None, [])
    first = make_token("Treasure", {"token": True}, type_line="Token Artifact - Treasure")
    second = make_token("Treasure", {"token": True}, type_line="Token Artifact - Treasure")
    owner.battlefield = [first, second]

    assert battle.sacrifice_permanent_for_activation(owner, first, 17) is True
    assert battle.sacrifice_permanent_for_activation(owner, first, 17) is False

    assert owner.battlefield == [second]
    assert len(owner.sacrificed_permanents_this_turn) == 1
    assert len(events_named(event_log, "token_ceased_to_exist", token="Treasure")) == 1


def test_non_token_transition_remains_persistent_and_emits_no_cease(event_log):
    owner = make_player()
    permanent = {"name": "Real Permanent", "type_line": "Artifact", "effect": "artifact"}
    owner.battlefield = [permanent]

    destination = battle.move_permanent_from_battlefield(
        owner,
        permanent,
        reason="destroy",
        all_players=[owner],
    )

    assert destination == "graveyard"
    assert permanent in owner.graveyard
    assert not events_named(event_log, "token_ceased_to_exist")
