# PG576 Simple Mana Source Auxiliary Draw E2E

Generated at: `2026-07-06T22:06:00+00:00`

## Scope

PG576 promotes the remaining exact safe neighbor from the PG575 recheck:
`All-Fates Scroll`. Only its normal tap-for-mana ability becomes executable.
The separate sacrifice draw-X ability is retained as partial metadata and is
not executed by this package.

- Battle model scope:
  `xmage_simple_tap_mana_source_permanent_v1`
- Family: `xmage_simple_mana_source_with_unmodeled_auxiliary`
- Cards: `All-Fates Scroll`

## Runtime Semantics

- The executable rule is `{T}: Add one mana of any color.`
- The runtime treats the card as a simple tap mana source with contextual mana
  support inherited from the existing mana-source adapter.
- The `{7}, {T}, Sacrifice this artifact: Draw X cards...` ability remains
  `_runtime_partial`; it is not promoted as an executable draw/sacrifice rule.

## Applied Cards

| Card | Produces | Mana amount | Activation cost | Tap | Sacrifice source | Partial |
| --- | --- | ---: | --- | --- | --- | --- |
| `All-Fates Scroll` | `WUBRG` | 1 |  | `true` |  | `true` |

Direct PostgreSQL verification:

```text
all-fates scroll|verified|auto|xmage_simple_tap_mana_source_permanent_v1|WUBRG|1||true||true
```

Direct Hermes/SQLite verification:

```text
all-fates scroll|verified|auto|xmage_simple_tap_mana_source_permanent_v1|WUBRG|1||1||1
```

## Validation

- Package precheck found `1/1` target card row, no missing targets, and `0`
  existing expected executable rows before apply.
- Package apply verified `1/1` promoted row with `review_status=verified`,
  `execution_status=auto`, and Oracle hash.
- PG -> Hermes/SQLite sync loaded `1` PostgreSQL row, updated `1` SQLite row,
  and exported `6636` canonical snapshot rows.
- Post-PG576 queue moved to `target_identity_count=25354` and
  `xmage_authoritative_source_count=25040`.
- Global readiness after sync reported `battle_and_oracle_ready=5596` and
  `battle_family_mapper_required=28277`.
- Final exact-scope recheck returned `proposal_count=0`.
- Final audits passed: XMage strategy `26/26`, PG-Hermes-SQLite `51/51`,
  operational surface `pass`, legacy contamination `pass`, and server-target
  `pass`.

## Residual Boundary

PG576 does not authorize execution of All-Fates Scroll's draw-X sacrifice
ability. That remains an explicit future runtime family if the battle simulator
needs to model large activated draw effects.
