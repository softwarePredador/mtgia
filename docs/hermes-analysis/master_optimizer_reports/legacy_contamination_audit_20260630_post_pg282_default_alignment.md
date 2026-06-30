# Legacy Contamination Audit

- Generated at: `2026-06-30T18:27:24.258942+00:00`
- Status: `pass`
- Summary: `{"baseline_loaded": true, "baseline_path": "/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/LEGACY_CONTAMINATION_BASELINE_2026-06-30.json", "category_totals": {"hardcoded_pg_fallback": 20, "legacy_deck6_current_default": 61, "legacy_ranked_decks_schema": 10, "stale_sqlite_path": 69}, "excess_group_count": 0, "hit_count": 160, "resolved_group_count": 0, "scanned_file_count": 950}`

## Pattern Totals

| Category | Hits | Meaning |
| --- | ---: | --- |
| `hardcoded_pg_fallback` | 20 | Hardcoded old PostgreSQL host, port, database, or fallback env default. |
| `legacy_deck6_current_default` | 61 | Historical deck 6 default/baseline reference. |
| `legacy_ranked_decks_schema` | 10 | Direct legacy ranked_decks schema reference. |
| `raw_edhrec_inclusion_score` | 0 | Raw EDHREC inclusion count used as a score instead of inclusionRate. |
| `stale_sqlite_path` | 69 | Stale or sibling Hermes knowledge.db path/default. |

## New Or Increased Legacy Groups

None.

## Excess Hit Samples

None.
