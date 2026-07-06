# PG575 Self-Sacrifice Mana Source Auxiliary E2E

Generated at: `2026-07-06T22:05:00+00:00`

## Scope

PG575 promotes exact XMage-derived mana abilities where the source sacrifices
itself as part of producing mana. The package intentionally executes only the
mana ability and records non-mana companion text as partial runtime metadata.

- Battle model scope:
  `xmage_self_sacrifice_mana_source_permanent_v1`
- Family: `xmage_self_sacrifice_mana_source_permanent`
- Cards: `Astrolabe`, `Barbed Sextant`, `Buried Treasure`, `Darkwater Egg`,
  `Generator Servant`, `Golden Egg`, `Kaleidostone`, `Lotus Bloom`,
  `Mossfire Egg`, `Omni-Cheese Pizza`, `Shadowblood Egg`, `Skycloud Egg`,
  `Sungrass Egg`, `Terrarion`, `Verdant Eidolon`

## Runtime Semantics

- The mapper accepts a safe `SimpleManaAbility` / `AnyColorManaAbility` window
  with `SacrificeSourceCost`.
- The runtime pays the activation mana cost when present, then sacrifices the
  source and creates contextual mana only when that mana unlocks a real
  same-turn play.
- Supported outputs in this package include fixed symbol outputs, any-color
  outputs, and "two mana in any combination of colors" where the current
  runtime can represent the flexible pool.
- Auxiliary abilities such as delayed draw, ETB draw, dies draw, Food,
  suspend, return-to-hand, or haste grants stay `_runtime_partial`; they are
  metadata evidence and are not executed by this package.
- Unsupported neighbors remain blocked instead of being collapsed into this
  scope.

## Applied Cards

| Card | Produces | Mana amount | Activation cost | Tap | Sacrifice source | Partial |
| --- | --- | ---: | --- | --- | --- | --- |
| `Astrolabe` | `WUBRG` | 2 | `{1}` | `true` | `true` | `true` |
| `Barbed Sextant` | `WUBRG` | 1 | `{1}` | `true` | `true` | `true` |
| `Buried Treasure` | `WUBRG` | 1 |  | `true` | `true` | `true` |
| `Darkwater Egg` | `UB` | 2 | `{2}` | `true` | `true` | `true` |
| `Generator Servant` | `C` | 2 |  | `true` | `true` | `true` |
| `Golden Egg` | `WUBRG` | 1 | `{1}` | `true` | `true` | `true` |
| `Kaleidostone` | `WUBRG` | 5 | `{5}` | `true` | `true` | `true` |
| `Lotus Bloom` | `WUBRG` | 3 |  | `true` | `true` | `true` |
| `Mossfire Egg` | `RG` | 2 | `{2}` | `true` | `true` | `true` |
| `Omni-Cheese Pizza` | `WUBRG` | 1 | `{1}` | `true` | `true` | `true` |
| `Shadowblood Egg` | `BR` | 2 | `{2}` | `true` | `true` | `true` |
| `Skycloud Egg` | `WU` | 2 | `{2}` | `true` | `true` | `true` |
| `Sungrass Egg` | `GW` | 2 | `{2}` | `true` | `true` | `true` |
| `Terrarion` | `WUBRG` | 2 | `{2}` | `true` | `true` | `true` |
| `Verdant Eidolon` | `WUBRG` | 3 | `{G}` | `false` | `true` | `true` |

Direct PostgreSQL verification:

```text
astrolabe|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|2|{1}|true|true|true
barbed sextant|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|true|true|true
buried treasure|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1||true|true|true
darkwater egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|UB|2|{2}|true|true|true
generator servant|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|C|2||true|true|true
golden egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|true|true|true
kaleidostone|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|5|{5}|true|true|true
lotus bloom|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|3||true|true|true
mossfire egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|RG|2|{2}|true|true|true
omni-cheese pizza|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|true|true|true
shadowblood egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|BR|2|{2}|true|true|true
skycloud egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WU|2|{2}|true|true|true
sungrass egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|GW|2|{2}|true|true|true
terrarion|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|2|{2}|true|true|true
verdant eidolon|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|3|{G}|false|true|true
```

Direct Hermes/SQLite verification:

```text
astrolabe|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|2|{1}|1|1|1
barbed sextant|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|1|1|1
buried treasure|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1||1|1|1
darkwater egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|UB|2|{2}|1|1|1
generator servant|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|C|2||1|1|1
golden egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|1|1|1
kaleidostone|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|5|{5}|1|1|1
lotus bloom|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|3||1|1|1
mossfire egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|RG|2|{2}|1|1|1
omni-cheese pizza|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|1|{1}|1|1|1
shadowblood egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|BR|2|{2}|1|1|1
skycloud egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WU|2|{2}|1|1|1
sungrass egg|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|GW|2|{2}|1|1|1
terrarion|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|2|{2}|1|1|1
verdant eidolon|verified|auto|xmage_self_sacrifice_mana_source_permanent_v1|WUBRG|3|{G}|0|1|1
```

## Validation

- `test_xmage_authoritative_exact_scope_split.py` passed after the mapper
  change: `671` tests.
- The battle runtime suite passed with PG-backed rules, including
  `test_verdant_eidolon_pays_green_and_sacrifices_source_for_contextual_mana`.
- Package precheck found `15/15` target card rows, no missing targets, and
  `0` existing expected executable rows before apply.
- Package apply verified `15/15` promoted rows with `review_status=verified`,
  `execution_status=auto`, and Oracle hashes.
- PG -> Hermes/SQLite sync loaded `15` PostgreSQL rows, updated `17` SQLite
  rows, and exported `6635` canonical snapshot rows.
- Post-PG575 queue moved to `target_identity_count=25355` and
  `xmage_authoritative_source_count=25041`.
- The exact-scope recheck still had one safe neighbor, `All-Fates Scroll`,
  isolated for PG576.

## Residual Boundary

PG575 does not authorize "different colors" constraints, static mana grants,
non-mana sacrifice abilities, discard/pay-life/exile costs, unsupported
conditional or dynamic mana, or source/Oracle mismatches. Examples left blocked
in this neighborhood include `Guild Globe`, `Basal Sliver`, `Lotus Ring`,
`Elsewhere Flask`, `Jack-o'-Lantern`, `Vulshok Factory`, and `Cryptex`.
