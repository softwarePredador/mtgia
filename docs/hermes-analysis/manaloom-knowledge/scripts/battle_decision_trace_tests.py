"""Decision trace v1 regression tests for Hermes battle replays."""


def register_tests(battle, replay_auditor):
    def test_emit_decision_trace_includes_chosen_option_and_scores():
        traces = []
        battle.DECISION_TRACE_HANDLER = traces.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = battle.Player("Trace Player", None, [])
            bolt = {
                "name": "Lightning Bolt",
                "cmc": 1,
                "type_line": "Instant",
                "effect": "deal_damage",
            }
            battle.emit_decision_trace(
                decision_type="cast_spell",
                player=active,
                turn=3,
                phase="precombat_main",
                available_options=[
                    battle.decision_card_option(bolt, {"effect": "deal_damage"}, score=25),
                ],
                chosen_option=battle.decision_card_option(bolt, {"effect": "deal_damage"}, score=25),
                rejected_options=[],
                score_components={"threat_score": 25, "cmc": 1},
                rule_source="known_cards_manual",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=25,
                actual_outcome="cast_to_stack",
            )
        finally:
            battle.DECISION_TRACE_HANDLER = None

        assert len(traces) == 1
        trace = traces[0]
        assert trace["schema_version"] == "decision_trace_v1"
        assert trace["decision_id"].endswith("000001")
        assert trace["chosen_option"]["card"] == "Lightning Bolt"
        assert trace["available_options"][0]["card"] == "Lightning Bolt"
        assert trace["score_components"]["threat_score"] == 25
        assert replay_auditor.audit_decision_traces(traces) == []

    def test_decision_trace_auditor_flags_missing_score_and_duplicate_id():
        decisions = [
            {
                "decision_id": "dup-1",
                "replay_id": "trace_test",
                "turn": 1,
                "phase": "combat",
                "player": "A",
                "decision_type": "combat_attack",
                "available_options": [{"action": "attack_player", "target": "B"}],
                "chosen_option": {"action": "attack_player", "target": "B"},
                "score_components": {},
                "rule_source": "battle_heuristic",
                "rule_status": "heuristic",
                "confidence": "medium",
                "expected_benefit_score": 3,
            },
            {
                "decision_id": "dup-1",
                "replay_id": "trace_test",
                "turn": 1,
                "phase": "combat",
                "player": "A",
                "decision_type": "combat_attack",
                "available_options": [{"action": "attack_player", "target": "C"}],
                "chosen_option": {"action": "attack_player", "target": "C"},
                "score_components": {"total_power": 3},
                "rule_source": "battle_heuristic",
                "rule_status": "heuristic",
                "confidence": "medium",
                "expected_benefit_score": 3,
            },
        ]

        findings = replay_auditor.audit_decision_traces(decisions)

        assert any("empty score_components" in finding["finding"] for finding in findings)
        assert any("Duplicate decision_id" in finding["finding"] for finding in findings)

    def test_decision_trace_auditor_flags_chosen_outside_options():
        decisions = [
            {
                "decision_id": "trace-1",
                "replay_id": "trace_test",
                "turn": 2,
                "phase": "precombat_main",
                "player": "A",
                "decision_type": "cast_spell",
                "available_options": [{"card": "Arcane Signet", "action": "cast"}],
                "chosen_option": {"card": "Boros Charm", "action": "cast"},
                "score_components": {"threat_score": 15},
                "rule_source": "known_cards_manual",
                "rule_status": "verified",
                "confidence": "medium",
                "expected_benefit_score": 15,
            }
        ]

        findings = replay_auditor.audit_decision_traces(decisions)

        assert any("Chosen option is not present" in finding["finding"] for finding in findings)

    return [
        test_emit_decision_trace_includes_chosen_option_and_scores,
        test_decision_trace_auditor_flags_missing_score_and_duplicate_id,
        test_decision_trace_auditor_flags_chosen_outside_options,
    ]
