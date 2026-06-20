# PG-008 - Machine God's Effigy Battle Rule Package

Status: `applied_validated_runtime_synced_battle_trusted`
Owner: Auditor Central / single operator
Prepared at: `2026-06-20 12:10 -0300`
Target table: `card_battle_rules`
Target card: `Machine God's Effigy`
Target card id: `1f48fdfb-983c-429b-a777-df0ce2b1d8f0`
Target logical rule key: `battle_rule_v1:c07949dca69471872a2d2b70c527b5f8`

## Source Evidence

- Latest battle artifact changed after the previous trusted state:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_150241/summary.json`.
- Current latest reports:
  `battle_replay_final_status=review_required`,
  `mandatory_gate_divergences=["forensic_audit=review_required"]`,
  `forensic_lineage_status=incomplete`,
  `forensic_rule_findings=1`, and `test_results_total=16` with all tests
  passing.
- Blocking seed:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_150241/seed_63211509/forensic_audit.json`.
- The finding is one medium forensic rule finding:
  `Machine God's Effigy`, event `spell_cast`, effect `ramp_permanent`, source
  `functional_tags_json`, recommendation `Move this card into card_battle_rules
  with verified/active status`.
- PostgreSQL read-only inspection found the target card row with
  `oracle_id=64ebdd6f-acde-4aab-a86b-2798bad5f70c`, official oracle text, and
  no `card_battle_rules` rows. `card_intelligence_snapshot` has
  `function_tags={ramp}`, `battle_rule_count=0`, and
  `has_any_battle_rules=false`.

## Proposed Row

The package inserts one runtime-safe but explicitly partial rule:

- `source=curated`
- `review_status=active`
- `execution_status=auto`
- `confidence=0.820`
- `effect_json.effect=ramp_permanent`
- `effect_json.produces=U`
- `effect_json.mana_produced=1`
- `effect_json.battle_model_scope=copy_artifact_mana_rock_partial_v1`
- `effect_json.copy_target_selection_not_modeled=true`
- `deck_role_json.category=ramp`
- `deck_role_json.subtype=copy_artifact_mana_rock`

Rationale:

- The battle engine already resolved the card as `ramp_permanent` through the
  broad `functional_tags_json` fallback. This package does not broaden runtime
  behavior beyond that fallback; it makes the event traceable to
  `card_battle_rules`.
- `active` is used instead of `verified` because the exact copy/ETB target
  selection and copied text are not modeled. The safe partial approximation is a
  4-mana artifact that can produce blue mana.
- `review_only/needs_review` would not close the current mandatory forensic
  gate, because the forensic auditor also flags game events that depend on
  `needs_review` rules.

## Files

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql`

## Apply Protocol And Result

Rafael moved this work into the Auditor Central single-operator thread with
authorization for database deploy, validation, and worktree organization. The
package was applied after the precheck matched the target card and confirmed no
existing Machine God's Effigy battle rule.

Precheck command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_precheck_20260620_1210.sql
```

Apply command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_apply_20260620_1210.sql
```

Postcheck command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_postcheck_20260620_1210.sql
```

Rollback command, if needed:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server && set -a && source .env && set +a && PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/machine_gods_effigy_battle_rule_pg008_rollback_20260620_1210.sql
```

## Runtime Follow-Up After Apply

Completed follow-up:

- Precheck result: target card `1`, existing target rule `0`, existing any
  Machine God's Effigy rule `0`; snapshot before had `battle_rule_count=0` and
  `function_tags={ramp}`.
- Apply result: `INSERT 0 1`, `COMMIT`.
- Postcheck result: `pg008_target_rule_count=1`; `card_intelligence_snapshot`
  exposes the Machine God's Effigy rule in `battle_rules`; backup rows `0`
  because no prior target row existed.
- SQLite backup:
  `docs/hermes-analysis/manaloom-knowledge/backups/knowledge.db.pre-pg008-runtime-sync.20260620_1210.bak`.
- Runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_execution_status_sqlite_refresh_20260620_1210_post_pg008.json`
  with `pg_rows_loaded=5190`, `sqlite_inserted_or_updated=5108`, and
  `canonical_snapshot_rows_exported=3161`.
- Full recurring battle rerun:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_151437/summary.json`
  with `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_lineage_status=complete`,
  `forensic_rule_findings=0`, `forensic_turn_findings=0`, and tests `16/16`
  pass.

PostgreSQL is the product source of truth; Hermes SQLite is only the runtime
cache/auditor surface.
