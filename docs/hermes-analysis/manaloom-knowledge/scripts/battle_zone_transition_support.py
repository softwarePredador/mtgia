#!/usr/bin/env python3
"""Zone-transition helpers for the Hermes battle analyst."""

import copy


def finish_countered_spell(player, card, *, move_to_exile_func):
    """Move a countered spell to the correct zone object."""
    if isinstance(card, dict) and card.get("_flashback_cast"):
        move_to_exile_func(player, card, reason="flashback_countered")
        return
    if isinstance(card, dict) and card.get("_adventure_cast") and card.get("_adventure_parent"):
        parent = copy.deepcopy(card["_adventure_parent"])
        parent.pop("_adventure_available", None)
        player.graveyard.append(parent)
        return
    player.graveyard.append(card)


def move_to_exile(player, card, *, face_down=False, public=None, reason=None, turn=None):
    """Move a card to exile while preserving minimal face-up/face-down metadata."""
    if isinstance(card, dict):
        is_face_down = bool(face_down)
        card["_exile_face_down"] = is_face_down
        card["_exile_public"] = (not is_face_down) if public is None else bool(public)
        if reason:
            card["_exile_reason"] = reason
        if turn is not None:
            card["_exile_turn"] = turn
    player.exile.append(card)
    return card


def finish_resolved_spell(player, card, *, turn=None, move_to_exile_func, emit_replay_event):
    """Move a resolved nonpermanent spell, honoring Adventure/Flashback replacements."""
    if isinstance(card, dict) and card.get("_flashback_cast"):
        move_to_exile_func(player, card, reason="flashback", turn=turn)
        emit_replay_event(
            "flashback_exiled",
            player=player.name,
            card=card.get("name", "?"),
            turn=turn,
        )
        return
    if isinstance(card, dict) and card.get("_adventure_cast") and card.get("_adventure_parent"):
        parent = copy.deepcopy(card["_adventure_parent"])
        parent["_adventure_available"] = True
        parent["_last_adventure_name"] = card.get("name")
        move_to_exile_func(player, parent, reason="adventure", turn=turn)
        emit_replay_event(
            "adventure_exiled",
            player=player.name,
            card=parent.get("name", "?"),
            adventure=card.get("name", "?"),
            turn=turn,
        )
        return
    player.graveyard.append(card)


def get_lki(creature):
    """Get Last Known Information for a permanent-like object."""
    if isinstance(creature, dict) and "_lki_snapshot" in creature:
        return creature["_lki_snapshot"]
    return {
        "name": creature.get("name", creature.get("card_name", "")),
        "power": creature.get("power", 0),
        "toughness": creature.get("toughness", 0),
        "cmc": creature.get("cmc", 0),
    }


def move_creature_from_battlefield(
    owner,
    creature,
    *,
    reason=None,
    source=None,
    all_players=None,
    replacement_registry,
    replacement_event_cls,
):
    """Move a dead/sacrificed creature to the correct zone for this simulator."""
    if not isinstance(creature, dict):
        return "none"

    creature["_lki_snapshot"] = {
        "name": creature.get("name", creature.get("card_name", "")),
        "power": creature.get("power", 0),
        "toughness": creature.get("toughness", 0),
        "cmc": creature.get("cmc", 0),
        "type_line": creature.get("type_line", ""),
        "is_commander": creature.get("is_commander", False),
        "owner": creature.get("owner", creature.get("controller", "")),
    }
    creature["_zone_id"] = creature.get("_zone_id", 0) + 1
    creature["_last_zone"] = "battlefield"
    if creature in owner.battlefield:
        owner.battlefield.remove(creature)
    if creature.get("is_commander"):
        event = replacement_registry.process_event(
            replacement_event_cls(
                "zone_change",
                affected_player=owner,
                card=creature,
                from_zone="battlefield",
                to_zone="graveyard",
                source=source,
                reason=reason,
            )
        )
        if event.to_zone == "command_zone":
            owner.command_zone.append(creature)
            return "command_zone"
    if creature.get("tag") == "token" or "token" in str(creature.get("type_line") or "").lower():
        return "vanished_token"
    owner.graveyard.append(creature)
    return "graveyard"
