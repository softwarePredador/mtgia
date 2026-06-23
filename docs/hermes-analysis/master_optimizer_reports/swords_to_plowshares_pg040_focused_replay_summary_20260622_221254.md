# PG040 Swords to Plowshares Focused Replay Summary

Generated at: `2026-06-22T22:12:54+00:00`

Scenario:

- Player: `Lorehold`.
- Opponent starts at `31` life with `Siege Rhino` on battlefield.
- `Siege Rhino`: power `4`, toughness `5`.
- Spell: `Swords to Plowshares` using runtime-selected PG040 effect.

Source rule:

- logical rule key: `battle_rule_v1:379008f3f03f94258292123453e3041c`
- oracle hash: `702f566e95dd477f5cf5a551e41e9df8`
- battle model scope: `swords_to_plowshares_creature_exile_life_equal_power_v1`

Observed outcome:

- `removal_resolved.destination`: `exile`
- `removal_resolved.target`: `Siege Rhino`
- `removal_resolved.target_power`: `4`
- `removal_resolved.life_gain_requested`: `4`
- `removal_resolved.life_gained`: `4`
- `removal_resolved.rule_logical_key`: `battle_rule_v1:379008f3f03f94258292123453e3041c`
- `removal_resolved.rule_oracle_hash`: `702f566e95dd477f5cf5a551e41e9df8`
- target in opponent battlefield after resolution: `False`
- target in opponent exile after resolution: `True`
- target in opponent graveyard after resolution: `False`
- opponent life after resolution: `35`
- spell zone event observed: `True`

Reading:

- This focused event proves the PG040 logical rule key executes the Swords oracle baseline currently modeled by battle: exile target creature and give its controller life equal to that creature's power.
- This is a card-level focused proof, not a full 16-seed deck battle matrix.
