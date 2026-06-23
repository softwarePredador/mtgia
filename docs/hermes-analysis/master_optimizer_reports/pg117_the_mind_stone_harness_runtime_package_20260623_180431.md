# PG117 The Mind Stone Harness Runtime

Prepared at: `2026-06-23 18:04:31 -03`

Scope:

- Promote `The Mind Stone` as an Oracle/XMage-backed executable mana-rock rule.
- Keep PostgreSQL as source of truth, then sync the promoted row into Hermes SQLite.
- Use the runtime already added in `battle_analyst_v9.py` for harness activation
  and the repeated end-step blink.

Audit backup table:

- `manaloom_deploy_audit.pg117_the_mind_stone_harness_runtime_20260623_180431`

Target rule:

- `card_name=The Mind Stone`
- `logical_rule_key=battle_rule_v1:57bb1f91d9eea2ad14a8e8d24d2f8d53`
- `oracle_hash=17bda9d167ae2799376387d03be5681f`
- `effect=ramp_permanent`
- `battle_model_scope=legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1`

Runtime contract:

- The permanent is an indestructible white mana rock.
- It can spend `{5}{W}` and tap to become harnessed.
- Once harnessed, at each of its controller's end steps it may blink up to one
  other nonland permanent the controller owns, preferring targets with ETB
  payoff.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg117_the_mind_stone_harness_runtime_precheck_20260623_180431.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg117_the_mind_stone_harness_runtime_apply_20260623_180431.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg117_the_mind_stone_harness_runtime_postcheck_20260623_180431.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg117_the_mind_stone_harness_runtime_rollback_20260623_180431.sql`

Execution order:

1. Run precheck and confirm exactly one Oracle-hash-matched `cards` row.
2. Apply the package and upsert the promoted rule.
3. Run postcheck and confirm one active verified/auto row with the expected
   scope and hash.
4. Sync `The Mind Stone` from PostgreSQL to Hermes SQLite.
5. Rerun the deck 607 coherence audit to confirm it leaves the high queue.
