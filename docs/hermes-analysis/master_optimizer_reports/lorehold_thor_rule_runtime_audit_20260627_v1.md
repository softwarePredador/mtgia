# Lorehold Thor Rule Runtime Audit - 2026-06-27

- Card: `Thor, God of Thunder`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Decision: `local_reviewed_runtime_rule_added_pending_durable_pg_sync`

## Runtime Rule

- Logical rule key: `battle_rule_v1:280e17ec34ac105baeb6989491c6ff25`
- Scope: `etb_graveyard_impulse_recast_noncreature_spell_damage_any_target_v1`
- Executed now: `noncreature_spell_cast -> damage_any_target`, amount from trigger spell mana value.
- Annotated, not fully executed yet: ETB exiles own graveyard Equipment/Instant/Sorcery for play until next turn.

## Evidence

- Focused runtime test: `30 passed` in `test_reviewed_battle_card_rules.py`.
- Temp SQLite sync: return code `0`, `134` rows inserted/updated, `0` manual rows, `0` generated rows included.
- Temp materialization after sync: deck materialized card count `94`; Thor deck rule count `1` with key `battle_rule_v1:280e17ec34ac105baeb6989491c6ff25`.

## Next Gate

- Run a Thor candidate battle gate only after the gate source SQLite has synced reviewed rules, or after explicit PostgreSQL promotion approval.
