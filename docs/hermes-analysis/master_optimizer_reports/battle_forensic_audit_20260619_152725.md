# Hermes Battle Forensic Audit

- generated_at: 2026-06-19 15:27:25 UTC
- status: blocked
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 1109
- card_events: 96
- unique_cards_seen: 51
- rule_logical_key_present: 94
- rule_logical_key_missing: 2
- card_id_present: 61
- card_id_missing: 35
- semantic_hash_present: 61
- semantic_hash_missing: 35
- findings_total: 10
- critical: 10
- high: 0
- medium: 0
- low: 0

## Replay Evidence

- external JSONL replay was audited.

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 94 |
| `type_line_creature` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 75 |
| `active` | 19 |
| `fact` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 22 |
| `topdeck_manipulation` | 16 |
| `add_mana` | 10 |
| `creature` | 7 |
| `ramp_ritual` | 7 |
| `draw_cards` | 6 |
| `counter` | 4 |
| `passive` | 3 |
| `copy_spell` | 2 |
| `draw_engine` | 2 |
| `equipment_haste_shroud` | 2 |
| `finisher` | 2 |
| `ramp_permanent` | 2 |
| `remove_creature` | 2 |
| `silence_opponents` | 2 |
| `silence_spell` | 2 |
| `token_maker` | 2 |
| `treasure_maker` | 2 |
| `ramp_engine` | 1 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:5f5c28a5289affadfc624c0ed212e287` | 20 |
| `battle_rule_v1:72ccece2add50c83e8d3a94af631f4a4` | 14 |
| `battle_rule_v1:c8e770836beb12da2460ac9f6bbe1bb8` | 11 |
| `battle_rule_v1:2ea9e585d59c7695a81a681b22589e91` | 8 |
| `battle_rule_v1:061f4ec99df6a1d9746f8d08623c50b2` | 2 |
| `battle_rule_v1:2ab6098df5e9555daa0584fd74a6aabe` | 2 |
| `battle_rule_v1:2d9a2f1f7842e5c722724602452fcfdb` | 2 |
| `battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2` | 2 |
| `battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7` | 2 |
| `battle_rule_v1:4e847febff98ad16558e2f8af78762ba` | 2 |
| `battle_rule_v1:58855129d68b92367301c3de428fc040` | 2 |
| `battle_rule_v1:74b210b77b004a677906e0216d44e445` | 2 |
| `battle_rule_v1:841ca05ca69e0f246289d058b2fc7741` | 2 |
| `battle_rule_v1:8971fad5c27e39b626e2e208206329d3` | 2 |
| `battle_rule_v1:a6f1cf83f297c03fbfdb701f8d766ff8` | 2 |
| `battle_rule_v1:b9b26d65a9269f25688f1ab756a33af8` | 2 |
| `battle_rule_v1:ed13c274dec8f6ba95496fed1196f343` | 2 |
| `battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4` | 2 |
| `battle_rule_v1:10a1ee0f9481c036f6e7e0062cb32d09` | 1 |
| `battle_rule_v1:1df9dc00a60496c01bba430b498146c5` | 1 |
| `battle_rule_v1:361bcd3f68ef017725543c30bed9b56c` | 1 |
| `battle_rule_v1:79aa5cdf4f6c56b2a0e7ffd1172558de` | 1 |
| `battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914` | 1 |
| `battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea` | 1 |
| `battle_rule_v1:93b92ac01ede49009a01fcd50efccc61` | 1 |
| `battle_rule_v1:9ac77aff3ec344aef3c04706c2361c35` | 1 |
| `battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498` | 1 |
| `battle_rule_v1:ca77e7d8b1007e89de87d5dcceba671a` | 1 |
| `battle_rule_v1:d512a33dfde0db70a2f0851a61f97ad6` | 1 |
| `battle_rule_v1:e894b4ff3d9c46c6b2cf6fc147f459a0` | 1 |
| `battle_rule_v1:ed8c7948ed635396139c4f608e132f4c` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| critical | seed_786135854 | 10 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 10 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 11 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 12 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 12 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 7 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 8 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 9 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 9 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |
| critical | seed_786135854 | 9 | precombat_main | Lorehold | trigger_resolved | Birgi, God of Storytelling // Harnfel, Horn of Bounty | add_mana | Effect `add_mana` is not implemented by the active battle engine. | Implement the effect branch or map the card to a supported approximation. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
