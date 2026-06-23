# PG109 Bender's Waterskin and Victory Chimes Package

Status: `prepared_read_only_precheck_pending_apply_approval`.

Scope:

- Cards: `Bender's Waterskin`, `Victory Chimes`.
- No PostgreSQL apply was executed.
- Purpose: preserve Oracle/XMage-backed mana artifact behavior in PostgreSQL
  before any future PG -> SQLite sync can reintroduce stale rows.

Why this exists:

- `Bender's Waterskin` has a trusted local/runtime shape but PostgreSQL still
  contains stale generated review-only shadow rows and no oracle hash.
- `Victory Chimes` is correct in local SQLite as a colorless mana artifact, but
  live PostgreSQL still contains an older verified `draw_engine` row. This must
  not survive as an executable rule.

Proposed rules:

- `Bender's Waterskin`:
  `battle_rule_v1:cf94f06a51a48080913a6c01290c7be2`,
  `oracle_hash=1bd371e1f09ed8b48837c3fc5cd2a2ff`,
  `effect=ramp_permanent`,
  `battle_model_scope=artifact_any_color_mana_rock_untaps_each_opponent_untap_step_v1`,
  `produces=WUBRG`.
- `Victory Chimes`:
  `battle_rule_v1:85d354bb1522e745de9e1bac865fd5e0`,
  `oracle_hash=8ca84e1f2e9f3efd1fe740d16d216105`,
  `effect=ramp_permanent`,
  `battle_model_scope=political_colorless_mana_rock_multiplayer_untap_v1`,
  `produces=C`.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_precheck_20260623_171938.sql`.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_precheck_20260623_171938.json`
  and
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_precheck_20260623_171938.out`.
- Apply candidate:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_apply_20260623_171938.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_rollback_20260623_171938.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_postcheck_20260623_171938.sql`.
- Focused runtime evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg109_benders_waterskin_victory_chimes_focused_runtime_20260623_171938.json`.

Runtime evidence:

- `Bender's Waterskin` source colors resolve to `wildcard`; after refresh it
  can pay `{R}`, `{1}`, and `{C}`.
- `Victory Chimes` source colors resolve to `colorless`; after refresh it can
  pay `{1}` and `{C}` but cannot pay `{R}`.
- Limitation: the runtime artifact validates mana color/payment behavior. The
  multiplayer untap cadence and Victory Chimes political target choice are
  preserved as model-scope metadata, not fully replayed in this focused check.

PostgreSQL read-only precheck:

- Target DB: `143.198.230.247:5433/halder`.
- `Bender's Waterskin`: `target_card_rows=1`,
  `card_oracle_hash_match_rows=1`, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, `trusted_rule_rows_before=1`,
  `trusted_missing_oracle_hash_rows_before=1`,
  `would_deprecate_shadow_rows=2`, `active_draw_engine_rows_before=0`.
- `Victory Chimes`: `target_card_rows=1`,
  `card_oracle_hash_match_rows=1`, `existing_rule_rows=2`,
  `expected_rule_rows_before=0`, `trusted_rule_rows_before=1`,
  `trusted_missing_oracle_hash_rows_before=1`,
  `would_deprecate_shadow_rows=2`, `active_draw_engine_rows_before=1`.
- The active `draw_engine` row for `Victory Chimes` is live PostgreSQL drift and
  should be disabled by PG109 before future PG -> SQLite syncs.

Apply gate:

- Do not run the apply SQL without explicit approval for the exact command.
- If approved later, required sequence is precheck, apply, postcheck,
  PG -> SQLite sync for these two cards, and deck `607` coherence re-audit.
