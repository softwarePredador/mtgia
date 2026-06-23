# PG115 Monument to Endurance Discard Modal Trigger

Prepared at: `2026-06-23 17:39:39 -03`

Scope:

- Promote `Monument to Endurance` from a generic `passive` curated row to an
  Oracle/XMage-backed executable discard-trigger modal rule.
- Preserve PostgreSQL as source of truth, then sync the reviewed row back into
  Hermes SQLite after apply/postcheck.
- Audit backup table created by the apply step:
  `manaloom_deploy_audit.pg115_monument_to_endurance_discard_modal_trigger_20260623_1739`.

Target rule:

- `card_name=Monument to Endurance`
- `logical_rule_key=battle_rule_v1:0ae531be7c36226d3f118c93feab3735`
- `oracle_hash=a60dc736f7e86e15001c8c7e59ff23c4`
- `effect=discard_trigger_modal_draw_treasure_opponent_life_loss`
- `battle_model_scope=discard_trigger_choose_unpicked_mode_draw_treasure_life_loss_v1`

Runtime contract:

- Trigger on each discard by the source controller.
- Modes available per turn: `draw_card`, `create_treasure`,
  `opponents_lose_3_life`.
- Each mode can be chosen at most once per turn.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg115_monument_to_endurance_discard_modal_trigger_precheck_20260623_173939.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg115_monument_to_endurance_discard_modal_trigger_apply_20260623_173939.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg115_monument_to_endurance_discard_modal_trigger_postcheck_20260623_173939.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg115_monument_to_endurance_discard_modal_trigger_rollback_20260623_173939.sql`

Execution order:

1. Run precheck and confirm exactly one Oracle-hash-matched `cards` row.
2. Apply the package and confirm the legacy passive row is deprecated.
3. Run postcheck and confirm one active verified/auto promoted row with the
   expected hash and zero active shadows.
4. Sync `Monument to Endurance` from PostgreSQL to Hermes SQLite.
5. Run focused tests, coherence re-audit, and battle replay validation.
