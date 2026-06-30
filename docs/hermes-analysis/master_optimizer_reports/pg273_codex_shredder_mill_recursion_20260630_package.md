# PG273 Codex Shredder Mill/Recursion Package

Status: `applied_synced`.

This package promotes Codex Shredder from the broad recursion review lane to an
exact activated artifact runtime scope.

- Generated at: `2026-06-30T09:52:03Z`
- Selected cards: `["Codex Shredder"]`
- Family: `recursion` / `mill_and_graveyard_return`
- Local XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/c/CodexShredder.java`
- Focused runtime proof:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_card_specific_tests.py::test_pg273_codex_shredder_returns_graveyard_card_or_mills_target_player`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_manifest.json`

Expected promoted rule:

- card: `Codex Shredder`
- oracle_hash: `48dd2cf11a80189f548581507ab88df9`
- logical_rule_key: `battle_rule_v1:3417000adca740f0c5036e7232221df4`
- battle_model_scope:
  `tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1`
- effect: `passive`
- review/execution: `verified/auto`

Runtime behavior:

- `{T}` mills one target player using the target-player mill activation branch.
- `{5}, {T}, sacrifice this artifact` returns the highest-value legal card from
  the controller's graveyard to hand.
- Replay evidence includes both `utility_artifact_activated` and
  `recursion_resolved` for the graveyard-to-hand activation.

Apply result:

- precheck: `target_card_rows=1`, `existing_rule_rows=0`,
  `expected_rule_rows_before=0`, `active_review_scope_rows_before=0`,
  `would_deprecate_shadow_rows=0`
- apply: `backup_rows=0`, `deprecated_shadow_rows=0`, `upserted_rows=1`
- postcheck: `promoted_verified_auto_rows=1`,
  `promoted_expected_scope_rows=1`, `active_review_scope_rows_after=0`
- sync: `pg_rows_loaded=1`, `sqlite_inserted_or_updated=1`,
  `canonical_snapshot_rows_exported=3285`

Post-apply validation route:

- rerun focused Codex Shredder runtime test;
- verify SQLite and `known_cards_canonical_snapshot.json` expose the same
  logical rule key and scope;
- rebuild the Lorehold runtime-gap queue to remove Codex Shredder from the
  recursion split backlog.
