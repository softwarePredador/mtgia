# Hermes Battle Forensic Audit

- generated_at: 2026-06-20 18:38:35 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 1091
- card_events: 85
- unique_cards_seen: 49
- rule_logical_key_present: 84
- rule_logical_key_missing: 1
- rule_logical_key_missing_accepted: 1
- rule_logical_key_missing_unaccepted: 0
- card_id_present: 50
- card_id_missing: 35
- card_id_missing_accepted: 35
- card_id_missing_unaccepted: 0
- semantic_hash_present: 50
- semantic_hash_missing: 35
- semantic_hash_missing_accepted: 35
- semantic_hash_missing_unaccepted: 0
- findings_total: 0
- critical: 0
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- external JSONL replay was audited.

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 84 |
| `type_line_creature` | 1 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 74 |
| `active` | 10 |
| `fact` | 1 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 25 |
| `draw_cards` | 7 |
| `creature` | 6 |
| `damage_each_opponent` | 5 |
| `draw_engine` | 4 |
| `modal_boros_charm` | 4 |
| `overload_recursion` | 4 |
| `ramp_permanent` | 4 |
| `ramp_ritual` | 4 |
| `remove_creature` | 4 |
| `composite_resolution` | 2 |
| `copy_spell` | 2 |
| `equipment_haste_shroud` | 2 |
| `ramp_engine` | 2 |
| `recursion` | 2 |
| `redirect_removal` | 2 |
| `topdeck_manipulation` | 2 |
| `tutor` | 2 |
| `board_wipe` | 1 |
| `passive` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `battle_rule_registry_without_card_identity_columns` | 34 |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 34 |
| `type_line_creature_fact_no_rule_identity` | 3 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:5f5c28a5289affadfc624c0ed212e287` | 21 |
| `battle_rule_v1:2ea9e585d59c7695a81a681b22589e91` | 11 |
| `battle_rule_v1:3dd2ca2e14e74719f377887f16a84722` | 6 |
| `battle_rule_v1:9828a36dd98a8e019a261a04b1f2125e` | 4 |
| `battle_rule_v1:d7b3e8dc972166e9d463178217a9fef9` | 4 |
| `battle_rule_v1:e5701db5db9af635f4ad2bcfc70608bb` | 4 |
| `battle_rule_v1:090e5f44fad63e8a58d455f358a6123e` | 2 |
| `battle_rule_v1:25e61cd494623c61e0daab0a34a7535a` | 2 |
| `battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2` | 2 |
| `battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff` | 2 |
| `battle_rule_v1:7bc994e4653e295f9c0d2ef91c2dcaa6` | 2 |
| `battle_rule_v1:8971fad5c27e39b626e2e208206329d3` | 2 |
| `battle_rule_v1:98733239f680fdef673028104fb783b7` | 2 |
| `battle_rule_v1:a04871c14f3ca25c877adc9e870bf437` | 2 |
| `battle_rule_v1:ca8e86595f53b6dc258dfd26f22ef93e` | 2 |
| `battle_rule_v1:e894b4ff3d9c46c6b2cf6fc147f459a0` | 2 |
| `battle_rule_v1:ed13c274dec8f6ba95496fed1196f343` | 2 |
| `battle_rule_v1:218c49467c254e7a90f54d85b4dbb9dc` | 1 |
| `battle_rule_v1:2416d3a98f1b3a126a893965ca4e3516` | 1 |
| `battle_rule_v1:3d1d7c9ec8ddbb2ca0307f4f7a323f11` | 1 |
| `battle_rule_v1:781600d4c5f4d8c10fadbc11c45eaccb` | 1 |
| `battle_rule_v1:79aa5cdf4f6c56b2a0e7ffd1172558de` | 1 |
| `battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c` | 1 |
| `battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914` | 1 |
| `battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea` | 1 |
| `battle_rule_v1:9a28465081dd2ac48819f94e919646a6` | 1 |
| `battle_rule_v1:c364544e9bd651211acf851db2313ccd` | 1 |
| `battle_rule_v1:e91607bdf9b86efb4552bca54178999f` | 1 |
| `battle_rule_v1:ea7e00f2d90b2ceead4036ab10cd0200` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
