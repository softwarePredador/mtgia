# Hermes Battle Forensic Audit

- generated_at: 2026-06-20 19:29:55 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 1132
- card_events: 110
- unique_cards_seen: 73
- rule_logical_key_present: 108
- rule_logical_key_missing: 2
- rule_logical_key_missing_accepted: 2
- rule_logical_key_missing_unaccepted: 0
- card_id_present: 75
- card_id_missing: 35
- card_id_missing_accepted: 35
- card_id_missing_unaccepted: 0
- semantic_hash_present: 75
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
| `curated` | 108 |
| `type_line_creature` | 2 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 95 |
| `active` | 13 |
| `fact` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 38 |
| `ramp_permanent` | 8 |
| `passive` | 7 |
| `token_maker` | 7 |
| `draw_engine` | 6 |
| `tutor` | 6 |
| `creature` | 5 |
| `remove_creature` | 4 |
| `add_mana` | 3 |
| `ramp_engine` | 3 |
| `copy_spell` | 2 |
| `draw_cards` | 2 |
| `equipment_haste_shroud` | 2 |
| `finisher` | 2 |
| `hand_filter` | 2 |
| `indestructible` | 2 |
| `modal_boros_charm` | 2 |
| `ramp_ritual` | 2 |
| `remove_permanent` | 2 |
| `silence_spell` | 2 |
| `topdeck_manipulation` | 2 |
| `approach` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 50 |
| `battle_rule_registry_without_card_identity_columns` | 16 |
| `type_line_creature_fact_no_rule_identity` | 6 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:5f5c28a5289affadfc624c0ed212e287` | 32 |
| `battle_rule_v1:a6f1cf83f297c03fbfdb701f8d766ff8` | 6 |
| `battle_rule_v1:c8e770836beb12da2460ac9f6bbe1bb8` | 4 |
| `battle_rule_v1:ed17512d1b7cbca757828380b896c98b` | 4 |
| `battle_rule_v1:1df9dc00a60496c01bba430b498146c5` | 3 |
| `battle_rule_v1:0386ff7a3b026a6fe97fabf9d9a21294` | 2 |
| `battle_rule_v1:1b5e5a972556d30833f4aca67274b791` | 2 |
| `battle_rule_v1:2ab6098df5e9555daa0584fd74a6aabe` | 2 |
| `battle_rule_v1:2d9a2f1f7842e5c722724602452fcfdb` | 2 |
| `battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2` | 2 |
| `battle_rule_v1:6b35a8b3794c3590e8d5b9294e1bf733` | 2 |
| `battle_rule_v1:6e1f3b876822abafe1de47610f46858d` | 2 |
| `battle_rule_v1:7b1efc300c303a2b54bcfc758f5698e6` | 2 |
| `battle_rule_v1:803fe04890623e5ebf4abf1c992c344b` | 2 |
| `battle_rule_v1:88de129cfe7aefc7151234f9420de2a8` | 2 |
| `battle_rule_v1:8971fad5c27e39b626e2e208206329d3` | 2 |
| `battle_rule_v1:b116fd57d8e26a39bffd9b52bbd95b3d` | 2 |
| `battle_rule_v1:b9b26d65a9269f25688f1ab756a33af8` | 2 |
| `battle_rule_v1:c06a3fad9aad3336c216a9cdd662f016` | 2 |
| `battle_rule_v1:c66a152a0ec70eb9e2a03412262eb225` | 2 |
| `battle_rule_v1:d512a33dfde0db70a2f0851a61f97ad6` | 2 |
| `battle_rule_v1:d7b3e8dc972166e9d463178217a9fef9` | 2 |
| `battle_rule_v1:d92558b449d8ace543f8ce653a9757df` | 2 |
| `battle_rule_v1:e5701db5db9af635f4ad2bcfc70608bb` | 2 |
| `battle_rule_v1:ed13c274dec8f6ba95496fed1196f343` | 2 |
| `battle_rule_v1:07c97c73f65d524510e30b6bbfca0b61` | 1 |
| `battle_rule_v1:09101297a604357352aeb80d9faad8b3` | 1 |
| `battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba` | 1 |
| `battle_rule_v1:4bddcb4c084d969a7ac60a4e378b06dd` | 1 |
| `battle_rule_v1:781600d4c5f4d8c10fadbc11c45eaccb` | 1 |
| `battle_rule_v1:8ca7b247ee54647b75f61f5c3f9e274a` | 1 |
| `battle_rule_v1:91aa990f0d25b0aba2a1447bc1a47914` | 1 |
| `battle_rule_v1:9384b4cf2ffc3b4afc5cb65fb4febaea` | 1 |
| `battle_rule_v1:93b92ac01ede49009a01fcd50efccc61` | 1 |
| `battle_rule_v1:972703914ee50acd7a4e6f529fea1adf` | 1 |
| `battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab` | 1 |
| `battle_rule_v1:affcdb9e10f188836fcfbec8d246c92f` | 1 |
| `battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498` | 1 |
| `battle_rule_v1:c11487143935b327650306d7e7e8c8e2` | 1 |
| `battle_rule_v1:c364544e9bd651211acf851db2313ccd` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| info | all | - | - | all | all | - | - | No forensic findings. | Keep replay as evidence. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.
