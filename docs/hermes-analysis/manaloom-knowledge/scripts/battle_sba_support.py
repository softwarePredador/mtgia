#!/usr/bin/env python3
"""State-based action helpers for the Hermes battle analyst."""


PLUS_ONE_COUNTER_KEYS = ("plus_one_counters", "plus1_counters", "+1/+1_counters")
MINUS_ONE_COUNTER_KEYS = ("minus_one_counters", "minus1_counters", "-1/-1_counters")


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
                player_obj.battlefield.remove(permanent)
                player_obj.graveyard.append(permanent)
                emit_replay_event(
                    "attachment_sba",
                    player=player_obj.name,
                    card=permanent.get("name"),
                    permanent_type="aura",
                    action="moved_to_graveyard",
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


def check_saga_final_chapter(all_players, *, numeric_stat, emit_replay_event):
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
            player_obj.battlefield.remove(permanent)
            player_obj.graveyard.append(permanent)
            emit_replay_event(
                "saga_sacrificed_by_sba",
                player=player_obj.name,
                card=permanent.get("name"),
                final_chapter=final_chapter,
            )
            return True
    return False


def check_token_lifecycle(all_players, *, emit_replay_event):
    """Token SBAs: tokens cease to exist outside battlefield."""
    removed = False
    for player_obj in all_players:
        for zone_attr in ["graveyard", "exile", "hand"]:
            zone = getattr(player_obj, zone_attr, [])
            for obj in list(zone):
                if isinstance(obj, dict) and (obj.get("is_token") or obj.get("tag") == "token"):
                    zone.remove(obj)
                    removed = True
                    emit_replay_event(
                        "token_ceased_to_exist",
                        player=player_obj.name,
                        zone=zone_attr,
                        token=obj.get("name"),
                    )
    return removed


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
    move_to_exile,
    resolve_battle_back_face,
    is_planeswalker_permanent,
    is_battle_permanent,
    emit_replay_event,
):
    """State-based actions after each spell resolution."""
    for player_obj in all_players:
        if getattr(player_obj, "failed_draw_from_empty_library", False) and not player_obj.eliminated:
            player_obj.life = 0
            player_obj.eliminated = True
            emit_replay_event("player_eliminated", player=player_obj.name, reason="draw_from_empty_library")
            return True
        if player_obj.life <= 0 and not player_obj.eliminated:
            player_obj.eliminated = True
            emit_replay_event("player_eliminated", player=player_obj.name, reason="life_zero")
            return True
        if player_obj.eliminated:
            continue
        for name, dmg, source_key in commander_damage_lethal_entries(player_obj):
            for opponent in all_players:
                if opponent.name == name and not opponent.eliminated:
                    opponent.life = 0
                    opponent.eliminated = True
                    emit_replay_event(
                        "player_eliminated",
                        player=opponent.name,
                        reason="commander_damage",
                        commander_damage_key=source_key,
                        commander_damage=dmg,
                    )
                    return True

    for player_obj in all_players:
        if getattr(player_obj, "poison", 0) >= 10 and not player_obj.eliminated:
            player_obj.life = 0
            player_obj.eliminated = True
            emit_replay_event("player_eliminated", player=player_obj.name, reason="poison")
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
            toughness = card.get("toughness", 1)
            damage = card.get("damage_marked", 0)
            if (toughness <= 0 or damage >= toughness) and not card.get("indestructible"):
                move_creature_from_battlefield(player_obj, card, "sba_lethal", None, all_players)
                return True

    for player_obj in all_players:
        for permanent in list(player_obj.battlefield):
            if not isinstance(permanent, dict):
                continue
            if is_planeswalker_permanent(permanent) and int(permanent.get("loyalty", 0) or 0) <= 0:
                player_obj.battlefield.remove(permanent)
                player_obj.graveyard.append(permanent)
                emit_replay_event(
                    "permanent_moved_by_sba",
                    player=player_obj.name,
                    card=permanent.get("name", "?"),
                    permanent_type="planeswalker",
                    destination="graveyard",
                    reason="loyalty_zero",
                )
                return True
            if is_battle_permanent(permanent) and int(permanent.get("defense", 0) or 0) <= 0:
                player_obj.battlefield.remove(permanent)
                move_to_exile(player_obj, permanent, reason="battle_defeated")
                permanent["battle_defeated"] = True
                back_face = resolve_battle_back_face(player_obj, permanent)
                emit_replay_event(
                    "permanent_moved_by_sba",
                    player=player_obj.name,
                    card=permanent.get("name", "?"),
                    permanent_type="battle",
                    destination="exile",
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
