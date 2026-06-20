# Hermes Battle Forensic Audit

- generated_at: 2026-06-20 19:45:39 UTC
- status: ready_for_review
- sqlite_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- structured_events: 541
- card_events: 63
- unique_cards_seen: 44
- rule_logical_key_present: 58
- rule_logical_key_missing: 5
- rule_logical_key_missing_accepted: 5
- rule_logical_key_missing_unaccepted: 0
- card_id_present: 15
- card_id_missing: 48
- card_id_missing_accepted: 46
- card_id_missing_unaccepted: 2
- semantic_hash_present: 15
- semantic_hash_missing: 48
- semantic_hash_missing_accepted: 46
- semantic_hash_missing_unaccepted: 2
- findings_total: 2
- critical: 0
- high: 0
- medium: 0
- low: 2

## Replay Evidence

- external JSONL replay was audited.

## Rule Sources Used

| Value | Count |
| --- | ---: |
| `curated` | 55 |
| `type_line_creature` | 5 |
| `known_cards_canonical_snapshot` | 2 |
| `manual_runtime_waiver` | 1 |

## Review Status Used

| Value | Count |
| --- | ---: |
| `verified` | 53 |
| `fact` | 5 |
| `active` | 3 |
| `review_only` | 2 |

## Effects Seen

| Value | Count |
| --- | ---: |
| `land` | 19 |
| `creature` | 11 |
| `draw_engine` | 8 |
| `draw_cards` | 6 |
| `tutor` | 6 |
| `passive` | 4 |
| `ramp_permanent` | 2 |
| `ramp_ritual` | 2 |
| `remove_permanent` | 2 |
| `silence_opponents` | 2 |
| `ramp_engine` | 1 |

## Accepted Lineage Missing Waiver Reasons

| Value | Count |
| --- | ---: |
| `battle_rule_registry_without_card_identity_columns` | 52 |
| `land_played_curated_runtime_rule_without_pg_card_identity` | 28 |
| `type_line_creature_fact_no_rule_identity` | 15 |
| `manual_runtime_waiver_without_pg_identity` | 2 |

## Rule Logical Keys Seen

| Value | Count |
| --- | ---: |
| `battle_rule_v1:5f5c28a5289affadfc624c0ed212e287` | 15 |
| `battle_rule_v1:2ea9e585d59c7695a81a681b22589e91` | 10 |
| `battle_rule_v1:030b2f3e0f549a462c3c8ea429877980` | 2 |
| `battle_rule_v1:0ab3867d7118abc751d3258d103b8135` | 2 |
| `battle_rule_v1:1b5e5a972556d30833f4aca67274b791` | 2 |
| `battle_rule_v1:1df9dc00a60496c01bba430b498146c5` | 2 |
| `battle_rule_v1:7b1efc300c303a2b54bcfc758f5698e6` | 2 |
| `battle_rule_v1:7bc994e4653e295f9c0d2ef91c2dcaa6` | 2 |
| `battle_rule_v1:b116fd57d8e26a39bffd9b52bbd95b3d` | 2 |
| `battle_rule_v1:c06a3fad9aad3336c216a9cdd662f016` | 2 |
| `battle_rule_v1:d92558b449d8ace543f8ce653a9757df` | 2 |
| `battle_rule_v1:ed17512d1b7cbca757828380b896c98b` | 2 |
| `battle_rule_v1:fcd399a7889d5ab307d06c1aba3fa5f9` | 2 |
| `battle_rule_v1:218c49467c254e7a90f54d85b4dbb9dc` | 1 |
| `battle_rule_v1:4bddcb4c084d969a7ac60a4e378b06dd` | 1 |
| `battle_rule_v1:684c7ea91b4b39134868269f9c5cf723` | 1 |
| `battle_rule_v1:b62b6dfa5cdc9db4b8b21faf7bfc0498` | 1 |
| `battle_rule_v1:b6e48063a7c24833bfe7fe9f493ea861` | 1 |
| `battle_rule_v1:c11487143935b327650306d7e7e8c8e2` | 1 |
| `battle_rule_v1:c364544e9bd651211acf851db2313ccd` | 1 |
| `battle_rule_v1:c9e98658950070eddbc1386956ba728d` | 1 |
| `battle_rule_v1:d512a33dfde0db70a2f0851a61f97ad6` | 1 |
| `battle_rule_v1:f052c961703873e8bce9d44815a698a7` | 1 |
| `battle_rule_v1:faf0412d36f280c62b14904ec21807cc` | 1 |

## Findings

| Severity | Replay | Turn | Phase | Player | Event | Card | Effect | Finding | Recommendation |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | --- |
| low | seed_63213000 | 2 | precombat_main | Yorion, Sky Nomad #38 (real) | spell_cast | Aether Channeler | passive | Runtime effect `passive` differs from registry effect `token_maker`. | Usually oracle normalization; review only if behavior looks wrong in replay. |
| low | seed_63213000 | 2 | precombat_main | Yorion, Sky Nomad #38 (real) | spell_resolved | Aether Channeler | passive | Runtime effect `passive` differs from registry effect `token_maker`. | Usually oracle normalization; review only if behavior looks wrong in replay. |

## Promotion Rule

- `critical` and `high` findings block trusting optimizer output from this replay.
- `needs_review` rules that affect wincons, removal, wipes, counters or protection must become `verified` only after replay/regression coverage.
- Heuristic sources may remain for broad exploration, but product-facing swaps should prefer `verified` or `active` rules.

Report written: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260620_194539.md
