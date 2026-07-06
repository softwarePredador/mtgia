# PG549 Token Flashback New Server Apply Evidence

- Generated at: `2026-07-06T04:24:30+00:00`
- Deploy id: `pg549_token_flashback_new_server`
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_package_manifest.json`
- PostgreSQL target: `143.198.230.247:5433/halder`
- SQLite target: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Canonical snapshot: `docs/hermes-analysis/manaloom-knowledge/scripts/known_cards_canonical_snapshot.json`
- XMage source root: `/Users/desenvolvimentomobile/Downloads/mage-master`

## Scope

PG549 promotes the safe spell-based fixed creature token creation rows where
XMage adds `CreateTokenEffect` plus `FlashbackAbility` and the flashback cost is
an exact mana cost that agrees with Oracle text.

Runtime-backed scope covered by this package:

- `xmage_fixed_create_creature_tokens_spell_v1`

The package deliberately excludes non-mana flashback costs, unsupported token
keywords, dynamic token counts, ETB/dies triggered token creation, and any row
whose XMage auxiliary ability does not match `FlashbackAbility`.

## Cards Applied

| Card | Tokens | Flashback cost | Runtime proof state |
| --- | ---: | --- | --- |
| `Army of the Damned` | 13 tapped `Zombie Token` | `{7}{B}{B}{B}` | battle execution created 13 modeled Zombie tokens |
| `Beast Attack` | 1 `Beast Token` | `{2}{G}{G}{G}` | battle execution created 1 modeled Beast token |
| `Call of the Herd` | 1 `Elephant Token` | `{3}{G}` | battle execution created 1 modeled Elephant token |
| `Chatter of the Squirrel` | 1 `Squirrel Token` | `{1}{G}` | battle execution created 1 modeled Squirrel token |
| `Crush of Wurms` | 3 `Wurm Token` | `{9}{G}{G}{G}` | battle execution created 3 modeled Wurm tokens |
| `Elephant Ambush` | 1 `Elephant Token` | `{6}{G}{G}` | battle execution created 1 modeled Elephant token |
| `Join the Dance` | 2 `Human Token` | `{3}{G}{W}` | battle execution created 2 modeled Human tokens |
| `Lingering Souls` | 2 `Spirit Token` with `flying` | `{1}{B}` | battle execution created 2 modeled Spirit tokens |
| `Moan of the Unhallowed` | 2 `Zombie Token` | `{5}{B}{B}` | battle execution created 2 modeled Zombie tokens |
| `Reap the Seagraf` | 1 `Zombie Token` | `{4}{U}` | battle execution created 1 modeled Zombie token |
| `Roar of the Wurm` | 1 `Wurm Token` | `{3}{G}` | battle execution created 1 modeled Wurm token |
| `Shadowbeast Sighting` | 1 `Beast Token` | `{6}{G}` | battle execution created 1 modeled Beast token |

## PostgreSQL Apply

Evidence files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_precheck_output.txt`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_apply_output.txt`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_postcheck_output.txt`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_package_rollback.sql`

Precheck found all 12 target card rows. `Army of the Damned` had 2 existing
nonmatching rows that the package intentionally deprecated; the other 11 cards
had no existing rule rows.

Apply result:

- `deprecated_shadow_rows`: 2
- `upserted_rows`: 12
- transaction result: `COMMIT`

Postcheck result:

- each card has `promoted_rule_rows = 1`
- each card has `promoted_verified_auto_rows = 1`
- each card has `promoted_oracle_hash_rows = 1`

## Hermes / SQLite Sync

Evidence files:

- Sync output: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_sync_output.txt`
- Sync report: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_sync_report.json`

Sync result:

- `pg_rows_loaded`: 8867
- `sqlite_inserted_or_updated`: 8631
- `canonical_snapshot_rows_exported`: 6370

## Runtime / E2E

Evidence files:

- E2E JSON: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_e2e.json`
- E2E MD: `docs/hermes-analysis/master_optimizer_reports/pg549_token_flashback_new_server_e2e.md`

E2E status: `pass`

- validated PostgreSQL source of truth: 12 rows
- validated SQLite/Hermes cache: 12 rows
- validated canonical snapshot fallback: 12 rows
- validated runtime card effect lookup: 12 rows
- battle execution scenarios: 12
- battle execution events: 24

## Audits

| Audit | Status |
| --- | --- |
| `pg_hermes_sqlite_contract_audit_20260706_post_pg549_token_flashback_new_server_with_pg.json` | `pass` (`51/51`) |
| `xmage_strategy_consistency_audit_20260706_post_pg549_token_flashback_new_server.json` | `pass` (`26/26`) |
| `operational_surface_alignment_audit_20260706_post_pg549_token_flashback_new_server.json` | `pass` |
| `legacy_contamination_audit_20260706_post_pg549_token_flashback_new_server.json` | `pass` |
| `global_card_oracle_battle_readiness_20260706_post_pg549_token_flashback_new_server.json` | `action_required` |

The readiness audit remains `action_required` because the global all-card XMage
adaptation queue is not finished; it is not a regression for PG549.

## Remaining Global Queue

Post-PG549 queue summary:

- `target_identity_count`: 25624
- `xmage_authoritative_source_count`: 25310
- `xmage_missing_source_exception_count`: 314
- `xmage_authoritative_parser_gap_count`: 0
- `xmage_authoritative_adapter_required_count`: 25310
- `adapter_work_unit_count`: 11366
- `token_maker`: 2333

The final exact-scope split after PG549 returned:

- `proposal_count`: 0
- `safe_for_batch_pg_package_count`: 0

That means this fixed token creation with mana flashback subpattern is exhausted
and the next package must target a different XMage work unit/family.

## Cleanup Policy

The raw queue JSON files for this package are temporary processing artifacts and
should not be committed because each is large. The compact `.md` queue
summaries, package SQL, postcheck outputs, sync reports, E2E reports, and audit
reports are retained as durable evidence.
