# Lorehold Mana Vault Method Repair Decision 2026-06-30

- Status: `rejected_keep_607_baseline`
- Scope: repaired one-card same-lane ramp test from protected deck `607`.
- Candidate: `candidate_607_v615_mana_vault_method_repair_v1`
- Swap: `+Mana Vault`; `-Bender's Waterskin`
- Preserved protected lanes: `Molecule Man`, `The Scarlet Witch`, `Victory Chimes`, and the rest of the 607 miracle/topdeck shell.
- PostgreSQL writes: `false`
- Source SQLite mutation: `false`

## Why This Test Exists

The prior 615 mana-engine candidate tied deck `607` in battle, but its cut logic
was not valid enough for an ideal-deck claim because it removed `Molecule Man`
for `The One Ring`. This repaired test keeps the miracle-zero and static
cost-reduction lanes intact and tests only whether `Mana Vault` is a better
same-lane ramp card than `Bender's Waterskin`.

External deckbuilding context still matters here: public Lorehold and
spellslinger guidance treats topdeck timing, instant/sorcery density, and
commander-specific enablers as plan-critical, while `Bender's Waterskin` and
`Victory Chimes` are relevant because they can support miracle timing outside
the Lorehold main turn.

## Generated Artifacts

- Candidate JSON: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_v615_mana_vault_method_repair_v1.json`
- Candidate decklist: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_v615_mana_vault_method_repair_v1.decklist.txt`
- Candidate DB: `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_v615_mana_vault_method_repair_v1/knowledge_candidate.db`
- Strategy matrix: `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_v615_mana_vault_method_repair_v1.md`
- Gate seed `20260630`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed20260630_real8_games3.md`
- Gate seed `123`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed123_real8_games3.md`
- Gate seed `999`: `docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_method_repair_gate_20260630_seed999_real8_games3.md`

## Structural Read

The strategy matrix ranked the repaired candidate and deck `607` as effectively
equal:

| Deck | Structural Score | Intent | Lands | Rule Ready | Main Risks |
| --- | ---: | ---: | ---: | ---: | --- |
| `candidate_607_v615_mana_vault_method_repair_v1` | `141.0` | `100.0` | `34` | `97.9%` | recursion_role, tutor_role |
| `deck_607` | `141.0` | `100.0` | `34` | `97.9%` | recursion_role, tutor_role |

Interpretation: the candidate is structurally coherent enough to test, but it
does not produce a structural reason to override battle evidence.

## Equal Battle Gate

Gate shape:

- Real opponents: `8`
- Games per opponent: `3`
- Seeds: `20260630`, `123`, `999`
- Total per deck: `72`
- Forced access: `none`
- Game timeout: `45s`
- Deck process timeout: `900s`
- Isolated deck process: `true`

Aggregate result:

| Deck | Wins | Games | WR | Losses | Stalls |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `30` | `72` | `41.67%` | `41` | `1` |
| `candidate_607_v615_mana_vault_method_repair_v1` | `24` | `72` | `33.33%` | `48` | `0` |

Seed breakdown:

| Seed | `deck_607` | Candidate |
| ---: | ---: | ---: |
| `20260630` | `11/24` | `7/24` |
| `123` | `8/24` | `7/24` |
| `999` | `11/24` | `10/24` |

## Card-Use Evidence

The candidate did not fail because `Mana Vault` was invisible. It was accessed
and cast often enough for the comparison to count.

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| `Bender's Waterskin` cost paid | `26` | `0` |
| `Bender's Waterskin` spell cast | `13` | `0` |
| `Mana Vault` cost paid | `0` | `36` |
| `Mana Vault` spell cast | `0` | `18` |
| `Molecule Man` cost paid | `4` | `14` |
| `Molecule Man` spell cast | `2` | `6` |
| `The Scarlet Witch` cost paid | `44` | `36` |
| `The Scarlet Witch` spell cast | `20` | `15` |
| `The Scarlet Witch` mana saved | `18` | `19` |
| `Victory Chimes` cost paid | `32` | `38` |
| `Victory Chimes` spell cast | `16` | `19` |

Strategic telemetry:

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| Miracle casts | `137` | `139` |
| Topdeck manipulation activations | `132` | `123` |
| Lorehold cost-paid events | `813` | `741` |
| Lorehold spell-cast events | `729` | `671` |
| Static cost-reduction casts | `99` | `92` |
| Static cost-reduction total mana saved | `221` | `155` |
| Scarlet-specific reduction casts | `9` | `9` |
| Scarlet-specific mana saved | `18` | `19` |

## Decision

Reject the repaired `Mana Vault` swap for the current 607 shell.

`Mana Vault` is still a powerful card and remains valid as a card to test in
other shells or packages, but this exact one-card replacement does not beat the
protected 607 baseline. `Bender's Waterskin` remains protected until a
same-lane replacement beats `607` on an equal real-opponent gate and preserves
the miracle/topdeck cadence.

## Next Deckbuilding Step

Keep deck `607` as the current best deck and protected baseline. The next
candidate should not cut `Bender's Waterskin`, `Molecule Man`, or `The Scarlet
Witch` unless the replacement directly challenges the same functional lane.

Highest-value next lane is draw/protection/value: test `The One Ring` only
against a true draw/protection/value slot, not against `Molecule Man`.

Public context sources to keep in the deckbuilding contract:

- EDHREC Lorehold commander page: `https://edhrec.com/commanders/lorehold-the-historian`
- EDHREC spellslinger Commander guide: `https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander`
- EDHREC Commander deckbuilding guide: `https://edhrec.com/articles/how-to-build-a-commander-deck`
- Archidekt Lorehold corpus: `https://archidekt.com/commanders/Lorehold%2C%20the%20Historian`
