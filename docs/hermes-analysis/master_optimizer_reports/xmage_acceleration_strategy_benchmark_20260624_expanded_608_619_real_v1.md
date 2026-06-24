# XMage Acceleration Strategy Benchmark

- Generated at: `2026-06-24T15:13:14+00:00`
- Status: `ready`
- Mutations performed: `[]`

## Sources

- `proposal_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_expanded_608_619_real_v5_proposals.json`
- `effective_queue_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260624_expanded_608_619_real_v2.json`
- `inventory_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_engine_absorption_inventory_20260623.json`
- `test_miner_report`: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_test_scenario_miner_targeted_damage_20260624.json`

## Summary

- Proposal count: `504`
- Strategy count: `8`
- Recommended strategy: `hybrid_effective_queue_pattern_registry`
- Recommended score: `80.1`

## Ranking

| Rank | Strategy | Verdict | Score | Cards/unit |
| --- | --- | --- | ---: | ---: |
| 1 | `hybrid_effective_queue_pattern_registry` | `recommended` | 80.1 | 19.25 |
| 2 | `exact_scope_cluster_first` | `use_as_next_modeling_lane` | 73.14 | 21.0 |
| 3 | `package_manifest_first` | `use_immediately_with_pg_approval` | 59.05 | 3.6 |
| 4 | `full_xmage_first` | `reject_as_primary` | 45.6 | 0.016 |
| 5 | `runtime_exact_scope_first` | `use_selectively` | 44.2 | 2.0 |
| 6 | `pattern_registry_first` | `use_as_shadow_infrastructure` | 44.05 | 0.033 |
| 7 | `card_by_card_queue` | `reject_as_default` | 42.0 | 1.0 |
| 8 | `test_miner_first` | `use_as_evidence_gate_not_primary_queue` | 36.56 | 0.333 |

## Strategy Evidence

### hybrid_effective_queue_pattern_registry

- Title: Hybrid: package gate, exact-scope clusters, test miner, and pattern registry
- Verdict: `recommended`
- Immediate cards: `77`
- Work units: `4`
- Decision score: `80.1`
- Cards per work unit: `19.25`
- Confidence/reuse/risk: `84` / `90` / `34`
- Next action: Adopt as the project instruction: no broad card-by-card loop while package, exact-scope, or runtime-homogeneous lanes remain.
- Evidence:
  - `package_cards_removed_from_modeling`: 54
  - `top_split_scope_cards`: 21
  - `top_runtime_scope_cards`: 2
  - `test_miner`: {"cards_with_test_reference": 7, "reference_ratio": 0.3333, "requested_card_count": 21, "usable_ratio": 0.0952, "usable_scenario_candidate_count": 2}
  - `why`: Combines immediate duplicate-work removal with reusable pattern creation and runtime gates.

### exact_scope_cluster_first

- Title: Batch the largest exact split-scope clusters
- Verdict: `use_as_next_modeling_lane`
- Immediate cards: `21`
- Work units: `1`
- Decision score: `73.14`
- Cards per work unit: `21.0`
- Confidence/reuse/risk: `74` / `82` / `42`
- Next action: Split the top scope into subpatterns before PG promotion; targeted_damage_variant_v1 is useful as a queue, not as one executable behavior.
- Evidence:
  - `split_scope_backlog`: 68
  - `split_scope_unique_scope_count`: 9
  - `top_scope`: {"battle_model_scope": "targeted_damage_variant_v1", "cards": ["Balefire Liege", "Boros Reckoner", "Brash Taunter", "Caldera Pyremaw", "Cemetery Gatekeeper", "Eiganjo, Seat of the Empire", "Firesong and Sunspeaker", "Gleeful Arsonist", "Harsh Mentor", "Kederekt Parasite", "Lightning Helix", "Mayhem Devil", "Mogis, God of Slaughter", "Niv-Mizzet, Parun", "Rampaging Ferocidon", "Razorgrass Ambush // Razorgrass Field", "Repercussion", "Spiteful Visions", "Terror of the Peaks", "The Lord of Pain", "Toralf, God of Fury // Toralf's Hammer"], "count": 21, "effect": "direct_damage", "family_id": "targeted_interaction"}
  - `test_miner`: {"cards_with_test_reference": 7, "reference_ratio": 0.3333, "requested_card_count": 21, "usable_ratio": 0.0952, "usable_scenario_candidate_count": 2}

### package_manifest_first

- Title: Stop rebuilding prepared PG packages and apply them through gates
- Verdict: `use_immediately_with_pg_approval`
- Immediate cards: `54`
- Work units: `15`
- Decision score: `59.05`
- Cards per work unit: `3.6`
- Confidence/reuse/risk: `86` / `63` / `32`
- Next action: Do not remodel these cards; move them through the PostgreSQL governance gate when approved.
- Evidence:
  - `pg_ready_total`: 54
  - `package_already_prepared`: 54
  - `package_ready_unprepared`: 0
  - `prepared_package_count`: 15
  - `required_gate`: precheck, approved apply, postcheck, PG->Hermes sync, focused audit

### full_xmage_first

- Title: Analyze/port the whole XMage corpus before queue work
- Verdict: `reject_as_primary`
- Immediate cards: `504`
- Work units: `31706`
- Decision score: `45.6`
- Cards per work unit: `0.016`
- Confidence/reuse/risk: `62` / `92` / `88`
- Next action: Use full inventory as reference only; do not block deck closure on global analysis.
- Evidence:
  - `card_implementation_files`: 31706
  - `java_files_total`: 38739
  - `current_queue_cards`: 504
  - `work_multiplier_vs_current_queue`: 62.91
  - `source_basis`: local XMage inventory plus official XMage repository structure

### runtime_exact_scope_first

- Title: Open runtime only for homogeneous exact scopes
- Verdict: `use_selectively`
- Immediate cards: `2`
- Work units: `1`
- Decision score: `44.2`
- Cards per work unit: `2.0`
- Confidence/reuse/risk: `78` / `65` / `70`
- Next action: Start with damage_all/destroy_all scopes; defer token_maker until taxonomy support exists.
- Evidence:
  - `runtime_backlog`: 24
  - `runtime_unique_scope_count`: 22
  - `top_runtime_scope`: {"battle_model_scope": "destroy_all_permanents_or_creatures_variant_v1", "cards": ["Armageddon", "Ultima"], "count": 2, "effect": "board_wipe", "family_id": "board_wipe_choice"}
  - `largest_raw_runtime_family`: {"cards": ["Aclazotz, Deepest Betrayal // Temple of the Dead", "Adagia, Windswept Bastion", "Biotransference", "Black Market Connections", "Blaze Commando", "Bone Miser", "Davros, Dalek Creator", "Fable of the Mirror-Breaker // Reflection of Kiki-Jiki", "Goldspan Dragon", "Green Goblin, Nemesis", "Maskwood Nexus", "Monastery Mentor", "Perch Protection", "Sand Scout", "Smuggler's Share", "Surly Badgersaur", "The Locust God", "Utvara Hellkite", "Waste Not", "Young Pyromancer"], "count": 20, "effect": "token_maker", "family_id": "token_maker", "scope_count": 20, "top_scopes": [{"battle_model_scope": "xmage_create_token_variant_perchprotection_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_youngpyromancer_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_bonemiser_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_maskwoodnexus_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_monasterymentor_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_thelocustgod_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_utvarahellkite_v1", "count": 1}, {"battle_model_scope": "xmage_create_token_variant_wastenot_v1", "count": 1}]}
  - `fragmentation_warning`: largest raw runtime family is fragmented

### pattern_registry_first

- Title: Create a persistent pattern registry before broad manual mapping
- Verdict: `use_as_shadow_infrastructure`
- Immediate cards: `92`
- Work units: `2811`
- Decision score: `44.05`
- Cards per work unit: `0.033`
- Confidence/reuse/risk: `70` / `96` / `58`
- Next action: Seed patterns incrementally from approved clusters; do not wait for a complete global registry.
- Evidence:
  - `effect_files`: 802
  - `test_files`: 2009
  - `candidate_cards_for_pattern_learning`: 92
  - `manual_mapper_backlog`: 356
  - `database_boundary`: registry may persist templates/observations, but executable rules remain gated in card_battle_rules

### card_by_card_queue

- Title: Inspect each current proposal card independently
- Verdict: `reject_as_default`
- Immediate cards: `504`
- Work units: `504`
- Decision score: `42.0`
- Cards per work unit: `1.0`
- Confidence/reuse/risk: `68` / `18` / `55`
- Next action: Keep as fallback for exception cards only.
- Evidence:
  - `current_queue_cards`: 504
  - `proposal_status_counts`: {"batch_pg_candidate_after_precheck": 54, "blocked_missing_xmage_source": 2, "mapper_metadata_or_test_scenario_required": 356, "runtime_family_implementation_required": 24, "split_family_scope_review_required": 68}
  - `reason`: Every card can eventually be handled, but each unit produces little reusable knowledge.

### test_miner_first

- Title: Mine XMage tests before writing local ManaLoom tests
- Verdict: `use_as_evidence_gate_not_primary_queue`
- Immediate cards: `7`
- Work units: `21`
- Decision score: `36.56`
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
