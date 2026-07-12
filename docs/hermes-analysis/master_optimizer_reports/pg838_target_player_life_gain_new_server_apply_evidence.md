# PG838 Target Player Life Gain Apply Evidence

- Database target: `127.0.0.1:15432/halder`
- Package: `pg838_target_player_life_gain_new_server`
- Applied at: `2026-07-12`
- Cards: `Heroes' Reunion`, `Natural Spring`, `Soothing Balm`

## Precheck

| Card | Target Rows | Existing Rule Rows | Expected Before | Shadow Rows To Deprecate |
| --- | ---: | ---: | ---: | ---: |
| `Heroes' Reunion` | 1 | 0 | 0 | 0 |
| `Natural Spring` | 1 | 0 | 0 | 0 |
| `Soothing Balm` | 1 | 0 | 0 | 0 |

## Apply

| Metric | Value |
| --- | ---: |
| `deprecated_shadow_rows` | 0 |
| `upserted_rows` | 3 |

## Postcheck

| Card | Promoted Rule Rows | Verified Auto Rows | Oracle Hash Rows | Backup Rows |
| --- | ---: | ---: | ---: | ---: |
| `Heroes' Reunion` | 1 | 1 | 1 | 0 |
| `Natural Spring` | 1 | 1 | 1 | 0 |
| `Soothing Balm` | 1 | 1 | 1 | 0 |

## E2E

`pg838_target_player_life_gain_new_server_e2e_validation.json` status: `pass`.

Runtime battle execution validated 3 scenarios:

| Card | Target Player | Life Gained | Life After |
| --- | --- | ---: | ---: |
| `Heroes' Reunion` | `Spell Controller` | 7 | 27 |
| `Natural Spring` | `Spell Controller` | 8 | 28 |
| `Soothing Balm` | `Spell Controller` | 5 | 25 |
