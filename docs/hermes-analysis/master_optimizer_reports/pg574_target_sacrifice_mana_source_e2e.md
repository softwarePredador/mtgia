# PG574 Target-Sacrifice Mana Source E2E

Generated at: `2026-07-06T21:40:00+00:00`

## Scope

PG574 promotes exact XMage-derived activated mana abilities that sacrifice a
target permanent as a cost and only spend that mana when it unlocks a real
same-turn play.

- Battle model scope:
  `xmage_target_sacrifice_mana_source_permanent_v1`
- Family: `xmage_target_sacrifice_mana_source_permanent`
- Cards: `Evendo Brushrazer`, `Krark-Clan Stoker`, `Skirk Prospector`,
  `Thermopod`, `Valleymaker`

## Runtime Semantics

- The mapper accepts exactly one `SimpleManaAbility` window with
  `SacrificeTargetCost`.
- The runtime chooses a valid sacrifice target before creating mana.
- The sacrificed target must match both Oracle text and XMage source filters.
- The activation is contextual-only: the simulator does not sacrifice a real
  permanent unless the generated mana unlocks an actionable cast.
- Non-tap target-sacrifice sources, such as `Skirk Prospector`, may activate
  more than once only when each activation finds a new valid sacrifice target
  and unlocks a real play.

## Applied Cards

| Card | Sacrifice target | Produces | Mana amount | Contextual-only |
| --- | --- | --- | --- | --- |
| `Evendo Brushrazer` | `land` | `R` | `2` | `true` |
| `Krark-Clan Stoker` | `artifact` | `R` | `2` | `true` |
| `Skirk Prospector` | `goblin` | `R` | `1` | `true` |
| `Thermopod` | `creature` | `R` | `1` | `true` |
| `Valleymaker` | `forest` | `G` | `3` | `true` |

Direct PostgreSQL verification:

```text
evendo brushrazer|land|R|2|true
krark-clan stoker|artifact|R|2|true
skirk prospector|goblin|R|1|true
thermopod|creature|R|1|true
valleymaker|forest|G|3|true
```

Direct Hermes/SQLite verification:

```text
evendo brushrazer|land|R|2|1
krark-clan stoker|artifact|R|2|1
skirk prospector|goblin|R|1|1
thermopod|creature|R|1|1
valleymaker|forest|G|3|1
```

## Validation

- `py_compile` passed for the changed mapper/runtime/test files.
- `test_xmage_authoritative_exact_scope_split.py` passed: `666` tests.
- `test_battle_analyst_v10_3.py` passed, including
  `test_skirk_prospector_sacrifices_goblin_for_contextual_mana`.
- Package precheck found `5/5` target card rows, no missing targets, and
  `0` existing expected executable rows before apply.
- Package apply verified `5/5` promoted rows with `review_status=verified`,
  `execution_status=auto`, and Oracle hashes.
- PG -> Hermes/SQLite sync loaded `5` PostgreSQL rows, updated `7` SQLite rows,
  and exported `6621` canonical snapshot rows.
- Post-sync exact split recheck returned `proposal_count=0`.
- Global readiness after sync reported `battle_and_oracle_ready=5580` and
  `battle_family_mapper_required=28293`.
- Final audits passed:
  XMage strategy `26/26`, PG-Hermes-SQLite `51/51`, operational surface
  `pass`, legacy contamination `pass`, and server-target `pass`.

## Residual Boundary

PG574 does not authorize target-sacrifice mana sources with non-simple Oracle
text, source/Oracle sacrifice-target mismatch, mana output mismatch,
multi-sacrifice costs, discard/pay-life/exile costs, conditional mana, or
unsupported dynamic output. The current post-PG574 exact split residuals for
this neighborhood are:

- `Goblin Clearcutter`: `target_sacrifice_mana_source_mana_output_mismatch`
- `The Golden Throne`: `target_sacrifice_mana_source_oracle_not_simple`
- `Slobad, Iron Goblin`: `target_sacrifice_mana_source_sacrifice_target_mismatch`
- `Overeager Apprentice`: `mana_source_sacrifice_oracle_not_simple`
