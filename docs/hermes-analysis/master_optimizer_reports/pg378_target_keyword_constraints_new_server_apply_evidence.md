# PG378 Target Keyword Constraints New Server Evidence

Status: `applied_synced_validated`.

PG378 promoted `16` XMage-backed constrained activated target-keyword rules on
the new server PostgreSQL target (`127.0.0.1:15432/halder` through the
new-server tunnel).

## Scope

- Family: `xmage_permanent_simple_activated_target_keyword_until_eot_v1`
- Cards:
  `Accursed Horde`, `Air Marshal`, `Beacon Behemoth`, `Bloodthorn Taunter`,
  `Hotfoot Gnome`, `Jawbone Skulkin`, `Kelsinko Ranger`,
  `Krosan Groundshaker`, `Might Weaver`, `Mosstodon`, `Rage Weaver`,
  `Rakeclaw Gargantuan`, `Sky Weaver`, `Sootstoke Kindler`,
  `Spearbreaker Behemoth`, `Whalebone Glider`

## Implementation

- Runtime:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  now validates `target_subtypes` / `required_subtypes`, generic
  `required_supertypes`, and permanent targets for activated keyword rules.
- Splitter:
  `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
  now parses constrained target phrases and requires exact XMage/Oracle
  `target_constraints` agreement before packaging.

## Evidence

- Split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg378_target_keyword_constraints_new_server.md`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_package.md`
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_precheck_new_server.txt`
  matched `16/16` target card rows, `0` existing expected rows, and `0` shadow
  rows to deprecate.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_apply_new_server.txt`
  upserted `16` rows and deprecated `0` shadow rows.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_postcheck_new_server.txt`
  verified `16/16` promoted rows as `verified`, `auto`, and oracle-hash backed.
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg378_target_keyword_constraints_new_server.json`
  loaded `16` PG rows, updated `16` SQLite rows, and exported `5079` canonical
  snapshot rows.
- E2E:
  `docs/hermes-analysis/master_optimizer_reports/pg378_target_keyword_constraints_new_server_e2e.md`
  passed PostgreSQL, SQLite/Hermes, canonical snapshot, and runtime
  `get_card_effect` checks for `16/16` cards.
- Post-PG378 queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg378_target_keyword_constraints_new_server_commander_legal.md`
  reports `target_identity_count=26979`, `xmage_authoritative_source_count=26665`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26665`.
- Supported recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg378_target_keyword_constraints_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7736` considered supported rows.

## Tests And Audits

- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py`
  -> `302` tests OK.
- `python3 -m unittest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py`
  -> `178` tests OK.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
  -> OK.
- `docs/hermes-analysis/deduplicated-report-content/d03981cd01e411c535e893ccb94c8fa769d8c184ddf283702189e66f52e646ce.md`
  -> `26/26` pass.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg378_target_keyword_constraints_new_server_docs_after_update.md`
  -> pass.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg378_target_keyword_constraints_new_server_docs_after_update.md`
  -> pass.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg378_target_keyword_constraints_new_server.md`
  -> `49` pass and `1` inherited warning
  (`deck_id_607_has_no_pg_deck_id_note`).
