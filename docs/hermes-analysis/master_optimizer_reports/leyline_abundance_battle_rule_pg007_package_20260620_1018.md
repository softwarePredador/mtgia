# PG-007 - Leyline of Abundance Battle Rule Package

Status: `applied_validated_runtime_synced_battle_trusted`
Owner: Auditor Central / single operator
Prepared at: `2026-06-20 10:18 -0300`
Target table: `card_battle_rules`
Target card: `Leyline of Abundance`
Target card id: `d524183f-6430-411b-8a9b-48eda6cb0f7d`
Target logical rule key: `battle_rule_v1:f3c990ed2e762aaab17c617ac3a42941`

## Source Evidence

- Latest battle artifact changed after the previous trusted state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/summary.json`.
- Current latest reports:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`,
  `forensic_rule_findings=1`, and `test_results_total=16` with all tests
  passing.
- Blocking seed:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_125745/seed_63211258/forensic_audit.json`.
- The finding is one medium forensic rule finding:
  `Leyline of Abundance`, event `spell_cast`, effect `ramp_permanent`, source
  `functional_tags_json`, recommendation `Move this card into card_battle_rules
  with verified/active status`.
- Current PostgreSQL read-only inspection found the target card row, but no
  `card_battle_rules` row for `Leyline of Abundance`; the current
  `card_intelligence_snapshot` row has `battle_rules=[]` and
  `function_tags={engine}`.

## Proposed Row

The package inserts one runtime-safe but explicitly partial rule:

- `source=curated`
- `review_status=active`
- `execution_status=auto`
- `confidence=0.820`
- `effect_json.effect=ramp_permanent`
- `effect_json.battle_model_scope=leyline_of_abundance_static_mana_bonus_partial_v1`
- `effect_json.activated_counter_ability_not_modelled=true`
- `deck_role_json.category=ramp`
- `deck_role_json.subtype=static_mana_bonus_enchantment`

Rationale:

- The battle engine already resolved the card as `ramp_permanent` through the
  broad `functional_tags_json` fallback. This package does not broaden runtime
  behavior beyond that fallback; it makes the event traceable to
  `card_battle_rules`.
- `active` is used instead of `verified` because historical focused evidence
  for this card is low/unsupported, and the activated counter ability is not
  modeled.
- `review_only/needs_review` would not close the current mandatory forensic
  gate, because the forensic auditor also flags game events that depend on
  `needs_review` rules.

## Files

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql`

## Apply Protocol And Result

Rafael moved this work into the Auditor Central single-operator thread with the
directive `faca tudo, faca deploy, suba em banco`. The package was applied after
the precheck matched the target card and confirmed no existing Leyline battle
rule.

Precheck command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_precheck_20260620_1018.sql
```

Apply command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_apply_20260620_1018.sql
```

Postcheck command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_postcheck_20260620_1018.sql
```

Rollback command, if needed:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/leyline_abundance_battle_rule_pg007_rollback_20260620_1018.sql
```

## Required Runtime Follow-Up After Apply

Completed follow-up:

- Apply result: `INSERT 0 1`, `COMMIT`.
- Postcheck result: `pg007_target_rule_count=1`; `card_intelligence_snapshot`
  exposes the Leyline rule in `battle_rules`; backup rows `0` because no prior
  target row existed.
- SQLite backup:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg007-runtime-sync.20260620_102701.bak`.
- Runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_102701_post_pg007.json`
  with `pg_rows_loaded=5189`, `sqlite_inserted_or_updated=5107`, and
  `canonical_snapshot_rows_exported=3160`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_132812/summary.json`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`, and
  tests `16/16` pass.

PostgreSQL is the product source of truth; Hermes SQLite is only the runtime
cache/auditor surface.
