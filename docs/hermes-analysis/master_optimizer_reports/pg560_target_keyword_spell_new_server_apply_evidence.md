# PG560 Target Keyword Spell New Server Apply Evidence

Status: `applied_postgresql_synced_validated`.

## Scope

PG560 promoted `10` XMage-authoritative exact target-keyword spell rows under
`xmage_fixed_keyword_target_creature_until_eot_spell_v1`.

Cards:

- `Alesha's Legacy`: target creature gains deathtouch and indestructible until end of turn
- `Assault Strobe`: target creature gains double strike until end of turn
- `Battle-Rage Blessing`: target creature gains deathtouch and indestructible until end of turn
- `Double Cleave`: target creature gains double strike until end of turn
- `Horrid Vigor`: target creature gains deathtouch and indestructible until end of turn
- `Jump`: target creature gains flying until end of turn
- `Offer Immortality`: target creature gains deathtouch and indestructible until end of turn
- `Serpent's Gift`: target creature gains deathtouch until end of turn
- `Ticked Off`: target creature gains double strike until end of turn
- `Unnatural Speed`: target creature gains haste until end of turn

## Artifacts

- candidate split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg560_target_keyword_spell_candidate.md`
- PostgreSQL package:
  `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_package_package.md`
- sync report:
  `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_sync_report.json`
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg560_target_keyword_spell_new_server_e2e.md`
- post-sync queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260706_post_pg560_target_keyword_spell_new_server.md`
- final split recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_post_pg560_target_keyword_spell_recheck.md`
- readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260706_post_pg560_target_keyword_spell_new_server.md`
- final audits:
  `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260706_post_pg560_target_keyword_spell_new_server_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260706_post_pg560_target_keyword_spell_new_server_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260706_post_pg560_target_keyword_spell_new_server_final.md`

## PostgreSQL Apply

Precheck:

- `10/10` proposed cards matched at least one PostgreSQL `cards` row by
  normalized name and Oracle hash.
- `0/10` already had the expected logical rule before apply.
- `0` active nonmatching shadow rows needed depreciation.

Apply:

- backup table:
  `manaloom_deploy_audit.pg560_target_keyword_spell_new_server_pg_20260706_102811`
- backup rows: `0`
- deprecated shadow rows: `0`
- upserted rows: `10`

Postcheck:

- promoted rule rows: `10/10`
- promoted verified/auto rows: `10/10`
- promoted Oracle-hash rows: `10/10`

## Sync And E2E

PG -> SQLite sync:

- PostgreSQL rows loaded: `9000`
- SQLite rows inserted or updated: `8764`
- canonical snapshot rows exported: `6501`
- PostgreSQL writes during sync: `0`

Package E2E:

- status: `pass`
- PostgreSQL source-of-truth validated rows: `10`
- SQLite Hermes cache validated rows: `10`
- canonical snapshot fallback validated cards: `10`
- runtime `get_card_effect` validated cards: `10`
- battle execution scenarios: `10`
- battle execution events: `20`

Each scenario resolved the rule through the runtime and confirmed the target
creature kept power/toughness unchanged while receiving the expected keyword or
keywords until end of turn.

## Queue Impact

Pre-cycle queue after PG559:

- `target_identity_count=25501`
- `xmage_authoritative_source_count=25187`
- `xmage_authoritative_adapter_required_count=25187`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1=1102`

Post-cycle queue after PG560:

- `target_identity_count=25491`
- `xmage_authoritative_source_count=25177`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25177`
- `adapter_work_unit_count=11354`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1=1092`

Final exact-scope recheck:

- `proposal_count=0`
- `safe_for_batch_pg_package_count=0`

## Final Audits

- XMage strategy consistency: `pass` (`26/26`)
- PG-Hermes-SQLite contract: `pass` (`51/51`)
- operational surface alignment: `pass`
- legacy contamination: `pass`

## Runtime Semantics

PG560 reuses the ManaLoom `stat_modifier_until_eot` runtime path with
`power_delta=0`, `toughness_delta=0`, and
`granted_keywords_until_eot` populated from XMage `GainAbilityTargetEffect`.

Supported in this lane:

- one-shot instant or sorcery spells;
- exactly one supported target-creature selector;
- fixed keyword grants only;
- no power/toughness boost;
- no modal choice, additional costs, auxiliary triggered/static abilities, or
  non-keyword side effects.

Residual boundary: PG560 does not authorize activated keyword-grant abilities,
mass keyword grants, protection-from-choice effects, keyword grants with boost,
or rows with auxiliary classes such as flashback, cycling, convoke, overload,
strive, channel, or unrelated triggered/static behavior. Those remain separate
exact-scope adapter work.
