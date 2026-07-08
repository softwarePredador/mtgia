# PG665 ETB Conditional Cast Mana Apply Evidence

- Applied UTC: `2026-07-08`
- PostgreSQL target: `127.0.0.1:15432/halder`
- Package: `pg665_etb_conditional_cast_mana_new_server`
- Scope: `xmage_creature_etb_add_fixed_mana_v1`
- Selected cards: `Coal Stoker`, `Iridescent Tiger`

## Precheck

- Target rows: `2`
- Existing expected rows: `0`
- Stale generated shadows to deprecate: `0`

## Apply

- Upserted rows: `2`
- Deprecated shadow rows: `0`

## Postcheck

| Card | Promoted Rule Rows | Verified/Auto Rows | Oracle Hash Rows | Backup Rows |
| --- | ---: | ---: | ---: | ---: |
| `Coal Stoker` | 1 | 1 | 1 | 0 |
| `Iridescent Tiger` | 1 | 1 | 1 | 0 |

## Runtime Evidence

Package E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot,
`runtime_get_card_effect`, and `2` battle-execution scenarios:

- `Coal Stoker`: cast from hand, condition `cast_from_hand`, added `{R}{R}{R}`.
- `Iridescent Tiger`: cast from graveyard, condition `cast`, added
  `{W}{U}{B}{R}{G}`.

## Sync Evidence

- PG -> SQLite sync loaded `9631` PostgreSQL rows, updated `9394` SQLite rows,
  and exported `7065` canonical snapshot rows after the follow-up hash
  backfill.
- Metadata sync used the new-server target and left `deck_cards` fully matched
  for the SQLite cache scope.
