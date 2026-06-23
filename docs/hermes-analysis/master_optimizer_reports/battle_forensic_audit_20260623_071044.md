# Hermes Battle Forensic Audit

- generated_at: 2026-06-23 07:10:44 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 598
- card_events: 67
- unique_cards_seen: 50
- rule_logical_key_present: 63
- rule_logical_key_missing: 4
- rule_logical_key_missing_accepted: 4
- rule_logical_key_missing_unaccepted: 0
- card_id_present: 24
- card_id_missing: 43
- card_id_missing_accepted: 43
- card_id_missing_unaccepted: 0
- semantic_hash_present: 24
- semantic_hash_missing: 43
- semantic_hash_missing_accepted: 43
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
| `curated` | 63 |
| `type_line_creature` | 4 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 49 |
| `active` | 14 |
| `fact` | 4 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 20 |
| `creature` | 10 |
| `topdeck_manipulation` | 6 |
| `ramp_permanent` | 4 |
| `treasure_maker` | 4 |
| `tutor` | 4 |
| `finisher` | 3 |
| `remove_permanent` | 3 |
| `attack_limit` | 2 |
| `copy_creature_token` | 2 |
| `land_tax` | 2 |
| `passive` | 2 |
| `ramp_ritual` | 2 |
| `remove_creature` | 2 |
| `redirect_removal` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `battle_rule_registry_without_card_identity_columns` | 48 |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 30 |
| `type_line_creature_fact_no_rule_identity` | 12 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:603c776839827f2f21cef8b62e22a1be` | 18 |
| `battle_rule_v1:3895145eecb0a2ac9b7805febd67ea54` | 3 |
| `battle_rule_v1:03bed5506a427743723cd7676c6a67d9` | 2 |
| `battle_rule_v1:0a516c943d34868170c663d2006b273d` | 2 |
| `battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2` | 2 |
| `battle_rule_v1:44f3e6ff98ac438be56aa74272b47f93` | 2 |
| `battle_rule_v1:70c8478871f352b46cee1af296117951` | 2 |
| `battle_rule_v1:807cdb2c6bd08602999fa89c4b4b712a` | 2 |
| `battle_rule_v1:86137800253980cc4594e0cf3fd78953` | 2 |
| `battle_rule_v1:8ef50c368534ec91af1e28c7e3079c2e` | 2 |
| `battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591` | 2 |
| `battle_rule_v1:e154b34c0deaa861094d5870f4c0ad69` | 2 |
| `battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef` | 2 |
| `battle_rule_v1:f1c22fd254adb5a3664c0bcccf24a9cd` | 2 |
| `battle_rule_v1:f6d96db6081c2fd3f48828c7594f4fcf` | 2 |
| `battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4` | 2 |
| `battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61` | 1 |
| `battle_rule_v1:107c3934f762e7ac8c32ecfad4f41d95` | 1 |
| `battle_rule_v1:128e222b4de1e6308d98743711b54985` | 1 |
| `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7` | 1 |
| `battle_rule_v1:45599a847c7127d51607bbbbb858d3b2` | 1 |
| `battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff` | 1 |
| `battle_rule_v1:6671147cad5e2014454ed291f4b0c5ea` | 1 |
| `battle_rule_v1:80a4b5beca8834e0c642dc8c0663106c` | 1 |
| `battle_rule_v1:9a28465081dd2ac48819f94e919646a6` | 1 |
| `battle_rule_v1:9d5afecce0b2500c1dff74bcd97e6eb4` | 1 |
| `battle_rule_v1:a5270b2fac934dee9b6efc9d0e2ea81d` | 1 |
| `battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518` | 1 |
| `battle_rule_v1:c24f4320a73bc60a3da4f29fd2bf6d41` | 1 |
| `battle_rule_v1:df079f5cb0c72382949c688f8e0bcb50` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
