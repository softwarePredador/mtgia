# PG471 XMage Destroy Target Spell Evidence

Status: pass

Deploy: `pg471`

Database target: `143.198.230.247:5433/halder`

## Scope

Closed the exact XMage destroy-target spell family as ManaLoom scope
`xmage_destroy_target_spell_v1`.

Cards promoted:

| Card | Effect | Target | Additional cost |
| --- | --- | --- | --- |
| Bone Splinters | remove creature | creature | sacrifice creature |
| Embrace Oblivion | remove creature | creature | sacrifice artifact or creature |
| Powerstone Fracture | remove permanent | creature or planeswalker | sacrifice artifact or creature |
| Raze | remove permanent | land | sacrifice land |

## Validation

- Tightened the batch package E2E manifest to require spell additional-cost
  fields: `additional_cost`, `requires_sacrifice_*`,
  `xmage_additional_cost_class`, and `xmage_additional_cost_target`.
- Focused unit lane passed `719` checks.
- PostgreSQL precheck found `4` target rows, `0` missing targets,
  `0` existing expected rows, and `0` generated shadow rows to deprecate.
- PostgreSQL apply/postcheck promoted `4/4` rows as `verified`/`auto` with
  Oracle hashes; `failed_cards=[]`; backup captured `0` rows.
- Direct PostgreSQL verification confirmed all `4` promoted rows preserve
  `battle_model_scope=xmage_destroy_target_spell_v1`, target constraints,
  `additional_cost`, `xmage_additional_cost_class=SacrificeTargetCost`, and
  the expected sacrifice target.
- E2E validation passed across PostgreSQL, SQLite/Hermes cache, canonical
  snapshot fallback, and runtime `get_card_effect` for all `4` selected cards.
- Generic battle scenario count remained `0`; destroy-target sacrifice-cost
  behavior is covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy `26/26`, operational surface `39/39`, legacy contamination
  `32/32`, and PG/Hermes/SQLite contract `51/51`.

## Sync

- Metadata sync requested `5489` unique names, matched `5674` PostgreSQL cards,
  wrote `5585` SQLite cache alias rows, and left `1` unresolved row.
- Deck-card backfill matched `2699/2699` rows and updated `108` card ids.
- Full PG -> SQLite sync loaded `4511` PostgreSQL runtime rows, wrote `4503`
  SQLite runtime rows, exported `4478` canonical fallback rows, and retained
  `1947` generated rows, `145` curated rows, and `274` Oracle-normalized rows.

## Post-Sync Queue

- `target_identity_count=26375`
- `xmage_authoritative_source_count=26061`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=26061`
- Exact split recheck: `proposal_count=36`,
  `safe_for_batch_pg_package_count=36`

Largest remaining exact families:

- `xmage_dynamic_graveyard_count_damage_spell`: `4`
- `xmage_permanent_simple_activated_self_boost_until_eot`: `4`
- `xmage_simple_mana_source_with_etb_draw`: `4`
- `xmage_fixed_damage_draw_card_spell`: `3`
- `xmage_fixed_target_player_draw_spell`: `3`
- `xmage_x_damage_spell`: `3`
