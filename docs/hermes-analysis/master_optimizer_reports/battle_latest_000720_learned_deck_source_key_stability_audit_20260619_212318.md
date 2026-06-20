# Battle Latest 000720 Learned-Deck Source Key Stability Audit

Status: reinforces BV-075 as open.

Scope: read-only audit of how learned-deck opponent identities flow from the
local Hermes SQLite cache into battle replay provenance. No PostgreSQL query,
database mutation, code change, deck swap, commit, or push was performed.

## Primary Evidence

- Latest artifact: `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_000720`.
- `summary.json` timestamp: `2026-06-20T00:07:20Z`.
- `battle_replay_final_status=trusted_for_strategy_learning`.
- `mandatory_gate_divergences=[]`.
- `summary.json` still does not publish `learned_deck_opponents`,
  `opponent_deck_provenance`, or `learned_opponent_source_counts`.
- Per-seed `deck_provenance.json` files contain `48` learned opponent
  appearances across `12` unique `source_ref` values.

## Source Key Finding

The per-seed provenance currently records learned opponents as:

- `source_kind=learned_decks`
- `source_ref=learned_deck:<row["id"]>`
- `source_system=pg_meta_decks`
- `source_card_count=100`
- `battle_card_count=99`

Code evidence:

- `battle_analyst_v9.py` builds the battle opponent name and id from the local
  SQLite `learned_decks` row: `real_name = f"{row['commander']} #{row['id']} (real)"`,
  `learned_deck_id = row["id"]`, and `source = row["source"]`
  (`battle_analyst_v9.py:14759-14765`).
- `battle_replay_v10_3.py` writes `source_ref=f"learned_deck:{profile.get('learned_deck_id')}"`,
  `source_system=profile.get("source")`, `source_card_count`,
  `battle_card_count`, runtime metrics, and `blocker_domain`
  (`battle_replay_v10_3.py:478-489`).

SQLite schema evidence:

- `learned_decks.id` is `INTEGER PRIMARY KEY AUTOINCREMENT`.
- `learned_decks.source_url` exists and contains the stable PG cache key for
  PG meta decks.
- `sync_pg_meta_decks_to_hermes.py` writes PG meta decks with
  `source="pg_meta_decks"` and `source_url=f"pg:meta_decks:{deck.pg_id}"`;
  updates are matched by `(source, source_url)`, not by the autoincrement id
  (`sync_pg_meta_decks_to_hermes.py:160-166`, `sync_pg_meta_decks_to_hermes.py:191-205`).

Implication: `learned_deck:<id>` is a local Hermes cache key, not the stable
PG meta-deck identity. It is useful inside this SQLite cache, but downstream
handoff should not treat it as the only learned-opponent key.

## Current Latest Learned Opponents

These are the `12` unique learned opponents observed in the current latest
run, enriched from the local Hermes SQLite cache without querying PostgreSQL.

| Local source_ref | Stable local cache source_url | Commander | Deck name | Appearances | Source system | Source cards | Battle cards |
| --- | --- | --- | --- | ---: | --- | ---: | ---: |
| `learned_deck:25` | `pg:meta_decks:94ae22cd-7c7f-412c-b15f-2892c0b9d21d` | `Tayam, Luminous Enigma` | `Tayam, Luminous Enigma` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:31` | `pg:meta_decks:94bc541d-6a20-4328-8f9b-dc5bc9efaa28` | `Sisay, Weatherlight Captain` | `Sisay, Weatherlight Captain` | 5 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:42` | `pg:meta_decks:2e768d73-e428-4fc1-a3a5-7bf477218f83` | `The Emperor of Palamecia` | `The Emperor of Palamecia` | 3 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:54` | `pg:meta_decks:f5c960f7-7613-4280-a054-4dec346bde9c` | `Thrasios, Triton Hero` | `Thrasios, Triton Hero + Tymna the Weaver` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:58` | `pg:meta_decks:eceb0abb-e46d-4b79-9f82-c8f426f3e91b` | `Thrasios, Triton Hero` | `Thrasios, Triton Hero + Vial Smasher the Fierce` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:62` | `pg:meta_decks:1ff1fab8-8862-4ef7-9f02-62486dcc4e4f` | `Rograkh, Son of Rohgahh` | `Rograkh, Son of Rohgahh + Thrasios, Triton Hero` | 5 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:74` | `pg:meta_decks:98eea635-2f96-4107-8059-e14436bded0f` | `Dargo, the Shipwrecker` | `Dargo, the Shipwrecker + Tymna the Weaver` | 3 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:83` | `pg:meta_decks:7dbe58fd-031c-4d0c-8a89-727b384eaded` | `Kraum, Ludevic's Opus` | `Kraum, Ludevic's Opus + Tymna the Weaver` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:84` | `pg:meta_decks:f5151bbc-a58c-4d53-ad3f-19ca80690b1b` | `Kinnan, Bonder Prodigy` | `Kinnan, Bonder Prodigy` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:104` | `pg:meta_decks:33899d41-c1e5-4827-8145-d370360cdf7e` | `Kinnan, Bonder Prodigy` | `Kinnan, Bonder Prodigy` | 3 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:105` | `pg:meta_decks:b170b0b7-4109-4d02-904d-0e5d9abaabe1` | `Etali, Primal Conqueror` | `Etali, Primal Conqueror` | 4 | `pg_meta_decks` | 100 | 99 |
| `learned_deck:116` | `pg:meta_decks:9ec2f925-33ab-4ce6-908b-4b26fa52e4c4` | `Tayam, Luminous Enigma` | `Tayam, Luminous Enigma` | 5 | `pg_meta_decks` | 100 | 99 |

## Register Impact

BV-075 should remain open, and its closure criterion should require the main
`summary.json` to publish both:

1. The local Hermes cache key already used by replay (`source_ref=learned_deck:<sqlite_id>`).
2. The stable source identity available in Hermes cache (`source_url=pg:meta_decks:<uuid>`)
   or a stronger backend-owned identity when available.

The aggregate should also preserve `source_system`, commander/deck name,
appearances/seeds, `source_card_count`, `battle_card_count`, metrics basis,
cached metadata flag, blocker domain, and construction/coherence status or an
explicit waiver.
