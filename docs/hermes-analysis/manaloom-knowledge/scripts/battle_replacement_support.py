#!/usr/bin/env python3
"""Replacement/prevention helpers for the Hermes battle analyst."""


class ReplacementEvent:
    """Minimal replacement/prevention event used before mutating game state."""

    def __init__(
        self,
        event_type,
        *,
        affected_player=None,
        card=None,
        amount=0,
        delta=0,
        from_zone=None,
        to_zone=None,
        source=None,
        reason=None,
    ):
        self.event_type = event_type
        self.affected_player = affected_player
        self.card = card
        self.amount = amount
        self.delta = delta
        self.original_amount = amount
        self.original_delta = delta
        self.from_zone = from_zone
        self.to_zone = to_zone
        self.original_from_zone = from_zone
        self.original_to_zone = to_zone
        self.source = source
        self.reason = reason
        self.prevented = False
        self.replacements = []
        self.replacement_order = []
        self.reflections = []
        self._applied_replacement_names = set()

    def mark_prevented(self, replacement):
        self.prevented = True
        self.amount = 0
        self.delta = 0
        self.replacements.append(replacement)

    @staticmethod
    def _source_field(source, *keys):
        if not isinstance(source, dict):
            return None
        for key in keys:
            value = source.get(key)
            if value not in (None, ""):
                return value
        return None

    @staticmethod
    def _source_name(source):
        if isinstance(source, dict):
            return (
                source.get("name")
                or source.get("card_name")
                or source.get("oracle_id")
                or source.get("id")
            )
        return source

    @staticmethod
    def _source_controller(source):
        if isinstance(source, dict):
            return source.get("controller") or source.get("owner")
        return None

    def _replacement_rule_source(self, replacement):
        name = str(replacement).split(":", 1)[0]
        player = self.affected_player
        if name == "life_total_cant_change":
            return (
                self._source_name(getattr(player, "life_cant_change_source", None))
                or "life_total_cant_change"
            )
        if name == "protection_from_everything":
            return (
                self._source_name(getattr(player, "protection_from_everything_source", None))
                or "protection_from_everything"
            )
        if name == "damage_life_floor":
            return "damage_life_floor"
        if name == "damage_prevention_shield":
            parts = str(replacement).split(":")
            return parts[1] if len(parts) > 1 and parts[1] else "damage_prevention_shield"
        if name == "commander_to_command_zone":
            return "commander_replacement_rule"
        return name

    def _inferred_reason(self):
        if self.reason:
            return self.reason
        if not self.replacements:
            return None
        replacement = str(self.replacements[0]).split(":", 1)[0]
        if self.event_type == "zone_change" and replacement == "commander_to_command_zone":
            return "commander_zone_replacement"
        if self.prevented:
            return f"prevention:{replacement}"
        return f"replacement:{replacement}"

    def to_replay_fields(self):
        replacement_sources = [
            self._replacement_rule_source(replacement)
            for replacement in self.replacements
        ]
        source_name = self._source_name(self.source) or (replacement_sources[0] if replacement_sources else None)
        reason = self._inferred_reason()
        causal_event = {
            "event_type": self.event_type,
            "reason": reason,
            "source": source_name,
            "from_zone": self.from_zone,
            "to_zone": self.to_zone,
            "original_from_zone": self.original_from_zone,
            "original_to_zone": self.original_to_zone,
            "final_from_zone": self.from_zone,
            "final_to_zone": self.to_zone,
            "original_amount": self.original_amount,
            "final_amount": self.amount,
            "original_delta": self.original_delta,
            "final_delta": self.delta,
            "replacements": list(self.replacements),
            "replacement_rule_sources": list(replacement_sources),
            "reflections": [
                {
                    "target_player": getattr(reflection.get("target_player"), "name", None),
                    "amount": reflection.get("amount"),
                    "source": self._source_name(reflection.get("source")),
                    "source_controller": self._source_controller(reflection.get("source")),
                    "reflect_card": self._source_name(reflection.get("reflect_card")),
                }
                for reflection in self.reflections
            ],
        }
        return {
            "replacement_pipeline": "replacement_prevention_minimal",
            "event_type": self.event_type,
            "affected_player": getattr(self.affected_player, "name", None),
            "card": self.card.get("name", "?") if isinstance(self.card, dict) else self.card,
            "amount": self.amount,
            "delta": self.delta,
            "original_amount": self.original_amount,
            "final_amount": self.amount,
            "original_delta": self.original_delta,
            "final_delta": self.delta,
            "original_from_zone": self.original_from_zone,
            "original_to_zone": self.original_to_zone,
            "final_from_zone": self.from_zone,
            "final_to_zone": self.to_zone,
            "from_zone": self.from_zone,
            "to_zone": self.to_zone,
            "source": source_name,
            "source_card_id": self._source_field(self.source, "card_id", "id"),
            "source_controller": self._source_field(self.source, "controller", "owner"),
            "source_effect": self._source_field(self.source, "effect"),
            "source_type_line": self._source_field(self.source, "type_line"),
            "source_semantic_hash": self._source_field(self.source, "semantic_hash"),
            "reason": reason,
            "causal_event": causal_event,
            "prevented": self.prevented,
            "replacements": list(self.replacements),
            "replacement_order": list(self.replacement_order),
            "replacement_rule_source": replacement_sources[0] if replacement_sources else None,
            "replacement_rule_sources": list(replacement_sources),
            "reflections": causal_event["reflections"],
        }


class ReplacementRegistry:
    """Deterministic replacement/prevention processor (CR 614-616/615)."""

    emit_replay_event = staticmethod(lambda *args, **kwargs: None)

    @staticmethod
    def process_event(event, *, emit_replay_event=None):
        while True:
            candidate = ReplacementRegistry._choose_next_effect(event)
            if candidate is None:
                break
            name, _, apply_fn = candidate
            event._applied_replacement_names.add(name)
            event.replacement_order.append(name)
            apply_fn(event)
            if event.prevented:
                break
        if event.replacements:
            emitter = emit_replay_event or ReplacementRegistry.emit_replay_event
            emitter(
                "replacement_applied",
                **event.to_replay_fields(),
            )
        return event

    @staticmethod
    def _choose_next_effect(event):
        candidates = [
            candidate
            for candidate in ReplacementRegistry._find_applicable(event)
            if candidate[0] not in event._applied_replacement_names
        ]
        if not candidates:
            return None
        candidates.sort(key=lambda candidate: (candidate[1], candidate[0]))
        return candidates[0]

    @staticmethod
    def _find_applicable(event):
        if event.event_type == "damage":
            return ReplacementRegistry._damage_replacement_candidates(event)
        if event.event_type == "life_change":
            return ReplacementRegistry._life_change_replacement_candidates(event)
        if event.event_type == "zone_change":
            return ReplacementRegistry._zone_change_replacement_candidates(event)
        return []

    @staticmethod
    def _damage_replacement_candidates(event):
        player = event.affected_player
        if player is None or event.amount <= 0:
            return []
        candidates = []
        if player.life_cant_change:
            candidates.append(
                ("life_total_cant_change", 10, lambda current: current.mark_prevented("life_total_cant_change"))
            )
        if player.protection_from_everything:
            candidates.append(
                ("protection_from_everything", 20, lambda current: current.mark_prevented("protection_from_everything"))
            )
        damage_floor = getattr(player, "damage_life_floor", None)
        if damage_floor is not None:
            candidates.append(("damage_life_floor", 25, ReplacementRegistry._apply_damage_life_floor))
        if any((shield.get("amount", 0) or 0) > 0 for shield in getattr(player, "damage_prevention_shields", [])):
            candidates.append(("damage_prevention_shields", 30, ReplacementRegistry._consume_damage_prevention_shields))
        return candidates

    @staticmethod
    def _apply_damage_life_floor(event):
        player = event.affected_player
        floor = getattr(player, "damage_life_floor", None)
        if floor is None:
            return
        current_life = int(getattr(player, "life", 0) or 0)
        allowed_damage = max(0, current_life - int(floor))
        if event.amount <= allowed_damage:
            return
        prevented = max(0, event.amount - allowed_damage)
        event.amount = allowed_damage
        event.delta = -allowed_damage
        event.replacements.append(f"damage_life_floor:{floor}:{prevented}")
        if allowed_damage <= 0:
            event.prevented = True

    @staticmethod
    def _consume_damage_prevention_shields(event):
        shields = getattr(event.affected_player, "damage_prevention_shields", [])
        remaining_damage = event.amount
        kept_shields = []
        prevented_total = 0
        for shield in shields:
            if not ReplacementRegistry._shield_matches_damage_source(shield, event.source):
                kept_shields.append(shield)
                continue
            try:
                available = int(shield.get("amount", 0))
            except (TypeError, ValueError):
                available = 0
            if available <= 0 or remaining_damage <= 0:
                if available > 0:
                    kept_shields.append(shield)
                continue
            prevented = min(available, remaining_damage)
            prevented_total += prevented
            remaining_damage -= prevented
            available -= prevented
            source = shield.get("source", "prevention_shield")
            event.replacements.append(f"damage_prevention_shield:{source}:{prevented}")
            reflect_player = shield.get("reflect_to_player")
            if reflect_player is not None and prevented > 0:
                event.reflections.append(
                    {
                        "target_player": reflect_player,
                        "amount": prevented,
                        "source": event.source,
                        "reflect_card": shield.get("reflect_card"),
                        "reflect_source": source,
                        "turn": shield.get("turn"),
                    }
                )
            if available > 0 and not shield.get("consume_once"):
                updated = dict(shield)
                updated["amount"] = available
                kept_shields.append(updated)
        event.affected_player.damage_prevention_shields = kept_shields
        if prevented_total:
            event.amount = remaining_damage
            event.delta = -remaining_damage
            if remaining_damage <= 0:
                event.prevented = True

    @staticmethod
    def _shield_matches_damage_source(shield, damage_source):
        mode = shield.get("source_match")
        if mode in (None, "", "any"):
            return True
        if mode != "chosen_source":
            return True
        chosen_name = shield.get("chosen_source_name")
        chosen_controller = shield.get("chosen_source_controller")
        source_name = ReplacementEvent._source_name(damage_source)
        source_controller = ReplacementEvent._source_controller(damage_source)
        if chosen_name and str(chosen_name) != str(source_name):
            return False
        if chosen_controller and str(chosen_controller) != str(source_controller):
            return False
        return True

    @staticmethod
    def _life_change_replacement_candidates(event):
        player = event.affected_player
        if player is None or not event.delta:
            return []
        candidates = []
        if player.life_cant_change:
            candidates.append(
                ("life_total_cant_change", 10, lambda current: current.mark_prevented("life_total_cant_change"))
            )
        if player.protection_from_everything:
            candidates.append(
                ("protection_from_everything", 20, lambda current: current.mark_prevented("protection_from_everything"))
            )
        return candidates

    @staticmethod
    def _zone_change_replacement_candidates(event):
        card = event.card
        if not isinstance(card, dict) or not card.get("is_commander"):
            return []
        if event.to_zone not in ("graveyard", "exile", "hand", "library"):
            return []
        choice = card.get("commander_replacement_choice", "command_zone")
        if choice == event.to_zone:
            return []
        return [("commander_to_command_zone", 10, ReplacementRegistry._apply_commander_zone_replacement)]

    @staticmethod
    def _apply_commander_zone_replacement(event):
        event.to_zone = "command_zone"
        event.replacements.append("commander_to_command_zone")


def change_life(player, delta, *, emit_replay_event=None):
    event = ReplacementRegistry.process_event(
        ReplacementEvent("life_change", affected_player=player, delta=delta),
        emit_replay_event=emit_replay_event,
    )
    if event.prevented or not event.delta:
        return False
    player.life += event.delta
    return True


def deal_damage(player, amount, *, emit_replay_event=None, source=None):
    if amount <= 0:
        return False
    event = ReplacementRegistry.process_event(
        ReplacementEvent(
            "damage",
            affected_player=player,
            amount=amount,
            delta=-amount,
            source=source,
        ),
        emit_replay_event=emit_replay_event,
    )
    for reflection in list(event.reflections):
        reflect_player = reflection.get("target_player")
        reflect_amount = int(reflection.get("amount") or 0)
        if reflect_player is None or reflect_amount <= 0:
            continue
        reflect_source = reflection.get("reflect_card") or {
            "name": reflection.get("reflect_source") or "damage_prevention_reflection"
        }
        reflected_event = ReplacementRegistry.process_event(
            ReplacementEvent(
                "damage",
                affected_player=reflect_player,
                amount=reflect_amount,
                delta=-reflect_amount,
                source=reflect_source,
                reason="damage_reflection",
            ),
            emit_replay_event=emit_replay_event,
        )
        dealt_reflected = False
        if not reflected_event.prevented and reflected_event.amount > 0:
            reflect_player.life -= reflected_event.amount
            dealt_reflected = True
        if emit_replay_event is not None:
            emit_replay_event(
                "damage_reflected",
                affected_player=getattr(event.affected_player, "name", None),
                target_player=getattr(reflect_player, "name", None),
                amount=reflect_amount,
                damage_dealt=reflected_event.amount if dealt_reflected else 0,
                prevented=not dealt_reflected,
                source=ReplacementEvent._source_name(reflection.get("source")),
                source_controller=ReplacementEvent._source_controller(reflection.get("source")),
                reflect_card=ReplacementEvent._source_name(reflect_source),
                turn=reflection.get("turn"),
            )
    if event.prevented or event.amount <= 0:
        return False
    player.life -= event.amount
    return True


def gain_life(player, amount, cap=40, *, emit_replay_event=None):
    if amount <= 0:
        return False
    event = ReplacementRegistry.process_event(
        ReplacementEvent("life_change", affected_player=player, delta=amount),
        emit_replay_event=emit_replay_event,
    )
    if event.prevented or event.delta <= 0:
        return False
    player.life = min(cap, player.life + event.delta)
    return True


def add_damage_prevention_shield(player, amount, source="prevention", **metadata):
    if amount <= 0:
        return False
    shield = {"amount": int(amount), "source": source}
    shield.update({key: value for key, value in metadata.items() if value is not None})
    player.damage_prevention_shields.append(shield)
    return True
