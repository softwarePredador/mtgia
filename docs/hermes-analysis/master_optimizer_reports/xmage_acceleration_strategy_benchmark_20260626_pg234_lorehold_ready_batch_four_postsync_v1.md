# XMage Acceleration Strategy Benchmark

- Generated at: `2026-06-26T08:25:24+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Sources

- `proposal_report`: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg234_lorehold_ready_batch_four_postsync_v1_proposals.json`
- `effective_queue_report`: `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg234_lorehold_ready_batch_four_postsync_v1.json`
- `inventory_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.json`
- `test_miner_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_targeted_damage_20260624.json`

## Summary

- Proposal count: `396`
- Strategy count: `8`
- Recommended strategy: `hybrid_effective_queue_pattern_registry`
- Recommended score: `67.17`

## Ranking

| Rank | Strategy | Verdict | Score | Cards/unit |
| --- | --- | --- | ---: | ---: |
| 1 | `exact_scope_cluster_first` | `use_as_next_modeling_lane` | 72.28 | 19.0 |
| 2 | `hybrid_effective_queue_pattern_registry` | `recommended` | 67.17 | 5.25 |
| 3 | `package_manifest_first` | `use_immediately_with_pg_approval` | 49.44 | 1.0 |
| 4 | `full_xmage_first` | `reject_as_primary` | 45.56 | 0.012 |
| 5 | `pattern_registry_first` | `use_as_shadow_infrastructure` | 43.71 | 0.023 |
| 6 | `card_by_card_queue` | `reject_as_default` | 42.0 | 1.0 |
| 7 | `runtime_exact_scope_first` | `use_selectively` | 40.18 | 1.0 |
| 8 | `test_miner_first` | `use_as_evidence_gate_not_primary_queue` | 36.61 | 0.333 |

## Strategy Evidence

### exact_scope_cluster_first

- Title: Batch the largest exact split-scope clusters
- Verdict: `use_as_next_modeling_lane`
- Immediate cards: `19`
- Work units: `1`
- Decision score: `72.28`
- Cards per work unit: `19.0`
- Confidence/reuse/risk: `74` / `82` / `42`
- Next action: Split the top scope into subpatterns before PG promotion; targeted_damage_variant_v1 is useful as a queue, not as one executable behavior.
- Evidence:
  - `split_scope_backlog`: 61
  - `split_scope_unique_scope_count`: 19
  - `top_scope`: {"battle_model_scope": "targeted_damage_variant_v1", "cards": ["Balefire Liege", "Boros Reckoner", "Brash Taunter", "Cemetery Gatekeeper", "Eiganjo, Seat of the Empire", "Firesong and Sunspeaker", "Gleeful Arsonist", "Harsh Mentor", "Kederekt Parasite", "Mayhem Devil", "Mogis, God of Slaughter", "Niv-Mizzet, Parun", "Rampaging Ferocidon", "Repercussion", "Spiteful Visions", "Terror of the Peaks", "The Lord of Pain", "Toralf, God of Fury // Toralf's Hammer", "Valakut, the Molten Pinnacle"], "count": 19, "effect": "direct_damage", "family_id": "targeted_interaction"}
  - `test_miner`: {"cards_with_test_reference": 7, "reference_ratio": 0.3333, "requested_card_count": 21, "usable_ratio": 0.0952, "usable_scenario_candidate_count": 2}

### hybrid_effective_queue_pattern_registry

- Title: Hybrid: package gate, exact-scope clusters, test miner, and pattern registry
- Verdict: `recommended`
- Immediate cards: `21`
- Work units: `4`
- Decision score: `67.17`
- Cards per work unit: `5.25`
- Confidence/reuse/risk: `84` / `90` / `34`
- Next action: Adopt as the project instruction: no broad card-by-card loop while package, exact-scope, or runtime-homogeneous lanes remain.
- Evidence:
  - `package_cards_removed_from_modeling`: 1
  - `top_split_scope_cards`: 19
  - `top_runtime_scope_cards`: 1
  - `test_miner`: {"cards_with_test_reference": 7, "reference_ratio": 0.3333, "requested_card_count": 21, "usable_ratio": 0.0952, "usable_scenario_candidate_count": 2}
  - `why`: Combines immediate duplicate-work removal with reusable pattern creation and runtime gates.

### package_manifest_first

- Title: Stop rebuilding prepared PG packages and apply them through gates
- Verdict: `use_immediately_with_pg_approval`
- Immediate cards: `1`
- Work units: `1`
- Decision score: `49.44`
- Cards per work unit: `1.0`
- Confidence/reuse/risk: `86` / `63` / `32`
- Next action: Do not remodel these cards; move them through the PostgreSQL governance gate when approved.
- Evidence:
  - `pg_ready_total`: 1
  - `package_already_prepared`: 1
  - `package_ready_unprepared`: 0
  - `package_ready_sample_cards`: ["Purphoros, God of the Forge"]
  - `prepared_package_count`: 1
  - `required_gate`: precheck, approved apply, postcheck, PG->Hermes sync, focused audit

### full_xmage_first

- Title: Analyze/port the whole XMage corpus before queue work
- Verdict: `reject_as_primary`
- Immediate cards: `396`
- Work units: `31706`
- Decision score: `45.56`
- Cards per work unit: `0.012`
- Confidence/reuse/risk: `62` / `92` / `88`
- Next action: Use full inventory as reference only; do not block deck closure on global analysis.
- Evidence:
  - `card_implementation_files`: 31706
  - `java_files_total`: 38739
  - `current_queue_cards`: 396
  - `work_multiplier_vs_current_queue`: 80.07
  - `source_basis`: local XMage inventory plus official XMage repository structure

### pattern_registry_first

- Title: Create a persistent pattern registry before broad manual mapping
- Verdict: `use_as_shadow_infrastructure`
- Immediate cards: `65`
- Work units: `2811`
- Decision score: `43.71`
- Cards per work unit: `0.023`
- Confidence/reuse/risk: `70` / `96` / `58`
- Next action: Seed patterns incrementally from approved clusters; do not wait for a complete global registry.
- Evidence:
  - `effect_files`: 802
  - `test_files`: 2009
  - `candidate_cards_for_pattern_learning`: 65
  - `manual_mapper_backlog`: 326
  - `database_boundary`: registry may persist templates/observations, but executable rules remain gated in card_battle_rules

### card_by_card_queue

- Title: Inspect each current proposal card independently
- Verdict: `reject_as_default`
- Immediate cards: `396`
- Work units: `396`
- Decision score: `42.0`
- Cards per work unit: `1.0`
- Confidence/reuse/risk: `68` / `18` / `55`
- Next action: Keep as fallback for exception cards only.
- Evidence:
  - `current_queue_cards`: 396
  - `proposal_status_counts`: {"blocked_missing_xmage_source": 4, "mapper_metadata_or_test_scenario_required": 326, "partial_batch_pg_candidate_preserve_shadow_rows_after_precheck": 1, "runtime_family_implementation_required": 4, "split_family_scope_review_required": 61}
  - `reason`: Every card can eventually be handled, but each unit produces little reusable knowledge.

### runtime_exact_scope_first

- Title: Open runtime only for homogeneous exact scopes
- Verdict: `use_selectively`
- Immediate cards: `1`
- Work units: `1`
- Decision score: `40.18`
- Cards per work unit: `1.0`
- Confidence/reuse/risk: `78` / `65` / `70`
- Next action: Start with damage_all/destroy_all scopes; defer token_maker until taxonomy support exists.
- Evidence:
  - `runtime_backlog`: 4
  - `runtime_unique_scope_count`: 4
  - `top_runtime_scope`: {"battle_model_scope": "damage_all_variant_v1", "cards": ["Ashling, Flame Dancer"], "count": 1, "effect": "sweeper_damage", "family_id": "board_wipe_choice"}
  - `largest_raw_runtime_family`: {"cards": ["Adagia, Windswept Bastion", "Hazel's Brewmaster", "Maskwood Nexus"], "count": 3, "effect": "token_maker", "family_id": "token_maker", "scope_count": 3, "top_scopes": [{"battle_model_scope": "xmage_create_token_variant_maskwoodnexus_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_hazelsbrewmaster_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_adagiawindsweptbastion_v1", "count": 1}]}
  - `fragmentation_warning`: largest raw runtime family is fragmented

### test_miner_first

- Title: Mine XMage tests before writing local ManaLoom tests
- Verdict: `use_as_evidence_gate_not_primary_queue`
- Immediate cards: `7`
- Work units: `21`
- Decision score: `36.61`
- Cards per work unit: `0.333`
- Confidence/reuse/risk: `72` / `54` / `47`
- Next action: Use test mining to design focused ManaLoom tests, not to decide the whole queue order alone.
- Evidence:
  - `xmage_test_files`: 2009
  - `pilot_scope`: targeted_damage_variant_v1
  - `test_miner`: {"cards_with_test_reference": 7, "reference_ratio": 0.3333, "requested_card_count": 21, "usable_ratio": 0.0952, "usable_scenario_candidate_count": 2}
  - `interpretation`: test references are valuable, but sparse for the current top split-scope pilot

## Project Instruction Delta

- `queue_order`: Use effective-lane ordering before any card-by-card work. Proof: Prepared package and exact-scope lanes close more cards per work unit than independent review.
- `pattern_registry`: Persist patterns as reviewable templates/observations; promote execution only through card_battle_rules gates. Proof: Pattern registry has high reuse but unsafe if treated as executable without local tests.
- `runtime`: Open runtime only for homogeneous exact scopes with focused tests. Proof: The largest raw runtime family can be fragmented and should not drive architecture by raw count.
- `validation`: Every promoted rule needs package/apply/sync/audit evidence; Hermes remains cache/lab evidence. Proof: Project semantic layer and prior PG packages require source-of-truth separation.
