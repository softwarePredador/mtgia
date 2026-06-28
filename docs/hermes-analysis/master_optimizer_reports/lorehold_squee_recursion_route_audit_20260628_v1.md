# Lorehold Squee Recursion Route Audit - 2026-06-28

## Scope

- Hypothesis reviewed: `audit_squee_graveyard_entry_route`.
- Question: whether the current battle runtime lets Lorehold convert `Squee, Goblin Nabob` into repeatable discard fuel, or whether Squee is being consumed as a generic creature.
- PostgreSQL writes: none.
- Source DB mutated: no.

## External Strategy Check

Current public Lorehold references agree on the main shell: topdeck manipulation plus miracle timing, especially `Sensei's Divining Top`, `Scroll Rack`, and `Library of Leng`. They also frame discard as a resource only when the discarded card creates value.

- EDHREC frames Lorehold as a miracle/topdeck deck and calls out Top, Rack, and Library as core setup pieces: `https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander`
- GameTyrant describes Lorehold as topdeck manipulation, draw timing, high-impact miracle spells, and discard payoffs: `https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech`
- Card Kingdom highlights that Lorehold rummages on each opponent upkeep to turn first draws on opponent turns into miracle windows: `https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/`

## Local Trace Finding

The current focus traces show two different failure modes:

| Seed | Record | Squee Observation |
| ---: | ---: | --- |
| 7 | 0-9 | no material Squee events; Squee stays in library in early snapshots |
| 20260625 | 0-9 | no material Squee events; Squee stays in library in early snapshots |
| 42 | 7-2 | Squee reaches hand and returns, but the observed route is mostly cast/combat/wipe/mill rather than Lorehold upkeep discard |

The runtime already had a correct isolated rummage rule: when Squee is the relevant discard candidate, Lorehold discards it to graveyard and Squee returns on upkeep. The gap was main-phase sequencing: Squee could still be cast as a low-impact creature before that discard route was used.

## Runtime Change

Added `should_hold_squee_for_lorehold_recursion`: if Lorehold's miracle/rummage engine is already active, Squee is held out of normal main-phase casting and reserved for discard-recursion use.

Regression test added:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_squee_recursion_priority.py`

## Gate Evidence

Small equal gates were run against the current Squee candidate shell with real opponents, opponent seed `20260626`, seeds `7`, `20260625`, and `42`, one game per opponent, isolated deck process, and no PostgreSQL writes.

Summary artifact:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hold_priority_gate_20260628_summary.md`

Result:

- The correction preserves the seed `42` positive anchor and produces Squee graveyard/return plus Squee rummage-discard telemetry in that recut.
- It does not fix seeds `7` or `20260625`; both still lack Squee access.

## Decision

Keep the runtime correction, but do not promote it as deck-list success by itself.

The next deck package must solve access density, not Squee sequencing: Squee now behaves correctly when reached, but the weak seeds still fail because the engine pieces do not arrive early enough.
