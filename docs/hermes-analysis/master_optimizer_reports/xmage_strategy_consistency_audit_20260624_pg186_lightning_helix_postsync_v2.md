# XMage Strategy Consistency Audit

- Status: `pass`
- Mutations performed: `[]`
- Summary: `{"check_count": 18, "status_counts": {"pass": 18}}`

| Check | Status | Detail |
| --- | --- | --- |
| `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py` | `pass` | contains=['import xmage_pattern_registry_builder as pattern_registry_builder', 'pattern_registry_builder.build_report', '_pattern_registry.json', 'pattern_status_counts'] |
| `docs/hermes-analysis/README.md` | `pass` | contains=['XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md', 'LOREHOLD_IDEAL_DECK_WORKFLOW_2026-06-24.md', 'hybrid_effective_queue_pattern_registry', 'pattern registry shadow-only'] |
| `docs/hermes-analysis/XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md` | `pass` | contains=['xmage_pattern_registry_builder.py', 'promotion_status=shadow_only', 'Regenerate the acceleration strategy benchmark', 'Build the shadow pattern registry'] |
| `docs/hermes-analysis/XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md` | `pass` | contains=['xmage_pattern_registry_builder.py', 'can_execute_in_battle=false', 'shadow pattern registry', 'hybrid_effective_queue_pattern_registry'] |
| `docs/hermes-analysis/LOREHOLD_IDEAL_DECK_WORKFLOW_2026-06-24.md` | `pass` | contains=['lorehold_ideal_deck_candidate_matrix.py', 'needs_rule_before_strategy', 'priority_benchmark_candidate', 'build_optimized_deck.py', 'universal_optimizer.py'] |
| `benchmark.recommended_strategy` | `pass` | hybrid_effective_queue_pattern_registry |
| `benchmark.hybrid_strategy_ranked` | `pass` | ["exact_scope_cluster_first", "hybrid_effective_queue_pattern_registry", "full_xmage_first", "pattern_registry_first", "runtime_exact_scope_first", "package_manifest_first", "card_by_card_queue", "test_miner_first"] |
| `benchmark.ranking_first` | `pass` | {"cards_per_work_unit": 21.0, "decision_score": 73.21, "strategy_id": "exact_scope_cluster_first", "verdict": "use_as_next_modeling_lane"} |
| `pattern_registry.promotion_status` | `pass` | shadow_only |
| `pattern_registry.executable_pattern_count` | `pass` | 0 |
| `pattern_registry.auto_promotable_pattern_count` | `pass` | 0 |
| `pattern_registry.unsafe_pattern_flags` | `pass` | none |
| `docs/hermes-analysis/master_optimizer_reports/xmage_pattern_registry_20260624_pg166_181_postsync_real_v2_schema_proposal.sql` | `pass` | contains=['CREATE TABLE IF NOT EXISTS public.xmage_pattern_registry', "promotion_status <> 'shadow_only'", 'can_execute_in_battle = FALSE', 'can_auto_promote_to_card_battle_rules = FALSE'] |
| `effective_queue.package_ready_unprepared` | `pass` | 0 |
| `effective_queue.package_already_prepared` | `pass` | 0 |
| `pipeline_manifest.expected_effective_deck_ids` | `pass` | [6, 58, 74, 105, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] |
| `pipeline_manifest.forced_include_deck_ids` | `pass` | [6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] |
| `pipeline_manifest.materialization_apply` | `pass` | local_sqlite_learned_decks=[58, 74, 105] |
