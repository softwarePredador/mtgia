# Data Field Alias Contract - 2026-06-30

Status: `current_guardrail`.

Purpose: prevent ManaLoom/Hermes work from duplicating logic across equivalent
fields such as `oracle*`, `card_id`, `card_name`, `normalized_name`,
`logical_rule_key`, and external references.

## Canonical Fields

| Area | Canonical field | Accepted aliases/cache fields | Rule |
| --- | --- | --- | --- |
| Card row | `cards.id` / `card_id` | `deck_cards.card_id`, `card_oracle_cache.card_id`, `card_intelligence_snapshot.card_id` | Use `card_id` for joins and identity-stable comparisons whenever available. |
| Card identity | `cards.oracle_id` | `scryfall_id` only as fallback/printing reference | `oracle_id` identifies playable identity; `scryfall_id` identifies a printing. Do not use `scryfall_id` as identity when `oracle_id` exists. |
| Card name | `cards.name` / `card_intelligence_snapshot.name` | `deck_cards.card_name`, `card_oracle_cache.name`, `lorehold_variant_deck_cards.oracle_name`, `input_name` | Names are display/resolution aliases. They must not override `card_id` when both exist. |
| Normalized name | `normalized_name` | local normalizers in scripts | Use only as lookup fallback or SQLite cache key. If a matching `card_id` exists, `card_id` wins. |
| Oracle text | `oracle_text` from PostgreSQL/Scryfall-backed card data | cached `deck_cards.oracle_text`, `card_oracle_cache.oracle_text` | Cached Oracle text must be refreshed from the cache/sync path, not edited independently. |
| Battle rule identity | `logical_rule_key` | `_rule_logical_key` in replay payloads | `logical_rule_key` is the durable rule key; replay aliases are evidence fields only. |
| Battle rule drift | `oracle_hash` | `_rule_oracle_hash` in replay payloads | New exact runtime promotions must include Oracle hash. Missing hashes in old trusted rows are warnings until touched by a package. |
| Source/reference | explicit `source`, `source_url`, `source_ref`, `report_path` | free-text notes | Source fields are provenance, not identity. Do not join or dedupe business objects by source text. |

## Guardrails Now Enforced

`docs/hermes-analysis/manaloom-knowledge/scripts/pg_hermes_sqlite_contract_audit.py`
now checks the cross-field drift that caused duplicate work risk:

- `deck_cards.card_id` must match `card_oracle_cache.card_id` whenever the
  cache has a card id for that normalized name.
- Name differences such as `Birgi, God of Storytelling` versus
  `Birgi, God of Storytelling // Harnfel, Horn of Bounty` are allowed only when
  the same `card_id` canonicalizes both rows.
- Trusted executable `battle_card_rules` missing `oracle_hash` are surfaced as
  warnings. This remains a backlog for old rows, not a reason to block every
  current runtime package.

## Current Remediation

On 2026-06-30, the Hermes card metadata sync was run against live PostgreSQL and
the local SQLite cache:

- `deck_cards.card_id` missing before sync: `1174`.
- `deck_cards.card_id` rows updated by sync after refreshing aliases: `1233`.
- `deck_cards.card_id` missing after sync: `0`.
- `deck_cards` rows still using display-name aliases: `37`, all canonicalized
  by matching `card_id`.
- Unresolved card name from sync: `Surgical Suite/Hospital Room`.

Final live audit:

- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260630_alias_guardrail_final.md`
- status: `pass`
- summary: `48 pass`, `2 warn`
- remaining warnings:
  - old trusted executable rules missing `oracle_hash`;
  - empty legacy sibling SQLite artifact
    `docs/hermes-analysis/manaloom-knowledge/knowledge.db`.

## Working Rule For Agents

When two fields can describe the same thing, agents must pick the durable field
first:

1. `card_id` over any card name alias.
2. `oracle_id` over `scryfall_id` for playable identity.
3. `logical_rule_key` over effect text or generated rule labels.
4. `oracle_hash` over timestamp/source notes for rule drift detection.
5. Aggregated snapshots over raw multi-row joins.

If the durable field is absent but a cache/source table can fill it, run the
sync/backfill path before writing new logic around the missing value.
