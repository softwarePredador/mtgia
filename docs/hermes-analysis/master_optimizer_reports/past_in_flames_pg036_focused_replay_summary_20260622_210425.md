# PG036 Past in Flames Focused Replay Summary

Generated at: `2026-06-22T21:04:25Z`.

Artifacts:

- Events: `docs/hermes-analysis/master_optimizer_reports/past_in_flames_pg036_focused_events_20260622_210425.jsonl`.

Statuses:

- PG source rule: pass. Runtime selected `battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be` with oracle hash `12f293d8d746fbc4e5ba80828919dec5`.
- SQLite/Hermes sync: pass. The focused event was generated after syncing `knowledge.db` from PostgreSQL PG036.
- Runtime flashback grant: pass. `graveyard_flashback_granted` granted flashback to 2 instant/sorcery graveyard cards and did not grant it to the creature card.
- Runtime flashback cast provenance: pass. `flashback_cast` for `Battle Cantrip` includes `flashback_granted_rule_key=battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be`.
- Event contract: pass. `spell_resolved` and `graveyard_flashback_granted` include the PG036 logical rule key and oracle hash.

Reading:

- This closes card-level event proof for `Past in Flames` as a temporary flashback grant under the current battle model.
- Full priority/timing policy for every possible flashback spell remains the battle engine approximation; the base flashback exile-on-resolution path is covered by `test_flashback_cast_from_graveyard_exiles_after_resolution`.
