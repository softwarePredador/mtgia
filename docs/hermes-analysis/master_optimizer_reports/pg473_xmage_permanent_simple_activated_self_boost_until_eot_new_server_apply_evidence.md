# PG473 XMage Permanent Simple Activated Self Boost Evidence

Status: pass

Deploy: `pg473`

Database target: `143.198.230.247:5433/halder`

## Scope

Closed the exact XMage permanent simple activated self-boost family as ManaLoom
scope `xmage_permanent_simple_activated_self_boost_until_eot_v1`.

Cards promoted:

| Card | Activation cost | Boost | Duration |
| --- | --- | --- | --- |
| Foxfire Oak | `{R/G}{R/G}{R/G}` | +3/+0 | until end of turn |
| Frostburn Weird | `{U/R}` | +1/-1 | until end of turn |
| Loch Korrigan | `{U/B}` | +1/+1 | until end of turn |
| Parapet Watchers | `{W/U}` | +0/+1 | until end of turn |

## Validation

- Focused unit lane passed `720` checks.
- PostgreSQL precheck found `4` target rows, `0` missing targets,
  `0` existing expected rows, and `0` generated shadow rows to deprecate.
- PostgreSQL apply/postcheck promoted `4/4` rows as `verified`/`auto` with
  Oracle hashes; `failed_cards=[]`; backup captured `0` rows.
- Direct PostgreSQL verification confirmed all `4` promoted rows preserve
  `battle_model_scope=xmage_permanent_simple_activated_self_boost_until_eot_v1`,
  activation cost, hybrid color list, no tap requirement, duration, and
  power/toughness boost values.
- E2E validation passed across PostgreSQL, SQLite/Hermes cache, canonical
  snapshot fallback, and runtime `get_card_effect` for all `4` selected cards.
- Generic battle scenario count remained `0`; activated self-boost behavior is
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy `26/26`, operational surface `39/39`, legacy contamination
  `32/32`, and PG/Hermes/SQLite contract `51/51`.

## Sync

- Metadata sync requested `5497` unique names, matched `5682` PostgreSQL cards,
  wrote `5593` SQLite cache alias rows, and left `1` unresolved row.
- Deck-card backfill matched `2699/2699` rows and updated `92` card ids.
- Full PG -> SQLite sync loaded `4519` PostgreSQL runtime rows, wrote `4511`
  SQLite runtime rows, exported `4486` canonical fallback rows, and retained
  `1947` generated rows, `145` curated rows, and `274` Oracle-normalized rows.

## Post-Sync Queue

- `target_identity_count=26367`
- `xmage_authoritative_source_count=26053`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26053`
- Exact split recheck: `proposal_count=28`,
  `safe_for_batch_pg_package_count=28`

Largest remaining exact families:

- `xmage_simple_mana_source_with_etb_draw`: `4`
- `xmage_fixed_damage_draw_card_spell`: `3`
- `xmage_fixed_target_player_draw_spell`: `3`
- `xmage_x_damage_spell`: `3`
