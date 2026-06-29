# Card Adjustment Throughput Benchmark

- Generated UTC: `2026-06-29T12:17:07+00:00`
- Mode: `live`
- PostgreSQL writes: `False`
- Sample cards: `12`
- Verdict: `pass`

## Benchmarks

| Benchmark | Mode | Cards | Seconds | Sec/card | Cards/min | Success | Fail |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `local_lookup_attempt_planning` | `local` | `12` | `0.000187` | `1.6e-05` | `3847694.2` | `12` | `0` |
| `scryfall_collection_bulk_oracle` | `live` | `12` | `1.240199` | `0.10335` | `580.6` | `12` | `0` |
| `scryfall_bulk_cache_lookup` | `live` | `12` | `0.000154` | `1.3e-05` | `4663968.1` | `12` | `0` |
| `scryfall_named_hard_fallback` | `live` | `3` | `2.874934` | `0.958311` | `62.6` | `3` | `0` |
| `local_source_gate_audit` | `local` | `8` | `0.013355` | `0.001669` | `35942.5` | `8` | `0` |

## Estimates

- `oracle_bulk_seconds_per_card`: `0.1033`
- `oracle_bulk_cards_per_minute`: `580.6`
- `bulk_cache_lookup_seconds_per_card`: `1.3e-05`
- `bulk_cache_lookup_cards_per_minute`: `4663968.1`
- `bulk_cache_load_and_index_seconds`: `1.117008`
- `hard_named_fallback_seconds_per_card`: `0.9583`
- `hard_named_fallback_cards_per_minute`: `62.6`
- `local_planning_seconds_per_card`: `1.6e-05`

## Recommendations

- Use local Scryfall Oracle Cards cache for mass Oracle backfills; reserve live Collection/named calls for cache refresh and unresolved misses.

## Sample Cards

- Sol Ring
- Swords to Plowshares
- Path to Exile
- Blasphemous Act
- Spectator Seating
- Sunbillow Verge
- Ruby Medallion
- The Mind Stone
- Emeria's Call // Emeria, Shattered Skyclave
- Pinnacle Monk // Mystic Peak
- Witch Enchanter // Witch-Blessed Meadow
- Approach of the Second Sun
