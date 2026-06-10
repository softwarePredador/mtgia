"""Miscellaneous battle regressions not large enough for dedicated domains."""

import random


def register_tests(battle, player, replay_auditor):
    def test_classify_loss_covers_poison_effect_and_concede_tags():
        loser = player("Loser")
        loser.poison = 10
        loser.lost_by_effect = True
        loser.conceded = True

        tags = battle.classify_loss(loser, [], turn=5, result="loss", reason="test")

        assert tags[:3] == ["concede", "effect_says_lose", "poison"]
        assert battle.classify_loss(loser, [], turn=5, result="win", reason="test") == []

    def test_token_maker_counts_dict_lands_for_land_based_tokens():
        active = player("Active")
        active.battlefield = [
            {"name": "Plains", "type_line": "Basic Land — Plains", "effect": "land"},
            {"name": "Mountain", "type_line": "Basic Land — Mountain", "effect": "land"},
            {"name": "Arcane Signet", "type_line": "Artifact", "effect": "ramp_permanent"},
        ]
        previous = battle.KNOWN_CARDS.get("Land Count Token Maker")
        was_handcrafted = "Land Count Token Maker" in battle.HANDCRAFTED_KNOWN_CARDS
        try:
            battle.KNOWN_CARDS["Land Count Token Maker"] = {
                "effect": "token_maker",
                "token_count": "lands",
                "token_power": 1,
            }
            battle.HANDCRAFTED_KNOWN_CARDS.add("Land Count Token Maker")
            battle.apply_effect_immediate(
                active,
                [],
                {"name": "Land Count Token Maker", "cmc": 4, "type_line": "Sorcery"},
                6,
                random.Random(43),
            )
            tokens = [
                card
                for card in active.battlefield
                if isinstance(card, dict) and card.get("name") == "Token"
            ]
            assert len(tokens) == 2
        finally:
            if previous is None:
                battle.KNOWN_CARDS.pop("Land Count Token Maker", None)
            else:
                battle.KNOWN_CARDS["Land Count Token Maker"] = previous
            if not was_handcrafted:
                battle.HANDCRAFTED_KNOWN_CARDS.discard("Land Count Token Maker")

    def test_lumra_returns_milled_and_graveyard_lands_tapped():
        active = player("Lumra")
        active.battlefield = [
            {"name": "Forest", "type_line": "Basic Land — Forest", "effect": "land"},
            {"name": "Mosswort Bridge", "type_line": "Land", "effect": "land"},
        ]
        active.graveyard = [
            {"name": "Fabled Passage", "type_line": "Land", "effect": "land"},
            {"name": "Cultivate", "type_line": "Sorcery", "effect": "ramp_permanent"},
        ]
        active.library = [
            {"name": "Boseiju, Who Endures", "type_line": "Legendary Land", "effect": "land"},
            {"name": "Rampant Growth", "type_line": "Sorcery", "effect": "ramp_permanent"},
            {"name": "Yavimaya, Cradle of Growth", "type_line": "Legendary Land", "effect": "land"},
            {"name": "Explore", "type_line": "Sorcery", "effect": "draw_cards"},
        ]
        lumra = {
            "name": "Lumra, Bellow of the Woods",
            "cmc": 6,
            "type_line": "Legendary Creature — Elemental Bear",
            "oracle_text": "Vigilance, reach\nLumra's power and toughness are each equal to the number of lands you control.\nWhen Lumra enters, mill four cards. Then return all land cards from your graveyard to the battlefield tapped.",
        }

        battle.apply_effect_immediate(active, [], lumra, 4, random.Random(40))

        permanent = next(
            card
            for card in active.battlefield
            if isinstance(card, dict) and card.get("name") == "Lumra, Bellow of the Woods"
        )
        returned_names = {
            card.get("name")
            for card in active.battlefield
            if isinstance(card, dict) and card.get("tapped")
        }
        assert {"Fabled Passage", "Boseiju, Who Endures", "Yavimaya, Cradle of Growth"} <= returned_names
        assert permanent["power"] == 5
        assert permanent["toughness"] == 5
        assert permanent["summoning_sick"] is True

    def test_protected_player_prevents_combat_damage_without_audit_finding():
        events = []
        battle.REPLAY_EVENT_HANDLER = (
            lambda event, data: events.append({"event": event, "replay_id": "protected", **data})
        )
        attacker = player("Attacker")
        defender = player("Defender")
        defender.life = 1
        defender.life_cant_change = True
        defender.protection_from_everything = True
        attacker.battlefield = [
            {
                "name": "Unblocked Attacker",
                "effect": "creature",
                "power": 5,
                "toughness": 5,
                "summoning_sick": False,
                "tapped": False,
            }
        ]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=4,
            rng=random.Random(43),
            stack=battle.Stack(),
        )

        combat_result = next(event for event in events if event["event"] == "combat_result")
        assert defender.life == 1
        assert combat_result["damage_to_player"] == 0
        assert combat_result["target_protection_from_everything"] is True
        findings = replay_auditor.audit_turn_events(events)
        assert not [
            finding
            for finding in findings
            if "Unblocked combat dealt 0" in finding["finding"]
            or "Unblocked lethal-looking combat" in finding["finding"]
        ]

    def test_auditor_flags_noncreature_land_attacker():
        events = [
            {
                "event": "combat",
                "replay_id": "land_bug",
                "turn": 2,
                "attacker": "Player A",
                "target": "Player B",
                "attackers_detail": [
                    {
                        "name": "Forest",
                        "type_line": "Land",
                        "tapped": True,
                        "summoning_sick": False,
                        "keywords": [],
                    }
                ],
            }
        ]

        findings = replay_auditor.audit_turn_events(events)

        assert any("Non-creature land attacked" in finding["finding"] for finding in findings)

    def test_zero_power_creature_without_attack_trigger_does_not_attack():
        events = []
        battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
        attacker = player("Attacker")
        defender = player("Defender")
        attacker.battlefield = [
            {
                "name": "Birds of Paradise",
                "effect": "creature",
                "type_line": "Creature — Bird",
                "power": 0,
                "toughness": 1,
                "summoning_sick": False,
                "tapped": False,
            }
        ]

        battle.combat_phase_v8(
            attacker,
            [defender],
            [attacker, defender],
            turn=3,
            rng=random.Random(44),
            stack=battle.Stack(),
        )

        assert not [event for event, _ in events if event == "combat"]
        assert attacker.battlefield[0]["tapped"] is False
        assert defender.life == 40

    return [
        test_classify_loss_covers_poison_effect_and_concede_tags,
        test_token_maker_counts_dict_lands_for_land_based_tokens,
        test_lumra_returns_milled_and_graveyard_lands_tapped,
        test_protected_player_prevents_combat_damage_without_audit_finding,
        test_auditor_flags_noncreature_land_attacker,
        test_zero_power_creature_without_attack_trigger_does_not_attack,
    ]
