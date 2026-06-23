# Hermes Battle Forensic Audit

- generated_at: 2026-06-23 06:59:06 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 906
- card_events: 102
- unique_cards_seen: 62
- rule_logical_key_present: 97
- rule_logical_key_missing: 5
- rule_logical_key_missing_accepted: 5
- rule_logical_key_missing_unaccepted: 0
- card_id_present: 23
- card_id_missing: 79
- card_id_missing_accepted: 79
- card_id_missing_unaccepted: 0
- semantic_hash_present: 23
- semantic_hash_missing: 79
- semantic_hash_missing_accepted: 79
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
| `curated` | 95 |
| `type_line_creature` | 5 |
| `manual_runtime_waiver` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 83 |
| `active` | 14 |
| `fact` | 5 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 19 |
| `create_treasure` | 16 |
| `creature` | 15 |
| `tutor` | 14 |
| `ramp_permanent` | 7 |
| `passive` | 4 |
| `remove_creature` | 3 |
| `attack_tax` | 2 |
| `copy_creature_token` | 2 |
| `draw_cards` | 2 |
| `draw_engine` | 2 |
| `finisher` | 2 |
| `indestructible` | 2 |
| `land_ramp` | 2 |
| `loot` | 2 |
| `ramp_ritual` | 2 |
| `recursion` | 2 |
| `remove_permanent` | 2 |
| `approach` | 1 |
| `ramp_engine` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `battle_rule_registry_without_card_identity_columns` | 120 |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 24 |
| `type_line_creature_fact_no_rule_identity` | 15 |
| `manual_runtime_waiver_without_pg_identity` | 4 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:242df1cde958c67ece11aae4af5f4bc6` | 17 |
| `battle_rule_v1:603c776839827f2f21cef8b62e22a1be` | 15 |
| `battle_rule_v1:807cdb2c6bd08602999fa89c4b4b712a` | 4 |
| `battle_rule_v1:abcfd8a217652da7900e0b2e59338ac4` | 3 |
| `battle_rule_v1:02606b54a9a7cf3dae5775c9211b0e32` | 2 |
| `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4` | 2 |
| `battle_rule_v1:0cae4a7bd1e862a0063b9c606ff96e6c` | 2 |
| `battle_rule_v1:19a6b12e4f32350914e970a7184a5a45` | 2 |
| `battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54` | 2 |
| `battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93` | 2 |
| `battle_rule_v1:554fe811b81e8a284b8a5ca9c6543caa` | 2 |
| `battle_rule_v1:70834ed31349e783de2c2270fec2b478` | 2 |
| `battle_rule_v1:73622071c1ad89267708f914a0729bf2` | 2 |
| `battle_rule_v1:7c9514700edc0f4c25fac340fd08424c` | 2 |
| `battle_rule_v1:86137800253980cc4594e0cf3fd78953` | 2 |
| `battle_rule_v1:8f38651412c0d6366a81bd426e980cdf` | 2 |
| `battle_rule_v1:97ab0167213936bfa544f19731284e56` | 2 |
| `battle_rule_v1:99151859bece89ba3ead032e05b1f65a` | 2 |
| `battle_rule_v1:a5270b2fac934dee9b6efc9d0e2ea81d` | 2 |
| `battle_rule_v1:c8621a807cc65adc820a8b8189979f70` | 2 |
| `battle_rule_v1:f6d96db6081c2fd3f48828c7594f4fcf` | 2 |
| `battle_rule_v1:fac5f8624ed06d963c77b5e56bd95d3b` | 2 |
| `battle_rule_v1:fb9b2b633a4842d42599c293e0de4d68` | 2 |
| `battle_rule_v1:02133e513da5ea98ac74d32d39b16470` | 1 |
| `battle_rule_v1:128e222b4de1e6308d98743711b54985` | 1 |
| `battle_rule_v1:150c8e33a8a7b917254bf379c9c083ed` | 1 |
| `battle_rule_v1:26190cd09ff09f21859165388f24587b` | 1 |
| `battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba` | 1 |
| `battle_rule_v1:3d154b436fcb6b4f290cdd0246d5def4` | 1 |
| `battle_rule_v1:45599a847c7127d51607bbbbb858d3b2` | 1 |
| `battle_rule_v1:4e8274d5902cf8ca66ff01be157ffddb` | 1 |
| `battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea` | 1 |
| `battle_rule_v1:6a8e3e2e2cf6972d52b2c736b35cb2fb` | 1 |
| `battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea` | 1 |
| `battle_rule_v1:9a28465081dd2ac48819f94e919646a6` | 1 |
| `battle_rule_v1:b9e1d8185b3928605b5bfa2f1a526bfa` | 1 |
| `battle_rule_v1:c364544e9bd651211acf851db2313ccd` | 1 |
| `battle_rule_v1:d2076e435470ab6c446676d321a12f1b` | 1 |
| `battle_rule_v1:ea7e00f2d90b2ceead4036ab10cd0200` | 1 |
| `battle_rule_v1:ed74fb069b6c1d635392d907804a1d98` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
