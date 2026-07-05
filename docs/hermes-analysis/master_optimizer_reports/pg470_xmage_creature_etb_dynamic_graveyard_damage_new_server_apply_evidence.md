# PG470 XMage Creature ETB Dynamic Graveyard Damage Evidence

Status: pass

Deploy: `pg470`

Database target: `143.198.230.247:5433/halder`

## Scope

Closed the exact XMage creature enter-the-battlefield dynamic graveyard count
damage family as ManaLoom scope
`xmage_creature_etb_dynamic_graveyard_count_damage_v1`.

Cards promoted:

| Card | Target | Graveyard count | Count scope | Damage |
| --- | --- | --- | --- | --- |
| Cyclops Electromancer | Opponent creature | instant, sorcery | controller graveyard | count * 1 |
| Lotleth Giant | Opponent | creature | controller graveyard | count * 1 |
| Ossuary Rats | Opponent creature or planeswalker | creature | controller graveyard | count * 1 |
| Warfire Javelineer | Opponent creature | instant, sorcery | controller graveyard | count * 1 |

## Validation

- Focused unit lane passed `718` checks.
- PostgreSQL precheck found `4` target rows, `0` missing targets,
  `0` existing expected rows, and `0` generated shadow rows to deprecate.
- PostgreSQL apply/postcheck promoted `4/4` rows as `verified`/`auto` with
  Oracle hashes; `failed_cards=[]`; backup captured `0` rows.
- E2E validation passed across PostgreSQL, SQLite/Hermes cache, canonical
  snapshot fallback, and runtime `get_card_effect` for all `4` selected cards.
- Generic battle scenario count remained `0`; this exact ETB behavior is covered
  by the focused runtime/model tests.
- Final governance audits passed:
  XMage strategy `26/26`, operational surface `39/39`, legacy contamination
  `32/32`, and PG/Hermes/SQLite contract `51/51`.

## Sync

- Metadata sync requested `5485` unique names, matched `5670` PostgreSQL cards,
  wrote `5581` SQLite cache alias rows, and left `1` unresolved row.
- Deck-card backfill matched `2699/2699` rows and updated `108` card ids.
- Full PG -> SQLite sync loaded `4507` PostgreSQL runtime rows, wrote `4499`
  SQLite runtime rows, exported `4474` canonical fallback rows, and retained
  `1947` generated rows, `145` curated rows, and `274` Oracle-normalized rows.

## Post-Sync Queue

- `target_identity_count=26379`
- `xmage_authoritative_source_count=26065`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26065`
- Exact split recheck: `proposal_count=40`,
  `safe_for_batch_pg_package_count=40`

Largest remaining exact families:

- `xmage_destroy_target_spell`: `4`
- `xmage_dynamic_graveyard_count_damage_spell`: `4`
- `xmage_permanent_simple_activated_self_boost_until_eot`: `4`
- `xmage_simple_mana_source_with_etb_draw`: `4`
- `xmage_fixed_damage_draw_card_spell`: `3`
- `xmage_fixed_target_player_draw_spell`: `3`
- `xmage_x_damage_spell`: `3`
