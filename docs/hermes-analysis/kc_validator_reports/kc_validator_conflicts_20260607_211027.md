# KC Validator Conflict Report

- created_at: 2026-06-07T21:10:27.020975+00:00
- validated_count: 500
- total_filtered: 1968
- new_entries: 1322
- corrections: 5
- conflicts: 3
- json: `/opt/data/workspace/mtgia/docs/hermes-analysis/kc_validator_reports/kc_validator_conflicts_20260607_211027.json`

## Corrections

| Card | From | To |
| --- | --- | --- |
| Cinder Storm | remove_creature | finisher |
| Dragonstorm | draw_cards | finisher |
| Grapeshot | remove_creature | finisher |
| Fiery Encore | draw_cards | finisher |
| Mana Geyser | ramp_permanent | ramp_ritual |

## Conflicts Requiring Review

| Card | Current | Reclassified | Oracle sample |
| --- | --- | --- | --- |
| Glacial Chasm | finisher | indestructible | Cumulative upkeep—Pay 2 life. (At the beginning of your upkeep, put an age counter on this permanent, then sacrifice it unless you pay its upkeep cost for each age counter on it.) When this land enters, sacrifice a land. Creatures you contr |
| Mica, Reader of Ruins | finisher | copy_spell | Ward—Pay 3 life. (Whenever this creature becomes the target of a spell or ability an opponent controls, counter it unless that player pays 3 life.) Whenever you cast an instant or sorcery spell, you may sacrifice an artifact. If you do, cop |
| Mystic Forge | finisher | topdeck_manipulation | You may look at the top card of your library any time. You may cast artifact spells and colorless spells from the top of your library. {T}, Pay 1 life: Exile the top card of your library. |

## Next Action

- Corrections are auto-applied only when the new effect is clearly more specific.
- Conflicts are not auto-applied; review them before changing classification rules.
- Use this report as the review queue for Hermes knowledge hardening.
