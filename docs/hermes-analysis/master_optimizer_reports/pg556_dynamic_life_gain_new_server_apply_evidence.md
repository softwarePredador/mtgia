# PG556 Dynamic Life Gain New Server Apply Evidence

Status: `applied_synced_validated`.

PG556 promoted `12` XMage-authoritative dynamic controller life-gain spell
rules under `xmage_dynamic_controller_gain_life_spell_v1`.

Selected cards:

- `Blessed Reversal`
- `Bountiful Harvest`
- `Festival of Trokin`
- `Fruition`
- `Gerrard's Wisdom`
- `Invigorating Falls`
- `Joyous Respite`
- `Landbind Ritual`
- `Peach Garden Oath`
- `Presence of the Wise`
- `Toil to Renown`
- `Wandering Stream`

Core artifacts:

- package:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_package.md`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_manifest.json`
- precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_precheck.sql`
- apply:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_apply.sql`
- postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_postcheck.sql`
- rollback:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_package_rollback.sql`
- PG -> SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_sync_report.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg556_dynamic_life_gain_new_server_e2e.md`

Database evidence:

- precheck found `12/12` target card rows;
- precheck found `0` existing matching expected rule rows before apply;
- precheck identified `2` old nonmatching `Landbind Ritual` shadow rows to
  deprecate;
- apply upserted `12` rows;
- apply deprecated `2` shadow rows;
- postcheck confirmed `12/12` promoted rows;
- postcheck confirmed `12/12` `verified` + `auto` rows;
- postcheck confirmed `12/12` oracle-hash rows.

Sync and runtime evidence:

- PG -> SQLite sync target:
  `143.198.230.247:5433/halder`;
- sync loaded `8965` PostgreSQL rule rows;
- sync inserted/updated `8729` SQLite rows;
- sync exported `6466` canonical snapshot rows;
- package E2E `status=pass`;
- package E2E validated `12` scenarios and `24` battle events;
- E2E passed PostgreSQL source of truth, SQLite/Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution stages.

Queue impact:

- pre-cycle `target_identity_count=25538`;
- post-cycle `target_identity_count=25526`;
- pre-cycle `xmage_authoritative_adapter_required_count=25224`;
- post-cycle `xmage_authoritative_adapter_required_count=25212`;
- `life_gain::xmage_life_gain_variant_review_v1` work units reduced from
  `726` to `714`;
- final exact-scope split returned `proposal_count=0` and
  `safe_for_batch_pg_package_count=0` over `7224` considered supported rows.

Validation:

- `py_compile` passed for the splitter, runtime, package builder, and package
  E2E scripts;
- `958` splitter/runtime unittests passed;
- `54` package builder/E2E pytest tests passed;
- `xmage_strategy_consistency_audit` passed with `26/26` checks;
- `operational_surface_alignment_audit` passed;
- `legacy_contamination_audit` passed;
- `pg_hermes_sqlite_contract_audit` passed with `51/51` checks.

Runtime semantics:

- `life_gain_amount_source` now supports battlefield permanent count,
  controller hand count, graveyard card count, and domain basic land type count;
- battlefield permanent count supports card-type, subtype, combat-state, and
  tapped-state filters used by this package;
- the runtime computes the dynamic count at resolution time and emits replay
  evidence for the computed count and gained life.

Residual boundary:

- PG556 does not authorize dynamic life-gain patterns that depend on target
  opponent counts, target creature power/toughness, X values, converge/colors
  spent, damage dealt to the controller, or broader non-simple Oracle text.
  Those remain blocked until their own exact runtime adapter exists.
