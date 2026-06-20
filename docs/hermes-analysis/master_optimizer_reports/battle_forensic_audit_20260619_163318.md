# Hermes Battle Forensic Audit

- generated_at: 2026-06-19 16:33:18 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 1073
- card_events: 111
- unique_cards_seen: 62
- rule_logical_key_present: 109
- rule_logical_key_missing: 2
- card_id_present: 63
- card_id_missing: 48
- semantic_hash_present: 63
- semantic_hash_missing: 48
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
| `curated` | 109 |
| `type_line_creature` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 96 |
| `active` | 13 |
| `fact` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 26 |
| `draw_cards` | 11 |
| `add_mana` | 10 |
| `topdeck_manipulation` | 10 |
| `creature` | 9 |
| `ramp_ritual` | 7 |
| `passive` | 5 |
| `finisher` | 4 |
| `copy_creature_token` | 2 |
| `copy_spell` | 2 |
| `draw_engine` | 2 |
| `equipment_haste_shroud` | 2 |
| `extra_turn` | 2 |
| `indestructible` | 2 |
| `ramp_permanent` | 2 |
| `recursion` | 2 |
| `remove_creature` | 2 |
| `silence_opponents` | 2 |
| `silence_spell` | 2 |
| `token_maker` | 2 |
| `treasure_maker` | 2 |
| `tutor` | 2 |
| `ramp_engine` | 1 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:5f5c28a5289affadfc624c0ed212e287` | 24 |
| `battle_rule_v1:2ea9e585d59c7695a81a681b22589e91` | 11 |
| `battle_rule_v1:c8e770836beb12da2460ac9f6bbe1bb8` | 11 |
| `battle_rule_v1:72ccece2add50c83e8d3a94af631f4a4` | 8 |
| `battle_rule_v1:2d9a2f1f7842e5c722724602452fcfdb` | 4 |
| `battle_rule_v1:061f4ec99df6a1d9746f8d08623c50b2` | 2 |
| `battle_rule_v1:090e5f44fad63e8a58d455f358a6123e` | 2 |
| `battle_rule_v1:132fb1a9b40732a75b8c14105ba41b19` | 2 |
| `battle_rule_v1:2ab6098df5e9555daa0584fd74a6aabe` | 2 |
| `battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2` | 2 |
| `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7` | 2 |
| `battle_rule_v1:6644c53d6565fe21003c83bfc85e204f` | 2 |
| `battle_rule_v1:6b35a8b3794c3590e8d5b9294e1bf733` | 2 |
| `battle_rule_v1:74b210b77b004a677906e0216d44e445` | 2 |
| `battle_rule_v1:7bc994e4653e295f9c0d2ef91c2dcaa6` | 2 |
| `battle_rule_v1:841ca05ca69e0f246289d058b2fc7741` | 2 |
| `battle_rule_v1:8971fad5c27e39b626e2e208206329d3` | 2 |
| `battle_rule_v1:908888276dcbc8c3db1126707691ae2c` | 2 |
| `battle_rule_v1:93b92ac01ede49009a01fcd50efccc61` | 2 |
| `battle_rule_v1:a6f1cf83f297c03fbfdb701f8d766ff8` | 2 |
| `battle_rule_v1:b9b26d65a9269f25688f1ab756a33af8` | 2 |
| `battle_rule_v1:ed13c274dec8f6ba95496fed1196f343` | 2 |
| `battle_rule_v1:ed17512d1b7cbca757828380b896c98b` | 2 |
| `battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4` | 2 |
| `battle_rule_v1:10a1ee0f9481c036f6e7e0062cb32d09` | 1 |
| `battle_rule_v1:1df9dc00a60496c01bba430b498146c5` | 1 |
| `battle_rule_v1:361bcd3f68ef017725543c30bed9b56c` | 1 |
| `battle_rule_v1:79aa5cdf4f6c56b2a0e7ffd1172558de` | 1 |
| `battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914` | 1 |
| `battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea` | 1 |
| `battle_rule_v1:9ac77aff3ec344aef3c04706c2361c35` | 1 |
| `battle_rule_v1:b08a13d6ce358035c6feaefffb34e47f` | 1 |
| `battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498` | 1 |
| `battle_rule_v1:ca77e7d8b1007e89de87d5dcceba671a` | 1 |
| `battle_rule_v1:d512a33dfde0db70a2f0851a61f97ad6` | 1 |
| `battle_rule_v1:e894b4ff3d9c46c6b2cf6fc147f459a0` | 1 |
| `battle_rule_v1:ed8c7948ed635396139c4f608e132f4c` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
