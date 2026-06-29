# Card Adjustment Throughput Benchmark

- Generated UTC: `2026-06-29T08:37:15+00:00`
- Mode: `live`
- PostgreSQL writes: `False`
- Sample cards: `15`
- Verdict: `pass`

## Benchmarks

| Benchmark | Mode | Cards | Seconds | Sec/card | Cards/min | Success | Fail |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `local_lookup_attempt_planning` | `local` | `15` | `0.000182` | `1.2e-05` | `4954121.4` | `15` | `0` |
| `scryfall_collection_bulk_oracle` | `live` | `15` | `1.311808` | `0.087454` | `686.1` | `15` | `0` |
| `scryfall_bulk_cache_lookup` | `live` | `15` | `0.000228` | `1.5e-05` | `3946641.1` | `15` | `0` |
| `scryfall_named_hard_fallback` | `live` | `3` | `0.274685` | `0.091562` | `655.3` | `3` | `0` |
| `local_source_gate_audit` | `local` | `8` | `0.012124` | `0.001515` | `39591.8` | `8` | `0` |

## Estimates

- `oracle_bulk_seconds_per_card`: `0.0875`
- `oracle_bulk_cards_per_minute`: `686.1`
- `bulk_cache_lookup_seconds_per_card`: `1.5e-05`
- `bulk_cache_lookup_cards_per_minute`: `3946641.1`
- `bulk_cache_load_and_index_seconds`: `1.028988`
- `hard_named_fallback_seconds_per_card`: `0.0916`
- `hard_named_fallback_cards_per_minute`: `655.3`
- `local_planning_seconds_per_card`: `1.2e-05`

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
- Mizzix's Mastery
- Teferi's Protection
- High Noon
