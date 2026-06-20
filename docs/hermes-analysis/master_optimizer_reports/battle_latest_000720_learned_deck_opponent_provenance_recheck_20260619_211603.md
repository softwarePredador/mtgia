# Battle Latest 000720 Learned-Deck Opponent Provenance Recheck

Status: BV-075 remains open.

Scope: read-only recheck of learned-deck opponent provenance against the current
official battle audit artifact. No code, database, deck swap, commit, or push
was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720`.
- `summary.json` timestamp: `2026-06-20T00:07:20Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `seeds_completed=16`.
- `deck_source_blocker_domains={"none":64}`.
- `deck_blocker_domain_policy=deck_source_or_legality_findings_are_reported_separately_from_battle_engine_findings`.

The main `summary.json` still does not publish learned-opponent aggregate
fields:

- `has("learned_deck_opponents")=false`.
- `has("opponent_deck_provenance")=false`.
- `has("learned_opponent_source_counts")=false`.

## Per-Seed Provenance Exists

The per-seed `deck_provenance.json` files contain the learned opponent details
that are missing from the main summary.

Aggregated across all 16 seed files:

- Total deck rows: `64`.
- Lorehold rows: `16`.
- Learned opponent rows: `48`.
- Unique learned `source_ref`: `12`.
- `source_kind_counts={"learned_decks":48,"sqlite_deck_cards":16}`.
- Learned `source_system_counts={"pg_meta_decks":48}`.
- Learned `blocker_domain_counts={"none":48}`.
- Learned `metrics_basis_counts={"runtime_derived_from_resolved_built_deck":48}`.
- Learned `cached_metadata_used_for_metrics=false` rows: `48`.
- Learned `source_card_count=100` rows: `48`.
- Learned `battle_card_count=99` rows: `48`.
- Learned rows with `construction_report`: `0`.
- Learned rows with `deck_coherence_report`: `0`.

Unique learned opponents seen in this run:

| Source ref | Name | Appearances | Source cards | Battle cards | Metrics basis | Cached metrics | Blocker domain | Construction report | Deck coherence report |
| --- | --- | ---: | ---: | ---: | --- | --- | --- | --- | --- |
| `learned_deck:104` | `Kinnan, Bonder Prodigy #104 (real)` | 3 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:105` | `Etali, Primal Conqueror #105 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:116` | `Tayam, Luminous Enigma #116 (real)` | 5 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:25` | `Tayam, Luminous Enigma #25 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:31` | `Sisay, Weatherlight Captain #31 (real)` | 5 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:42` | `The Emperor of Palamecia #42 (real)` | 3 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:54` | `Thrasios, Triton Hero #54 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:58` | `Thrasios, Triton Hero #58 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:62` | `Rograkh, Son of Rohgahh #62 (real)` | 5 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:74` | `Dargo, the Shipwrecker #74 (real)` | 3 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:83` | `Kraum, Ludevic's Opus #83 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |
| `learned_deck:84` | `Kinnan, Bonder Prodigy #84 (real)` | 4 | 100 | 99 | `runtime_derived_from_resolved_built_deck` | false | `none` | false | false |

## Producer Evidence

`battle_replay_v10_3.py` writes learned opponent provenance into each
`deck_provenance.json`:

- Learned opponents are recorded with `source_kind="learned_decks"`,
  `source_ref=learned_deck:<id>`, `source_system`, `source_card_count`,
  `battle_card_count`, runtime-derived metrics, cached metadata flag and
  `blocker_domain="none"` (`battle_replay_v10_3.py:478-489`).

`battle_analyst_v9.py` loads real opponents from the local Hermes
`learned_decks` table:

- It prefers `source='pg_meta_decks'`, excludes Lorehold commanders, requires
  non-empty `card_list`, enforces `card_count >= min_cards`, and limits the
  candidate pool before building the real opponent decks
  (`battle_analyst_v9.py:14693-14745`).

The recurring wrapper reads per-seed `deck_provenance.json`, but currently only
aggregates generic blocker counts and Lorehold deck metadata into the main
summary:

- It appends `deck_provenance_files`, updates `deck_metrics_policy`,
  `deck_cached_metadata_used_for_replay_metrics`,
  `deck_blocker_domain_policy`, and `deck_source_blocker_domains`
  (`manaloom-battle-strategy-audit.sh:771-788`).
- It only copies detailed source fields when `deck_item["name"] == "Lorehold"`
  (`manaloom-battle-strategy-audit.sh:789-802`).
- No current wrapper match was found for `learned_deck_opponents`,
  `opponent_deck_provenance`, or `learned_opponent_source_counts`.

## Register Decision

BV-075 remains open.

The engine/replay layer captures enough learned-opponent provenance per seed to
audit this run manually, but the primary `summary.json` still lacks the
aggregate learned-opponent fields needed by downstream consumers.

## Task For "Ajustar battle"

1. Aggregate learned opponents into `summary.json` from all
   `deck_provenance.json` files.
2. Use an unambiguous key per opponent: `source_system`, `source_ref`, `name`,
   and row id when available.
3. Publish appearances/seeds, `source_card_count`, `battle_card_count`,
   `metrics_basis`, cached metadata flag, and blocker domain.
4. Add construction/coherence status for learned opponents, or publish an
   explicit waiver when those reports are unavailable.
5. Add a regression test that fails when a run uses learned opponents but
   `summary.json` omits the learned-opponent aggregate.
