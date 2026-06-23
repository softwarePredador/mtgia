# PG042 Valakut Awakening Focused Replay - 2026-06-22 22:53 UTC

Scope: card-level event proof for `Valakut Awakening // Valakut Stoneforge` after PostgreSQL PG042 and SQLite sync. This is not a full 16-seed battle matrix.

Evidence:

- Events: `docs/hermes-analysis/master_optimizer_reports/valakut_awakening_pg042_focused_events_20260622_225355.jsonl`.
- Selected rule key: `battle_rule_v1:6e1f3b876822abafe1de47610f46858d`.
- Oracle hash: `22b42fcc181b7aed71f78b2e1e51e887`.
- Runtime event: `hand_filter_resolved`.
- Bottomed cards: `Nine Drop B, Eight Drop A`.
- Draw count: `3`.
- Drawn cards: `Draw One, Draw Two, Draw Three`.
- Preserved critical win condition in hand: `Approach of the Second Sun`.
- Spell resolution event: `destination=graveyard`.

Reading:

- The executor proved the front-face oracle behavior modeled by PG042: choose cards to put on the bottom, then draw that many plus one.
- The test card used PostgreSQL's type line (`Instant`) for cast resolution. The MDFC land-face metadata remains attached to the split-name rule for runtime lookup, but this focused event proves the instant hand-filter resolution, not land-play/tapped-mana execution.
