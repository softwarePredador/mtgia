# Global Battle, Rules, and Learning Closure

Status: `current_operating_runbook`.

This runbook is the single operational entrypoint after the external battle
restudy. It does not replace the detailed rule-family contract. It connects
PostgreSQL identity, local XMage evidence, live XMage/Forge catalogs, native
ManaLoom rules, resumable battles, and deckbuilding evidence without merging
their meanings.

## Non-negotiable source boundaries

| Question | Source of truth | What it does not prove |
| --- | --- | --- |
| Card identity, Oracle, printing, legality | PostgreSQL populated from reviewed Scryfall/MTGJSON lanes | Executable behavior |
| Primary executable behavior | Pinned live XMage catalog and simulation | Commander legality, deck quality, hidden draws |
| Secondary executable behavior | Pinned live Forge catalog and simulation | Quality or superiority |
| Native residual behavior | Verified/active executable `card_battle_rules` in PostgreSQL | External engine coverage |
| Hermes/SQLite | Cache, laboratory, family tests, audit evidence | Product truth or independent promotion authority |
| Deckbuilding learning | Positive typed exposure plus controlled comparison | Causal superiority from one battle |

A local Java path is source evidence, not runtime coverage. The pinned XMage
catalog must resolve the exact product identity or an audited unique Unicode
normalization that preserves punctuation. This rule prevents class-name
collisions such as `Clear, the Mind` being associated with `ClearTheMind.java`.

## One entrypoint

```bash
scripts/manaloom_global_battle_closure.sh coverage
scripts/manaloom_global_battle_closure.sh battle registry.json /tmp/battle-state
```

`coverage` performs, in order:

1. read-only export of all PostgreSQL card rows;
2. read-only export of verified/active executable native rules;
3. rebuild of the local XMage source-candidate queue;
4. live `/cards/coverage` against XMage;
5. live Forge coverage only for the exact XMage residual;
6. native coverage only for the final external residual;
7. source-candidate/catalog reconciliation;
8. semantic grouping of the explicit residual;
9. compact report generation;
10. local and remote work-directory cleanup.

The default retained output is under `/tmp`. It contains summaries, Markdown,
family gates, and residual rows. Full 34k-row intermediate ledgers are deleted.
No PostgreSQL or Hermes write occurs.

## Coverage schemas

`external_card_coverage_closure_v1` assigns every input row to exactly one lane:

- `xmage_exact`;
- `forge_exact`;
- `native_verified`;
- `identity_reconciliation_required`;
- `unresolved`.

Identity reconciliation is deliberately not counted as coverage until the
runtime identity bridge consumes the candidate name and the coverage test
passes again.

`xmage_source_catalog_reconciliation_v1` separates:

- `xmage_catalog_confirmed`;
- `forge_catalog_fallback`;
- `native_verified_fallback`;
- `local_source_candidate_not_executable`.

The last status must never enter executable coverage or an automatic
PostgreSQL package.

## Residual family gate

Every unresolved row receives both a product/layout family and a semantic hint.
Semantic hints prioritize work but never create an executable rule. Conventional
cards remain `action_required` until their runtime/test/PostgreSQL/Hermes gate
passes. Technical product objects receive one explicit terminal disposition,
remain `promotion_allowed=false`, and name the dedicated subsystem gate that
would be required to bring them into scope later.

Current read-only baseline:

| Semantic family | Residual cards |
| --- | ---: |
| `creature_combat_or_ability` | 226 |
| `token_creation` | 213 |
| `targeted_or_mass_removal` | 127 |
| `damage_or_life` | 120 |
| `other_long_tail` | 115 |
| `draw_selection_topdeck` | 92 |
| `triggered_static_or_replacement` | 76 |
| `mana_generation_or_cost` | 37 |
| `graveyard_recursion` | 21 |
| `tutor_search_library` | 25 |
| `counterspell_or_stack` | 5 |
| `product_identity_or_nonstandard_object` | 5 |
| `copy_or_alternate_cast` | 1 |

The hint ordering is routing evidence only. XMage/Forge tests, Oracle text, and
the ManaLoom runtime adapter still define the exact family contract.

## Async battle registry

The queue schema is `external_battle_async_registry_v1`:

```json
{
  "schema_version": "external_battle_async_registry_v1",
  "minimum_completed_per_variant": 3,
  "jobs": [
    {
      "job_id": "swap-1-candidate-seed-1001",
      "comparison_id": "swap-1",
      "variant": "candidate",
      "same_lane": true,
      "forced_access": false,
      "focus_cards": ["Candidate Card"],
      "request": {
        "request_id": "swap-1-candidate-seed-1001",
        "seed": 1001,
        "timeout_ms": 120000,
        "deck_a": {},
        "deck_b": {}
      }
    }
  ]
}
```

Each `request` must contain complete legal sidecar deck payloads. The sidecars
remain responsible for exact 100-card/one-commander validation.

The runner:

- writes `external_battle_async_checkpoint_v1` atomically after every state
  transition;
- resumes `pending` and interrupted `running` jobs;
- never reruns a completed job;
- uses Forge only after XMage returns structured HTTP `422` coverage failure;
- never changes engine after timeout, transport failure, or HTTP `5xx`;
- never records a timeout as a draw;
- after XMage timeout, requires a different healthy `sidecar_process_id` before
  retrying;
- compresses full responses as deterministic `.json.gz` files;
- keeps compact positive evidence in the checkpoint;
- rejects checkpoint reuse when the registry hash changes.
- rejects duplicate job IDs, result-file collisions, non-integer seeds, and
  duplicate comparison variant/seed samples;
- never retries a terminal failed, timeout, or coverage-incomplete job on
  resume without a new registry;

## Positive learning evidence

Both Python and Dart publish `battle_positive_evidence_v1`.

Positive exposure requires:

1. a completed engine result;
2. `external_battle_learning_v1` or `native_battle_learning_v1` with
   `absence_proves_nonuse=false`;
3. a typed action such as stack entry, cast, activation, zone transition,
   battlefield entry, combat, damage, tap, or counter change;
4. a named card field attached to that action.

Generic waiting/log rows do not prove card activity. Missing events do not
prove non-use. Forced access can diagnose a rule but is not a natural deck
comparison sample.

The comparison gate requires:

- base and candidate variants;
- the configured minimum completed games for both;
- the same completed seed set;
- same-lane replacement declaration;
- natural samples;
- positive exposure of removed cards in base games;
- positive exposure of added cards in candidate games.

The minimum applies to unique paired seeds whose base and candidate jobs both
have positive focus-card exposure. A single replay, even natural and same-lane,
can only publish `natural_same_lane_exposure=true`; it cannot publish a ready
comparison gate.

Only `external_battle_comparison_gate_v1` can produce
`comparison_input_ready=true`. It still publishes:

```text
swap_superiority_proven=false
promotion_allowed=false
next_gate=statistical_and_strategy_evaluation
```

The backend `/ai/simulate` route now writes the same safe evidence summary into
persisted battle results. Its order is XMage, Forge only for a structured XMage
gap, then the reviewed native sidecar after complete-deck native coverage.
Commander diagnostics consume only natural positive exposure and never turn it
into automatic promotion.

## Measured proof on 2026-07-15

Global coverage:

| Lane | Cards |
| --- | ---: |
| PostgreSQL rows | 34,331 |
| XMage exact | 31,285 |
| Forge exact after XMage gap | 1,796 |
| Native verified after external gap | 187 |
| Operationally covered | 33,268 |
| Explicit technical residual | 1,063 |
| Coverage | 96.9037% |

The 1,063 residual rows contain zero conventional-rules or digital-only cards:
816 are nonstandard or playtest cards, 138 are auxiliary game objects, 55
require physical or external interaction, and 54 belong to scenario or
challenge-deck rulesets. At Oracle-identity level, 33,019 of 34,080 identities
are fully covered and 1,061 remain as terminal technical exclusions.

`global_residual_terminal_dispositions_v1` is generated by every canonical
coverage run. It rejects conventional or unknown scopes and requires one unique,
non-promotable terminal disposition per residual row. The current proof has
1,063 dispositions, zero actionable residual, zero unknown dispositions, and
zero rows eligible for promotion.

Local-source/catalog reconciliation:

| Status | Cards |
| --- | ---: |
| XMage catalog confirmed | 23,886 |
| Forge catalog fallback | 56 |
| Local source candidate not executable | 9 |
| Total local source candidates | 23,951 |

The 9 rejected local candidates are:

- `Clear, the Mind`;
- `Gather, the Townsfolk`;
- `Glimpse, the Unthinkable`;
- `Monster Mash-Up`;
- `Rampant, Growth`;
- `Ransack, the Lab`;
- `The Archenemy's Charm`;
- `The Horizon Seeker`;
- `The Warmonger`.

The refreshed ledger classifies the first eight as nonstandard/playtest product
objects and `The Warmonger` as a scenario/challenge-deck object. None is a
conventional-rules residual. The source-candidate report now preserves the
PostgreSQL product, Oracle, layout, and legality metadata used to prove that
classification instead of presenting those rows as if their Oracle data were
missing.

Current native review debt is separate from that external coverage result. A
SELECT-only PostgreSQL recheck found `83` `active/auto` rows, and a live catalog
probe confirmed all `83` are already `xmage_exact`. They therefore do not block
the primary external execution lane, but they still require native focused
verification before being treated as fully closed native behavior:

| Native scope label | Rows |
| --- | ---: |
| Exact scope awaiting verification | 43 |
| Explicit runtime scope awaiting verification | 3 |
| Annotation-bearing scope | 21 |
| Partial scope | 9 |
| Explicitly unexecuted scope | 6 |
| Baseline scope | 1 |

The first native triage batch is the six explicitly unexecuted cards:
`Ashnod's Altar`, `Basking Broodscale`, `Drown in Dreams`, `Formidable Speaker`,
`Scavenging Ooze`, and `The Emperor of Palamecia`. The next batch is the nine
partial scopes: `Gemstone Caverns`, `Leyline of Abundance`, `Machine God's
Effigy`, `Mana Vault`, `Mystical Tutor`, `Skullclamp`, `Staff of Compleation`,
`Talisman of Conviction`, and `Urza's Saga`. Scope names are triage signals, not
permission to rewrite PostgreSQL statuses: each row still needs its focused
positive/negative runtime proof and exact package gate.

Production async-runner proof:

- XMage completed Krenko vs Isamaru in one attempt;
- elapsed engine request: 9,107 ms in the final compressed run;
- learning contract valid;
- Krenko positive exposure proven by battlefield, stack, tap, and zone events;
- no strategy or superiority claim emitted;
- a second invocation preserved one attempt and did not rerun the job;
- full result retention fell from approximately 3.2 MiB JSON to 44 KiB gzip.

## HBG Specialize native closure

The native digital residual is closed by one generated family registry rather
than card-by-card branches:

- 19 base cards and 95 WUBRG derived faces;
- 114 reviewed, verified, executable rules with stable semantic
  `logical_rule_key` values;
- one shared activation/transition/trigger runtime in `battle_analyst_v9.py`;
- five Lae'zel faces explicitly marked for their "enters or specializes"
  transition;
- exact PostgreSQL and Hermes postcheck: 114 rows, 114 Oracle hashes, 19 base
  scopes, 95 face scopes, and no stale keys.

Run `build_specialize_rule_registry.py --check` and
`test_digital_specialize_runtime.py` before promotion. Use
`sync_battle_card_rules_pg.py --only-cards-json <selector>` for dry-run, exact
PostgreSQL apply, and PostgreSQL-to-Hermes synchronization. A change to effect
metadata must update the existing stable key; it must not create a second rule
for the same Specialize card.

## Unfinity ticket and sticker closure

The Commander-legal Unfinity residual is closed by one shared native family:

- 45 conventional cards with ticket, sticker, Attraction-mode, attachment,
  combat, death, and delayed-zone descriptors;
- stable logical keys and current Oracle hashes generated from PostgreSQL-backed
  Hermes metadata;
- exact PostgreSQL and Hermes reconciliation: 45 rows on each side, identical
  payloads, no missing names, and only `verified/auto/curated` status;
- 15 focused runtime tests, including ticket spending, sticker persistence,
  forced blocking, Equipment inheritance/removal, Aura leave sacrifice, and
  end-step exile;
- 49 sticker-sheet rows and the remaining Attractions retained as supplemental
  objects with dedicated terminal subsystem gates, not executable deck cards.

Legality is evaluated per card, while sticker sheets are supplemental game
objects selected separately from the deck. The classifier must never exclude
all `UNF` cards merely because the set is a funny product.

## PostgreSQL and Hermes boundary

Coverage and battle closure are read-only. A residual family can mutate product
truth only through the existing package process:

1. exact family scope and runtime adapter;
2. focused unit and E2E scenario;
3. SELECT-only PostgreSQL precheck;
4. approved exact SQL apply;
5. PostgreSQL postcheck;
6. Hermes synchronization from PostgreSQL;
7. strategy, execution, operational, contamination, and PG/Hermes/SQLite gates;
8. commit, push, and deployed task-image verification.

Pattern-registry rows remain shadow-only. External engine coverage does not
create `card_battle_rules` rows.

## Product E2E gate

Every battle-related deploy runs
`scripts/manaloom_battle_product_gate.sh` before changing a service. The gate
checks the app-to-API route, external-to-native routing, verified native
coverage, typed evidence persistence, deck-analysis consumption, unit tests,
static analysis, and deployment syntax.

The live contract test is `server/test/battle_product_e2e_test.dart`. It creates
two temporary legal Commander decks through the public API, naturally casts and
resolves a reviewed residual card, persists the replay, confirms
`/decks/:id/analysis` consumes the natural evidence, and deletes the decks. An
optional forced-access run proves diagnostic labelling but cannot satisfy the
natural deckbuilder gate.

## Definition of done

- A card is execution-covered only by an exact live engine catalog or a
  verified executable native rule.
- A family is native-ready only after runtime, focused test, PostgreSQL, Hermes,
  and audit closure.
- A battle is learning-eligible only after completion and positive typed
  evidence under the current learning contract.
- A swap is comparison-ready only after equal natural samples and same-lane
  exposure.
- No automated surface may call a swap superior from catalog presence, one
  battle, a timeout-selected sample, or missing events.
