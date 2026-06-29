# Lorehold Molecule Man / The Scarlet Witch Validation - 2026-06-29

- status: `ready`
- postgres_writes: `false`
- source_db_mutated: `false`
- natural_gate: `8 real opponents x 3 games x 3 seeds = 72 games per candidate`
- forced_opening_diagnostic: `8 real opponents x 3 games x seed 42 only; diagnostic, not promotion proof`

## Decision

- `Molecule Man`: runtime rule is valid, but current natural and forced evidence does not justify restoring it over `The One Ring` by itself. Keep as a high-ceiling hypothesis, not a promoted swap.
- `The Scarlet Witch`: runtime rule is valid and has real cast/use evidence. Scarlet alone performed poorly in the current package, but the paired restore with Molecule/old shell deserves a confirmation gate because it beat the promoted candidate by one win and improved Winota.
- `Molecule Man + The Scarlet Witch`: promising but not decisive. Natural result was `19/72`, one win above promoted `18/72`, but forced-opening collapsed and Molecule itself was still barely cast. Do not replace the promoted deck yet; run a confirmation gate or a better cut model first.

## Structural Matrix

| Candidate | Rank | Score | Intent | Rule Ready | Risks |
| --- | ---: | ---: | ---: | ---: | --- |
| `candidate_607_v615_mana_engine_v1` | 1 | 141.114 | 100.0 | 96.8% | recursion_role, tutor_role |
| `candidate_607_v615_mana_engine_molecule_retest_v1` | 2 | 140.979 | 100.0 | 96.8% | recursion_role, tutor_role |
| `candidate_607_v615_mana_engine_scarlet_retest_v1` | 1 | 141.171 | 100.0 | 97.9% | recursion_role, tutor_role |
| `candidate_607_v615_mana_engine_molecule_scarlet_retest_v1` | 1 | 141.036 | 100.0 | 97.9% | recursion_role, tutor_role |

## Natural Battle Gate

| Deck | W/Games | Winota | Seed 42 | Seed 7 | Seed 20260625 | Miracle | Topdeck | Birgi Mana | Key Card Use |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `deck_607` | 18/72 (25.00%) | 1-8 | 3/24 | 8/24 | 7/24 | 85 | 80 | 0 | Molecule Man: cost_paid=1,spell_cast=1,spell_resolved=1 |
| `candidate_607_v615_mana_engine_v1` | 18/72 (25.00%) | 1-8 | 6/24 | 2/24 | 10/24 | 98 | 82 | 87 | Birgi, God of Storytelling // Harnfel, Horn of Bounty: cost_paid=18,spell_cast=16,trigger_resolved=87; The One Ring: cost_paid=13,spell_cast=13,spell_resolved=10,utility_artifact_activated=18; Mana Vault: cost_paid=20,spell_cast=20 |
| `candidate_607_v615_mana_engine_molecule_retest_v1` | 16/72 (22.22%) | 2-7 | 6/24 | 9/24 | 1/24 | 103 | 83 | 42 | Molecule Man: cost_paid=3,spell_cast=3,spell_resolved=3; Birgi, God of Storytelling // Harnfel, Horn of Bounty: cost_paid=13,spell_cast=12,trigger_resolved=42; Mana Vault: cost_paid=13,spell_cast=13 |
| `candidate_607_v615_mana_engine_scarlet_retest_v1` | 12/72 (16.67%) | 0-9 | 1/24 | 5/24 | 6/24 | 104 | 77 | 0 | The Scarlet Witch: cost_paid=15,spell_cast=15,spell_resolved=15; The One Ring: cost_paid=14,spell_cast=14,spell_resolved=9,utility_artifact_activated=13; Mana Vault: cost_paid=18,spell_cast=18 |
| `candidate_607_v615_mana_engine_molecule_scarlet_retest_v1` | 19/72 (26.39%) | 3-6 | 8/24 | 8/24 | 3/24 | 95 | 77 | 0 | Molecule Man: cost_paid=1,spell_cast=1,spell_resolved=1; The Scarlet Witch: cost_paid=19,spell_cast=19,spell_resolved=19; Mana Vault: cost_paid=19,spell_cast=19 |

## Card-Level Interpretation

### Molecule Man

- Focused runtime test passed: it grants zero-miracle to nonland first draw.
- Natural `molecule_retest`: `16/72`; Molecule accessed `13` games, drawn `8`, cast/resolved `3`.
- Natural paired restore: `19/72`; Molecule accessed `17`, drawn `8`, cast/resolved only `1`.
- Forced opening hand did not reveal a strong ceiling: molecule candidate was `6/24` and Molecule was cast/resolved `3`; paired forced opening was `2/24` and Molecule was cast/resolved `1`.
- Interpretation: valid rule, valid concept, but current deck/ramp sequencing does not reliably turn Molecule into wins.

### The Scarlet Witch

- Focused runtime tests passed: reduces MV4+ instant/sorcery by source power and does not reduce invalid spells.
- Natural `scarlet_retest`: `12/72`; Scarlet accessed `19`, drawn `6`, cast/resolved `15`.
- Natural paired restore: `19/72`; Scarlet accessed `25`, drawn `7`, cast/resolved `19`, and Winota improved to `3-6`.
- Forced opening hand was mixed/negative inside the candidate shells: Scarlet-only candidate `2/24`; paired candidate `2/24`.
- Interpretation: Scarlet is real and used, but not enough alone. It should be kept in the next confirmation lane with a better cut model, not blindly swapped back now.

## Required Next Validation

1. Do not overwrite the promoted deck from this evidence alone.
2. Generate a confirmation candidate around `Mana Vault + Scarlet`, preserving either `The One Ring` or Birgi only if a better cut can be found than Molecule.
3. Run another natural 72-game confirmation against promoted current, not just 607.
4. Add card-level report fields for static cost reduction savings; current traces show Scarlet cast/use but not aggregate mana saved by Scarlet.
