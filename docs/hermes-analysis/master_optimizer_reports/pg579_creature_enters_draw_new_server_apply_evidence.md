# PG579 Creature Enters Draw New Server Apply Evidence

- Database target: `127.0.0.1:15432/halder`
- Package manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg579_creature_enters_draw_new_server_package_manifest.json`
- Apply SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg579_creature_enters_draw_new_server_package_apply.sql`
- Rollback SQL:
  `docs/hermes-analysis/master_optimizer_reports/pg579_creature_enters_draw_new_server_package_rollback.sql`

## Scope

PG579 promoted `5` XMage-authoritative creature-enters draw trigger rules:

- `Elemental Bond`
- `Garruk's Packleader`
- `Mary Jane Watson`
- `Wirewood Savage`
- `Woodland Liege`

The package is limited to supported permanent triggers where a creature entering
the battlefield draws cards for the controller under exact filters:

- creature you control with fixed minimum power;
- creature subtype entering under any player's control;
- another creature you control entering once each turn.

## Precheck

- target cards resolved: `5/5`
- expected executable rows before apply: `0`
- shadow/generated rows deprecated by apply: `4`
- cards with deprecated shadow rows:
  `Elemental Bond`, `Garruk's Packleader`

The deprecated rows were generated/review-only rows with no exact
`battle_model_scope`; no reviewed executable rule was removed.

## Apply

- deprecated shadow rows: `4`
- upserted rows: `5`
- transaction status: committed

## Postcheck

Each selected card had:

- promoted rule rows: `1`
- promoted `verified_auto` rows: `1`
- promoted Oracle-hash rows: `1`

## Sync And Runtime

- PG -> Hermes/SQLite sync loaded PostgreSQL rows: `5`
- SQLite inserted or updated rows: `9`
- canonical snapshot rows exported: `6654`
- E2E validation status: `pass`
- E2E PostgreSQL validated cards: `5`
- E2E SQLite validated cards: `5`
- E2E runtime `get_card_effect` validated cards: `5`
- E2E battle execution scenarios: `5`
- E2E battle execution events: `5`

Runtime proof:

- `Elemental Bond`, `Garruk's Packleader`, `Mary Jane Watson`, and
  `Woodland Liege` draw from `creature_you_control_enters`;
- `Wirewood Savage` draws from `creature_enters` when an opponent-controlled
  Beast enters.

## Queue Delta

Post-PG579 commander-legal queue:

- target identities: `25334`
- XMage authoritative source rows: `25020`
- XMage authoritative adapter-required rows: `25020`
- manual semantic decision units remaining: `314`
- top draw-engine work unit moved from `1593` to `1588`

Post-PG579 exact-scope recheck:

- proposal count: `0`
- safe batch PostgreSQL package count: `0`
- residual neighbor count:
  `creature_enters_draw_oracle_not_simple=4`

Residual boundary: optional-cost and per-turn/cards-not-supported variants
remain blocked and require separate runtime modeling.
