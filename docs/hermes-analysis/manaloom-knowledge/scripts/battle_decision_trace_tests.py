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
            helix = {
                "name": "Lightning Helix",
                "cmc": 2,
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
                    battle.decision_card_option(helix, {"effect": "deal_damage"}, score=19),
                ],
                chosen_option=battle.decision_card_option(bolt, {"effect": "deal_damage"}, score=25),
                rejected_options=[
                    battle.decision_card_option(helix, {"effect": "deal_damage"}, score=19),
                ],
                score_components={"threat_score": 25, "cmc": 1},
                rule_source="known_cards_manual",
                rule_status="verified",
                confidence="medium",
                expected_benefit_score=25,
                actual_outcome="cast_to_stack",
                expected_payoff_reason="remove blocker and push damage",
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
        assert trace["chosen_option_score"] == 25.0
        assert trace["best_rejected_option_score"] == 19.0
        assert trace["score_gap_vs_best_rejected"] == 6.0
        assert trace["expected_payoff_reason"] == "remove blocker and push damage"
        assert trace["available_option_scores"][0]["score"] == 25.0
        assert trace["rejected_option_scores"][0]["score"] == 19.0
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

    def test_decision_trace_auditor_flags_missing_comparative_fields_for_multi_option_choice():
        decisions = [
            {
                "decision_id": "trace-2",
                "replay_id": "trace_test",
                "turn": 4,
                "phase": "precombat_main",
                "player": "A",
                "decision_type": "cast_spell",
                "available_options": [
                    {"card": "Arcane Signet", "action": "cast"},
                    {"card": "Talisman of Conviction", "action": "cast"},
                ],
                "chosen_option": {"card": "Arcane Signet", "action": "cast"},
                "rejected_options": [{"card": "Talisman of Conviction", "action": "cast"}],
                "score_components": {"threat_score": 15},
                "rule_source": "known_cards_manual",
                "rule_status": "verified",
                "confidence": "medium",
                "expected_benefit_score": 15,
            }
        ]

        findings = replay_auditor.audit_decision_traces(decisions)

        assert any("missing chosen_option_score" in finding["finding"] for finding in findings)
        assert any("missing available_option_scores" in finding["finding"] for finding in findings)
        assert any("missing rejected_option_scores" in finding["finding"] for finding in findings)

    def test_approach_topdeck_setup_trace_is_auditable_without_hard_executor():
        traces = []
        previous_handler = battle.DECISION_TRACE_HANDLER
        battle.DECISION_TRACE_HANDLER = traces.append
        try:
            if hasattr(battle, "reset_decision_trace_counter"):
                battle.reset_decision_trace_counter()
            active = battle.Player("Lorehold Pilot", None, [])
            active.approach_count = 1
            approach = {
                "name": "Approach of the Second Sun",
                "cmc": 7,
                "type_line": "Sorcery",
            }
            top = {
                "name": "Sensei's Divining Top",
                "cmc": 1,
                "type_line": "Artifact",
            }
            scroll_rack = {
                "name": "Scroll Rack",
                "cmc": 2,
                "type_line": "Artifact",
            }
            brainstone = {
                "name": "Brainstone",
                "cmc": 1,
                "type_line": "Artifact",
            }

            approach_effect = battle.get_card_effect(approach)
            assert approach_effect["effect"] == "approach"
            assert approach_effect["gain_life"] == 7
            assert approach_effect["_rule_review_status"] == "active"

            def topdeck_option(card, score):
                effect = battle.get_card_effect(card)
                assert effect["effect"] == "topdeck_manipulation"
                assert effect["_rule_review_status"] in {"active", "verified"}
                return battle.decision_card_option(
                    card,
                    effect,
                    score=score,
                    action="prepare_approach_second_cast",
                    battle_model_scope=effect.get("battle_model_scope"),
                    rule_source=effect.get("_rule_source"),
                    rule_status=effect.get("_rule_review_status"),
                    rule_key=effect.get("_rule_logical_key"),
                )

            brainstone_option = topdeck_option(brainstone, 45)
            top_option = topdeck_option(top, 40)
            scroll_option = topdeck_option(scroll_rack, 35)

            battle.emit_decision_trace(
                decision_type="topdeck_setup",
                player=active,
                turn=6,
                phase="precombat_main",
                available_options=[brainstone_option, top_option, scroll_option],
                chosen_option=brainstone_option,
                rejected_options=[top_option, scroll_option],
                score_components={
                    "approach_already_resolved": active.approach_count,
                    "second_cast_win_line": 30,
                    "topdeck_setup_quality": 15,
                },
                rule_source=brainstone_option["rule_source"],
                rule_status=brainstone_option["rule_status"],
                confidence="medium",
                expected_benefit_score=45,
                actual_outcome="audit_only_setup_not_executed",
                reason="setup_approach_second_cast",
                expected_payoff_reason="prepare second Approach resolution without inventing a hard topdeck executor",
                strategic_principle="topdeck tools should be used when they materially improve a known win line",
                resource_delta={
                    "approach_count": active.approach_count,
                    "target_spell": "Approach of the Second Sun",
                },
                risk_flags=["topdeck_executor_not_hard_modeled"],
            )
        finally:
            battle.DECISION_TRACE_HANDLER = previous_handler

        assert len(traces) == 1
        trace = traces[0]
        assert trace["decision_type"] == "topdeck_setup"
        assert trace["chosen_option"]["card"] == "Brainstone"
        assert trace["chosen_option"]["battle_model_scope"] == "brainstone_draw_three_put_two_back_unexecuted_v1"
        assert trace["score_components"]["approach_already_resolved"] == 1
        assert trace["best_rejected_option_score"] == 40.0
        assert trace["score_gap_vs_best_rejected"] == 5.0
        assert trace["resource_delta"]["target_spell"] == "Approach of the Second Sun"
        assert trace["risk_flags"] == ["topdeck_executor_not_hard_modeled"]
        assert replay_auditor.audit_decision_traces(traces) == []

    return [
        test_emit_decision_trace_includes_chosen_option_and_scores,
        test_decision_trace_auditor_flags_missing_score_and_duplicate_id,
        test_decision_trace_auditor_flags_chosen_outside_options,
        test_decision_trace_auditor_flags_missing_comparative_fields_for_multi_option_choice,
        test_approach_topdeck_setup_trace_is_auditable_without_hard_executor,
    ]
