# Battle latest learned-deck opponent provenance recheck - 2026-06-19T22:32Z

Scope: read-only validation of learned-deck opponent provenance in the current
recurring battle audit. No code, PostgreSQL, deck swaps, commits or pushes were
changed.

Sources checked:

- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/summary.json`
- `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_215228/seed_*/deck_provenance.json`
- `docs/hermes-analysis/BATTLE_VALIDATION_REGISTER_2026-06-19.md`

## Latest aggregate state

- Latest run checked: `20260619_215228`.
- `summary.json.deck_provenance_files` lists `16` per-seed provenance files.
- `summary.json.deck_source_blocker_domains={"none":64}`.
- `summary.json.lorehold_deck_source_kind=sqlite_deck_cards`.
- `summary.json.lorehold_deck_source_ref=deck_id:6`.
- `summary.json.deck_cached_metadata_used_for_replay_metrics=false`.
- `summary.json.deck_metrics_policy=runtime_derived_from_resolved_card_lists`.
- The summary publishes `deck_provenance_files`, but does not publish aggregate
  learned-opponent fields such as `learned_deck_opponents`,
  `opponent_deck_provenance`, or `learned_opponent_source_counts`.

## Learned opponent inventory from per-seed provenance

The `16` seed files contain `48` learned-deck opponent appearances and `12`
unique learned-deck opponent refs:

| Appearances | Opponent | Source system | Source ref | Source cards | Battle cards | Cached metrics | Metrics basis | Blocker domain | Construction report |
| ---: | --- | --- | --- | ---: | ---: | --- | --- | --- | --- |
| 6 | Dargo, the Shipwrecker #74 (real) | pg_meta_decks | learned_deck:74 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 4 | Etali, Primal Conqueror #105 (real) | pg_meta_decks | learned_deck:105 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 5 | Kinnan, Bonder Prodigy #104 (real) | pg_meta_decks | learned_deck:104 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 3 | Kinnan, Bonder Prodigy #84 (real) | pg_meta_decks | learned_deck:84 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 3 | Kraum, Ludevic's Opus #83 (real) | pg_meta_decks | learned_deck:83 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 2 | Rograkh, Son of Rohgahh #62 (real) | pg_meta_decks | learned_deck:62 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 5 | Sisay, Weatherlight Captain #31 (real) | pg_meta_decks | learned_deck:31 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 6 | Tayam, Luminous Enigma #116 (real) | pg_meta_decks | learned_deck:116 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 5 | Tayam, Luminous Enigma #25 (real) | pg_meta_decks | learned_deck:25 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 4 | The Emperor of Palamecia #42 (real) | pg_meta_decks | learned_deck:42 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 2 | Thrasios, Triton Hero #54 (real) | pg_meta_decks | learned_deck:54 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |
| 3 | Thrasios, Triton Hero #58 (real) | pg_meta_decks | learned_deck:58 | 100 | 99 | false | runtime_derived_from_resolved_built_deck | none | null |

The Lorehold source deck appears in all `16` provenance files with
`source_kind=sqlite_deck_cards`, `source_ref=deck_id:6`, and a
`construction_report` showing `is_valid=true`, `main_quantity=99`,
`total_quantity=100`, `commander_count=1`, and no off-color/singleton issues.

## Operational reading

The current per-seed provenance is materially better than a summary-only read:
it exposes learned deck refs, names, `source_system`, card counts, runtime
metric basis, and blocker domain. However, the primary `summary.json` still does
not aggregate the learned-opponent list and still does not publish construction
or coherence status for learned opponents.

Because `battle_replay_final_status` is an engine/gate status, it should not be
read as source-deck coherence proof for learned opponents. The source deck
provenance gate remains separate from the battle-engine gate.

## Task for Ajustar battle

Aggregate learned opponent provenance into `summary.json` with at least:

- `source_system`
- `source_ref`
- opponent display name
- appearances/seeds
- `source_card_count`
- `battle_card_count`
- metric basis
- cached metadata flag
- blocker domain
- construction/coherence status or explicit unavailable waiver

## Validation commands run

- `jq` reads against latest `summary.json`
- `jq` reads against all `seed_*/deck_provenance.json` files
- grouped count of learned-opponent refs and appearances
- check that aggregate learned-opponent summary fields are absent while
  `deck_provenance_files` is present

