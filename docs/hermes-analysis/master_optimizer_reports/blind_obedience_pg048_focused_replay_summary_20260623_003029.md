# PG048 Blind Obedience Focused Replay

- Card: `Blind Obedience`.
- Rule: `battle_rule_v1:40f23fcea3b7955bacd550a9090c6872`.
- Oracle hash: `4e62bff316f784c1b468b9e53146d2aa`.
- Scope: `opponent_artifact_creature_enter_tapped_extort_annotation_v1`.
- Extort status: `annotation_only`.

## Checks
- `sqlite_rule_key_loaded`: pass
- `sqlite_oracle_hash_loaded`: pass
- `extort_annotation_only`: pass
- `enter_tapped_flag_loaded`: pass
- `opponent_creature_entered_tapped`: pass
- `opponent_artifact_entered_tapped`: pass
- `controller_artifact_not_tapped_by_own_blind`: pass
- `static_events_use_pg048_key`: pass
- `static_events_use_pg048_hash`: pass
- `static_events_cover_opponent_artifact_and_creature`: pass

## Event Contract

- `spell_resolved` for Blind Obedience carries the PG048 rule key/hash.
- `static_enter_tapped_applied` fires for an opponent creature and opponent artifact.
- The same event is not emitted for the controller artifact entering under its own Blind Obedience.
- No extort drain/lifegain event is emitted; extort remains annotation-only.
