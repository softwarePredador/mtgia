# PG026 Lorehold Magus+Sphere Deck Deploy Validation - 2026-06-22 17:09 UTC

## Scope

- Official deck target: PostgreSQL deck
  `528c877f-f829-4207-95e6-73981776c323`, mirrored to Hermes SQLite deck
  `6`.
- Applied deck swap:
  - Remove `Electroduplicate`.
  - Remove `Victory Chimes`.
  - Add `Magus of the Moat`.
  - Add `Sphere of Safety`.
- Goal: convert the previously tested Magus+Sphere candidate into the durable
  PostgreSQL/Hermes deck state and re-run the real battle gate without a
  temporary swap.

## PostgreSQL Package

- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_precheck_20260622_165810.sql`
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_apply_20260622_165810.sql`
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_postcheck_20260622_165810.sql`
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_rollback_20260622_165810.sql`
- Package:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_package_20260622_165810.md`

## PostgreSQL Evidence

Precheck confirmed:

- Deck rows/quantity: `100/100`.
- `Electroduplicate` deck row: `1`.
- `Victory Chimes` deck row: `1`.
- `Magus of the Moat` deck rows before apply: `0`.
- `Sphere of Safety` deck rows before apply: `0`.
- `Magus of the Moat` commander legality rows: `1`.
- `Sphere of Safety` commander legality rows: `1`.
- Verified battle rules existed for both new cards.
- Existing backup table rows: `0`.

Apply result:

- Backup table created:
  `manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810`.
- Backup rows inserted: `2`.
- Post-apply deck rows:
  - `Electroduplicate`: `0`.
  - `Victory Chimes`: `0`.
  - `Magus of the Moat`: `1`.
  - `Sphere of Safety`: `1`.
  - Total quantity: `100`.

Postcheck confirmed:

- Deck rows/quantity: `100/100`.
- `Electroduplicate` rows: `0`.
- `Victory Chimes` rows: `0`.
- `Magus of the Moat` rows: `1`.
- `Sphere of Safety` rows: `1`.
- Backup rows: `2`.

Rollback was not executed because precheck, apply, postcheck, SQLite sync, and
post-deploy battle validation passed.

## SQLite/Hermes Sync

Sync command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db --pg-deck-id 528c877f-f829-4207-95e6-73981776c323 --target-deck-id 6 --min-total-cards 100 --apply --report docs/hermes-analysis/master_optimizer_reports/sync_pg_target_deck_to_hermes_pg026_magus_sphere_20260622_165810.json
```

Sync report:

- `cards_written=100`.
- `quantity_written=100`.
- `deck_hash=d43fde9ac9ff60ba4a3578579c50c85c2d761b9057daa5979182ae31a65fa268`.
- `ruleset_hash=89ad57eea9c9feabb93e9dd8b51bbb1a2d0d04dfa0d51429f18a070151a7180d`.
- `sync_run_id=20260622T170115Z`.

SQLite direct validation:

- `Magus of the Moat|1|0`.
- `Sphere of Safety|1|0`.
- Deck rows/quantity: `100/100`.
- Both new cards carry the PG026 deck hash and ruleset hash.

## Battle Validation

Post-deploy official artifact:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_170304/summary.json`
- `run_profile=pg026_magus_sphere_post_deploy_16_seed`.
- `invocation_kind=codex_pg026_magus_sphere_post_deploy_16_seed`.
- `start_seed=63231313`.
- `seeds_completed=16`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `battle_replay_final_status_reason=all_mandatory_gates_pass`.
- `mandatory_gate_divergences=[]`.
- `test_results_status_counts={"pass":18}`.
- `table_intent_statuses={"pass":16}`.
- `target_pressure_statuses={"pass":16}`.
- Lorehold wins: `6/16`.
- Opponent wins: `10/16`.

Lorehold winning seeds:

- `63231314`: Lorehold, `approach`, turn `11`.
- `63231315`: Lorehold, `approach`, turn `14`.
- `63231316`: Lorehold, `elimination`, turn `19`.
- `63231324`: Lorehold, `approach`, turn `11`.
- `63231327`: Lorehold, `approach`, turn `9`.
- `63231328`: Lorehold, `approach`, turn `21`.

Replay text observability:

- `seed_63231314/replay.txt` line `19` shows opening hand:
  `Lorehold: 1 mulligan(s), 7 cards, 2 lands, HandCards=[Sphere of Safety, Esper Sentinel, Pyroblast, Mana Confluence, Jeska's Will, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Clifftop Retreat]`.
- `seed_63231314/replay.txt` line `142` shows cleanup and retained hand:
  `DiscardedCards=[War Room, Urza's Saga, Drannith Magistrate] HandCards=[Sphere of Safety, Pyroblast, Giver of Runes, Get Lost, Flawless Maneuver, Spectator Seating, Deflecting Swat]`.
- `seed_63231314/replay.txt` final summary shows final `HandCards=[...]` for
  Lorehold and all opponents.

## Reading

- PG026 is a durable deck deploy, not a temporary simulator swap.
- The deployed Magus+Sphere deck improved the controlled 16-seed matrix from
  the PG025 official deck result of Lorehold `0/16` to Lorehold `6/16`.
- The deck is better, but not solved: opponents still win `10/16`.
- The remaining work should analyze the ten post-PG026 losses from
  `20260622_170304` before another deck or PostgreSQL change is proposed.
