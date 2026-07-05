# Game Changer Discovery Gap Audit

- generated_at: `2026-07-05T02:51:17Z`
- status: `game_changer_discovery_gap_found_report_only`
- deck_id: `607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- game changers in policy: `53`
- game_changers table present: `false`
- format_staples present: `21`
- format_staples missing: `32`
- oracle missing: `5`
- commander legal: `53`
- Lorehold-legal/color-allowed missing format_staples: `12`
- owned Game Changers: `9`
- deck-607 Game Changers: `5`
- status counts: `{"discovery_gap_missing_format_staples": 27, "discovery_ready_in_format_staples": 21, "identity_gap_missing_oracle_cache": 5}`

## Lorehold-Relevant Missing format_staples Rows

| Card | Owned | In 607 | Oracle | Commander | Color Identity | Status |
| --- | ---: | --- | --- | --- | --- | --- |
| ancient tomb | 1 | `True` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| drannith magistrate | 1 | `False` | `True` | `legal` | `W` | `discovery_gap_missing_format_staples` |
| farewell | 1 | `True` | `True` | `legal` | `W` | `discovery_gap_missing_format_staples` |
| field of the dead | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| glacial chasm | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| grim monolith | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| humility | 0 | `False` | `True` | `legal` | `W` | `discovery_gap_missing_format_staples` |
| lion's eye diamond | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| mishra's workshop | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| serra's sanctum | 0 | `False` | `True` | `legal` | `W` | `discovery_gap_missing_format_staples` |
| the one ring | 1 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |
| the tabernacle at pendrell vale | 0 | `False` | `True` | `legal` | `colorless` | `discovery_gap_missing_format_staples` |

## Decision

- no_deck_promotion: `true`
- reason: Game Changer discovery coverage is metadata only. Missing format_staples rows should be repaired as candidate-source coverage, not interpreted as proof that a card belongs in protected deck 607.
- next_action: `Use the bracket Game Changer list as a supplemental discovery lane and repair missing identity/staple rows before relying on format_staples-only candidate generation.`
