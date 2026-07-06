# PG545 Token Prowess Apply Evidence

- Deploy ID: `pg545_token_prowess_new_server`
- Scope: XMage-authoritative fixed creature-token spell with token `prowess`.
- Runtime scope: `xmage_fixed_create_creature_tokens_spell_v1`
- PostgreSQL target: `143.198.230.247:5433/halder`

## PostgreSQL

- Precheck: 1 target row, `target_card_rows=1`, no SQL errors.
- Existing expected rows found: 0.
- Shadow cleanup: 0 rows deprecated.
- Apply: `COMMIT`, 1 row upserted, 0 shadow rows deprecated.
- Postcheck: 1 promoted row, `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- Backup table rows: 0.

## Promoted Card

- `Goblin Wizardry`

## XMage Source

- Card class: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/g/GoblinWizardry.java`
- Token class: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage/src/main/java/mage/game/permanent/token/GoblinWizardToken.java`
- XMage behavior: `CreateTokenEffect(new GoblinWizardToken(), 2)`; token is a 1/1 red Goblin Wizard creature token with `ProwessAbility`.

## Mapper / Runtime

- `ProwessAbility` is now accepted by the token parser as `token_keywords=["prowess"]`.
- The battle runtime already recognizes `prowess` on token keywords and marks the token with `prowess=True`.
- Unsupported token keywords such as `infect` remain blocked.

## Hermes / SQLite

- Sync command: `sync_battle_card_rules_pg.py --apply-sqlite-from-pg --include-needs-review`
- PG rows loaded: 8,843
- SQLite rows inserted or updated: 8,607
- Canonical snapshot rows exported: 6,348

## Runtime E2E

- Validator: `battle_package_end_to_end_validation.py`
- Manifest: `pg545_token_prowess_new_server_package_manifest.json`
- Status: `pass`
- Stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical snapshot fallback, runtime lookup, battle execution.
- Battle scenarios: 1
- Battle events: 2
- Runtime evidence: `Goblin Wizardry` created two `Goblin Wizard Token` permanents; expected token count, power/toughness, colors, subtype, tapped state, and `prowess` keyword were validated by the package scenario.

## Test Coverage

- `python3 -m py_compile` passed for mapper, package builder, E2E validator, and battle runtime.
- XMage exact-scope split unittest passed: 598 tests, 0 failures.
- Package builder and E2E pytest suite passed: 43 tests, 0 failures.

## Contract Audits

- `xmage_strategy_consistency_audit_20260706_post_pg545_token_prowess_new_server_final`: pass, 26 checks.
- `pg_hermes_sqlite_contract_audit_20260706_post_pg545_token_prowess_new_server_with_pg`: pass, 51 checks.
- `operational_surface_alignment_audit_20260706_post_pg545_token_prowess_new_server_final`: pass.
- `legacy_contamination_audit_20260706_post_pg545_token_prowess_new_server_final`: pass.
- `global_card_oracle_battle_readiness_20260706_post_pg545_token_prowess_new_server_final`: action_required because the global all-card backlog remains open.

## Remaining Global Queue

- Commander-legal target identities still requiring adaptation: 25,648.
- XMage authoritative sources remaining: 25,334.
- Missing local XMage source exceptions: 314.
- Parser gaps: 0.
- Adapter work units remaining: 11,366.
- Post-apply exact split safe candidates: 0.
- All-card readiness: 34,331 known cards; 5,302 `battle_and_oracle_ready`; 28,571 still require battle-family mapper work.
- Token-creation battle gap family count: 3,541.

## Cleanup

- Raw queue JSON dumps for the pre-apply candidate source and post-apply global queue are not durable evidence because they are large intermediate files. Their `.md` summaries preserve the required metrics and routing signal.
