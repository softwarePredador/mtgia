# PG413 E2E Validation

Status: `pass`.

Focused tests:

- `test_xmage_authoritative_exact_scope_split.py`: 417 tests passed.
- `test_xmage_exact_scope_runtime.py`: 241 tests passed.
- `test_xmage_batch_pg_package_builder.py` + `test_sync_battle_card_rules_pg_selection.py` + `test_sync_battle_card_rules_manual_preserve.py`: 27 tests passed. Existing SQLite `ResourceWarning` messages appeared, but no failures.

Runtime behavior validated:

- `xmage_static_self_protection_from_colors_creature_v1` stores `protection_from` on the creature permanent.
- The battle target legality gate rejects a matching colored source, e.g. a red spell cannot target a creature with protection from red.
- The direct damage resolver returns `no_legal_creature_target` and leaves the protected creature on the battlefield.
- A nonmatching colored source remains legal, e.g. black can target a creature protected only from red.

Audits:

- XMage strategy consistency: 26/26 pass.
- Operational surface alignment: pass.
- PG/Hermes/SQLite contract: 51/51 pass.
- Legacy contamination: pass.
- Global card Oracle/battle readiness: `action_required`, expected because the all-card queue remains open after this 19-card package.
