# Hermes Battle Forensic Audit

- generated_at: 2026-06-29 09:12:35 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 756
- card_events: 66
- unique_cards_seen: 45
- rule_logical_key_present: 58
- rule_logical_key_missing: 8
- rule_logical_key_missing_accepted: 6
- rule_logical_key_missing_unaccepted: 2
- card_id_present: 15
- card_id_missing: 51
- card_id_missing_accepted: 47
- card_id_missing_unaccepted: 4
- semantic_hash_present: 15
- semantic_hash_missing: 51
- semantic_hash_missing_accepted: 47
- semantic_hash_missing_unaccepted: 4
- findings_total: 4
- critical: 0
- high: 0
- medium: 2
- low: 2

## Replay Evidence

- external JSONL replay was audited.

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 56 |
| `type_line_creature` | 6 |
| `functional_tags_json` | 2 |
| `known_cards_canonical_snapshot` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 51 |
| `fact` | 6 |
| `active` | 5 |
| `heuristic` | 2 |
| `review_only` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 18 |
| `creature` | 13 |
| `draw_cards` | 7 |
| `ramp_ritual` | 4 |
| `passive` | 3 |
| `ramp_permanent` | 3 |
| `remove_creature` | 3 |
| `brain_freeze` | 2 |
| `damage_any_target` | 2 |
| `draw_engine` | 2 |
| `equipment_static_attachment` | 2 |
| `recursion` | 2 |
| `remove_permanent` | 2 |
| `tutor` | 2 |
| `land_ramp` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `battle_rule_registry_without_card_identity_columns` | 56 |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 26 |
| `type_line_creature_fact_no_rule_identity` | 18 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:603c776839827f2f21cef8b62e22a1be` | 14 |
| `battle_rule_v1:83dbd32fed8c770f977cd7b1fcd2883d` | 7 |
| `battle_rule_v1:128e222b4de1e6308d98743711b54985` | 3 |
| `battle_rule_v1:280e17ec34ac105baeb6989491c6ff25` | 3 |
| `battle_rule_v1:0d42202d79e9f7e0b0a65fe5848c9849` | 2 |
| `battle_rule_v1:4d539456ce3026ca5a85fbadc3e7b339` | 2 |
| `battle_rule_v1:70fa2e668d7c5e40f055c04c01d25a6c` | 2 |
| `battle_rule_v1:86b568648669ceb1eef6d7f6b95d4f1c` | 2 |
| `battle_rule_v1:98961b0f9243bcc73308c30365ad835c` | 2 |
| `battle_rule_v1:b992316c10714f267a5a33a4c62795d4` | 2 |
| `battle_rule_v1:c8621a807cc65adc820a8b8189979f70` | 2 |
| `battle_rule_v1:d3402dff750bf6369a6e50379066870b` | 2 |
| `battle_rule_v1:ff4327093d44df534a0f3aba335e124d` | 2 |
| `battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4` | 1 |
| `battle_rule_v1:0cae4a7bd1e862a0063b9c606ff96e6c` | 1 |
| `battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba` | 1 |
| `battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba` | 1 |
| `battle_rule_v1:6c79ee0d7eda6f8a02666036cad990fa` | 1 |
| `battle_rule_v1:778677cb1baf3abdb20067499dbdcffd` | 1 |
| `battle_rule_v1:ad607c99185b8f57b168e12e24117777` | 1 |
| `battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3` | 1 |
| `battle_rule_v1:cab6dca71d1d5e86c85ef5f8089f1648` | 1 |
| `battle_rule_v1:cc7e65cfa812dc06a42f853773180ca1` | 1 |
| `battle_rule_v1:e9cb68d2e2a585c86ff5699757221488` | 1 |
| `battle_rule_v1:f07edd2f4f3e3c9897f03ec390a5cf44` | 1 |
| `battle_rule_v1:f2d4cbe84d49d11a20aa13e9f9db53a9` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| medium | seed_6060 | 5 | precombat_main | Rowan, Scion of War #32 (real) | spell_cast | Blood Celebrant | ramp_permanent | Game event depended on heuristic source `functional_tags_json`. | Move this card into card_battle_rules with verified/active status. |
| medium | seed_6060 | 6 | precombat_main | Kinnan, Bonder Prodigy #72 (real) | spell_cast | Boreal Druid | ramp_permanent | Game event depended on heuristic source `functional_tags_json`. | Move this card into card_battle_rules with verified/active status. |
| low | seed_6060 | 7 | precombat_main | Rowan, Scion of War #32 (real) | spell_cast | Torment of Hailfire | passive | Runtime effect `passive` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_6060 | 7 | precombat_main | Rowan, Scion of War #32 (real) | spell_resolved | Torment of Hailfire | passive | Runtime effect `passive` differs from registry effect `draw_cards`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.

Report written: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260629_091235.md
