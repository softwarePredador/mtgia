# PG520 XMage Counter Unless Pays Apply Evidence

- Generated at: `2026-07-05T17:55:00+00:00`
- Deploy ID: `xmage_pg520_counter_unless_pays_new_server`
- Status: `applied_synced_validated`
- Source of truth: PostgreSQL `card_battle_rules`
- Runtime scope: `xmage_counter_target_spell_unless_controller_pays_generic_v1`

## Scope

PG520 promotes exact local-XMage instant/sorcery one-shot counterspells whose
Oracle and XMage source both match:

`Counter target [spell/nonartifact spell] unless its controller pays {N}.`

The runtime stores the fixed generic tax in
`counter_unless_pays_generic` and resolves the counter only when the target
controller cannot pay.

## Promoted Cards

| Card | Target | Tax |
| --- | --- | ---: |
| `Convolute` | `spell` | 4 |
| `Force Spike` | `spell` | 1 |
| `It'll Quench Ya!` | `spell` | 2 |
| `Mana Tithe` | `spell` | 1 |
| `Mindstatic` | `spell` | 6 |
| `Quench` | `spell` | 2 |
| `Revolutionary Rebuff` | `nonartifact_spell` | 2 |

## PostgreSQL Evidence

Precheck:

- `target_card_rows=1` for all 7 selected cards.
- 6 cards had no existing rule rows.
- `Mana Tithe` had 2 old shadow rows selected for deprecation.
- `would_deprecate_shadow_rows=2`.

Apply:

- `deprecated_shadow_rows=2`
- `upserted_rows=7`
- transaction committed.

Postcheck:

- all 7 selected cards have `promoted_rule_rows=1`.
- all 7 selected cards have `promoted_verified_auto_rows=1`.
- all 7 selected cards have `promoted_oracle_hash_rows=1`.
- deploy backup table captured 2 preexisting rows.

SQL package:

- `docs/hermes-analysis/master_optimizer_reports/pg520_xmage_pg520_counter_unless_pays_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg520_xmage_pg520_counter_unless_pays_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg520_xmage_pg520_counter_unless_pays_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg520_xmage_pg520_counter_unless_pays_new_server_rollback.sql`

## Sync And Runtime Evidence

PostgreSQL -> Hermes/SQLite sync:

- `selected_card_count=7`
- `pg_rows_loaded=9` because the selected names include 2 deprecated shadow
  rows for `Mana Tithe`.
- `sqlite_inserted_or_updated=9`
- `canonical_snapshot_rows_exported=6042`
- exact E2E validation confirmed 7 promoted executable rules.

E2E package validation:

- PostgreSQL source of truth: `pass`, validated rows `7`.
- SQLite Hermes cache: `pass`, validated rows `7`.
- canonical snapshot fallback: `pass`, validated cards `7`.
- runtime `get_card_effect`: `pass`, validated cards `7`.
- battle execution no override: `pass`.

Focused runtime smoke:

- `Force Spike` against a target controller with no available generic mana:
  `result=countered`, `counter_tax_paid=false`, `stack_countered=true`.
- `Force Spike` against a target controller with 1 available generic mana:
  `result=not_countered_tax_paid`, `counter_tax_paid=true`,
  `counter_tax_paid_by=Active`, `stack_countered=false`.

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py`
- `Ran 849 tests`
- `OK`

Final audits:

- strategy consistency: `pass`, 26 checks.
- operational surface alignment: `pass`.
- legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `pass`, 51 checks.

## Queue Delta

Before PG520, the post-PG519 authoritative queue reported:

- `target_identity_count=25978`
- `xmage_authoritative_source_count=25664`
- `xmage_authoritative_adapter_required_count=25664`

After PG520:

- `target_identity_count=25971`
- `xmage_authoritative_source_count=25657`
- `xmage_authoritative_adapter_required_count=25657`
- final exact-scope split `proposal_count=0`
- final exact-scope split `safe_for_batch_pg_package_count=0`

## Residual Boundary

PG520 deliberately does not promote counter-unless cards with dynamic or
non-fixed taxes, X costs, domain/count formulas, devotion formulas, modal
branches, additional effects such as exile-if-countered, alternate targets, or
activated/triggered counter abilities.

Blocked neighbors include:

- `Clash of Wills`
- `Concerted Defense`
- `Evasive Action`
- `Ixidor's Will`
- `No More Lies`
- `Reject`
- `Scatter Ray`
- `Spectral Interference`
- `Spell Stutter`
- `Syncopate`
- `Thassa's Rebuff`

Those cards require separate runtime/modeling work before any PostgreSQL
promotion.
