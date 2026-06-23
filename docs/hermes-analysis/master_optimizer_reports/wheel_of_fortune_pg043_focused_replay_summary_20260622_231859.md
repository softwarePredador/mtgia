# PG043 Wheel of Fortune Focused Replay

- Source: PostgreSQL-synced `knowledge.db` after PG043.
- Card oracle: Each player discards their hand, then draws seven cards.
- Logical rule key: `battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Oracle hash: `c37cd579d8132efac0c2118608f6f001`.
- Battle model scope: `multiplayer_discard_draw_v1`.
- Replay event count: `1` wheel_resolved.
- Event rule_logical_key: `battle_rule_v1:f8bdb05cc883fda55628d6928c5562d3`.
- Event rule_oracle_hash: `c37cd579d8132efac0c2118608f6f001`.
- Draw count: `7`.
- Opponent cards drawn: `7`.
- Treasures created from Smothering Tithe payoff: `7`.
- Participants: `[{"discarded": 2, "discarded_to_graveyard": ["Old Instant", "Old Sorcery"], "discarded_to_top": [], "drawn": 7, "hand_after": 7, "player": "Caster"}, {"discarded": 1, "discarded_to_graveyard": ["Opponent Old Creature"], "discarded_to_top": [], "drawn": 7, "hand_after": 7, "player": "Opponent"}]`.
- Decision model_scope: `multiplayer_discard_draw_v1`.
- Decision wheel_payoffs: `['Smothering Tithe']`.
- Decision risk_flags: `[]`.
