# Battle Runtime Surface Manifest

- Generated UTC: `2026-06-29T13:59:22Z`
- Total related Python files: `147`
- Unclassified files: `0`
- Recurring categories covered: `["core runtime", "recurring audit gate", "renderer", "rule registry/sync"]`
- Categories outside recurring run: `["core runtime", "focused evidence/promotion", "learned-deck source", "optimizer/scorecard", "recurring audit gate", "renderer", "review queue", "rule registry/sync"]`

## Category Counts

| Category | Files |
| --- | ---: |
| `core runtime` | `31` |
| `focused evidence/promotion` | `29` |
| `learned-deck source` | `16` |
| `optimizer/scorecard` | `19` |
| `recurring audit gate` | `30` |
| `renderer` | `4` |
| `review queue` | `1` |
| `rule registry/sync` | `17` |

## Automation Coverage Counts

| Coverage | Files |
| --- | ---: |
| `covered_by_recurring_run` | `31` |
| `imported_by_core_runtime` | `6` |
| `outside_recurring_run` | `110` |

## Rules Alignment

External source contract:

| Source | URL | Use |
| --- | --- | --- |
| `official_comprehensive_rules` | `https://magic.wizards.com/en/rules` | authoritative turn structure, priority, casting, stack, zones, SBAs, replacement/prevention, continuous effects, and keyword rules |
| `xmage` | `https://github.com/magefree/mage` | primary open implementation reference for card-level behavior and exact ability/effect decomposition |
| `forge` | `https://github.com/Card-Forge/forge` | secondary open implementation reference when XMage mapping is ambiguous or needs cross-checking |
| `scryfall` | `https://scryfall.com/docs/api` | Oracle text, rulings, legalities, identifiers, and bulk card data; not a rules executor |
| `mtgjson` | `https://mtgjson.com/` | portable bulk card metadata and cross-source identity checks; not a rules executor |
| `commander` | `https://mtgcommander.net/index.php/rules/` | Commander-specific deck construction, command zone, commander tax, and commander damage rules |

Rule area status counts:

| Status | Areas |
| --- | ---: |
| `covered_by_core_tests` | `4` |
| `covered_with_known_mode_gaps` | `1` |
| `covered_with_known_scope_limits` | `3` |
| `family_mapper_required` | `1` |
| `partial_family_specific_support` | `2` |

| Rule area | Rule refs | Status | Local files | Next gate |
| --- | --- | --- | --- | --- |
| `turn_priority_stack_casting_resolution` | `CR 117, CR 405, CR 500, CR 601, CR 608` | `covered_by_core_tests` | `battle_analyst_v9.py, battle_stack_casting_tests.py, battle_turn_flow_tests.py` | run stack/turn focused tests before changing priority, casting, or stack resolution |
| `mana_cost_payment_and_mana_abilities` | `CR 106, CR 107.4, CR 601.2f-h, CR 605` | `covered_with_known_mode_gaps` | `battle_analyst_v9.py, battle_mana_cost_support.py, battle_mana_tests.py` | add explicit mode executor tests before promoting alternate or sacrifice mana modes |
| `zones_lki_and_object_movement` | `CR 400, CR 608.2, CR 701` | `covered_by_core_tests` | `battle_zone_transition_support.py, battle_zone_transition_tests.py, battle_sba_zone_tests.py` | run zone transition and SBA zone tests before changing movement helpers |
| `state_based_actions` | `CR 704` | `covered_by_core_tests` | `battle_sba_support.py, battle_sba_zone_tests.py, battle_analyst_v9.py` | run SBA tests after any damage, counters, token, aura/equipment, or legendary handling change |
| `replacement_prevention_and_damage_life` | `CR 119, CR 120, CR 614, CR 615` | `covered_with_known_scope_limits` | `battle_replacement_support.py, battle_replacement_tests.py, battle_continuous_effects_tests.py` | cross-check replacement ordering against XMage/Forge when multiple replacement effects compete |
| `continuous_effect_layers` | `CR 613` | `partial_family_specific_support` | `battle_continuous_effects_tests.py, battle_card_characteristics_support.py, battle_analyst_v9.py` | do not claim generic layer engine; add family-specific tests for each promoted continuous effect |
| `combat_attack_block_damage` | `CR 506, CR 508, CR 509, CR 510` | `covered_by_core_tests` | `battle_combat_tests.py, battle_targeting_tests.py, battle_analyst_v9.py` | run combat tests before changing target pressure, blocker selection, combat damage, or restrictions |
| `triggered_abilities` | `CR 603` | `partial_family_specific_support` | `battle_event_trigger_tests.py, battle_analyst_v9.py, reviewed_battle_card_rules.py` | promote triggered families only after deterministic event contract and focused replay tests |
| `modal_targets_choices_and_copying` | `CR 115, CR 601.2b-d, CR 707` | `covered_with_known_scope_limits` | `battle_targeting_tests.py, battle_stack_casting_tests.py, test_reviewed_battle_card_rules.py` | require target legality, selected modes, and stack provenance tests for each modal/copy family |
| `commander_format` | `CR 903, Commander Rules` | `covered_with_known_scope_limits` | `battle_commander_tests.py, battle_stack_casting_tests.py, battle_analyst_v9.py` | verify command zone replacement, commander tax, color identity, and 21-damage lethal before deck/battle promotion |
| `card_specific_runtime_rules` | `Oracle text, XMage Mage.Sets, Forge forge-game` | `family_mapper_required` | `reviewed_battle_card_rules.py, battle_rule_registry.py, xmage_to_manaloom_effect_hints.py, xmage_semantic_family_classifier.py` | XMage/Oracle extraction creates review candidate; PG promotion requires focused test and safe lane |

## Files

| Path | Category | Owner | Role | Gate expected | Automation coverage |
| --- | --- | --- | --- | --- | --- |
| `docs/hermes-analysis/manaloom-knowledge/scripts/audit_handcrafted_battle_rule_canonicalization.py` | `rule registry/sync` | `battle-rule-registry` | `audit script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/audit_multi_rule_runtime_readiness.py` | `rule registry/sync` | `battle-rule-registry` | `audit script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_action_critic.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py` | `core runtime` | `battle-engine` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_acceleration_source_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_adjustment_throughput_benchmark.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_characteristics_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_import_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_combat_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_commander_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_conformance_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_continuous_effects_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_research_review.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_taxonomy_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_trace_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_residual_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_engine_metrics_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_contract_static_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_event_trigger_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_external_engine_crosscheck.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_focused_template_dispatch_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_land_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_cost_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mana_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_misc_regression_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_mtga_player_log_parser.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_permanents_complex_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replacement_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py` | `renderer` | `battle-replay-renderer` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rules_2026_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_sba_zone_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_stack_casting_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_summoning_sickness_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_table_intent_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_target_pressure_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_targeting_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_turn_flow_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_unknown_template_backlog_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_support.py` | `core runtime` | `battle-engine` | `support module` | `core_runtime_import_regression` | `imported_by_core_runtime` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/deck_card_battle_rule_coherence_audit.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/derive_functional_tags_from_battle_rules.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/export_hermes_learned_deck.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/external_card_rule_reference_harvester.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/learned_deck_completeness.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_optimizer_equal_gate.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_variant_battle_gate.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_baseline.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_common.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_confirmation.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_gate_baseline.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_handoff.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_post_apply_gate.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_quality_gate.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_rollback.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/materialize_learned_deck_to_deck_cards.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/mtg_battle_external_source_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py` | `recurring audit gate` | `battle-recurring-audit` | `script` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_battle_prior_compare.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_general_absorption_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_history_learning.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/seventeenlands_replay_profile.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py` | `rule registry/sync` | `battle-rule-registry` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_handcrafted_battle_rule_canonicalization.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_multi_rule_runtime_readiness.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_action_critic.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_cli_help.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py` | `core runtime` | `battle-engine` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_card_acceleration_source_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_card_adjustment_throughput_benchmark.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_research_review.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_trace_taxonomy_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_known_cards.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_effect_coverage_residual_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_event_contract_static_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_external_engine_crosscheck.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_focused_template_dispatch_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_functional_tags_json.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_mtga_player_log_parser.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_replay_v10_3_renderer.py` | `renderer` | `battle-replay-renderer` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_alternatives.py` | `core runtime` | `battle-engine` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_rule_registry_runtime_safe.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_runtime_surface_manifest.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_table_intent_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_target_pressure_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_unknown_template_backlog_audit.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_deck_card_battle_rule_coherence_audit.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_derive_functional_tags_from_battle_rules.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_metadata.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_export_hermes_learned_deck_wrapper_parity.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_external_card_rule_reference_harvester.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_learned_deck_completeness.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_optimizer_equal_gate.py` | `optimizer/scorecard` | `master-optimizer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_variant_battle_gate.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_gate_baseline.py` | `optimizer/scorecard` | `master-optimizer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_master_optimizer_hashes.py` | `optimizer/scorecard` | `master-optimizer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_materialize_learned_deck_to_deck_cards.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_mtg_battle_external_source_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_replay_decision_auditor_scope.py` | `recurring audit gate` | `battle-recurring-audit` | `test` | `recurring_audit_required` | `covered_by_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_reviewed_battle_card_rules.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_seventeenlands_battle_prior_compare.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_seventeenlands_general_absorption_audit.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_seventeenlands_history_learning.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_seventeenlands_replay_profile.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_slot_optimizer_real_roles.py` | `optimizer/scorecard` | `master-optimizer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_manual_preserve.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_sync_battle_card_rules_pg_selection.py` | `rule registry/sync` | `battle-rule-registry` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_universal_optimizer_known_cards.py` | `optimizer/scorecard` | `master-optimizer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_current_replay_batch_pipeline.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_local_rule_indexer.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py` | `optimizer/scorecard` | `master-optimizer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_local_rule_indexer.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/auto_promote_battle_rules.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/auto_promote_learned_decks.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/auto_sync_learned_decks.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/export_hermes_learned_deck.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/generate_card_replays.py` | `renderer` | `battle-replay-renderer` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/learned_deck_coherence_audit.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/manaloom_battle_rule_focused_evidence.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/manaloom_battle_rule_promotion_gate.py` | `focused evidence/promotion` | `battle-focused-evidence` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/manaloom_battle_rule_review_queue.py` | `review queue` | `server-rule-review-queue` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/plan_learned_deck_partner_identity_backfill.py` | `learned-deck source` | `learned-deck-pipeline` | `script` | `targeted_manual_gate_required_before_change` | `outside_recurring_run` |
| `server/bin/test_auto_promote_battle_rules.py` | `focused evidence/promotion` | `battle-focused-evidence` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `server/bin/test_battle_runtime_cli_paths.py` | `renderer` | `battle-replay-renderer` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `server/test/auto_promote_learned_decks_test.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `server/test/auto_sync_learned_decks_test.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `server/test/learned_deck_coherence_audit_test.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
| `server/test/plan_learned_deck_partner_identity_backfill_test.py` | `learned-deck source` | `learned-deck-pipeline` | `test` | `targeted_test_required_before_change` | `outside_recurring_run` |
