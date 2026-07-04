# PG375 XMage Counter Draw Spell Wave Apply Evidence

- Generated at: `2026-07-04T00:59:30Z`
- PostgreSQL target: `127.0.0.1:15432/halder` via the new EasyPanel server tunnel.
- Package manifest: `docs/hermes-analysis/master_optimizer_reports/pg375_xmage_counter_draw_spell_wave_manifest.json`
- Scope: `xmage_counter_target_and_draw_card_spell_v1`
- Cards: `Bone to Ash`, `Contradict`, `Dismiss`, `Exclude`, `Halt Order`, `Scatter Arc`

## Runtime And Splitter Proof

- `python3 test_xmage_authoritative_exact_scope_split.py`: `288` tests, `OK`.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`: `173` tests, `OK`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_db_helper.py`: `1` test, `OK`.
- The focused runtime test proves the new counter-draw scope is selected as a stack response, counters a legal creature spell, moves the counterspell to graveyard, and draws `1` card through `draw_on_counter`.

## PostgreSQL Apply

Precheck:

- Target card rows matched by Oracle hash: `6/6`.
- Existing rule rows before apply: `0`.
- Would deprecate shadow rows: `0`.

Apply:

- `deprecated_shadow_rows`: `0`.
- `upserted_rows`: `6`.

Postcheck:

- `promoted_rule_rows`: `6/6`.
- `promoted_verified_auto_rows`: `6/6`.
- `promoted_oracle_hash_rows`: `6/6`.
- `backup_rows`: `0`.

## Sync And E2E

- PG -> Hermes/SQLite sync target: `127.0.0.1:15432/halder`.
- `pg_rows_loaded`: `6`.
- `sqlite_inserted_or_updated`: `6`.
- Canonical snapshot rows exported: `5023`.
- E2E validation status: `pass`.
- E2E validated stages: PostgreSQL source of truth `6/6`, SQLite/Hermes cache `6/6`, canonical snapshot fallback `6/6`, runtime `get_card_effect` `6/6`, battle execution no override `pass`.

## Queue Delta

- Pre-PG375 authoritative queue: `target_identity_count=27045`, `xmage_authoritative_adapter_required_count=26731`.
- Post-PG375 authoritative queue: `target_identity_count=27039`, `xmage_authoritative_adapter_required_count=26725`.
- `draw_cards::xmage_draw_card_variant_review_v1`: `654 -> 648`.
- `draw_effect_class_not_pure`: `522 -> 511`.
- Post-PG375 exact splitter: `proposal_count=0`, `safe_for_batch_pg_package_count=0`, `considered_supported_work_unit_rows=7796`.

## Final Audits

- XMage strategy consistency audit: `pass`, `26/26`.
- Operational surface alignment audit: `pass`.
- Legacy contamination audit: `pass`.
- PG/Hermes/SQLite contract audit: `status=pass`, `49 pass`, `1 warn`.
- The warning is `deck_id_607_has_no_pg_deck_id_note`, unrelated to PG375.

## New-Server Guard

- `db_helper.py` now prefers explicit process `DATABASE_URL` or complete `DB_*`/`PG*` variables over convenience `.env` values.
- Verified fail-closed behavior with no explicit env: missing DB config raises `RuntimeError` instead of falling back to an old server.
- Verified explicit `DB_*` target: `127.0.0.1:15432/halder`.
