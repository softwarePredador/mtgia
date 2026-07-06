# PG557 ETB Dynamic Life Gain New Server Apply Evidence

Status: `applied_synced_validated`.

PG557 promoted `12` XMage-authoritative creature ETB dynamic life-gain rules
under `xmage_creature_etb_dynamic_gain_life_v1`.

Selected cards:

- `Ancestor's Chosen`
- `Angel of Renewal`
- `Archway Angel`
- `Aven Gagglemaster`
- `Dwarven Priest`
- `Flourishing Hunter`
- `Goldnight Redeemer`
- `Kraul Foragers`
- `Luminollusk`
- `Nylea's Disciple`
- `Setessan Petitioner`
- `Shepherd of Heroes`

Core artifacts:

- package:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_package.md`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_manifest.json`
- precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_precheck.sql`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_apply.sql`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_postcheck.sql`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_package_rollback.sql`
- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_sync_report.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg557_etb_dynamic_life_gain_new_server_e2e.md`

Database evidence:

- precheck found `12/12` target card rows;
- precheck found `0` existing matching expected rule rows before apply;
- precheck identified `0` shadow rows to deprecate;
- apply upserted `12` rows;
- apply deprecated `0` shadow rows;
- postcheck confirmed `12/12` promoted rows;
- postcheck confirmed `12/12` `verified` + `auto` rows;
- postcheck confirmed `12/12` oracle-hash rows.

Sync and runtime evidence:

- PG -> SQLite sync target:
  `143.198.230.247:5433/halder`;
- sync loaded `8977` PostgreSQL rule rows;
- sync inserted/updated `8741` SQLite rows;
- sync exported `6478` canonical snapshot rows;
- package E2E `status=pass`;
- package E2E validated `12` scenarios and `12` battle events;
- E2E passed PostgreSQL source of truth, SQLite/Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution stages.

Queue impact:

- pre-cycle `target_identity_count=25526`;
- post-cycle `target_identity_count=25514`;
- pre-cycle `xmage_authoritative_adapter_required_count=25212`;
- post-cycle `xmage_authoritative_adapter_required_count=25200`;
- `life_gain::xmage_life_gain_variant_review_v1` work units reduced from
  `714` to `702`;
- final exact-scope split returned `proposal_count=0` and
  `safe_for_batch_pg_package_count=0` over `7212` considered supported rows.

Validation:

- `py_compile` passed for the splitter, runtime, package builder, and package
  E2E scripts;
- `962` splitter/runtime unittests passed;
- `54` package builder/E2E pytest tests passed;
- `xmage_strategy_consistency_audit` passed with `26/26` checks;
- `operational_surface_alignment_audit` passed with `39/39` checks;
- `legacy_contamination_audit` passed with `32/32` checks;
- `pg_hermes_sqlite_contract_audit` passed with `51/51` checks.

Runtime semantics:

- the splitter now maps exact ETB-triggered dynamic life-gain creatures backed
  by XMage `EntersBattlefieldTriggeredAbility` plus `GainLifeEffect`;
- `life_gain_amount_source` now supports graveyard card count, battlefield
  permanent count, colors among permanents you control, devotion to green,
  greatest toughness among other controlled creatures, and party count;
- battlefield permanent count supports subtype filters, keyword filters, and
  excluding the source permanent for "other creatures you control";
- the runtime computes the dynamic count at ETB resolution time and emits replay
  evidence for count source, computed count, and gained life.

Residual boundary:

- PG557 does not authorize non-ETB life-gain variants, target-opponent counts,
  target creature power/toughness, X values, converge/colors-spent logic,
  damage-dealt-derived life gain, or broad non-simple Oracle text. Those remain
  blocked until their own exact runtime adapter exists.
