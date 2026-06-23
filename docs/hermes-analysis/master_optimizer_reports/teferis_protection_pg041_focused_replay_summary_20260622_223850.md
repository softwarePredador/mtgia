# PG041 Teferi's Protection Focused Event Proof

Generated at: 2026-06-22T22:38:50Z

Artifacts:

- Events: `docs/hermes-analysis/master_optimizer_reports/teferis_protection_pg041_focused_events_20260622_223850.jsonl`

Rule proof:

- `spell_resolved.rule_logical_key`: `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`
- `spell_resolved.rule_oracle_hash`: `bdc0faecf4420dc6162c7e72e98cc0eb`
- `spell_resolved.destination`: `exile`
- `phase_out_resolved.rule_logical_key`: `battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a`
- `phase_out_resolved.rule_oracle_hash`: `bdc0faecf4420dc6162c7e72e98cc0eb`
- `phase_out_resolved.phased_count`: `3`
- `phase_out_resolved.phase_out_includes_lands`: `True`
- `phase_out_resolved.life_total_cant_change`: `True`
- `phase_out_resolved.protection_from_everything`: `True`
- `phase_out_resolved.exiles_self`: `True`

Runtime result:

- Battlefield after resolution: `[]`
- Phased out permanents: `['Monastery Mentor', 'Sol Ring', 'Plateau']`
- Teferi in exile: `True`
- Teferi in graveyard: `False`
- Life before damage: `8`
- Life after 20 damage attempt: `8`
- Life after 5 life-gain attempt: `8`
- Prevented/replacement event count after resolution: `2`

Reading:

- This is focused event proof, not a full 16-seed battle matrix.
- It proves the PG041 logical rule key through the runtime event contract for Teferi's Protection.
- `Blasphemous Act` cost reduction per creature remains `annotation_only`; PG029 proved only the 13-damage creature-wipe executor.
