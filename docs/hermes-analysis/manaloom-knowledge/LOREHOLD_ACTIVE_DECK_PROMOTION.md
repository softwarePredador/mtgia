# Lorehold Active Deck Promotion

Generated: 2026-06-02T18:38:55+00:00

## Status

- Promoted learned candidate to active Hermes Lorehold deck.
- Active deck table: `decks.id = 6`.
- Source candidate: `learned_deck_id = 82`.
- Active name: `Lorehold Best-of Learned No Premium Mox 2026-06-02`.
- Previous active name: `Lorehold Spellslinger`.
- Backup created: `knowledge.db.bak_before_promote_bestof_20260602_183700`.
- Removed by request: `Chrome Mox`, `Mox Diamond`, `Mox Opal`.
- Replacement cards: `Fellwar Stone`, `Lightning Greaves`, `Victory Chimes`.

## Active Deck Metrics

- Cards: `100`
- Lands: `33`
- Ramp: `6`
- Draw: `6`
- Tutor: `6`
- Protection: `4`
- Removal: `3`
- Stax: `3`
- Wincon: `11`

## Oracle Result After Promotion

1. `Rite of Dragoncaller` — available
2. `Mizzix's Mastery Overload` — available
3. `Fiery Emancipation + Damage` — available

Unavailable high-score package:

- `Underworld Breach Combo`

## Scope

This promotion updates the Hermes knowledge SQLite active Lorehold deck used by the local cron scripts (`deck_id=6`). It does not write to production PostgreSQL app user decks unless a separate app-level sync is run.
