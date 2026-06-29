# PGC054 Spectator Seating Opponent-Count Runtime Package

Scope: `Spectator Seating` only.

Reason: the previous PG051 rule treated the bond-land ETB clause as a Commander-table assumption. In one-opponent battle gates that overstates early mana because Oracle says the land enters tapped unless you have two or more opponents.

Sources:

- Scryfall artifact: `docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_scryfall_oracle_20260629.json`
- Scryfall URI captured in artifact: `https://scryfall.com/card/msc/268/spectator-seating?utm_source=api`
- XMage local source: `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/s/SpectatorSeating.java`
  - Implements `EntersBattlefieldTappedUnlessAbility(TwoOrMoreOpponentsCondition.instance)`.
  - Adds separate red and white mana abilities.

Expected precheck:

- `target_cards=1`
- `target_rule_rows=2`
- `curated_auto_rows=1`
- `generated_disabled_rows=1`
- `target_oracle_hash_rows=1`
- `current_assumed_commander_rows=1`
- `current_annotation_scope_rows=1`
- `pgc054_namespace_rows=0`
- `backup_table_exists=0`

Runtime change:

- `battle_analyst_v9.py` now models conditional mana sources as one source with legal color choices.
- `Spectator Seating` enters tapped when live opponent count is below 2.
- `Spectator Seating` produces exact red/white choices, not off-color wildcard mana.
- `Sunbillow Verge` PGC053 data is now executable again in the current checkout through `conditional_mana_modes`.

Files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_precheck_20260629.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_apply_20260629.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_postcheck_20260629.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_rollback_20260629.sql`

Apply command:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
set -a; source server/.env; set +a
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_precheck_20260629.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_apply_20260629.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pgc054_spectator_seating_opponent_count_postcheck_20260629.sql
```
