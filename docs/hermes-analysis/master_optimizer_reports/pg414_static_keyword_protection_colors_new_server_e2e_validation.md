# PG414 E2E Validation

Status: `pass`.

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py`: 419 tests passed.
- `test_xmage_exact_scope_runtime.py`: 241 tests passed.
- `test_xmage_batch_pg_package_builder.py` + `test_sync_battle_card_rules_pg_selection.py` + `test_sync_battle_card_rules_manual_preserve.py`: 27 tests passed. Existing SQLite `ResourceWarning` messages appeared, but no failures.

Runtime behavior validated:

- `xmage_static_self_protection_from_colors_creature_v1` can carry static self keywords and `protection_from` in the same creature rule.
- The battle target legality gate rejects a matching colored source.
- The direct damage resolver returns `no_legal_creature_target` and leaves the protected creature on the battlefield.
- A nonmatching colored source remains legal.

Audits:

- XMage strategy consistency: 26/26 pass.
- Operational surface alignment: pass.
- PG/Hermes/SQLite contract: initially failed on 44 older trusted executable rows missing `oracle_hash`; after backfill and full sync, 51/51 pass.
- Legacy contamination: pass.
- Global card Oracle/battle readiness: `action_required`, expected because the all-card queue remains open after this 32-card package.
