# PG026 Lorehold Magus + Sphere Deck Swap Package

## Scope

- Target deck: `528c877f-f829-4207-95e6-73981776c323`.
- Replace `Electroduplicate` with `Magus of the Moat`.
- Replace `Victory Chimes` with `Sphere of Safety`.
- Do not change battle rules in this package; `Magus of the Moat` and
  `Sphere of Safety` already have verified executable PostgreSQL rules.

## Evidence

- Official deck, current corrected pilot:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_165220/summary.json`
  reached `1/16` Lorehold wins, `15/16` opponent wins, with
  `battle_replay_final_status=trusted_for_strategy_learning` and tests
  `pass=18`.
- Candidate local SQLite swap:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_164720/summary.json`
  reached `6/16` Lorehold wins, `10/16` opponent wins, with
  `battle_replay_final_status=trusted_for_strategy_learning` and tests
  `pass=18`.
- Candidate winning seeds: `63231314`, `63231315`, `63231316`, `63231324`,
  `63231327`, `63231328`.
- Focus replay proof after cleanup guard:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260622_164600/seed_63231314/replay.txt`
  shows `DiscardedCards=[War Room, Urza's Saga, Drannith Magistrate]`,
  preserving `Sphere of Safety`, and Lorehold winning by Approach on turn 11.

## Commands

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_precheck_20260622_165810.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_apply_20260622_165810.sql
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_postcheck_20260622_165810.sql
```

Rollback:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f ../docs/hermes-analysis/master_optimizer_reports/lorehold_magus_sphere_deck_swap_pg026_rollback_20260622_165810.sql
```

## Guards

- Deck must remain `100` rows and `100` total quantity.
- Pre-state must contain exactly one `Electroduplicate` and one
  `Victory Chimes`.
- Pre-state must contain no `Magus of the Moat` or `Sphere of Safety`.
- Both candidate cards must be Commander legal.
- `Magus of the Moat` must have verified executable `attack_limit` rule
  `battle_rule_v1:439de5be33887bbce5dde1cfb367774a`.
- `Sphere of Safety` must have verified executable `attack_tax` rule
  `battle_rule_v1:a619518cf24caa68fdd86b555687f20f`.
- Apply stores both prior deck rows in
  `manaloom_deploy_audit.pg026_lorehold_magus_sphere_deck_swap_20260622_165810`.
