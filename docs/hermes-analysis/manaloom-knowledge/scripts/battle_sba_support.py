#!/usr/bin/env python3
"""State-based action helpers for the Hermes battle analyst."""

from battle_zone_transition_support import is_token_object


PLUS_ONE_COUNTER_KEYS = ("plus_one_counters", "plus1_counters", "+1/+1_counters")
MINUS_ONE_COUNTER_KEYS = ("minus_one_counters", "minus1_counters", "-1/-1_counters")
PLAYER_DEPARTURE_OBJECT_ZONES = (
    "battlefield",
    "phased_out",
    "hand",
    "library",
    "graveyard",
    "exile",
    "command_zone",
)
PLAYER_DEPARTURE_CONTROL_ZONES = ("battlefield", "phased_out")


def _counter_total(card, keys, *, numeric_stat):
    total = 0
    for key in keys:
        value = numeric_stat(card.get(key))
        if value:
            total += max(0, value)
    return total


def _replace_counter_aliases(card, keys, canonical_key, value):
    for key in keys:
        card.pop(key, None)
    card[canonical_key] = max(0, int(value or 0))


def cancel_plus_minus_counters(all_players, *, numeric_stat, emit_replay_event):
    """+1/+1 and -1/-1 counters cancel as a state-based action."""
    for player_obj in all_players:
        for permanent in list(player_obj.battlefield):
            if not isinstance(permanent, dict):
                continue
            plus = _counter_total(
                permanent,
                PLUS_ONE_COUNTER_KEYS,
                numeric_stat=numeric_stat,
            )
            minus = _counter_total(
                permanent,
                MINUS_ONE_COUNTER_KEYS,
                numeric_stat=numeric_stat,
            )
            cancel = min(plus, minus)
            if cancel <= 0:
                continue
            _replace_counter_aliases(
                permanent,
                PLUS_ONE_COUNTER_KEYS,
                "plus_one_counters",
                plus - cancel,
            )
            _replace_counter_aliases(
                permanent,
                MINUS_ONE_COUNTER_KEYS,
                "minus_one_counters",
                minus - cancel,
            )
            emit_replay_event(
                "counters_cancelled",
                player=player_obj.name,
                card=permanent.get("name"),
                cancelled=cancel,
                plus_one_remaining=permanent["plus_one_counters"],
                minus_one_remaining=permanent["minus_one_counters"],
            )
            return True
    return False


def is_aura_permanent(card):
    return isinstance(card, dict) and "aura" in str(card.get("type_line") or "").lower()


def is_equipment_permanent(card):
    return isinstance(card, dict) and "equipment" in str(card.get("type_line") or "").lower()


def _attached_target_reference(permanent):
    return (
        permanent.get("attached_to")
        or permanent.get("equipped_to")
        or permanent.get("enchanting")
    )


def _find_attached_target(reference, all_players):
    if not reference:
        return None
    for player_obj in all_players:
        for candidate in getattr(player_obj, "battlefield", []):
            if not isinstance(candidate, dict):
                continue
            if candidate is reference:
                return candidate
            if isinstance(reference, str) and candidate.get("name") == reference:
                return candidate
    return None


def _clear_attachment(permanent):
    permanent.pop("attached_to", None)
    permanent.pop("equipped_to", None)
    permanent.pop("enchanting", None)


def _attachment_is_legal(
    permanent,
    target,
    *,
    is_battlefield_creature,
    is_effective_land,
    is_artifact_permanent,
):
    if target is None:
        return False
    text = f"{permanent.get('oracle_text', '')} {permanent.get('type_line', '')}".lower()
    if is_equipment_permanent(permanent):
        return is_battlefield_creature(target)
    if is_aura_permanent(permanent):
        if "enchant land" in text:
            return is_effective_land(target)
        if "enchant artifact" in text:
            return is_artifact_permanent(target)
        if "enchant player" in text:
            return False
        return is_battlefield_creature(target)
    return True


def check_illegal_attachments(
    all_players,
    *,
    is_battlefield_creature,
    is_effective_land,
    is_artifact_permanent,
    emit_replay_event,
    move_permanent_from_battlefield,
):
    """Basic Aura/Equipment SBA handling for illegal attachments."""
    for player_obj in all_players:
        for permanent in list(player_obj.battlefield):
            if not isinstance(permanent, dict):
                continue
            if not (is_aura_permanent(permanent) or is_equipment_permanent(permanent)):
                continue
            reference = _attached_target_reference(permanent)
            if is_equipment_permanent(permanent) and not reference:
                continue
            target = _find_attached_target(reference, all_players)
            legal = _attachment_is_legal(
                permanent,
                target,
                is_battlefield_creature=is_battlefield_creature,
                is_effective_land=is_effective_land,
                is_artifact_permanent=is_artifact_permanent,
            )
            if legal:
                continue
            if is_aura_permanent(permanent):
                destination = move_permanent_from_battlefield(
                    player_obj,
                    permanent,
                    "aura_illegal_attachment_sba",
                    None,
                    all_players,
                )
                emit_replay_event(
                    "attachment_sba",
                    player=player_obj.name,
                    card=permanent.get("name"),
                    permanent_type="aura",
                    action="moved_to_graveyard",
                    destination=destination,
                )
                return True
            _clear_attachment(permanent)
            emit_replay_event(
                "attachment_sba",
                player=player_obj.name,
                card=permanent.get("name"),
                permanent_type="equipment",
                action="detached",
            )
            return True
    return False


def is_saga_permanent(card):
    return isinstance(card, dict) and "saga" in str(card.get("type_line") or "").lower()


def _saga_final_chapter(permanent, *, numeric_stat):
    for key in ("final_chapter", "chapter_count", "max_chapter"):
        value = numeric_stat(permanent.get(key))
        if value:
            return max(1, value)
    chapters = permanent.get("saga_chapters") or permanent.get("chapters")
    if isinstance(chapters, (list, tuple)) and chapters:
        return len(chapters)
    return None


def _saga_lore_counters(permanent, *, numeric_stat):
    for key in ("lore_counters", "chapter", "current_chapter"):
        value = numeric_stat(permanent.get(key))
        if value is not None:
            return max(0, value)
    return 0


def check_saga_final_chapter(
    all_players,
    *,
    numeric_stat,
    emit_replay_event,
    move_permanent_from_battlefield,
):
    """Basic Saga SBA after the final chapter ability is no longer pending."""
    for player_obj in all_players:
        for permanent in list(player_obj.battlefield):
            if not is_saga_permanent(permanent):
                continue
            final_chapter = _saga_final_chapter(permanent, numeric_stat=numeric_stat)
            if not final_chapter:
                continue
            if permanent.get("chapter_ability_pending"):
                continue
            if _saga_lore_counters(permanent, numeric_stat=numeric_stat) < final_chapter:
                continue
            destination = move_permanent_from_battlefield(
                player_obj,
                permanent,
                "sacrifice_saga_final_chapter_sba",
                permanent,
                all_players,
            )
            emit_replay_event(
                "saga_sacrificed_by_sba",
                player=player_obj.name,
                card=permanent.get("name"),
                final_chapter=final_chapter,
                destination=destination,
            )
            return True
    return False


def check_token_lifecycle(
    all_players,
    *,
    emit_replay_event,
    emit_token_ceased_to_exist=None,
):
    """Token SBAs: tokens cease to exist outside battlefield."""
    removed = False
    for player_obj in all_players:
        for zone_attr in ["graveyard", "exile", "hand", "library", "command_zone"]:
            zone = getattr(player_obj, zone_attr, [])
            for obj in list(zone):
                if is_token_object(obj):
                    zone.remove(obj)
                    removed = True
                    if emit_token_ceased_to_exist is not None:
                        emit_token_ceased_to_exist(
                            player_obj,
                            obj,
                            zone=zone_attr,
                            from_zone=zone_attr,
                            reason="state_based_action",
                        )
                    else:
                        emit_replay_event(
                            "token_ceased_to_exist",
                            player=player_obj.name,
                            token=obj.get("name"),
                            from_zone=zone_attr,
                            to_zone=zone_attr,
                            zone=zone_attr,
                            destination=zone_attr,
                            result="ceased_to_exist",
                            reason="state_based_action",
                            source=None,
                            turn=None,
                        )
    return removed


def _remove_zone_object(zone, obj):
    if not isinstance(zone, list):
        return False
    for index, candidate in enumerate(zone):
        if candidate is obj:
            del zone[index]
            return True
    try:
        zone.remove(obj)
        return True
    except ValueError:
        return False


def _append_zone_object(zone, obj):
    if not isinstance(zone, list):
        return False
    if any(candidate is obj for candidate in zone):
        return False
    zone.append(obj)
    return True


def _player_from_reference(reference, all_players):
    if reference is None:
        return None
    for participant in all_players:
        if reference is participant:
            return participant
    reference_name = str(
        getattr(reference, "name", reference) or ""
    ).strip()
    if not reference_name:
        return None
    return next(
        (
            participant
            for participant in all_players
            if str(getattr(participant, "name", "")) == reference_name
        ),
        None,
    )


def _temporary_control_return_player(obj, all_players):
    if not isinstance(obj, dict):
        return None
    for key in (
        "_until_eot_control_return_player_ref",
        "_specialize_temporary_control_original_owner",
        "_until_eot_control_return_player_name",
    ):
        participant = _player_from_reference(obj.get(key), all_players)
        if participant is not None:
            return participant
    return None


def _object_owner(obj, holder, all_players):
    if isinstance(obj, dict):
        explicit_owner = _player_from_reference(obj.get("owner"), all_players)
        if explicit_owner is not None:
            return explicit_owner
        return_player = _temporary_control_return_player(obj, all_players)
        if return_player is not None:
            return return_player
    return holder


def _object_name(obj):
    if isinstance(obj, dict):
        return obj.get("name", obj.get("card_name", "?"))
    return str(obj)


def _end_departing_player_control_effect(obj, return_player):
    """End only the control-changing part of a temporary effect.

    Haste and other until-end-of-turn modifiers remain until cleanup even when
    the player who gained control leaves the game. Control changes are not zone
    changes and must not reset the permanent or retrigger battlefield events.
    """
    if not isinstance(obj, dict):
        return False
    originals = obj.get("_until_eot_originals")
    if isinstance(originals, dict) and "controller" in originals:
        original_controller = originals.pop("controller")
        if original_controller is None:
            obj.pop("controller", None)
        else:
            obj["controller"] = original_controller
        if not originals:
            obj.pop("_until_eot_originals", None)
    for key in (
        "_until_eot_control_return_player_ref",
        "_until_eot_control_return_player_name",
        "_specialize_temporary_control_original_owner",
        "_specialize_temporary_control_controller",
        "_specialize_temporary_control_acquired_turn",
    ):
        obj.pop(key, None)
    obj["controller"] = getattr(return_player, "name", obj.get("controller"))
    for key in ("attacking", "blocking", "blocked", "blockers"):
        obj.pop(key, None)
    return bool(obj.get("_until_eot_originals"))


def _clear_departure_exile_state(obj, from_zone):
    if not isinstance(obj, dict):
        return
    obj["_lki_snapshot"] = {
        "name": obj.get("name", obj.get("card_name", "")),
        "power": obj.get("power", 0),
        "toughness": obj.get("toughness", 0),
        "cmc": obj.get("cmc", 0),
        "type_line": obj.get("type_line", ""),
        "is_commander": obj.get("is_commander", False),
        "owner": obj.get("owner", ""),
    }
    obj["_zone_id"] = int(obj.get("_zone_id", 0) or 0) + 1
    obj["_last_zone"] = from_zone
    originals = obj.pop("_until_eot_originals", {})
    if isinstance(originals, dict):
        for key, original in originals.items():
            if original is None:
                obj.pop(key, None)
            else:
                obj[key] = original
    for key in (
        "_until_eot_control_return_player_ref",
        "_until_eot_control_return_player_name",
        "_specialize_temporary_control_original_owner",
        "_specialize_temporary_control_controller",
        "_specialize_temporary_control_acquired_turn",
        "_compact_attack_projected_turn",
        "_compact_attack_projected_by",
        "attacking",
        "blocking",
        "blocked",
        "blockers",
        "damage_marked",
        "summoning_sick",
        "tapped",
        "controller",
    ):
        obj.pop(key, None)
    obj["_exile_face_down"] = False
    obj["_exile_public"] = True
    obj["_exile_reason"] = "controller_left_game"


def remove_eliminated_player_objects(player_obj, all_players, *, emit_replay_event):
    """Apply the CR 800.4a object/control cleanup for a departing player.

    Objects owned by the departing player leave the game without changing
    zones. Temporary control effects end without a zone change. Only objects
    still controlled by that player after those steps are exiled.
    """
    participants = list(all_players or [player_obj])
    if player_obj not in participants:
        participants.append(player_obj)
    owned_removed = []
    control_returned = []
    controlled_exiled = []
    nonowned_rehomed = []
    unresolved_owner_removed = []

    # CR 800.4a, first instruction: every object owned by the departing
    # player leaves the game, wherever another player may currently control it.
    for holder in participants:
        for zone_name in PLAYER_DEPARTURE_OBJECT_ZONES:
            zone = getattr(holder, zone_name, None)
            if not isinstance(zone, list):
                continue
            for obj in list(zone):
                if _object_owner(obj, holder, participants) is not player_obj:
                    continue
                if not _remove_zone_object(zone, obj):
                    continue
                owned_removed.append(
                    {
                        "card": _object_name(obj),
                        "zone": zone_name,
                        "holder": getattr(holder, "name", "?"),
                        "token": is_token_object(obj),
                    }
                )

    # Exile is shared by the rules but stored per player in this runtime. Keep
    # survivor-owned nonbattlefield objects reachable without modeling a zone
    # change merely because their storage holder left the game.
    for zone_name in PLAYER_DEPARTURE_OBJECT_ZONES:
        if zone_name in PLAYER_DEPARTURE_CONTROL_ZONES:
            continue
        zone = getattr(player_obj, zone_name, None)
        if not isinstance(zone, list):
            continue
        for obj in list(zone):
            owner = _object_owner(obj, player_obj, participants)
            if not _remove_zone_object(zone, obj):
                continue
            if owner is not None and owner is not player_obj and not getattr(owner, "eliminated", False):
                _append_zone_object(getattr(owner, zone_name, []), obj)
                nonowned_rehomed.append(
                    {
                        "card": _object_name(obj),
                        "zone": zone_name,
                        "owner": getattr(owner, "name", "?"),
                    }
                )
            else:
                unresolved_owner_removed.append(
                    {"card": _object_name(obj), "zone": zone_name}
                )

    # CR 800.4a, second instruction: effects giving the departing player
    # control end. Moving an object between per-controller battlefield arrays
    # is runtime bookkeeping, not a battlefield zone change.
    for zone_name in PLAYER_DEPARTURE_CONTROL_ZONES:
        zone = getattr(player_obj, zone_name, None)
        if not isinstance(zone, list):
            continue
        for obj in list(zone):
            return_player = _temporary_control_return_player(obj, participants)
            if (
                return_player is None
                or return_player is player_obj
                or getattr(return_player, "eliminated", False)
            ):
                continue
            if not _remove_zone_object(zone, obj):
                continue
            modifiers_remain = _end_departing_player_control_effect(obj, return_player)
            _append_zone_object(getattr(return_player, zone_name, []), obj)
            detail = {
                "card": _object_name(obj),
                "zone": zone_name,
                "returned_to": getattr(return_player, "name", "?"),
                "until_eot_modifiers_remain": modifiers_remain,
            }
            control_returned.append(detail)
            emit_replay_event(
                "temporary_control_returned",
                player=getattr(player_obj, "name", "?"),
                returned_to=getattr(return_player, "name", "?"),
                card=_object_name(obj),
                from_controller=getattr(player_obj, "name", "?"),
                to_controller=getattr(return_player, "name", "?"),
                zone=zone_name,
                zone_changed=False,
                reason="controller_left_game",
                result="returned_on_controller_departure",
                player_departure_rule="CR 800.4a",
            )

    # CR 800.4a, final instruction: objects still controlled by the departing
    # player are exiled. This is a real zone move, but never a dies event.
    for zone_name in PLAYER_DEPARTURE_CONTROL_ZONES:
        zone = getattr(player_obj, zone_name, None)
        if not isinstance(zone, list):
            continue
        for obj in list(zone):
            owner = _object_owner(obj, player_obj, participants)
            if not _remove_zone_object(zone, obj):
                continue
            if owner is None or owner is player_obj or getattr(owner, "eliminated", False):
                unresolved_owner_removed.append(
                    {"card": _object_name(obj), "zone": zone_name}
                )
                continue
            token_object = is_token_object(obj)
            _clear_departure_exile_state(obj, zone_name)
            if not token_object:
                _append_zone_object(getattr(owner, "exile", []), obj)
            detail = {
                "card": _object_name(obj),
                "from_zone": zone_name,
                "owner": getattr(owner, "name", "?"),
                "token": token_object,
            }
            controlled_exiled.append(detail)
            if zone_name == "battlefield":
                emit_replay_event(
                    "permanent_moved_from_battlefield",
                    player=getattr(player_obj, "name", "?"),
                    owner=getattr(owner, "name", "?"),
                    card=_object_name(obj),
                    permanent_type="permanent",
                    from_zone="battlefield",
                    to_zone="exile",
                    destination="exile",
                    reason="controller_left_game",
                    source=None,
                    player_departure_rule="CR 800.4a",
                    departed_controller_trigger_suppressed=True,
                )
            if token_object:
                emit_replay_event(
                    "token_ceased_to_exist",
                    player=getattr(owner, "name", "?"),
                    token=_object_name(obj),
                    from_zone=zone_name,
                    to_zone="exile",
                    zone="exile",
                    destination="exile",
                    result="ceased_to_exist",
                    reason="controller_left_game",
                    source=None,
                    player_departure_rule="CR 800.4a",
                )

    removed_by_zone = {
        zone_name: sum(1 for detail in owned_removed if detail["zone"] == zone_name)
        for zone_name in PLAYER_DEPARTURE_OBJECT_ZONES
    }
    return {
        # Compatibility fields retained for existing replay consumers.
        "battlefield_removed_from_game": removed_by_zone["battlefield"],
        "phased_out_removed_from_game": removed_by_zone["phased_out"],
        # Explicit CR 800.4a accounting for new consumers and audits.
        "owned_objects_removed_from_game": len(owned_removed),
        "owned_objects_removed_by_zone": removed_by_zone,
        "owned_objects_removed": owned_removed[:20],
        "temporary_control_returned_count": len(control_returned),
        "temporary_control_returned": control_returned[:20],
        "remaining_controlled_objects_exiled_count": len(controlled_exiled),
        "remaining_controlled_objects_exiled": controlled_exiled[:20],
        "nonowned_zone_objects_rehomed_count": len(nonowned_rehomed),
        "unresolved_owner_objects_removed_count": len(unresolved_owner_removed),
        "player_departure_rule": "CR 800.4a",
        "owned_object_zone_change_events_emitted": 0,
    }


def check_sbas(
    all_players,
    *,
    commander_damage_lethal_entries,
    numeric_stat,
    cancel_plus_minus_counters_func,
    check_illegal_attachments_func,
    check_saga_final_chapter_func,
    check_token_lifecycle_func,
    move_creature_from_battlefield,
    move_permanent_from_battlefield,
    move_permanent_from_battlefield_to_exile,
    move_to_exile,
    resolve_battle_back_face,
    is_battlefield_creature,
    is_planeswalker_permanent,
    is_battle_permanent,
    emit_replay_event,
    apply_loss_replacement_func=None,
):
    """State-based actions after each spell resolution."""
    for player_obj in all_players:
        if getattr(player_obj, "failed_draw_from_empty_library", False) and not player_obj.eliminated:
            if getattr(player_obj, "cannot_lose_this_turn", False):
                continue
            if apply_loss_replacement_func and apply_loss_replacement_func(
                player_obj,
                reason="draw_from_empty_library",
            ):
                player_obj.failed_draw_from_empty_library = False
                return True
            player_obj.life = 0
            player_obj.eliminated = True
            emit_replay_event(
                "player_eliminated",
                player=player_obj.name,
                reason="draw_from_empty_library",
                **remove_eliminated_player_objects(
                    player_obj,
                    all_players,
                    emit_replay_event=emit_replay_event,
                ),
            )
            return True
        if player_obj.life <= 0 and not player_obj.eliminated:
            if getattr(player_obj, "cannot_lose_this_turn", False):
                continue
            if apply_loss_replacement_func and apply_loss_replacement_func(
                player_obj,
                reason="life_zero",
            ):
                return True
            player_obj.eliminated = True
            emit_replay_event(
                "player_eliminated",
                player=player_obj.name,
                reason="life_zero",
                **remove_eliminated_player_objects(
                    player_obj,
                    all_players,
                    emit_replay_event=emit_replay_event,
                ),
            )
            return True
        if player_obj.eliminated:
            continue
        for name, dmg, source_key in commander_damage_lethal_entries(player_obj):
            for opponent in all_players:
                if opponent.name == name and not opponent.eliminated:
                    if getattr(opponent, "cannot_lose_this_turn", False):
                        continue
                    if apply_loss_replacement_func and apply_loss_replacement_func(
                        opponent,
                        reason="commander_damage",
                        commander_damage_key=source_key,
                        commander_damage=dmg,
                    ):
                        return True
                    opponent.life = 0
                    opponent.eliminated = True
                    emit_replay_event(
                        "player_eliminated",
                        player=opponent.name,
                        reason="commander_damage",
                        commander_damage_key=source_key,
                        commander_damage=dmg,
                        **remove_eliminated_player_objects(
                            opponent,
                            all_players,
                            emit_replay_event=emit_replay_event,
                        ),
                    )
                    return True

    for player_obj in all_players:
        if getattr(player_obj, "poison", 0) >= 10 and not player_obj.eliminated:
            if getattr(player_obj, "cannot_lose_this_turn", False):
                continue
            if apply_loss_replacement_func and apply_loss_replacement_func(
                player_obj,
                reason="poison",
            ):
                return True
            player_obj.life = 0
            player_obj.eliminated = True
            emit_replay_event(
                "player_eliminated",
                player=player_obj.name,
                reason="poison",
                **remove_eliminated_player_objects(
                    player_obj,
                    all_players,
                    emit_replay_event=emit_replay_event,
                ),
            )
            return True

    if cancel_plus_minus_counters_func(all_players):
        return True

    if check_illegal_attachments_func(all_players):
        return True

    if check_saga_final_chapter_func(all_players):
        return True

    for player_obj in all_players:
        for card in list(player_obj.battlefield):
            if not isinstance(card, dict):
                continue
            if not is_battlefield_creature(card):
                continue
            toughness = numeric_stat(card.get("toughness"))
            if toughness is None:
                toughness = 1
            damage = numeric_stat(card.get("damage_marked")) or 0
            if toughness <= 0 or (damage >= toughness and not card.get("indestructible")):
                move_creature_from_battlefield(player_obj, card, "sba_lethal", None, all_players)
                return True

    for player_obj in all_players:
        for permanent in list(player_obj.battlefield):
            if not isinstance(permanent, dict):
                continue
            if is_planeswalker_permanent(permanent) and int(permanent.get("loyalty", 0) or 0) <= 0:
                destination = move_permanent_from_battlefield(
                    player_obj,
                    permanent,
                    "planeswalker_loyalty_zero_sba",
                    None,
                    all_players,
                )
                emit_replay_event(
                    "permanent_moved_by_sba",
                    player=player_obj.name,
                    card=permanent.get("name", "?"),
                    permanent_type="planeswalker",
                    destination=destination,
                    reason="loyalty_zero",
                )
                return True
            if is_battle_permanent(permanent) and int(permanent.get("defense", 0) or 0) <= 0:
                token_ceased = is_token_object(permanent)
                destination = move_permanent_from_battlefield_to_exile(
                    player_obj,
                    permanent,
                    reason="battle_defeated",
                    source=permanent,
                )
                permanent["battle_defeated"] = True
                back_face = None if token_ceased else resolve_battle_back_face(player_obj, permanent)
                emit_replay_event(
                    "permanent_moved_by_sba",
                    player=player_obj.name,
                    card=permanent.get("name", "?"),
                    permanent_type="battle",
                    destination=destination,
                    reason="defense_zero",
                    back_face_cast=back_face.get("name", "?") if back_face else None,
                )
                return True

    legends = {}
    for player_obj in all_players:
        for card in list(player_obj.battlefield):
            if not isinstance(card, dict):
                continue
            if card.get("is_legendary") or "Legendary" in str(card.get("type_line", "")):
                key = card.get("name", card.get("card_name", ""))
                if not key:
                    continue
                if key in legends:
                    existing = legends[key]
                    if card.get("_bt", 0) > existing.get("_bt", 0):
                        move_creature_from_battlefield(
                            existing.get("_ctrl", player_obj),
                            existing,
                            "sba_legend",
                            None,
                            all_players,
                        )
                        legends[key] = card
                    else:
                        move_creature_from_battlefield(player_obj, card, "sba_legend", None, all_players)
                        return True
                else:
                    legends[key] = card

    if check_token_lifecycle_func(all_players):
        return True

    return False


def check_sbas_until_stable(all_players, *, check_sbas_func, record_engine_metric):
    """Loop SBAs until no more actions."""
    while check_sbas_func(all_players):
        record_engine_metric("sba_iterations")
