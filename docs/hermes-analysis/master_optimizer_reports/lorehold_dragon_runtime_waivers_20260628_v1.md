# Lorehold Dragon Runtime Waivers

- generated_at_utc: `2026-06-28T19:20:00Z`
- postgresql_writes: `false`
- source_db_mutated: `false`

## What Was Learned

The current logs and queues showed two Lorehold variant cards with local XMage source and a supported ManaLoom runtime family, but `get_card_effect` still resolved them as `review_only/passive`:

- `Twinflame Tyrant`: decks `608`, `611`, `615`; XMage static replacement doubles damage from sources you control to opponents and permanents opponents control.
- `Terror of the Peaks`: decks `608`, `612`; XMage trigger deals damage equal to another entering controlled creature's power to any target.

## Runtime Fix

- Added temporary manual runtime waivers for both cards with verified/auto metadata and the existing PG package logical keys.
- Fixed a runtime bug in `_static_damage_modifier_effects`: the same static damage modifier could be discovered from both the battlefield permanent and `get_card_effect`, causing double application. The executor now deduplicates by permanent, scope, targets, applies-to value, and multiplier.

## Audit Fix

- Fixed `manaloom_log_learning_audit.py` so it no longer scans older `manaloom_log_learning_audit_*` reports as input evidence.
- Added a runtime-waiver overlay to classify cards like `Verge Rangers`, `Twinflame Tyrant`, `Terror of the Peaks`, and `Ephemerate` as `runtime_waived_pending_pg_promotion`, not `runtime_rule_missing`.
- Clean audit: `docs/hermes-analysis/master_optimizer_reports/manaloom_log_learning_audit_20260628_v8_after_dragon_waivers.json`.
- Next runtime-missing queue after overlay: `Goliath Daydreamer`, `Taunt from the Rampart`, `Semblance Anvil`, `Planetarium of Wan Shi Tong`, `Invincible Hymn`.

## Validation

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_dragon_runtime_waivers.py docs/hermes-analysis/manaloom-knowledge/scripts/test_static_damage_modifier_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_terror_of_the_peaks_runtime.py -q` -> `9 passed`
- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_manaloom_log_learning_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_dragon_runtime_waivers.py docs/hermes-analysis/manaloom-knowledge/scripts/test_static_damage_modifier_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_terror_of_the_peaks_runtime.py -q` -> `15 passed`
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/manaloom_log_learning_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/test_manaloom_log_learning_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_dragon_runtime_waivers.py` -> passed

## Remaining Boundary

This is runtime-only. Canonical PostgreSQL promotion still requires explicit approval plus successful PG precheck/apply/sync.
