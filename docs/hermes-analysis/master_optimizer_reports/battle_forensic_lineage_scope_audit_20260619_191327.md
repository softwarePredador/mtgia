# Battle Forensic Lineage Scope Audit - 2026-06-19T19:13Z

## Scope

This audit checks the current forensic lineage counters in the recurring battle
audit. It separates two claims:

- no unaccepted lineage gaps are present;
- every card event has complete PostgreSQL/card identity and semantic hash.

No code, PostgreSQL data, swaps, or commits were changed.

## Sources

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.md`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/forensic_audit.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/seed_*/forensic_audit.md`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`

## Current Latest State

- `timestamp_utc`: `2026-06-19T18:47:21Z`
- `battle_replay_final_status`: `trusted_for_strategy_learning`
- `mandatory_gate_divergences`: `[]`
- `seeds_with_high_or_critical_action_findings`: `[]`
- `seeds_with_high_or_critical_forensic_findings`: `[]`
- `seeds_with_strategy_blockers`: `[]`
- `forensic_rule_findings`: `0`
- `forensic_turn_findings`: `0`
- `forensic_lineage_status`: `complete`
- `forensic_lineage_unaccepted_missing_samples`: `[]`

## Aggregate Lineage Counters

Across the 16 latest seeds:

| Counter | Present | Missing | Missing accepted | Missing unaccepted |
| --- | ---: | ---: | ---: | ---: |
| `card_id` | `988` | `530` | `530` | `0` |
| `semantic_hash` | `988` | `530` | `530` | `0` |
| `rule_logical_key` | `1502` | `16` | `16` | `0` |

Total card events: `1518`.

Approximate missing rates:

- `card_id`: `34.9%`
- `semantic_hash`: `34.9%`
- `rule_logical_key`: `1.1%`

## Accepted Waiver Reasons

The latest summary aggregates accepted missing fields by reason:

| Waiver reason | Count |
| --- | ---: |
| `land_played_curated_runtime_rule_without_pg_card_identity` | `584` |
| `battle_rule_registry_without_card_identity_columns` | `430` |
| `type_line_creature_fact_no_rule_identity` | `48` |
| `manual_runtime_waiver_without_pg_identity` | `14` |

These counts are field-level waiver counts, so the total can be greater than the
number of card events with missing identity.

## Per-Seed Distribution

| Seed | Card events | Card ID present | Card ID missing | Semantic hash present | Semantic hash missing | Rule key present | Rule key missing |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `63201734` | `38` | `19` | `19` | `19` | `19` | `37` | `1` |
| `63201735` | `66` | `31` | `35` | `31` | `35` | `66` | `0` |
| `63201736` | `118` | `87` | `31` | `87` | `31` | `115` | `3` |
| `63201737` | `104` | `65` | `39` | `65` | `39` | `99` | `5` |
| `63201738` | `84` | `49` | `35` | `49` | `35` | `84` | `0` |
| `63201739` | `84` | `62` | `22` | `62` | `22` | `83` | `1` |
| `63201740` | `123` | `97` | `26` | `97` | `26` | `122` | `1` |
| `63201741` | `58` | `40` | `18` | `40` | `18` | `58` | `0` |
| `63201742` | `81` | `42` | `39` | `42` | `39` | `81` | `0` |
| `63201743` | `106` | `47` | `59` | `47` | `59` | `106` | `0` |
| `63201744` | `140` | `100` | `40` | `100` | `40` | `136` | `4` |
| `63201745` | `137` | `109` | `28` | `109` | `28` | `137` | `0` |
| `63201746` | `51` | `32` | `19` | `32` | `19` | `51` | `0` |
| `63201747` | `87` | `42` | `45` | `42` | `45` | `86` | `1` |
| `63201748` | `123` | `90` | `33` | `90` | `33` | `123` | `0` |
| `63201749` | `118` | `76` | `42` | `76` | `42` | `118` | `0` |

The missing identity fields are spread across the run, not isolated to one seed.

## Contract Reading

The current forensic lineage contract is working as designed:

- high/critical forensic findings are absent;
- all missing identity/hash/rule-key fields are classified by accepted waiver;
- unaccepted missing samples are empty;
- tests include an explicit regression that unaccepted lineage missing remains
  visible.

The important limitation is semantic:

`forensic_lineage_status=complete` means `missing_unaccepted=0`. It does not
mean every card event has a PostgreSQL `card_id`, `semantic_hash`, and
`rule_logical_key`.

## Finding

The current latest can be trusted under the mandatory gate contract, but
downstream learning, WR confirmation, and card-specific replay explanation must
not treat the forensic lineage as full per-event identity coverage.

For exact card identity learning, the relevant counters are the present/missing
pairs, not only `forensic_lineage_status`.

## Recommended Follow-up

- When reporting forensic readiness, always include:
  - `forensic_lineage_status`
  - `forensic_card_id_present/missing`
  - `forensic_semantic_hash_present/missing`
  - `forensic_rule_logical_key_present/missing`
  - accepted/unaccepted missing counters
  - waiver reasons
- Consider renaming or documenting `forensic_lineage_status=complete` as
  `forensic_lineage_missing_unaccepted_complete` in handoffs/docs.
- For future card-specific learning or exact rule attribution, prioritize
  reducing `battle_rule_registry_without_card_identity_columns` and
  `land_played_curated_runtime_rule_without_pg_card_identity` instead of only
  checking that unaccepted samples are empty.
