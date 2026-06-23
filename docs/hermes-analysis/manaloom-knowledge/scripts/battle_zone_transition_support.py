#!/usr/bin/env python3
"""Zone-transition helpers for the Hermes battle analyst."""

import copy


def finish_countered_spell(player, card, *, move_to_exile_func):
    """Move a countered spell to the correct zone object."""
    if isinstance(card, dict) and card.get("is_copy"):
        return
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


def finish_resolved_spell(
    player,
    card,
    *,
    turn=None,
    move_to_exile_func,
    emit_replay_event,
    effect_data=None,
):
    """Move a resolved nonpermanent spell, honoring Adventure/Flashback replacements."""
    effect_data = effect_data or {}
    if isinstance(card, dict) and card.get("is_copy"):
        emit_replay_event(
            "spell_copy_ceased_to_exist",
            player=player.name,
            card=card.get("name", "?"),
            copied_from=card.get("_copied_from_spell"),
            copied_by=card.get("_copied_by"),
            turn=turn,
        )
        return
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
    if effect_data.get("exiles_self"):
        move_to_exile_func(player, card, reason="self_exile", turn=turn)
        emit_replay_event(
            "self_exiled_on_resolution",
            player=player.name,
            card=card.get("name", "?") if isinstance(card, dict) else str(card),
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


def _resolve_zone_object(zone, zone_object):
    """Return the actual object stored in a zone before mutating LKI fields."""
    if not isinstance(zone, list):
        return zone_object
    for candidate in zone:
        if candidate is zone_object:
            return candidate
    for candidate in zone:
        if candidate == zone_object:
            return candidate
    if isinstance(zone_object, dict):
        target_name = zone_object.get("name") or zone_object.get("card_name")
        if target_name:
            name_matches = [
                candidate
                for candidate in zone
                if isinstance(candidate, dict)
                and (candidate.get("name") or candidate.get("card_name")) == target_name
            ]
            if len(name_matches) == 1:
                return name_matches[0]
    return zone_object


def _remove_zone_object(zone, zone_object):
    if not isinstance(zone, list):
        return False
    for index, candidate in enumerate(zone):
        if candidate is zone_object:
            del zone[index]
            return True
    try:
        zone.remove(zone_object)
        return True
    except ValueError:
        return False


def move_permanent_from_battlefield(
    owner,
    permanent,
    *,
    reason=None,
    source=None,
    all_players=None,
    replacement_registry,
    replacement_event_cls,
):
    """Move a battlefield permanent to the correct zone for this simulator."""
    if not isinstance(permanent, dict):
        return "none"

    permanent = _resolve_zone_object(owner.battlefield, permanent)
    permanent["_lki_snapshot"] = {
        "name": permanent.get("name", permanent.get("card_name", "")),
        "power": permanent.get("power", 0),
        "toughness": permanent.get("toughness", 0),
        "cmc": permanent.get("cmc", 0),
        "type_line": permanent.get("type_line", ""),
        "is_commander": permanent.get("is_commander", False),
        "owner": permanent.get("owner", permanent.get("controller", "")),
    }
    permanent["_zone_id"] = permanent.get("_zone_id", 0) + 1
    permanent["_last_zone"] = "battlefield"
    _remove_zone_object(owner.battlefield, permanent)
    if permanent.get("is_commander"):
        event = replacement_registry.process_event(
            replacement_event_cls(
                "zone_change",
                affected_player=owner,
                card=permanent,
                from_zone="battlefield",
                to_zone="graveyard",
                source=source,
                reason=reason,
            )
        )
        if event.to_zone == "command_zone":
            owner.command_zone.append(permanent)
            return "command_zone"
    if permanent.get("tag") == "token" or "token" in str(permanent.get("type_line") or "").lower():
        return "vanished_token"
    owner.graveyard.append(permanent)
    return "graveyard"


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
    """Compatibility wrapper for older creature-specific call sites."""
    return move_permanent_from_battlefield(
        owner,
        creature,
        reason=reason,
        source=source,
        all_players=all_players,
        replacement_registry=replacement_registry,
        replacement_event_cls=replacement_event_cls,
    )
