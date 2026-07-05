# PG472 XMage Dynamic Graveyard Count Damage Spell Evidence

Status: pass

Deploy: `pg472`

Database target: `143.198.230.247:5433/halder`

## Scope

Closed the exact XMage dynamic graveyard-count damage spell family as ManaLoom
scope `xmage_dynamic_graveyard_count_damage_spell_v1`.

Cards promoted:

| Card | Target | Graveyard count | Count scope | Damage |
| --- | --- | --- | --- | --- |
| Galvanic Bombardment | creature | named card: Galvanic Bombardment | controller graveyard | 2 + count |
| Ire of Kaminari | any target | subtype: arcane | controller graveyard | count |
| Kindle | any target | named card: Kindle | all graveyards | 2 + count |
| Scrapyard Salvo | player or planeswalker | artifact cards | controller graveyard | count |

## Validation

- Tightened the batch package E2E manifest to require dynamic graveyard damage
  fields: `damage_amount_source`, `damage_base_amount`,
  `damage_per_graveyard_count`, `graveyard_count_card_names`, and
  `graveyard_count_subtypes`.
- Focused unit lane passed `720` checks.
- PostgreSQL precheck found `4` target rows, `0` missing targets,
  `0` existing expected rows, and `0` generated shadow rows to deprecate.
- PostgreSQL apply/postcheck promoted `4/4` rows as `verified`/`auto` with
  Oracle hashes; `failed_cards=[]`; backup captured `0` rows.
- Direct PostgreSQL verification confirmed all `4` promoted rows preserve
  `battle_model_scope=xmage_dynamic_graveyard_count_damage_spell_v1`, target
  constraints, `damage_amount_source=graveyard_card_count`, base amount,
  per-count multiplier, count scope, and the expected count filter.
- E2E validation passed across PostgreSQL, SQLite/Hermes cache, canonical
  snapshot fallback, and runtime `get_card_effect` for all `4` selected cards.
- Generic battle scenario count remained `0`; dynamic graveyard-count damage
  behavior is covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy `26/26`, operational surface `39/39`, legacy contamination
  `32/32`, and PG/Hermes/SQLite contract `51/51`.

## Sync

- Metadata sync requested `5493` unique names, matched `5678` PostgreSQL cards,
  wrote `5589` SQLite cache alias rows, and left `1` unresolved row.
- Deck-card backfill matched `2699/2699` rows and updated `96` card ids.
- Full PG -> SQLite sync loaded `4515` PostgreSQL runtime rows, wrote `4507`
  SQLite runtime rows, exported `4482` canonical fallback rows, and retained
  `1947` generated rows, `145` curated rows, and `274` Oracle-normalized rows.

## Post-Sync Queue

- `target_identity_count=26371`
- `xmage_authoritative_source_count=26057`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26057`
- Exact split recheck: `proposal_count=32`,
  `safe_for_batch_pg_package_count=32`

Largest remaining exact families:

- `xmage_permanent_simple_activated_self_boost_until_eot`: `4`
- `xmage_simple_mana_source_with_etb_draw`: `4`
- `xmage_fixed_damage_draw_card_spell`: `3`
- `xmage_fixed_target_player_draw_spell`: `3`
- `xmage_x_damage_spell`: `3`
