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
        self.from_zone = from_zone
        self.to_zone = to_zone
        self.source = source
        self.reason = reason
        self.prevented = False
        self.replacements = []
        self.replacement_order = []
        self._applied_replacement_names = set()

    def mark_prevented(self, replacement):
        self.prevented = True
        self.amount = 0
        self.delta = 0
        self.replacements.append(replacement)

    def to_replay_fields(self):
        return {
            "replacement_pipeline": "replacement_prevention_minimal",
            "event_type": self.event_type,
            "affected_player": getattr(self.affected_player, "name", None),
            "card": self.card.get("name", "?") if isinstance(self.card, dict) else self.card,
            "amount": self.amount,
            "delta": self.delta,
            "from_zone": self.from_zone,
            "to_zone": self.to_zone,
            "source": self.source,
            "reason": self.reason,
            "prevented": self.prevented,
            "replacements": list(self.replacements),
            "replacement_order": list(self.replacement_order),
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
        if any((shield.get("amount", 0) or 0) > 0 for shield in getattr(player, "damage_prevention_shields", [])):
            candidates.append(("damage_prevention_shields", 30, ReplacementRegistry._consume_damage_prevention_shields))
        return candidates

    @staticmethod
    def _consume_damage_prevention_shields(event):
        shields = getattr(event.affected_player, "damage_prevention_shields", [])
        remaining_damage = event.amount
        kept_shields = []
        prevented_total = 0
        for shield in shields:
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
            if available > 0:
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


def deal_damage(player, amount, *, emit_replay_event=None):
    if amount <= 0:
        return False
    event = ReplacementRegistry.process_event(
        ReplacementEvent("damage", affected_player=player, amount=amount, delta=-amount),
        emit_replay_event=emit_replay_event,
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


def add_damage_prevention_shield(player, amount, source="prevention"):
    if amount <= 0:
        return False
    player.damage_prevention_shields.append({"amount": int(amount), "source": source})
    return True
