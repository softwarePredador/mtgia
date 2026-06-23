# PG056 Deck 608 Dragon Package

Purpose:

- Correct and promote the runtime model for the `Dragon's Approach` package in
  Lorehold Variant 03 / `deck_id=608`.
- Fix the simulator behavior where `Dragon's Approach` incorrectly scaled
  damage from graveyard copies.
- Add reviewed provenance for `Thrumming Stone` ripple support.
- No deck swap and no `deck_cards` mutation.

Target cards:

- `Dragon's Approach`.
- `Thrumming Stone`.

Files:

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_precheck_20260623_015223.sql`.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_apply_20260623_015223.sql`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_postcheck_20260623_015223.sql`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_rollback_20260623_015223.sql`.
- Precheck output:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_precheck_20260623_015223.out`.
- Apply output:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_apply_20260623_015223.out`.
- Postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_postcheck_20260623_015223.out`.
- SQLite-from-PG sync:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg056_deck608_dragons_approach_thrumming_20260623_015223.json`.
- Focused events:
  `docs/hermes-analysis/master_optimizer_reports/deck608_dragons_approach_thrumming_pg056_focused_events_20260623_015223.jsonl`.
- Deck 608 post-apply audit:
  `docs/hermes-analysis/master_optimizer_reports/deck_card_battle_rule_coherence_audit_deck608_20260623_015223.json`.

Expected postcheck:

- `target_cards=2`.
- `target_rule_rows=4`.
- `trusted_active_rows=2`.
- `trusted_missing_hash_rows=0`.
- `trusted_hash_mismatch_rows=0`.
- `trusted_without_scope_rows=0`.
- `generated_review_only_rows=0`.
- `disabled_or_deprecated_rows=2`.
- `backup_rows=4`.

Runtime tests:

- `test_dragons_approach_deals_fixed_damage_and_tutors_dragon_from_graveyard_cost`.
- `test_thrumming_stone_ripples_dragons_approach_without_bonus_damage`.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`.
