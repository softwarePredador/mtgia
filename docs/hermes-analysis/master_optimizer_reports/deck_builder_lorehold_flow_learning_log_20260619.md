# Deck Builder And Lorehold Flow Learning Log - 2026-06-19

## Scope

Read-only learning pass for the general ManaLoom deck builder, optimize flow,
PostgreSQL oracle structure, and Lorehold deck id `6` as the current control
case.

No code, PostgreSQL rows, swaps, migrations, or commits were changed in this
pass. New evidence was limited to read-only commands, tests, and markdown/json
artifacts.

## Source Of Truth

- PostgreSQL/backend remains the product source of truth.
- Hermes SQLite and recurring battle artifacts are lab evidence and regression
  signals, not the final source of product deck composition.
- Card intelligence reads should prefer `card_intelligence_snapshot` and
  identity resolution should prefer `card_identity_bridge`.
- Learned deck rows are still single-commander records; partner/background
  inference in the audit reduces false positives but is not a replacement for a
  first-class combined commander identity model.

## PostgreSQL Card Oracle Structure

Fresh PostgreSQL read via `server/.env`:

| Metric | Count |
| --- | ---: |
| `cards` total | 34,329 |
| `cards` with `oracle_id` and non-empty `oracle_text` | 33,966 |
| Missing `oracle_id` | 4 |
| Missing `oracle_text` | 360 |
| Missing `oracle_id` or `oracle_text` | 363 |
| Missing `type_line` | 1 |
| Missing `color_identity` | 0 |
| Missing `card_identity_bridge` row | 0 |
| Missing `card_intelligence_snapshot` row | 0 |
| `deck_cards` rows total | 50,841 |
| `deck_cards` rows missing oracle id/text | 56 |
| `deck_cards` quantity total | 79,145 |
| `deck_cards` quantity missing oracle id/text | 56 |

Problem examples by category:

- Missing both `oracle_id` and `oracle_text`: `Birds of Paradise // Birds of Paradise`.
- Missing `oracle_id` only: `A-Alrund's Epiphany`, `A-Omnath, Locus of Creation`, `A-Unholy Heat`.
- Missing `oracle_text` only: mostly vanilla/simple creatures such as `Aegis Turtle`, `Ageless Guardian`, `Alpha Myr`, `Ancient Brontodon`.
- Deck-card impact is concentrated in 6 card names: `Isamaru, Hound of Konda`, `A-Alrund's Epiphany`, `Grizzly Bears`, `Runeclaw Bear`, `A-Omnath, Locus of Creation`, `Yargle and Multani`.

Interpretation: the global oracle layer is structurally healthy at the view
level because every card has bridge/snapshot rows, but `363` base card rows
still fail the stricter oracle contract. This matters to optimize and learned
deck audits when they depend on oracle text for roles, legality interpretation,
and color/rules semantics.

## Lorehold Deck 6 Control Check

Fresh PostgreSQL read for linked deck
`528c877f-f829-4207-95e6-73981776c323`:

| Metric | Count |
| --- | ---: |
| PG deck rows | 100 |
| PG deck quantity | 100 |
| Commander quantity | 1 |
| Land quantity by `type_line` | 33 |
| Land rows by `type_line` | 33 |
| Rows missing `oracle_id` or `oracle_text` | 0 |
| Quantity missing `oracle_id` or `oracle_text` | 0 |

Active learned row:

- `commander_learned_decks.id`: `f46c0421-71b4-4de3-bb79-05a916b4988b`
- commander: `Lorehold, the Historian`
- source ref: `learned_deck:82`
- active: `true`
- legal status: `commander_legal`
- card count: `100`
- cached `metadata.total_lands`: `30`

Interpretation: Lorehold deck id `6` is coherent as a 100-card Commander deck
and has no oracle-structure gap. The live divergence remains cached metadata:
the resolved deck has `33` lands while the active learned row says `30`.

## Deck Builder Flow Learned

`/ai/generate` is reference-driven rather than raw learned-deck-table driven.
The route can use active learned deck data passed into helper inputs; in fact,
when a commander is present it loads `activeLearnedDeck` through the support
helper and passes that evidence into the deterministic reference deck builder.
The route itself is guarded by tests so it does not embed direct
`commander_learned_decks` SQL, reference `commander_learning_snapshot`, return
`promoted_learned_deck_pg`, or call `/ai/commander-learning`. The explicit
learned-deck product surface remains `/ai/commander-learning`.

Important contract correction: the current boundary test proves no direct SQL
or product-route coupling in `routes/ai/generate`; it does not prove that
`/ai/generate` ignores learned decks at runtime. It uses them as source
precedence, not as the promoted learned-deck product payload.

The deterministic reference deck source precedence is:

1. `active_learned_deck`
2. `reference_card_stats`
3. `reference_corpus_packages`
4. `profile_expected_packages`
5. `usage_hot_cards`
6. `deterministic_fallback`

The fallback list should remain as a safety rail, but provenance must prove when
it was not used. Current Lorehold source-mix artifacts already report the
critical fallback buckets as zero.

`GeneratedDeckValidationService` repairs AI output before final validation. It
can remove off-color cards, reduce extra non-basic copies, remove commander
duplicates from the main deck, and fill basics to reach Commander/Brawl size.
This is useful for product safety, but it can mask upstream generator quality
problems unless diagnostics and warnings are treated as first-class evidence.

`DeckRulesService` and pairing helpers support combined commander identity for
Partner, Partner With, Choose a Background, Friends Forever, and Doctor's
companion patterns. The current systemic partner issue is therefore not the
core deck-rules validator; it is the learned-deck row model and metadata, which
store active learned decks as single-commander records.

`/ai/commander-learning` is the explicit product route for promoted learned
decks. With no commander query it returns active learned deck summaries from
`commander_learned_decks`; with a commander query it returns
`recommended_deck.source = promoted_learned_deck_pg`, canonicalizes card
metadata through the backend card lookup path, runs
`GeneratedDeckValidationService`, and avoids exposing raw learned-deck metadata.
However, its visible `role_summary` is still computed from learned-deck
metadata keys such as `total_lands`, `ramp_count`, and `draw_count`. That means
the Lorehold stale `metadata.total_lands = 30` risk is not only an internal
audit issue; if the active row is not re-canonicalized, product consumers can
see a stale role/land summary even while the decklist itself is correct.

## Optimize Flow Learned

`/ai/optimize` loads commander reference profile and meta-priority evidence,
then applies layered safety checks:

- commander color identity filter for additions;
- bracket policy filter when bracket is supplied;
- complete-mode basic-land top-up;
- non-complete land-removal protection;
- functional quality gate using persisted `functional_tags`, semantic v2, and
  oracle heuristics;
- profile-aware role targets and profile land targets;
- final quality rejection when validation verdict is not `aprovado` or score is
  below `70`;
- serialized validation and semantic v2 enforcement gates.

Important divergence found in the current test contract:

- `filterOptimizeAdditionsByCommanderIdentity` treats missing identity data as
  colorless and allows the addition. That preserves older route behavior, but
  for deck-builder coherence it should be treated as a review risk. Missing
  card identity is not the same as a proven colorless card.

## Tests And Artifacts

Tests run in this pass:

- `cd server && dart test test/ai_generate_learning_boundary_test.dart test/commander_pairing_test.dart test/generated_deck_validation_service_test.dart -r expanded`: `17` tests passed.
- `cd server && dart test test/commander_learned_deck_support_test.dart -r expanded`: `12` tests passed.
- `cd server && dart test test/optimization_quality_gate_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_final_gate_support_test.dart test/optimize_route_quality_rejection_support_test.dart -r expanded`: `37` tests passed.
- `python3 -m unittest server.test.learned_deck_coherence_audit_test -v`: `7` tests passed.
- `python3 server/bin/learned_deck_coherence_audit.py --stdout`: read-only full audit completed.
- `python3 server/bin/learned_deck_coherence_audit.py`: generated fresh artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_164611.json`
  - `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_164611.md`
- `cd server && dart test test/commander_reference_card_stats_support_test.dart -r expanded`: `23` tests passed, including active learned deck precedence, source usage counts, basic-land quantity preservation, and off-color filtering before validation repair.

Fresh learned-deck audit result:

- active learned decks checked: `60`
- high issues: `173`
- medium issues: `27`
- `metadata_total_lands_mismatch`: `58`
- `all_core_metadata_zero`: `54`
- `missing_oracle_text`: `6`
- `partner_identity_not_modeled`: `9`
- `off_color_cards`: `5`
- Lorehold package strategy: pass
- Lorehold forbidden Premium Mox violations: `0`

Latest recurring battle-strategy summary checked:

- summary path:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest/summary.json`
- timestamp UTC: `2026-06-19T16:42:53Z`
- run dir:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260619_164253`
- seeds requested/completed: `1/1`
- action findings: `0`
- strategy findings: `0`
- decision audit turn/decision findings: `0/0`
- forensic turn/rule findings: `0/0`
- action events total/unclassified: `1073/0`
- action event types total/unclassified: `40/0`
- runtime files total: `98`
- recurring coverage: `19` covered by recurring run, `6` imported by core runtime, `73` outside recurring run

Interpretation: the battle summary currently has no high/critical blocker for
Lorehold strategy, but battle runtime coverage remains a separate simulator
surface. It should not be used as proof that the deck builder metadata is
correct.

## Required Adjustments

1. Re-derive active learned-deck metadata from resolved card lists, starting
   with Lorehold `learned_deck:82`, so `metadata.total_lands` becomes `33`.
2. Backfill or intentionally classify the `363` base card rows missing
   `oracle_id` and/or `oracle_text`; prioritize the 6 card names currently
   present in `deck_cards`.
3. Change optimize policy for missing addition identity from "allowed as
   colorless" to "review/block unless card identity is proven colorless", or
   preserve current behavior only with explicit warning telemetry.
4. Keep generate fallback as a safety rail, but require output diagnostics to
   show actual source provenance and fallback use counts.
5. Treat `GeneratedDeckValidationService` repair warnings as quality evidence,
   not just successful validation cleanup.
6. Add first-class partner/background or combined commander identity to learned
   deck metadata instead of relying on audit-time inference.
7. Keep recurring battle artifacts in the strategy review loop, but do not mix
   battle simulator coverage issues with deck-list coherence issues.

## App And Saved-Deck Product Surface Update

Read path learned:

- `DeckGenerateScreen` loads learned commander summaries with
  `fetchCommanderLearningDecks()` and loads a specific commander through
  `fetchCommanderLearningDeck(commanderName)`.
- The learned path consumes `/ai/commander-learning`, then builds
  `_generatedDeck` from `recommended_deck.commander`, `recommended_deck.cards`,
  `validation`, and `diagnostics`.
- Save requires `validation.is_valid == true`.
- Save sends one commander slot plus main-board cards after filtering the
  commander name out of the main list.
- `DeckProvider.createDeck` aggregates card rows, resolves name-only rows via
  `/cards/resolve/batch`, rejects unresolved/ambiguous rows, then POSTs
  `/decks`.

Backend write path learned:

- `POST /decks` validates unsupported sections, resolves missing `card_id`
  values, runs `DeckRulesService.validateAndThrow(strict: false)`, then writes
  the deck. Learning-event logging is asynchronous after successful creation and
  should not be treated as part of the atomic deck validity proof.
- `PUT /decks/:id` validates a complete replacement list before deleting and
  reinserting cards.
- `POST /decks/:id/cards`, `/cards/bulk`, `/cards/replace`, and `/cards/set`
  all validate the final candidate state through `DeckRulesService` before the
  write.
- `/cards/bulk` refuses commander rows. `/cards/replace` only swaps printings
  of the same card name. `/cards/set` supports repair-like setting but still
  requires final deck validity.
- `POST /decks/:id/validate` uses `strict: true`, so Commander must have a
  commander and exactly `100` cards.

Rules-service contract learned:

- Saved decks do not support sideboard, wishboard, maybeboard, or
  outside-the-game sections.
- Copy limits are enforced by physical card key using `oracle_id` when present,
  with normalized physical-name fallback.
- Commander/Brawl slots are rejected outside Commander-style formats.
- Partner, Partner With, Choose a Background + Background, Friends Forever, and
  Doctor's companion + Time Lord Doctor are accepted pair models.
- Combined commander identity is computed from all commander cards and enforced
  against every non-commander card.

Product-surface divergence:

- Current tests intentionally keep `learned_deck:82` hidden before the learned
  deck is loaded, then show `Origem: HERMES learned_deck:82` in the loaded
  preview. This is useful provenance, but it is also an internal-ish source id
  in user-facing UI. The team should decide whether this remains visible or
  moves into debug/provenance details.
- App save can recover from missing card ids through `/cards/resolve/batch`,
  but the learned-deck route should still emit stable `card_id` values for
  every card whenever possible. Name resolution is a safety net, not the ideal
  primary contract.
- The stale Lorehold land metadata is product-facing through `role_summary`:
  the route can return a valid canonical decklist while showing stale summary
  counts if `role_summary` is still derived from learned-deck metadata.

App tests run in this pass:

- `cd app && flutter test test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart`: `64` tests passed.
- `cd app && flutter test test/features/decks/widgets/deck_diagnostic_panel_test.dart`: `3` tests passed.

Coverage from the app test pass:

- learned Lorehold shortcut and preview;
- learned-deck save with `99` main cards plus `1` commander;
- `/cards/resolve/batch` before save;
- async generate polling and sync fallback;
- optimize structured quality errors;
- async optimize polling;
- stale deck signature rejection;
- app-side commander-identity filtering for optimize additions.
- generic Commander diagnostic panel targets and current heuristic evidence
  labels.

Additional required adjustments:

8. Decide whether `HERMES learned_deck:82` remains visible in normal product
   preview or moves to debug/provenance details.
9. Keep app name-resolution fallback, but make `/ai/commander-learning` return
   stable `card_id` values for all resolved cards.
10. Keep the read-time `role_summary` recanonicalization guard in place and
    still backfill persisted learned-deck metadata so DB state and product
    responses agree outside the route.
11. Add a regression that runs the learned Lorehold response through app save
    normalization and backend create-deck validation semantics: one commander,
    no commander duplicate in main, and exactly `100` total quantity.
12. Tighten `/ai/generate` learning-boundary tests/documentation so they do not
    imply learned decks are ignored at runtime. The true contract is no direct
    SQL/product-route coupling, while active learned decks remain the first
    deterministic source when available.
13. Align Commander land targets across learned-deck strategy, backend
    `ai-analysis`, and Flutter `DeckDiagnosticPanel`. Lorehold has `33`
    resolved lands; backend weakness starts below `33`, backend scoring ideal
    starts at `34`, and the app panel marks Commander below `34` as low.
14. Avoid split-brain functional counts. Backend analysis uses persisted
    functional tags, semantic v2, then heuristics, while the Flutter diagnostic
    panel currently recomputes ramp/draw/removal from oracle text locally.

## Role Summary Source-Code Confirmation

The `/ai/commander-learning` implementation now mitigates the Lorehold metadata
divergence at read time:

- `_buildRecommendedDeck()` resolves card metadata, returns `card_id` when
  available, and validates the promoted learned deck through
  `GeneratedDeckValidationService`.
- `canonicalizeCommanderLearnedDeckMetadata()` can compute these values from
  the card list using `card_identity_bridge` and `card_function_tags`, and
  `upsertCommanderLearnedDeck()` calls it on write.
- The route now calls
  `await canonicalizeCommanderLearnedDeckMetadata(pool, learnedDeck)` before
  building the single-commander response.
- `recommended_deck.role_summary` and `promoted_deck.role_summary` now use
  `_roleSummaryFromMetadata(roleMetadata)`.
- Source tests explicitly prevent returning to
  `_roleSummary(learnedDeck)` or `_roleSummary(deck)`.

Net result for Lorehold deck `6`:

- The card list is coherent: `100` cards, one commander, `33` resolved lands,
  no oracle gap.
- The product route in this workspace now rederives `role_summary` from the
  canonical card list before responding, so stale persisted
  `metadata.total_lands = 30` should not leak through this endpoint.
- Persisted DB metadata can still be stale for other readers, exports, or
  future code paths. The remaining fix is a safe metadata backfill/re-upsert
  plus a regression that verifies Lorehold `learned_deck:82` returns `33`
  lands in both promoted and recommended summaries.

## Saved-Deck Analysis Surface Update

`POST /decks/:id/ai-analysis` writes `synergy_score`, `strengths`, and
`weaknesses` into `decks`, so it was inspected but not executed live for this
read-only audit.

Backend behavior:

- Reads `deck_cards` and prefers `card_intelligence_snapshot` when present.
- Computes totals, lands, commander count, average nonland CMC, and functional
  role counts.
- Functional counts use persisted functional tags first, semantic v2 second,
  and deterministic heuristics last.
- Commander heuristic scoring uses `34-39` as the ideal land band, but only
  emits the textual weakness "Poucos terrenos" when `land_count < 33`.

Flutter panel behavior:

- Recomputes metrics locally from `DeckDetails` and oracle text.
- Commander targets are `34-38` lands, `8+` ramp, `8+` draw, `8+`
  interaction, `2+` wipes, curve target `3.6`, curve warning `4.1`.
- A Lorehold list with `33` resolved lands can therefore be valid and coherent
  while still showing `Terrenos: Baixo` and "Base de mana curta" in the app
  panel.

Required interpretation:

- This is a target mismatch, not a legality failure.
- If `33` lands is intentional for Lorehold because the deck has enough ramp,
  draw/filtering, and topdeck setup, that needs a profile-aware target or a
  documented exception.
- If the product wants one source of truth, the app panel should consume the
  backend functional summary or a shared target profile instead of maintaining
  independent oracle-text heuristics.

## Import And Resolution Flow Update

Read-only code audit covered:

- `server/routes/import/index.dart`
- `server/routes/import/to-deck/index.dart`
- `server/routes/import/validate/index.dart`
- `server/lib/import_list_service.dart`
- `server/lib/import_card_lookup_service.dart`
- app import screen/dialog tests

Current guarantees:

- `POST /import` rejects unsupported sections before writing, resolves cards
  with `preferredFormat`, can add an explicit Commander/Brawl commander, forces
  commander quantity to `1`, and validates through `DeckRulesService` before
  creating the deck.
- `POST /import/to-deck` rejects unsupported raw sections and parsed
  unsupported sections, preserves an existing commander on Commander/Brawl
  replace-all imports when no imported commander is present, and validates the
  final merged/replaced state through `DeckRulesService`.
- `parseImportLines()` strips commander markers, keeps commander-tag state, and
  stops unsupported sections from becoming main-deck cards.
- `resolveImportCardNames()` uses canonical names, cleaned names, static
  Portuguese aliases, localized-name bridge rows, and front-face split-card
  fallback. The `card_identity_bridge` SQL is read-only view logic.
- App import UX has partial-import handling and refreshes deck details after
  importing into an existing deck.

Tests run in this pass:

- `cd server && dart test test/import_list_service_test.dart test/unsupported_deck_sections_route_contract_test.dart test/import_parser_test.dart -r expanded`
  - result: `43` tests passed.
- `cd app && flutter test test/features/decks/screens/deck_import_screen_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart`
  - result: `4` tests passed.
- `cd server && dart test test/commander_learned_deck_support_test.dart -r expanded`
  - result: `13` tests passed.

Remaining divergences to fix or explicitly accept:

15. `/import/validate` is preview-only and currently does not share the same
    hard unsupported-section response contract as mutation routes. It should
    either return the same structured `unsupported_section_lines` contract or
    the product should document why preview is softer than write routes.
16. `/import/to-deck` and `/import/validate` call `resolveImportCardNames()`
    without `preferredFormat`, while `POST /import` passes the deck format.
    This can make preview/update choose a different printing/card id than
    create for the same text input.
17. Import preview and update warnings aggregate copy limits by normalized name,
    while `DeckRulesService` enforces physical card identity using `oracle_id`
    when available. Final writes are protected, but warning quality can diverge
    for alternate printings and face-name cases.
18. Split-card fallback is front-face oriented (`<front> // %`). Add explicit
    tests or resolver support for back-face-only import text before treating
    that input as fully supported.
19. Some import tests still mirror regex behavior directly instead of only
    exercising `parseImportLines()`. Keep them as smoke tests, but move
    product-contract coverage to the real parser/service functions.

## Generate And Reference Flow Update

The `/ai/generate` route uses a reference/deterministic pipeline around the AI
call:

- loads exact commander profile, card stats, and corpus guidance when available;
- otherwise loads compatible archetype stats;
- loads usage hot cards and the active learned deck for the requested
  commander;
- uses deterministic fast path or deterministic fallback when appropriate;
- filters/refills generated cards against the reference profile before final
  validation;
- validates the final response with `GeneratedDeckValidationService`.

Important nuance:

- The route file does not embed `commander_learned_decks` SQL and does not call
  `/ai/commander-learning`.
- It still uses learned deck data at runtime through
  `loadActiveCommanderLearnedDeck(...)`.
- The real source precedence for deterministic reference decks is:
  `active_learned_deck`,
  `reference_card_stats`,
  `reference_corpus_packages`,
  `profile_expected_packages`,
  `usage_hot_cards`,
  `deterministic_fallback`.

`GeneratedDeckValidationService` is the structural gate:

- rejects unsupported sections before resolving cards;
- resolves names with `preferredFormat`;
- removes duplicated commander from the main card list;
- validates through `DeckRulesService(strict: true)`;
- auto-repairs Commander/Brawl by removing off-color cards, reducing extra
  singleton copies, filling missing slots with basic lands, and trimming excess
  basics.

This is safe for validity, but not enough for strategic quality. A deck that is
made valid by basic-land filling can still be strategically weak, so repair
warnings should be surfaced in product diagnostics.

Tests run in this pass:

- `cd server && dart test test/generated_deck_validation_service_test.dart test/ai_generate_learning_boundary_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_profile_lorehold_test.dart -r expanded`
  - result: `26` tests passed.
- `cd server && dart test test/commander_reference_deck_corpus_support_test.dart test/commander_reference_card_stats_support_test.dart test/commander_generate_provenance_audit_test.dart -r expanded`
  - result: `34` tests passed.

Additional required adjustments:

20. Reword generate/learned-deck boundary docs and tests: the safe claim is no
    direct SQL/product-route coupling in `/ai/generate`, not that learned decks
    are absent from generation.
21. Move Lorehold's no-premium-Mox policy into profile `avoid_patterns` or a
    dedicated generation policy filter. Today it is enforced in learned-deck
    audit/fallback evidence, but not explicitly in the profile avoid examples.
22. Add a regression that deterministic Lorehold diagnostics show
    `active_learned_deck` as a source before fallback when learned deck `82` is
    active.
23. Surface auto-repair warnings as product diagnostics so `validation.is_valid`
    is not mistaken for full strategic coherence.
24. Align Commander land targets across generate prompt, Lorehold profile,
    active learned deck truth, backend analysis, and Flutter diagnostics.

## Post-Creation Signals Update

Saved-deck analysis and recommendation surfaces are not all equivalent:

- `GET /decks/:id/analysis` is read-only and useful for mana curve, price,
  functional tags, warnings, and meta similarity, but it does not call
  `DeckRulesService`. Treat it as heuristic analysis, not canonical legality.
- `POST /decks/:id/ai-analysis` writes `synergy_score`, `strengths`, and
  `weaknesses`, so it is not part of this read-only execution loop.
- `POST /decks/:id/recommendations` has a filtered fallback path, but its
  OpenAI path returns parsed JSON without resolving/revalidating recommended
  card names before response.

Simulation surfaces also split:

- `GET /decks/:id/simulate` has an older local Monte Carlo implementation.
- `POST /ai/simulate` uses `GoldfishSimulator`, `MatchupAnalyzer`, or
  `BattleSimulator`, but writes simulation rows when called.
- `GoldfishSimulator` is the better tested primitive and should be the source
  of truth for consistency metrics.

Test run:

- `cd server && dart test test/goldfish_simulator_test.dart -r expanded`
  - result: `17` tests passed.

Additional required adjustments:

25. Consolidate simulation UX around `GoldfishSimulator` or clearly label the
    older `/decks/:id/simulate` route.
26. Either make `/decks/:id/analysis` call/share `DeckRulesService` for
    legality, or label `legality.is_valid` as heuristic issue status.
27. Resolve/revalidate OpenAI recommendation cards before returning or applying
    them.
28. Use simulation metrics to justify Lorehold's `33`-land choice if that
    remains intentional.

## Rebuild Guided Update

`POST /ai/rebuild` is draft-oriented and does not mutate the original deck:

- supports Commander/Brawl;
- requires an existing commander;
- can return preview or create a private draft clone;
- derives commander color identity from commander cards;
- uses `RebuildGuidedService`;
- validates rebuilt cards through `DeckRulesService(strict: true)`.

Good contracts:

- final strict validation is present before draft creation;
- commander identity filters candidate cards;
- bracket policy is applied to additions when bracket is present;
- basic lands are distributed by commander identity;
- Wastes are allowed only for colorless commanders by
  `rebuild_guided_land_support`.

Test run:

- `cd server && dart test test/rebuild_guided_land_support_test.dart -r expanded`
  - result: `3` tests passed.

Additional required adjustments:

29. Align rebuild target lands with the same Lorehold/profile target model as
    generate, analysis, app diagnostics, and active learned deck truth.
30. Make rebuild consume newer profile `expected_packages` and
    `avoid_patterns`, or explicitly document that it only uses legacy
    `recommended_structure/top_cards/average_deck_seed`.
31. Use the import resolver/card identity bridge for rebuild candidate
    resolution, or add coverage for exact-name misses on split/alias cards.
32. Add full service tests for rebuild assembly: color identity, bracket,
    must_keep, must_avoid, land target, and strict validation.
33. Enforce Lorehold no-premium-Mox policy in rebuild through profile
    `avoid_patterns`, `mustAvoid`, or a dedicated filter.

## Optimize Flow Update

`POST /ai/optimize` was inspected but not executed live because it records
analysis outcomes, ML feedback, fallback telemetry, cache rows, and async job
state. Source and unit/support tests were used instead.

What optimize does well:

- rejects `needs_repair` decks and points them to rebuild-guided;
- supports async aggressive optimize and async complete mode;
- loads commander priority pools from profile/meta/EDHREC;
- runs deterministic-first swaps when available;
- filters suggestions by deck membership, commander/core cards, duplicates,
  color identity, bracket policy, land-removal safety, quality gate, virtual
  post-analysis, and final validation;
- attaches swap integrity tied to the deck signature;
- can reject the whole response when no safe swaps remain or final quality
  validation fails.

Tests run:

- `cd server && dart test test/optimization_quality_gate_test.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_land_removal_protection_support_test.dart test/optimize_route_final_gate_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimize_route_virtual_analysis_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart -r expanded`
  - result: `50` tests passed.
- `cd server && dart test test/optimize_route_complete_top_up_support_test.dart test/optimize_complete_support_test.dart test/optimize_route_rebalance_support_test.dart test/optimize_route_payload_support_test.dart test/optimize_route_validator_support_test.dart test/optimize_runtime_support_test.dart test/optimization_validator_test.dart test/optimize_route_addition_data_support_test.dart test/optimize_route_warnings_support_test.dart -r expanded`
  - result: `73` tests passed.

Additional required adjustments:

34. Tighten land-removal protection for Lorehold/profile decks. The current
    direct helper only protects at `<=31` lands, while Lorehold's active truth
    is `33`.
35. Change missing addition identity behavior from "assume colorless" to
    "block or warn unless proven colorless".
36. Keep optimize mock/no-API behavior dev-only; it should not be product
    success without final validation.
37. Align complete-mode recommended lands with the same global/profile target
    model used elsewhere.
38. Enforce Lorehold no-premium-Mox policy in optimize through profile/policy
    data, not only through strict legality.
39. Add a no-write optimize dry-run path before using the route itself for
    read-only audits.

## Apply/Mutation Flow Update

Optimize suggestions are applied by the app through generic deck mutation
surfaces, not through a dedicated optimize-apply route.

Current flow:

- `requestOptimizePreview` validates `swap_integrity` hash/counts when the
  backend sends that block.
- `buildOptimizeApplyPlan` routes:
  - complete mode detailed additions -> `/decks/:id/cards/bulk`;
  - detailed swaps -> `applyOptimizationWithIds`;
  - name-only suggestions -> `applyOptimization`.
- `applyOptimizationWithIds` compares `expectedDeckSignature` against the
  currently selected `DeckDetails`, filters additions by commander identity when
  it can resolve the card names, then saves a full card payload with
  `PUT /decks/:id`.
- `applyOptimization` resolves names through card search, applies local counts,
  filters additions by commander identity, and also persists a full payload.
- After `PUT /decks/:id`, the app calls `/decks/:id/validate`.

Backend mutation contracts:

- `PUT /decks/:id`: full replacement, `DeckRulesService(strict:false)`,
  transactional delete/insert.
- `/cards/bulk`: additive batch, `DeckRulesService(strict:false)`,
  transactional replacement.
- `/cards/set`: absolute quantity for one card, `DeckRulesService(strict:false)`.
- `/cards/replace`: same-name printing swap only, validated before mutation.
- `/validate`: strict validation with `DeckRulesService(strict:true)`.

Tests run:

- `cd app && flutter test test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `95` tests passed.

Additional required adjustments:

40. Add a server-side optimize apply contract that validates
    `expectedDeckSignature`/`swap_integrity` against current `deck_cards` in the
    same transaction as the mutation.
41. Force-refresh or server-verify deck state immediately before app apply; the
    current app check uses cached selected deck data unless the deck is missing.
42. Carry signature/integrity through complete-mode bulk apply, or make bulk
    reject stale optimize-generated additions.
43. Avoid name-only optimize apply where possible. When unavoidable, use the
    same resolver/identity bridge semantics as import and backend validation.
44. Treat post-save strict validation failure as a failed optimize apply, not as
    a logged warning with success.
45. Add pure non-live tests for deck mutation semantics and future optimize
    apply; current backend route tests for these paths are live/db-write.

## DeckRulesService Contract Update

`DeckRulesService.validateAndThrow` is the central legality gate.

Current contract:

- blocks unsupported saved sections: sideboard, wishboard, maybeboard,
  outside-the-game;
- permits `is_commander` only for Commander/Brawl;
- loads `cards` and `card_legalities`;
- enforces copy limits by `oracle_id`, falling back to normalized physical front
  name;
- exempts basic lands from copy limits;
- blocks banned/not legal/restricted violations;
- validates commander quantity and commander eligibility;
- supports one commander or valid two-commander pairings: Partner, Partner With,
  Choose a Background + Background, Friends Forever, Doctor's Companion + Time
  Lord Doctor;
- validates combined commander color identity;
- blocks a selected commander from also appearing in the 99;
- enforces exact Commander/Brawl size only in `strict:true`.

Call-site split:

- `strict:true`: generated-deck validation, rebuild final validation,
  `/decks/:id/validate`.
- `strict:false`: creation, import save, import-to-deck, full deck update,
  add/set/bulk/replace card mutations.

Tests run:

- `cd server && dart test test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/commander_pairing_test.dart test/color_identity_test.dart -r expanded`
  - result: `33` tests passed.

Additional required adjustments:

46. Do not treat `DeckRulesService` as strategy coherence. It proves legality,
    not Lorehold's land target, package balance, or no-premium-Mox policy.
47. Use `strict:true` as the final success contract for optimize apply, not only
    `strict:false` mutation acceptance.
48. Close remaining card-data gaps around `oracle_id` and `oracle_text`; those
    fields are fallback-critical for singleton and identity behavior.
49. Add a color-identity regression test for whole-line parenthesized reminder
    text with mana symbols, or require authoritative `color_identity` for those
    cases.
50. Add service-level two-commander tests through `DeckRulesService`, not only
    helper tests.
51. Keep bracket/power/premium-card policy in explicit profile/policy gates,
    because legality does not equal ManaLoom strategic correctness.

## Lorehold Deck 6 Current Composition

Source inspected:

- SQLite `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- `decks.id=6`, not `learned_decks.id=6`
- deck name: `Runtime Lorehold Learned 19e93de3cca`
- PG deck link in notes:
  `528c877f-f829-4207-95e6-73981776c323`
- `100` cards, `1` commander, `33` lands, `67` nonlands
- local oracle identity only shows `R` and `W`
- no `Chrome Mox`, `Mox Diamond`, or `Mox Opal`

How it works:

- Lorehold gives instants/sorceries in hand miracle `{2}`.
- Opponent upkeeps create discard/draw windows.
- The list builds mana with lands, rocks, rituals and treasure engines.
- Topdeck/draw tools set up miracle and `Approach of the Second Sun`.
- Copy package duplicates high-impact spells/creatures.
- Recursion turns discard/graveyard into second-use value.
- Protection/stax buys the turn cycle needed to resolve haymakers.

Primary functional tag distribution:

- ramp `41`
- draw `16`
- engine `11`
- removal `7`
- protection `6`
- spellslinger `3`
- stax `3`
- remaining single/small categories: big_spell, board_wipe, loot, tutor,
  wincon, combo_piece, payoff, token_maker

Profile package coverage:

- complete: `mana_ramp_foundation` `5/5`,
  `draw_rummage_foundation` `3/3`, `protection_and_equipment` `3/3`
- partial: `interaction_and_resets` `4/7`
- weak by exact profile names: `topdeck_and_miracle_setup` `3/7`,
  `miracle_payoffs_expensive_spells` `4/12`,
  `spell_payoff_copy_package` `1/9`

Additional required adjustments:

52. Always disambiguate `deck id 6` as `decks.id=6` or PG deck id
    `528c877f-f829-4207-95e6-73981776c323`; `learned_decks.id=6` is Kefka in
    the current SQLite.
53. Reconcile the Lorehold land target: profile says `36-38`, current deck is
    `33`.
54. Reconcile the older canonical decision (`Wheel of Misfortune` present,
    `Reforge the Soul` absent) with the current materialized deck
    (`Reforge the Soul` present, no `Wheel of Misfortune`).
55. Decide whether missing topdeck package cards (`Library of Leng`,
    `Brainstone`, `Temple Bell`, `Mikokoro`) should be added or whether the
    profile should accept the current alternative setup.
56. Teach profile/package evaluation equivalence for the actual copy package:
    `Reiterate`, `Reverberate`, `Dualcaster Mage`, `Twinflame`,
    `Heat Shimmer`, `Electroduplicate`, `Molten Duplication`.
57. Do not score Lorehold only from primary `functional_tag`; consume
    `functional_tags_json`, `semantic_tags_v2_json`, and `battle_rules_json`.
58. Clean up battle-rule categories where key engines appear as `unknown`,
    especially cards like `Storm-Kiln Artist`.

Readonly canonical snapshot rerun:

- command:
  `python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_canonical_deck_snapshot.py --prefix lorehold_canonical_snapshot_readonly_20260619_1723`
- status: `blocked`
- artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_readonly_20260619_1723.md`
  - `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_readonly_20260619_1723.json`
- blocking errors:
  - expected `Wheel of Misfortune` present;
  - expected `Reforge the Soul` absent.
- no local SQLite apply was run.

## Battle Rules Learning

Read-only checks:

- `test_reviewed_battle_card_rules.py`
  - first run from repo root failed due to script-local import path
    (`battle_rule_registry`);
  - rerun from `docs/hermes-analysis/manaloom-knowledge/scripts` passed
    `18` tests.
- `test_battle_analyst_v10_3.py`,
  `test_battle_rule_registry_runtime_safe.py`, and
  `test_battle_effect_coverage_known_cards.py` passed `5` tests.

What is coherent:

- The reviewed registry knows how to model the core Lorehold miracle engine:
  Lorehold grants miracle `{2}`, opponent-upkeep rummage is modeled, Top and
  Scroll Rack can set up miracle draws, and Approach has a specific wincon
  rule.
- Runtime tests prove that Top/Scroll Rack interactions can actually produce
  miracle windows in the battle model.

Current deck-materialization finding:

- `96` current Lorehold rows have `battle_rules_json`.
- `4` rows are missing materialized rules:
  `Ancient Tomb`, `Command Tower`, `Lorehold, the Historian`, `Sol Ring`.
- Important current roles:
  - `Sensei's Divining Top` and `Scroll Rack`: `draw/topdeck_manipulation`
  - `Reiterate`, `Reverberate`, `Dualcaster Mage`: `engine/copy_spell`
  - `Approach of the Second Sun`: `wincon/approach`
  - `Mizzix's Mastery`: `wincon/overload_recursion`
  - `Storm-Kiln Artist`: `unknown/creature`
  - `Monument to Endurance`: `unknown/passive`

Additional required adjustments:

59. Fix the sync/materialization gap where `Lorehold, the Historian` has a
    reviewed registry rule but no current `deck_cards.battle_rules_json`.
60. Materialize battle rules for basic high-impact infrastructure cards in the
    current deck, especially `Sol Ring`, `Ancient Tomb`, and `Command Tower`.
61. Reconcile battle readiness with list composition: `Brainstone` and
    `Library of Leng` have reviewed rules, but they are not in the current
    Lorehold list.
62. Reclassify key `unknown` cards so battle/optimizer scoring can recognize
    engines, tutors, protection, and payoff pieces.
63. Add copy/combo/enabler role credit to token-copy spells instead of only
    treating them as `wincon/token_maker`.
64. Normalize cross-layer roles for cards like `Mizzix's Mastery`, where battle
    rules and primary functional tags currently describe different jobs.
65. Do not infer that Lorehold is final only because battle tests pass. The
    engine can model the strategy, but profile targets, canonical decisions,
    and the materialized deck still disagree.

## Battle Simulation Learning

Safe commands run:

- `python3 battle_forensic_audit.py --seed 42 --generate 3 --output-dir ../../master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44 --json-report ../../master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44.json`
- `python3 test_battle_replay_v10_3_renderer.py`
- `python3 test_battle_forensic_audit_supported_effects.py`
- `python3 test_battle_decision_strategy_auditor.py`
- `python3 test_battle_analyst_v10_3.py`

Results:

- three-seed forensic replay: `ready_for_review`
- critical/high findings: `0`
- medium findings: `2`
- low findings: `4`
- card events: `289`
- curated source events: `283`
- heuristic source events: `2`
- Lorehold miracle casts observed: `14`
- all observed miracle casts happened in `draw_step`
- Top activations observed: `6`
- opponent-upkeep rummage observed: `17`
- opponent-upkeep miracle casts observed in this sample: `0`

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_battle_forensic_readonly_20260619_seeds42_44/`

Additional required adjustments:

66. Add a report-only/dry-run mode for `master_optimizer_baseline.py`; the
    current script writes `optimizer_baseline_runs`, so it is not safe for
    read-only strategy audits.
67. Make the battle analyst deck id explicit. Today the CLI is seed/games only
    and the main path defaults to `deck_id=6`, which makes it Lorehold-first
    rather than a general all-decks evaluator.
68. Treat forensic `ready_for_review` as replay-provenance readiness, not final
    deck-list approval.
69. Reconcile the opponent-upkeep miracle claim: the engine supports it, but in
    seeds `42-44` the current list only showed draw-step miracle casts.
70. Fix `Rise of the Eldrazi` as a composite runtime rule. It currently casts
    through miracle but resolves only as `remove_permanent`, losing draw-four,
    extra turn, and exile-self behavior.
71. Add battle-rule coverage for opponent cards that affected the replay via
    heuristics, especially `Infernal Plunge`.
72. Review oracle normalization for bounce/removal cards such as `Snap`, where
    runtime broadens verified `remove_creature` to `remove_permanent`.
73. Add a targeted regression for composite spells whose oracle combines
    removal, draw, extra turn, and self-exile.
74. Keep replay provenance in final reports separated by quality tier: Lorehold
    events with card id/semantic hash versus opponent events with missing
    identity or heuristic source.

## Generation, Rebuild, And Learned Deck Learning

Safe commands/tests reviewed:

- `dart test test/ai_generate_learning_boundary_test.dart test/commander_generate_provenance_audit_test.dart test/commander_reference_card_stats_support_test.dart test/commander_learned_deck_support_test.dart test/generated_deck_validation_service_test.dart test/rebuild_guided_land_support_test.dart -r expanded`
  - `57` tests passed.
- `dart test test/deck_learning_event_support_test.dart -r expanded`
  - `3` tests passed.
- `python3 server/test/learned_deck_coherence_audit_test.py`
  - `7` tests passed.

Artifacts reviewed:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_generator_source_mix_2026-06-19_fallback_provenance_v4.json`
- `server/test/artifacts/commander_generate_provenance_2026-06-19_fallback_provenance_v4/commander_generate_provenance_summary.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_164611.json`
- `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260619_164611.md`

What is coherent:

- The Lorehold generator has strong provenance for the current output:
  `active_learned_deck` supports `99/99` non-commander cards.
- The provenance audit records `no_db_mutations: true`, `gaps: []`, and no
  fallback-only cards.
- The active learned deck, SQLite deck `6`, and linked PG saved deck
  `528c877f-f829-4207-95e6-73981776c323` have no name diff.
- The current PG/SQLite/Learned list has `100` total cards, `1` commander, and
  `33` lands.
- The focused learned-deck package checker passes Lorehold's broad minimums:
  commander identity, copy combo, topdeck/miracle setup, graveyard value, big
  spells, protection, and acceleration.
- All current no-premium-Mox policy checks pass for Lorehold: no `Chrome Mox`,
  `Mox Diamond`, or `Mox Opal`.

What is not coherent yet:

- Active learned metadata says `total_lands: 30`, while resolved cards and PG
  deck state say `33`.
- The canonical snapshot still blocks on the `Wheel of Misfortune` versus
  `Reforge the Soul` decision.
- The stricter reference profile expects topdeck/miracle setup cards such as
  `Brainstone`, `Library of Leng`, `Temple Bell`, and
  `Mikokoro, Center of the Sea`; the broader learned-deck checker accepts the
  current alternatives.
- `/ai/generate` validates legality/shape, not Lorehold strategy completeness.
- Production `/ai/generate` logs valid commander generations into
  `deck_learning_events`; use provenance scripts or a future no-learn flag for
  read-only audits.
- `/ai/rebuild` defaults to `draft_clone`, which writes a new draft deck. Use
  `preview_only` for audit runs.

Fleet-level learned deck finding:

- Active learned decks audited: `60`.
- High issues: `173`; medium issues: `27`.
- `58/60` have cached `total_lands` mismatching resolved card lists.
- `54/60` have all core metadata counters zero.
- `9` appear to need partner/background identity modeling.
- `5` still show off-color cards after basic checks.
- `6` include active deck cards with missing oracle text.
- By source, `pg_meta_decks` is the main risk surface: `52` active decks,
  `158` high issues, and `23` medium issues.

Additional required adjustments:

75. Treat active learned deck `82` as the current Lorehold generator source of
    truth for reproducibility, but not as final strategic truth.
76. Fix learned deck `82` cached metadata so `total_lands` matches the resolved
    33-land list.
77. Reconcile the canonical card decision: either restore
    `Wheel of Misfortune` and remove `Reforge the Soul`, or update the canonical
    decision artifact with a new tested rationale.
78. Define a Lorehold equivalence policy for topdeck/miracle setup, so broad
    package checks and strict reference-profile checks do not disagree silently.
79. Add a post-validation strategy gate after `GeneratedDeckValidationService`
    for commander-specific packages, bracket policy, and canonical decisions.
80. Add a no-learn/read-only option to `/ai/generate` if the live route is ever
    used for audit evidence.
81. Keep deterministic fallback under periodic audit even though it currently
    contributes `0` Lorehold cards.
82. Run rebuild audits only with `preview_only` unless the goal explicitly
    allows creating draft decks.
83. Reconcile Lorehold land policy before rebuild uses profile/default targets;
    current truth is `33`, while other guidance can push `36-38`.
84. Re-derive learned-deck metadata from resolved PostgreSQL card lists across
    the fleet; cached counters are not reliable today.
85. Add partner/background identity as first-class learned-deck metadata before
    using off-color checks as hard failures.
86. Repair legality/source coverage for staples such as `Sol Ring` and
    `Command Tower`, which appear as missing legality rather than real
    illegality.
87. Surface active-deck oracle gaps separately from general PostgreSQL oracle
    gaps before using optimizer or battle scores as product proof.

## Final Surface Coverage Learning

Final scan:

- backend routes scanned under `server/routes/decks`, `server/routes/ai`, and
  card/commander-related route names.
- app deck/card feature files scanned under `app/lib/features`.
- targeted reads confirmed the already-documented behavior for:
  `GET /decks/:id/analysis`, `POST /decks/:id/recommendations`, and
  `GET /decks/:id/simulate`.

Coverage state:

- Core construction flow is covered: create/import, generate, optimize, apply,
  mutate, validate, rebuild, learned deck, analysis, recommendation, simulation,
  battle, and Lorehold deck `6`/learned deck `82`/PG deck
  `528c877f-f829-4207-95e6-73981776c323`.
- Non-canonical product surfaces are intentionally not treated as construction
  truth: pricing, export, community decks, cards search, printings, and rulings.
- Any future product claim from those surfaces should consume a shared
  canonical deck-builder summary instead of recomputing strategy independently.

Additional required adjustments:

88. Define a named precedence contract across legality, diagnostics, reference
    profile, active learned deck, canonical Lorehold snapshot, battle rules, and
    simulation.
89. Keep pricing/export/community/card lookup surfaces out of strategy scoring
    unless they explicitly consume the same canonical construction summary.
90. Rerun the read-only snapshots after any PG, Hermes, profile, battle-rule, or
    generator change; otherwise this 2026-06-19 report becomes stale.

## Role Summary And Card Identity Bridge Recheck

Safe evidence collected:

- `cd server && dart test test/commander_learned_deck_support_test.dart -r expanded`
  - result: `16/16` tests passed.
- `cd server && dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --source-ref=learned_deck:82`
  - `status: PASS`
  - `mode: dry_run`
  - `db_mutations: false`
  - `checked: 1`
  - `changed: 1`
  - `applied: 0`
- Python PostgreSQL query with `readonly=True, autocommit=True`
  - active `source_ref`: `learned_deck:82`
  - parsed quantity: `100`
  - distinct names: `100`
  - `card_identity_bridge` resolved: `100`
  - unresolved: `0`
  - selected land quantity via bridge/type line: `33`
  - persisted metadata `total_lands`: `30`

What is coherent:

- `server/routes/ai/commander-learning/index.dart` recomputes canonical learned
  metadata before returning the single-commander response.
- `promoted_deck.role_summary` and `recommended_deck.role_summary` use
  `_roleSummaryFromMetadata(roleMetadata)`.
- The old stale `_roleSummary(learnedDeck)` / `_roleSummary(deck)` response
  path is absent.
- `card_identity_bridge` resolves all `100` learned deck `82` names when using
  the same lower/trim/apostrophe-preserving normalization as the Dart code.

What is still not coherent:

- Persisted `commander_learned_decks.metadata` for learned deck `82` is stale:
  dry-run changes `total_lands` from `30` to `33`, `ramp_count` from `17` to
  `20`, `draw_count` from `16` to `18`, `engine_count` from `33` to `36`, and
  `protection_count` from `8` to `13`.
- The route response is safer than direct metadata reads, but any consumer that
  bypasses `/ai/commander-learning` can still see stale role counts.

Additional required adjustments:

91. Do not open a Lorehold bridge-fix task from punctuation-stripping false
    positives; the corrected bridge check resolves `100/100` names.
92. Keep the metadata backfill task for chat "Ajustar deck": run
    `dart run bin/canonicalize_learned_deck_metadata.dart --apply --source-ref=learned_deck:82`
    only after explicit PostgreSQL mutation approval.
93. Until backfill is approved, route consumers should recompute role summary at
    read time or call `/ai/commander-learning`.
94. Keep normalization semantics aligned: current bridge view uses
    `LOWER(TRIM(...))`; learned/import code must not silently switch to
    punctuation-stripping normalization without matching bridge aliases.

## API Contract Documentation Recheck

Safe evidence collected:

- `cd server && dart test test/api_contracts_data_map_guard_test.dart test/commander_learned_deck_support_test.dart test/import_list_service_test.dart test/unsupported_deck_sections_route_contract_test.dart -r expanded`
  - result: `33/33` tests passed.
- Compared current route/app behavior against:
  - `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  - `server/doc/COMMANDER_LEARNING_API_2026-06-03.md`
  - `server/routes/ai/commander-learning/index.dart`
  - app deck generation providers, screen, and tests.

What is coherent:

- `API_CONTRACTS_AND_DATA_MAP.md` broadly matches current product behavior for
  `/ai/commander-learning?commander=`: auth-only, no costly AI quota, no raw
  Hermes metadata, backend-owned role counts, and `commander_learned_decks` as
  the source.
- Current single-commander route recomputes learned metadata through
  `canonicalizeCommanderLearnedDeckMetadata(...)` before exposing
  `promoted_deck.role_summary` and `recommended_deck.role_summary`.
- The Flutter availability list does not currently depend on list-mode
  `role_summary` or `win_conditions`; tests fake only summary fields such as
  commander, source ref, score, and legal status.

What is still not coherent:

- `server/doc/COMMANDER_LEARNING_API_2026-06-03.md` has a stale list response
  sample that includes `win_conditions` and `role_summary`, but the current
  list route returns only safe summary fields.
- Detail docs understate the read-time canonicalization behavior and the fact
  that persisted `commander_learned_decks.metadata` can still be stale.
- The current doc guard checks route rows, not field-level list/detail payload
  contracts, so this stale sample can survive while tests pass.

Additional required adjustments:

95. Update or mark the standalone Commander Learning API doc as historical; do
    not let its list-mode `role_summary`/`win_conditions` sample drive product
    implementation.
96. Add field-level tests/docs for Commander Learning list mode versus detail
    mode, separating cheap availability summaries from full deck payloads.
97. Document that detail-mode `role_summary` is read-time canonicalized through
    `canonicalizeCommanderLearnedDeckMetadata`, while persisted metadata may
    remain stale until an approved backfill.
98. For chat "Ajustar deck", treat
    `server/doc/API_CONTRACTS_AND_DATA_MAP.md` plus current route/tests as the
    controlling contract until `COMMANDER_LEARNING_API_2026-06-03.md` is
    reconciled.

## Saved-Deck AI Analysis Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/ai-analysis/index.dart' test/experimental_deck_ai_authorization_source_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart -r expanded`
  - result: `8/8` tests passed.
- `cd app && flutter test test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `64/64` tests passed.

What is coherent:

- `POST /decks/:id/ai-analysis` is owner-scoped and uses
  `card_intelligence_snapshot` when available, with aggregated functional and
  semantic tag fallbacks.
- Functional counts are derived through `summarizeFunctionalTagsForDeck(...)`,
  preserving multi-tag evidence before exposing legacy count fields.
- The app parser is defensive: it updates only `synergy_score`, `strengths`,
  and `weaknesses`, so missing `metrics` on cached responses does not break the
  current provider tests.
- `GET /decks/:id/analysis` remains the read-only functional-count surface;
  `POST /decks/:id/ai-analysis` is the persisted AI summary surface.

What is still not coherent:

- `ai-analysis` is not read-only: non-cached calls update
  `decks.synergy_score`, `decks.strengths`, and `decks.weaknesses`.
- `DeckAnalysisTab` auto-triggers the write route for decks with `cardCount >=
  60` and no existing AI summary.
- `API_CONTRACTS_AND_DATA_MAP.md` lists `archetype` and `bracket` as response
  fields, but the current route only reads them for the AI/heuristic payload and
  does not return them.
- Cached responses omit `metrics`, while non-cached responses include it.
- Commander land target wording is split: scoring accepts `33-39`, while prompt
  and user-facing weakness copy say `33-38`.

Additional required adjustments:

99. Do not use live `POST /decks/:id/ai-analysis` calls as read-only evidence
    for deck `6`; inspect code/tests or use isolated mocks instead.
100. Reconcile the API contract for `ai-analysis` response fields, especially
     `archetype`, `bracket`, and cached-response `metrics`.
101. Add a direct widget/provider regression for the auto-trigger branch in
     `DeckAnalysisTab`, including the no-trigger cases when the deck is under 60
     cards or already has analysis.
102. Align `ai-analysis` Commander land target text and scoring range before
     treating its synergy score as product guidance.
103. Keep `ai-analysis` as explanatory persisted summary, not final
     construction truth, until the deck-builder precedence contract is named and
     enforced.

## Weakness Analysis Advisory Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/weakness-analysis/index.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `11/11` tests passed.
- `server/test/ai_weakness_analysis_live_test.dart` was inspected but not run
  because it is tagged `live`, `live_backend`, and `live_db_write`.

What is coherent:

- `POST /ai/weakness-analysis` owner-scopes decks by `id + user_id`.
- The route prefers `card_intelligence_snapshot` and falls back to aggregated
  `card_function_tags` / `card_semantic_tags_v2`, then
  `resolveCardFunctionalRoles(...)`.
- Recommendation lookup is DB-backed and legal/color-aware; static tests guard
  against fixed staple literal recommendations.
- The route now returns combo, advanced-analysis, hate-card, and weakness
  history context, so it is richer than a simple ramp/draw/removal checklist.

What is still not coherent:

- It is not read-only: each detected weakness is inserted into
  `deck_weakness_reports`, and response `history` is loaded from that table.
- API docs list top-level `recommendations`, but the current route puts
  recommendations inside each `weaknesses[]` item and returns top-level
  `combos`, `advanced`, `history`, `weakness_count`, and `critical_count`.
- Recommendation color filtering derives `deckColors` from observed
  `cards.colors`, not from authoritative commander/deck color identity.
- Land guidance remains split: low-land threshold is `<33`, but copy says
  Commander generally needs `35-38` and `recommended_value` is `36`.

Additional required adjustments:

104. Do not run live `POST /ai/weakness-analysis` for deck `6` in read-only
     audits; use code/tests or isolated fixtures.
105. Reconcile `API_CONTRACTS_AND_DATA_MAP.md` with the current
     `weakness-analysis` response shape.
106. Add non-live response-shape coverage for `weakness-analysis`; current
     response assertions are in a live/db-write test.
107. Use commander/deck color identity for weakness recommendation filtering,
     or explicitly document the current observed-card-colors limitation.
108. Align weakness-analysis land target language and recommended value with the
     deck-builder precedence contract and Lorehold's current `33`-land truth.
109. Treat weakness-analysis as advisory investigation input, not as final
     deck-construction truth or a swap driver.

## Simulation Surface Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/simulate/index.dart routes/ai/simulate-matchup/index.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `12/12` tests passed.
- `server/test/ai_simulate_authorization_live_test.dart` was inspected but not
  run because it is tagged `live`, `live_backend`, and `live_db_write`.

What is coherent:

- `/ai/simulate` owner-scopes the primary deck and limits opponent decks to
  caller-owned or public decks.
- `/ai/simulate` documents and implements `type=battle` as a lightweight Dart
  simulator, not the Hermes Python Commander battle engine.
- `/ai/simulate-matchup` owner-scopes `my_deck_id`, allows owned/public
  opponent decks, and can fall back to `meta_decks`.
- API docs already warn that `/ai/simulate-matchup` is not an authoritative
  competitive prediction and correctly mention `deck_matchups` writes/reads.

What is still not coherent:

- These are not read-only endpoints: `/ai/simulate` writes
  `battle_simulations`, and `/ai/simulate-matchup` upserts `deck_matchups`.
- `/ai/simulate-matchup` uses raw oracle/type heuristics and observed card
  colors, not canonical functional roles or authoritative deck/commander color
  identity.
- `/ai/simulate-matchup` uses seedless `Random()` and accepts unvalidated
  `simulations`; both matchup and goldfish paths divide by the requested count.
- API docs list `win_rate`/`stats` for `/ai/simulate-matchup`, but current
  response nests win rate under `simulation` and does not return top-level
  `stats`.
- Current non-live coverage is mostly static source guards; the richer behavior
  test for `/ai/simulate` is live/db-write.

Additional required adjustments:

110. Do not run live simulation endpoints for deck `6` in read-only audits;
     inspect code/tests or use isolated fixtures instead.
111. Keep `/ai/simulate type=battle` advisory and separate from the Hermes
     battle/forensic engine used for Lorehold strategy evidence.
112. Reconcile `/ai/simulate-matchup` API docs with the current nested response
     shape, including `simulation.win_rate*` and `stored_matchup`.
113. Add non-live response-shape tests for both simulation routes.
114. Validate/clamp `simulations` and make seedless stochastic output explicit
     or deterministic under test.
115. Move matchup stats toward canonical functional roles and commander/deck
     color identity before using the route as deck-builder guidance.
116. Treat simulation output as advisory investigation input only; it must not
     certify deck coherence or drive swaps without validation, learned/reference
     checks, and the named deck-builder precedence contract.

## Import And Validation Flow Recheck

Safe evidence collected:

- `cd server && dart analyze routes/import/index.dart routes/import/validate/index.dart routes/import/to-deck/index.dart lib/import_list_service.dart lib/import_card_lookup_service.dart lib/deck_rules_service.dart test/import_list_service_test.dart test/import_parser_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart`
  - result: no issues found.
- `cd server && dart test test/import_list_service_test.dart test/import_parser_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart -r expanded`
  - result: `29/29` tests passed.
- `cd app && flutter test test/features/decks/screens/deck_import_screen_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `37/37` tests passed.
- `server/test/import_to_deck_flow_test.dart` was inspected but not run because
  it is tagged `live`, `live_backend`, and `live_db_write`.

What is coherent:

- Import routes are auth-protected by `server/routes/import/_middleware.dart`.
- `/import/validate` is non-mutating preview and passes preferred format into
  card lookup.
- `/import` rejects unsupported parsed sections, resolves localized/split
  names, can resolve the separate commander field, then writes `decks` and
  `deck_cards`.
- `/import/to-deck` owner-scopes the deck, rejects unsupported raw/parsed
  sections, resolves with the existing deck format, preserves an existing
  Commander/Brawl commander on replace-all when the list has no commander, and
  validates the final merged list before rewriting `deck_cards`.
- Import lookup now carries `oracle_id`, exposes `card_identity_bridge`, and
  supports front/back-face split aliases; `DeckRulesService` enforces final
  physical-copy identity by `oracle_id` where available.
- `DeckImportScreen` treats partial full imports as draft review before
  analysis/optimization.

What is still not coherent:

- `/import` and `/import/to-deck` are not read-only; they create/update
  persisted deck state.
- `/import/validate` is intentionally softer than write routes, so it must not
  be treated as final import success.
- Existing-deck import UX parses backend `warnings`, `missing_commander`, and
  `commander_preserved`, but `DeckImportListDialog` closes on success and only
  surfaces imported/not-found/localized feedback.
- Non-live coverage for `/import/to-deck` route behavior is still weaker than
  parser/resolver coverage; the focused flow test is live/db-write.

Additional required adjustments:

117. Do not run live `/import` or `/import/to-deck` for deck `6` in read-only
     audits; use code/tests or isolated fixtures.
118. Keep `/import/validate` as preview-only evidence and never as final
     construction truth.
119. Add non-live route-level tests for `/import/to-deck` response shape,
     commander preservation, and final total semantics.
120. Surface existing-deck import warnings and commander status in the dialog
     before treating the import as clean success.
121. Preserve import/validation physical identity alignment through
     `oracle_id`/`physicalCopyKey` in future changes.
122. Treat imported decks as draft/review state in chat "Ajustar deck" until
     strict validation, learned/reference checks, and strategy gates prove
     coherence.

## Validation Gate Recheck

Safe evidence collected:

- First backend `dart analyze` attempt failed before execution because the
  unquoted `[id]` route segment was expanded by `zsh`; the same command was
  rerun with the route path quoted.
- `cd server && dart analyze 'routes/decks/[id]/validate/index.dart' lib/deck_rules_service.dart lib/generated_deck_validation_service.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart -r expanded`
  - result: `65/65` tests passed.
- `cd app && flutter test test/features/decks/widgets/deck_details_actions_test.dart test/features/decks/widgets/deck_details_overview_tab_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `42/42` tests passed.
- No live `/decks/:id/validate` call was made against deck `6`.

What is coherent:

- `POST /decks/:id/validate` is auth/owner scoped by `id + user_id`, reads
  current `deck_cards`, and calls `DeckRulesService(... strict:true)`.
- The route response shape is source-proven: success returns
  `ok`, `format`, and `deck_id`; rule failures return HTTP `400` with
  `ok:false`, `error`, and optional `card_name`.
- `DeckRulesService` uses `oracle_id` through `physicalCopyKey` when available,
  enforces singleton/copy limits, card legality, commander eligibility,
  commander-not-in-99, commander color identity, and strict deck size.
- `GeneratedDeckValidationService` uses the same strict legality service after
  name resolution and can expose auto-repair/invalid-card quality evidence.
- App validation consumers correctly treat `{ok:false}` as a validation result,
  not only as an exception, and the overview UI names this surface legalidade.

What is still not coherent:

- Strict validation is not strategy validation. It cannot prove Lorehold package
  quality, topdeck/miracle support, recursion density, copy/payoff structure, or
  learned/reference deck alignment.
- Creation/update/import paths can use `strict:false`, so a persisted edit can
  still be legal-enough for building but not final-valid.
- Optimization apply persists cards first, then validates; a failed
  post-write validation is logged as a warning and details are refreshed rather
  than rolled back.
- `API_CONTRACTS_AND_DATA_MAP.md` still says the validate response body is not
  fully proven and cites `deck_validation_test.dart`, which is mostly
  mirror/spec coverage rather than direct route-contract proof.

Additional required adjustments:

123. Treat `/decks/:id/validate` as final legality/shape only, not strategy
     coherence.
124. Update the API contract row for `/decks/:id/validate` with the source-proven
     success and rule-failure response fields.
125. Add focused non-live route/handler tests for validation owner scope, method
     rejection, success shape, and `DeckRulesException` shape.
126. Preserve `strict:true` as the final apply-ready contract; `strict:false`
     write paths are only edit/build allowances.
127. Treat post-write validation failure in optimization/apply as failed or
     rollback-worthy state, not only warning telemetry.
128. Expose generated-deck auto-repairs and invalid-card removals as quality
     evidence, not clean proof of strategic coherence.
129. For chat "Ajustar deck", require a strategy/package gate after strict
     validation for Lorehold and for every other commander deck.

## Manual Card Lookup And Mutation Recheck

Safe evidence collected:

- `date -u +%Y-%m-%dT%H:%MZ`
  - result: `2026-06-19T22:58Z`.
- `cd server && dart analyze routes/cards/index.dart routes/cards/printings/index.dart 'routes/decks/[id]/cards/index.dart' 'routes/decks/[id]/cards/bulk/index.dart' 'routes/decks/[id]/cards/set/index.dart' 'routes/decks/[id]/cards/replace/index.dart' lib/card_query_contract.dart lib/deck_rules_service.dart test/cards_route_test.dart test/card_resolution_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/cards_route_test.dart test/card_resolution_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `18/18` tests passed.
- `cd app && flutter test test/features/cards/screens/card_search_screen_test.dart test/features/decks/widgets/deck_details_dialogs_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart`
  - result: `71/71` tests passed.
- No live card lookup sync or deck mutation route was called against deck `6`.

What is coherent:

- `/cards` is local backend DB lookup with 45s endpoint cache, `limit` clamp,
  page clamp, image normalization, optional set metadata, and additive identity
  fields when migrated columns exist.
- `/cards` defaults to `include_tokens=false` and `dedupe=true`; mobile search
  uses `/cards?name=<query>&limit=50&page=<page>`.
- `/cards/printings` is local read by exact name unless `sync=true` is supplied.
- Manual mutation routes owner-scope the deck and validate through
  `DeckRulesService(... strict:false)` before writes.
- Card search UI guides Commander/Brawl users toward commander-first setup and
  blocks visible off-identity adds, while backend validation remains the real
  authority.

What is still not coherent:

- `/cards/printings?sync=true` can upsert `cards` and `sets`, so the edition
  picker's loading path is not read-only.
- Manual deck mutation endpoints all write `deck_cards`; they cannot be live
  audit probes for deck `6`.
- API docs do not make `/cards` defaults explicit enough: `include_tokens=true`
  and `dedupe=false` are opt-in values, not defaults.
- Edition replacement is same-name based in `/cards/set` and `/cards/replace`,
  while final legality has moved toward `oracle_id`/`physicalCopyKey`.
- `/cards/bulk` rebuilds `deck_cards` without carrying existing condition
  values.
- Safe tests for this slice are mostly helper/static/widget/provider tests;
  focused mutation behavior still relies heavily on live/db-write coverage.

Additional required adjustments:

130. Do not call live manual mutation endpoints for deck `6` in read-only
     audits.
131. Treat `/cards/printings?sync=true` as write-capable and avoid it in
     read-only audit evidence.
132. Clarify `/cards` API defaults: `include_tokens=false`, `dedupe=true`.
133. Add non-live route tests for `/cards` default dedupe/token behavior and
     `/cards/printings` no-sync versus sync boundary.
134. Add non-live handler/source-contract tests for manual mutation response
     shapes and `DeckRulesService(... strict:false)` gates.
135. Align edition replacement with `oracle_id`/`physicalCopyKey` or document
     same-name-only semantics.
136. Preserve condition values through `/cards/bulk`, or document that bulk add
     sacrifices condition fidelity.
137. Treat card-search UI filtering as advisory; backend validation remains the
     legal source of truth.
138. After manual mutation, require strict validation and strategy/package review
     before chat "Ajustar deck" accepts a deck as coherent.

## Pricing, Export, And Community Copy Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/pricing/index.dart' 'routes/decks/[id]/export/index.dart' 'routes/community/decks/[id].dart' test/api_contracts_data_map_guard_test.dart test/error_contract_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_details_actions_test.dart test/features/decks/widgets/deck_details_overview_tab_test.dart test/features/decks/widgets/deck_details_dialogs_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/community/providers/community_provider_test.dart test/features/community/providers/social_provider_test.dart`
  - result: `95/95` tests passed.
- No live pricing or community-copy route was called against deck `6`.

What is coherent:

- `/decks/:id/pricing` is owner scoped and computes a consistent USD deck
  pricing payload from `deck_cards JOIN cards`.
- `/decks/:id/export` is owner scoped and read-only; it produces backend-owned
  text for copy/share flows.
- `/community/decks/:id` public detail is read-only for public decks and returns
  usable presentation stats, commander/main-board grouping, and flat card rows.
- App provider/parser tests are aligned with the current public copy response
  shape: HTTP `201` with `{success:true, deck}`.

What is still not coherent:

- Pricing is not read-only: it always updates the deck pricing snapshot and can
  update up to `10` missing/forced card prices in `cards`.
- Deck details auto-loads pricing with `force:false`, so opening a meaningful
  deck can trigger write-capable backend behavior.
- Pricing/export/community stats do not prove Lorehold strategy, role coverage,
  learned-deck package alignment, or oracle/semantic identity correctness.
- Export `card_count` is line count, not quantity sum.
- Public deck copy creates a draft-like deck: it copies only
  `card_id/quantity/is_commander` plus basic deck fields, without conditions,
  archetype/bracket/pricing/analysis and without strict validation.
- API docs are stale for pricing aliases and public-copy response shape.

Additional required adjustments:

139. Do not call live `/decks/:id/pricing` for deck `6` in read-only audits.
140. Treat deck-details pricing auto-load as write-capable even with
     `force:false`.
141. Keep pricing, export, and community presentation stats out of the final
     strategy/coherence truth precedence.
142. Update the pricing API contract to match current response fields and to
     make the always-write deck snapshot explicit.
143. Clarify export `card_count` as line count or expose separate
     `line_count`/`total_quantity` fields.
144. Update the public-copy API contract from `newDeckId` to nested `deck`.
145. Treat community deck copies as draft/review until strict validation and
     strategy/package review pass.
146. Add non-live route/handler tests for pricing write boundaries, export count
     semantics, and public-copy response/copied-field semantics.

## Saved Deck Fetch And Hydration Recheck

Safe evidence collected:

- `cd server && dart analyze routes/decks/index.dart 'routes/decks/[id]/index.dart' test/api_contracts_data_map_guard_test.dart test/error_contract_test.dart`
  - result: no issues found.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `5/5` tests passed.
- `cd app && flutter test test/features/decks/models/deck_test.dart test/features/decks/models/deck_details_test.dart test/features/decks/models/deck_card_item_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_details_overview_tab_test.dart test/features/decks/widgets/deck_card_overflow_test.dart test/features/decks/widgets/deck_card_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `103/103` tests passed.
- Live/db-write deck route tests were inspected for scope but not run:
  `decks_crud_test.dart`, `decks_incremental_add_test.dart`,
  `deck_analysis_contract_test.dart`, and `error_contract_test.dart` carry
  `live`, `live_backend`, and `live_db_write` tags.
- No live `GET /decks/:id` was called for deck `6`.

What is coherent:

- `GET /decks` is owner-scoped, returns the legacy raw array, and computes
  `card_count` as sum of persisted `deck_cards.quantity`.
- `GET /decks/:id` is owner-scoped, reads `deck_cards JOIN cards`, returns
  root-level deck fields, grouped `commander`/`main_board`, `all_cards_flat`,
  and `stats.total_cards` from quantities.
- The app models preserve the main card quantities, commander flag, condition,
  set/printing display fields, pricing snapshot fields, and presentation color
  identity.
- Detail cache is bounded to `5` minutes and mutation/import paths have tests
  proving important refresh/invalidation behavior.
- Optimize/apply color filtering uses the actual commander card identity through
  `getCommanderIdentitySet()`, not the aggregate deck `colorIdentity`.

What is still not coherent:

- Deck-level `color_identity` is a union of current deck card identities. It is
  not the same thing as commander legal identity and can reflect off-color draft
  state.
- `GET /decks/:id` detail cards and `DeckCardItem` do not expose `oracle_id`,
  `layout`, or `card_faces`, so app-side canonical identity decisions are not
  available from the hydrated details model.
- Detail `mana_curve`, `color_distribution`, type grouping, and list
  `colorIdentity` are UI/read-model aggregates, not learned/reference strategy
  evidence.
- Background color enrichment is best-effort; non-200 detail responses can be
  skipped without appearing in `failedDeckIds`.
- The API contract row for `GET /decks/:id` is ambiguous/stale around a nested
  `deck` wrapper and edition identity fields.

Additional required adjustments:

147. Use saved-deck fetch as the card-list substrate only, never as final
     strategy/coherence proof.
148. Do not treat deck-level `color_identity` as commander legal identity.
149. Keep optimize/apply filtering anchored to the actual commander card
     identity.
150. Update the `GET /decks/:id` API contract to state root-level deck fields,
     not a nested `deck` wrapper.
151. Add or explicitly defer `oracle_id`/layout/card-face fields in saved deck
     details; until then, app canonical identity decisions must remain
     backend-owned.
152. Treat detail stats and grouping as presentation aggregates only.
153. Improve or document best-effort color enrichment failure reporting.
154. Require a fresh details read/source artifact after mutations before drawing
     deck-state conclusions for deck `6`.
155. Add non-live route/handler tests for deck list/detail response shape and
     count/color/card-field semantics.

## Deck Create, Full Persist, And Optimize Apply Recheck

Safe evidence collected:

- `cd server && dart analyze routes/decks/index.dart 'routes/decks/[id]/index.dart' lib/deck_rules_service.dart lib/deck_schema_support.dart test/api_contracts_data_map_guard_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart`
  - result: no issues found.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart -r expanded`
  - result: `14/14` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
  - result: `95/95` tests passed.
- Live/db-write CRUD tests were inspected for intent but not run:
  `server/test/decks_crud_test.dart`.
- No live `POST /decks`, `PUT /decks/:id`, PostgreSQL write, or deck `6`
  mutation was performed.
- Current revalidation, `2026-06-19 21:49 -03`:
  - `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/widgets/deck_optimize_flow_support.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
    - result: no issues found.
  - `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart -r expanded`
    - result: `87/87` tests passed.
  - `cd server && dart analyze routes/decks/index.dart 'routes/decks/[id]/index.dart' test/api_contracts_data_map_guard_test.dart`
    - result: no issues found.
  - `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
    - result: `6/6` tests passed.

What is coherent:

- `POST /decks` creates deck and cards in one transaction, rejects unsupported
  deck sections, resolves name-only cards with format legality preference, and
  validates with `DeckRulesService(... strict:false)` before commit.
- `POST /decks` returns the direct created deck map, and the app parser accepts
  that shape.
- `PUT /decks/:id` is owner-scoped and replaces the full `deck_cards` list only
  when `cards` is supplied.
- `PUT /decks/:id` validates the composed full list before deleting/reinserting
  old cards.
- `PUT /decks/:id` normalizes missing or invalid `condition` to `NM`, so missing
  condition in write payloads is an implicit default-condition decision.
- `/decks/:id/validate` reloads persisted cards and runs
  `DeckRulesService(... strict:true)`, making it the ready-deck gate.
- Learned-deck save builds a Commander payload with one commander row and main
  rows resolved to card IDs before `POST /decks`.
- Optimize apply checks stale signature before PUT and refilters additions by
  actual commander identity before persisting.
- Current optimize full-persist preserves existing commander/mainboard
  `DeckCardItem.condition`; new optimize additions and complete-mode bulk add
  still omit `condition` and therefore rely on the backend/default `NM` path.

What is still not coherent:

- Create and update resolve name-only card payloads differently: create uses
  target-format legality ordering; update uses first lowercase name match.
- New optimize additions and complete-mode bulk add carry only `card_id`,
  `quantity`, and `is_commander`; they default to `NM` unless an explicit
  condition is added. Existing-card condition preservation is current app
  source/test behavior.
- App create does not send `archetype`/`bracket`, even though backend create
  supports those fields.
- App persist validates strictly only after the full PUT succeeds; it reports
  validation status but does not roll back a deck that was write-valid yet not
  strict-ready.
- Optimize stale signature is structural only (`id:quantity`), not condition or
  full printing metadata proof.
- Create learning telemetry is unawaited and raw-request based, so it is not
  canonical learned strategy evidence.

Additional required adjustments:

156. Do not use live create/full-PUT routes as audit probes for deck `6`.
157. Treat create/full-PUT `strict:false` validation as draft/construction
     validation, not final Commander readiness.
158. Require strict validation after any full persist before declaring Lorehold
     or another commander deck coherent.
159. Preserve or intentionally default `condition` for new optimize/full-persist
     additions. Existing-card condition is now preserved by the app helper, while
     new additions still omit condition and rely on backend/default `NM`.
160. Align create/update name resolution or require `card_id`-only full PUT
     payloads.
161. Keep the destructive full-replacement semantics of `PUT /decks/:id`
     visible in docs and UI.
162. Keep app copy-limit and identity filtering advisory; backend rules remain
     canonical.
163. Expand stale-deck signatures if physical condition or edition metadata
     should block optimize apply.
164. Add create support for `archetype`/`bracket` if generated/learned deck
     saves need immediate strategy metadata persistence.
165. Treat create-learning telemetry as advisory, not persisted deck truth.
166. Add route-level non-live tests for create/update shape, name resolution,
     new-addition condition defaulting, full replacement, and strict-validation-
     after-persist behavior. App helper/provider tests cover the current
     existing-condition preservation and apply-flow behavior, but not backend
     route semantics.

## Rebuild Guided Draft Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/rebuild/index.dart lib/ai/rebuild_guided_service.dart lib/ai/rebuild_guided_land_support.dart lib/ai/optimize_route_response_support.dart lib/ai/optimize_feedback_support.dart test/rebuild_guided_land_support_test.dart test/optimize_route_response_support_test.dart test/optimize_route_outcome_support_test.dart test/optimize_feedback_support_test.dart`
  - result: no issues found.
- `cd server && dart test test/rebuild_guided_land_support_test.dart test/optimize_route_response_support_test.dart test/optimize_route_outcome_support_test.dart test/optimize_feedback_support_test.dart -r expanded`
  - result: `17/17` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `103/103` tests passed.
- Live/db-write rebuild tests in `server/test/ai_optimize_flow_test.dart` were
  inspected for scope but not run.
- No live `/ai/rebuild`, draft clone, PostgreSQL write, or deck `6` mutation
  was performed.

What is coherent:

- `/ai/rebuild` is owner-scoped, Commander/Brawl-only, and supports
  `preview_only` plus `draft_clone`.
- Rebuild validates the rebuilt list with `DeckRulesService(... strict:true)`
  before response/draft creation.
- `draft_clone` creates a new private deck and never mutates the original deck.
- The response and app branch preserve `applied_to_original=false` semantics.
- The app treats `rebuild_guided` as a structured repair branch, opens a
  confirmation modal, calls `/ai/rebuild`, refreshes the draft details, and
  opens the new draft.

What is still not coherent:

- Rebuild uses EDHREC commander/average data plus cached
  `commander_reference_profiles` and local heuristics; it does not directly
  consume active learned-deck `role_summary`, `card_identity_bridge`,
  `card_intelligence_snapshot`, or persisted multi-role function tags.
- Candidate loading is direct lowercase-name lookup from `cards`, not
  identity-bridge or format-legality ordered lookup.
- Draft clone drops physical condition and does not copy pricing/analysis
  metadata.
- Non-live backend route coverage for `/ai/rebuild` request/response/copy
  semantics is still thin; the strongest route proof is live/db-write and was
  intentionally not executed.

Additional required adjustments:

167. Do not call live `/ai/rebuild` with `draft_clone` for deck `6` during
     read-only audits.
168. Keep rebuild as a draft-review branch, never an in-place apply branch.
169. Require strict validation, fresh draft details, and learned/reference
     package review before any rebuild draft is accepted for Lorehold.
170. Preserve or explicitly document loss of `condition` in rebuild drafts.
171. Align rebuild candidate lookup with `card_identity_bridge` and legality
     preference, or document strict validation as the only post-lookup guard.
172. Keep rebuild role heuristics separate from learned-deck `role_summary` and
     semantic multi-role truth.
173. Add focused non-live route/handler tests for `/ai/rebuild` request
     validation, owner scoping, `preview_only`, `draft_clone`, copied fields,
     condition handling, and `applied_to_original=false`.
174. Update the `/ai/rebuild` API contract with source precedence and physical
     metadata-loss caveats.
175. For chat "Ajustar deck", surface rebuild results as draft tasks to review,
     not as automatic swaps to the current deck.

## Strategy Options / Archetypes Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/archetypes/index.dart lib/ai/commander_reference_profile_support.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `16/16` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: `54/54` tests passed.
- Live/db-write archetype and error-contract tests were inspected for intent
  but not run: `server/test/ai_archetypes_flow_test.dart` and
  `server/test/error_contract_test.dart`.
- No live `/ai/archetypes`, OpenAI call, PostgreSQL write, or deck `6`
  mutation was performed.

What is coherent:

- `/ai/archetypes` is owner-scoped and reads only the authenticated user's deck.
- The Lorehold commander reference profile path returns deterministic
  commander-relevant strategy choices before OpenAI.
- Lorehold deterministic options are `Miracle Big Spells`,
  `Topdeck / Discard Value`, and `Spellslinger Burn Finishers`, which align
  with the reference profile's miracle/topdeck/spellslinger package.
- The route includes cache/timing diagnostics and caches reference, mock, and
  OpenAI payloads for ten minutes.
- The app consumes options tolerantly and still requires an optimize preview
  before any apply.
- Empty options do not block the sheet: the app shows a `midrange` fallback as
  a safe UI continuation.

What is still not coherent:

- The route reads only card names, commander flag, and quantity from the deck.
  It does not use oracle identity, `card_identity_bridge`, oracle text,
  semantic tags, `card_intelligence_snapshot`, or learned-deck role summaries.
- OpenAI prompt context is a reduced name-only sample of up to forty
  non-commander cards, so it cannot prove exact package coherence.
- Reference-profile lookup uses only `commanders.first`, which is not enough
  for partner/background/multi-commander strategy truth.
- Mock generic options and app `midrange` fallback can look like strategy
  choices, but they are continuity fallbacks, not analyzed deck evidence.
- Current API contract does not fully document these source limitations or the
  advisory-only nature of this route.
- Strongest route behavior tests for caching and Lorehold options are live
  backend tests; focused non-live handler coverage is still missing.

Additional required adjustments:

176. Do not use live `/ai/archetypes` as a required deck `6` audit probe when
     the audit must avoid OpenAI/runtime-cache side effects.
177. Treat archetype options as optimize-input labels, not final strategy
     verdicts.
178. Preserve owner scoping on `/ai/archetypes`.
179. Generalize commander reference selection before treating this route as
     truth for partner/background/multi-commander decks.
180. Add canonical identity and role-summary inputs, or document that the route
     is intentionally name/sample based.
181. Keep Lorehold options aligned to miracle big spells, topdeck/discard
     value, and spellslinger burn finishers when the reference profile is
     usable.
182. Mark mock options and `midrange` fallback as UX fallbacks only.
183. Keep reference-profile version/cache invalidation explicit.
184. Add non-live route/handler tests for required body, owner scoping,
     reference response shape, mock/no-key fallback, invalid-key fallback,
     cache key/version behavior, and malformed OpenAI responses.
185. Update the `/ai/archetypes` API contract with source limits, cache/mock
     semantics, and advisory-only status.
186. For chat "Ajustar deck", require optimize preview plus strict validation
     before any selected archetype becomes a real adjustment.

## Commander Reference Endpoint Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/commander-reference/index.dart lib/ai/commander_reference_helpers.dart lib/ai/commander_reference_readiness_support.dart lib/ai/commander_reference_profile_support.dart lib/ai/commander_reference_card_stats_support.dart lib/ai/commander_reference_deck_corpus_support.dart test/commander_learned_deck_support_test.dart test/commander_reference_readiness_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/commander_reference_readiness_support_test.dart test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_deck_corpus_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `82/82` tests passed.
- Live/backend/write commander-reference test inspected but not run:
  `server/test/commander_reference_atraxa_test.dart`.
- No live `/ai/commander-reference`, EDHREC fetch, MTGTop8 fetch, PostgreSQL
  write, or deck `6` mutation was performed.

What is coherent:

- `/ai/commander-reference` can build competitive reference cards from
  `meta_decks`, EDHREC cache/profile data, or `card_meta_insights`.
- Optional `learning=1` can expose commander profile, card stats, corpus,
  readiness, usage hot cards, and promoted learned-deck summary.
- Optional `include_deck=1` prefers promoted learned deck before deterministic
  reference fallback.
- Recommended learning decks use `card_identity_bridge` through
  `loadCardMetadataByName` and validate through
  `GeneratedDeckValidationService`.
- Raw learned-deck metadata is not exposed by the route.
- The app currently uses `/ai/commander-learning` for learned decks, not direct
  `/ai/commander-reference`.

What is still not coherent:

- The route is `GET` but can write: it creates
  `commander_reference_profiles`, can upsert EDHREC profiles, and can insert
  MTGTop8 decks into `meta_decks`.
- Base `reference_cards` from `meta_decks` are textual-name aggregates, not
  canonical identity or role-summary evidence.
- EDHREC profile fallback uses a hardcoded 36-land structure, while current
  Lorehold active truth remains 33 lands.
- `/ai/commander-reference` remains under costly AI middleware, unlike
  `/ai/commander-learning`; that is sensible for current behavior but confirms
  it is not a cheap product read path.
- Current API contract understates write side effects and optional learning
  payload/source tables.
- Focused non-live handler coverage for commander-reference route branches is
  thin; the strongest endpoint test is live/db-write.

Additional required adjustments:

187. Do not call live `/ai/commander-reference` during read-only deck `6`
     audits without explicit mutation/external-fetch approval.
188. Keep `/ai/commander-learning` as the product learned-deck route.
189. Keep `/ai/commander-reference` behind costly AI middleware until pure-read
     and mutating refresh/cache paths are separated.
190. Split or clearly label mutating refresh/cache behavior on this `GET`
     route.
191. Do not treat textual `meta_decks.card_list` reference-card aggregation as
     canonical card identity, package, or role proof.
192. If using `commander_learning.recommended_deck` from this route, keep
     promoted learned deck precedence and require validation.
193. Reconcile EDHREC 36-land structure with Lorehold's current 33-land active
     truth before using it as a repair target.
194. Update the commander-reference API contract with side effects, optional
     learning payloads, source tables, and advisory-only semantics.
195. Add non-live handler/source tests for missing commander, limit clamping,
     no-refresh behavior, EDHREC cache write path, MTGTop8 refresh write path,
     and `learning/include_deck` shape.
196. For chat "Ajustar deck", treat commander-reference as supporting context
     only; actual adjustments still need learned/reference/bridge/preview/
     strict-validation proof.

## Card Explanation / AI Explain Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/explain/index.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd app && flutter analyze lib/features/cards/providers/card_provider.dart lib/features/decks/widgets/deck_details_dialogs.dart test/features/decks/widgets/deck_details_dialogs_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/widgets/deck_details_dialogs_test.dart`
  - result: `7/7` tests passed.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `6/6` tests passed.
- Live/e2e `/ai/explain` checks in `error_contract_test.dart`,
  `e2e_general_tests.py`, and `e2e_ml_tests.py` were inspected but not run.
- No live `/ai/explain`, OpenAI call, PostgreSQL write, card cache update, or
  deck `6` mutation was performed.

What is coherent:

- `/ai/explain` gives the app a simple card-learning helper.
- The route can return cached `cards.ai_description` when `card_id` is present.
- With no OpenAI key or invalid-key dev fallback, it returns a local simplified
  explanation with `is_mock=true`.
- The prompt asks for PT-BR rules/timing, play tips, common mistakes, and
  typical synergies.
- The app exposes the flow from deck card details and tests loading, dialog
  rendering, action dispatch, and friendly handling when the injected callback
  throws.

What is still not coherent:

- The route writes `cards.ai_description` after OpenAI success, so it is not a
  read-only route when `card_id` is supplied.
- The route trusts client-supplied `card_name`, `oracle_text`, and `type_line`
  for generation/cache and does not reload canonical DB card fields first.
- The cache has no visible prompt/model/oracle version metadata, so stale
  explanations can survive rules text or prompt changes.
- The app copy promises contextual deck role/value, but the provider sends no
  `deck_id`, commander, archetype, role summary, package context, or deck list.
- `CardProvider.explainCard` catches exceptions and returns technical error
  text; the dialog then treats that returned string as explanation content.
- There is no focused non-live backend handler test for `/ai/explain`; current
  backend coverage is live/e2e or broad contract guard.

Additional required adjustments:

197. Do not call live `/ai/explain` during read-only deck `6` audits when
     `card_id` is present.
198. Treat `cards.ai_description` as UX cache only.
199. Reload/verify canonical DB card fields before caching generated
     explanation, or mark cache provenance as caller-supplied.
200. Add cache metadata for prompt/model/oracle/version if explanations are
     reused across sessions.
201. Align UI copy with actual route inputs, or add real deck-context inputs
     and owner-scope checks.
202. Change provider error handling so technical exceptions are not displayed as
     explanation text.
203. Add non-live backend tests for missing/empty `card_name`, cache hit,
     fallback paths, OpenAI success cache policy, and provider failure shape.
204. Update the `/ai/explain` API contract with write effects, caller-field
     limits, no deck context, and advisory-only status.
205. For chat "Ajustar deck", use card explanations only to help a human review
     already-justified candidates.

## Saved-Deck Recommendations Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/recommendations/index.dart' lib/ai/edhrec_trend_service.dart lib/ai/optimization_functional_roles.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `17/17` tests passed.
- `rg` over `app/lib` and focused app deck/card tests found no current direct
  Flutter consumer for `/decks/:id/recommendations`.
- No live recommendations route, OpenAI call, PostgreSQL write, deck `6`
  mutation, swap, commit, or push was performed.

What is coherent:

- The route is owner-scoped by `deck id + user_id`.
- The route uses `card_intelligence_snapshot` when present and otherwise
  aggregates `card_function_tags` and `card_semantic_tags_v2` by `card_id`.
- Fallback candidate lookup is DB-backed, legal/color-aware, and avoids fixed
  staple literals or rarity-as-impact shortcuts.
- EDHREC trend use in this route calls `getCardTrends`, which reads
  `edhrec_card_snapshots`; the snapshot-writing method is separate and is not
  called here.
- The API contract already marks this as experimental, direct app consumption
  not proven, and says `/ai/optimize` is preferred for app-facing optimization.

What is still not coherent:

- With `OPENAI_API_KEY`, the route calls OpenAI and returns parsed model JSON
  without backend post-validation of proposed add/remove cards.
- Heuristic fallback uses observed deck colors as the candidate color filter,
  not authoritative commander color identity. Existing illegal off-color cards
  could broaden the search.
- Fallback land logic flags Commander `landCount < 34` while copy says
  `35-38`; this can conflict with the current Lorehold active truth of `33`
  lands.
- Fallback `power_level` returns `3/5/7/8`, but the OpenAI prompt asks for
  Commander bracket `1-4`.
- OpenAI and fallback response shapes differ: fallback returns `statistics`,
  `trending`, `source`, and `message`; OpenAI may return only the prompt JSON or
  `raw_response`.
- Current focused tests are source/contract guards, not route-handler shape
  tests for fallback/OpenAI/EDHREC branches.

Additional required adjustments:

206. Do not call live `POST /decks/:id/recommendations` in deck `6` read-only
     audits when OpenAI is configured.
207. Keep saved-deck recommendations advisory-only; use `/ai/optimize`, strict
     validation, learned-deck truth, and reference package checks before any
     real adjustment.
208. Align Commander land threshold/copy with Lorehold's current `33`-land truth.
209. Do not compare fallback `power_level` to bracket-based optimize outputs
     until both use the same scale.
210. Post-validate OpenAI recommendations or label them as unvalidated AI text.
211. Filter fallback additions by authoritative commander color identity, not
     only observed deck colors.
212. Normalize response shapes before wiring this route to Flutter or chat
     actions.
213. Add non-live route-handler tests for no-key fallback, OpenAI success/error,
     malformed JSON, EDHREC trend reads, 33-land Lorehold behavior, and
     commander-color filtering.
214. Update the API contract with external-call risk, response-shape split,
     current non-mutating DB-read behavior, and advisory-only status.
215. If exposed in UI, label results as review suggestions and require
     optimize/validation before any replace/apply action.

## Read-Only Deck Analysis Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/analysis/index.dart' lib/ai/functional_card_tags.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart test/functional_card_tags_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart test/functional_card_tags_test.dart -r expanded`
  - result: `24/24` tests passed.
- `cd app && flutter analyze lib/features/decks/models/deck_analysis.dart lib/features/decks/providers/deck_provider_support_fetch.dart lib/features/decks/providers/deck_provider.dart lib/features/decks/widgets/deck_analysis_tab.dart lib/features/decks/widgets/deck_diagnostic_panel.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/models/deck_analysis_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/models/deck_analysis_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart`
  - result: `72/72` tests passed.
- Live `/decks/:id/analysis` contract/smoke tests were inspected but not run
  because they are tagged `live`, `live_backend`, and `live_db_write`.
- No live route call, PostgreSQL write, deck `6` mutation, swap, commit, or push
  was performed.

What is coherent:

- `GET /decks/:id/analysis` is owner-scoped and read-only in current source.
- It uses `card_intelligence_snapshot` when present; fallback paths aggregate
  `card_function_tags` and `card_semantic_tags_v2` per card before deck-row use.
- Functional counts come from `summarizeFunctionalTagsForDeck`, with tested
  priority: persisted functional tags, semantic v2, then deterministic
  heuristics.
- Flutter caches `DeckAnalysisData`, coalesces in-flight requests, and
  invalidates analysis cache after card mutations and AI-analysis refresh.
- `DeckAnalysisTab` and `DeckDiagnosticPanel` both consume backend functional
  counts/samples, with legacy fallback to `stats.composition`.

What is still not coherent:

- `legality.is_valid` from this route is local/basic and does not call strict
  `DeckRulesService`.
- The route does not use `oracle_id` or `card_identity_bridge` for singleton
  identity, nor commander color identity/presence for Commander legality.
- Commander land warning uses `31 + avgCmc * 2.5`, which can conflict with the
  current Lorehold `33-38` target.
- `meta_analysis.suggested_adds` comes from textual Jaccard overlap against
  recent `meta_decks`, not bridge-backed learned/reference package truth.
- Opening `DeckAnalysisTab` can also auto-trigger the separate write route
  `POST /decks/:id/ai-analysis` for complete unanalyzed decks.

Additional required adjustments:

216. Treat `GET /analysis.legality.is_valid` as advisory only; strict validation
     remains the legal gate.
217. Do not use analysis legality to prove commander color identity, commander
     presence, or singleton identity across printings.
218. Align analysis land warnings with the Lorehold `33-38` target or label the
     CMC formula as generic heuristic.
219. Keep `meta_analysis.suggested_adds` advisory-only until reconciled through
     `card_identity_bridge`, learned/reference package truth, and validation.
220. Separate `DeckAnalysisTab` read-only functional fetch from auto-triggered
     write `POST /ai-analysis` if the tab must be guaranteed read-only on open.
221. Add non-live route-handler tests for response shape, owner-scope not-found,
     method-not-allowed, strict-validation mismatch examples, 33-land Lorehold,
     and advisory meta-analysis fields.
222. Update the API contract to state that `legality` is local/basic and
     `meta_analysis.suggested_adds` must not drive swaps.
223. For chat "Ajustar deck", use analysis functional counts only as diagnosis;
     candidate changes still need learned/reference/bridge/optimize/validation
     evidence.

## Opening-Hand / Sample-Hand Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/simulate/index.dart' test/experimental_deck_ai_authorization_source_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart -r expanded`
  - result: `11/11` tests passed.
- `cd server && dart test test/goldfish_simulator_test.dart -r expanded`
  - result: `17/17` tests passed.
- `cd app && flutter analyze lib/features/decks/widgets/sample_hand_widget.dart lib/features/decks/widgets/deck_details_overview_tab.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/widgets/sample_hand_widget_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/widgets/sample_hand_widget_test.dart`
  - result: `2/2` tests passed.
- No live route call, PostgreSQL write, deck `6` mutation, swap, commit, or push
  was performed.

What is coherent:

- `GET /decks/:id/simulate` is owner-scoped before it derives deck statistics.
- The route can provide coarse land-distribution and turn 1-5 on-curve
  percentages for a deck's current persisted cards.
- `SampleHandWidget` gives the player a local hand-draw experience and is used
  in both the overview and analysis surfaces.
- `POST /ai/simulate` is a separate, more complete backend goldfish path using
  `GoldfishSimulator`, clamped simulation counts, stable default seeding, and
  focused simulator tests.

What is still not coherent:

- `GET /decks/:id/simulate` and `SampleHandWidget` are different local/backend
  implementations and are not currently wired into one product contract.
- `GET /decks/:id/simulate` uses fixed `1000` iterations and unseeded
  randomness, so its output is not reproducible enough for audit claims.
- The legacy route does not read `oracle_id`, `card_identity_bridge`,
  semantic/function tags, learned deck data, or card intelligence snapshots.
- The legacy route's turn model draws on turn 1 and does not model London
  mulligan, colors, tapped lands, fixing, ramp sequencing, commander tax, or
  interaction.
- `SampleHandWidget` excludes commander cards, shuffles only `mainBoard`, and
  judges hands by land count, early CMC `<=3`, and colored pips. It is useful
  UX, not deck-construction proof.

Additional required adjustments:

224. Treat opening-hand tools as playtest/consistency support only for Lorehold
     deck `6` and for all other deck builders.
225. Do not use `GET /decks/:id/simulate` as a legality, strategy, role, or
     oracle-identity verdict.
226. Do not use non-reproducible `GET /simulate` percentages as audit evidence
     until seed/iteration controls or `GoldfishSimulator` delegation exist.
227. Keep `SampleHandWidget` labels out of swap selection logic; they can only
     illustrate a hand after the proposed list is already validated.
228. Separate app-local sample hand, legacy `GET /decks/:id/simulate`, and
     `POST /ai/simulate` goldfish in the API/product contract.
229. Prefer `POST /ai/simulate` + `GoldfishSimulator` for backend consistency
     metrics, but keep it advisory rather than a final deck-coherence gate.
230. Add non-live tests for `GET /decks/:id/simulate` response shape,
     method-not-allowed, owner-scope not-found, empty deck behavior, and
     advisory-only limitations.
231. For chat "Ajustar deck", sample-hand data may explain land/curve concerns
     only after learned/reference, bridge/identity, optimize/analysis, and
     strict validation evidence already support the candidate list.

## Import Existing-Deck UI Reconciliation

Safe evidence collected:

- `cd server && dart analyze routes/import/index.dart routes/import/validate/index.dart routes/import/to-deck/index.dart lib/import_list_service.dart lib/import_card_lookup_service.dart lib/deck_rules_service.dart test/import_list_service_test.dart test/import_parser_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart`
  - result: no issues found.
- `cd server && dart test test/import_list_service_test.dart test/import_parser_test.dart test/unsupported_deck_sections_route_contract_test.dart test/deck_rules_service_identity_test.dart -r expanded`
  - result: `29/29` tests passed.
- `cd app && flutter analyze lib/features/decks/widgets/deck_import_list_dialog.dart lib/features/decks/providers/deck_provider_support_import.dart lib/features/decks/screens/deck_import_screen.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_import_screen_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_import_screen_test.dart`
  - result: `38/38` tests passed.
- Live `server/test/import_to_deck_flow_test.dart` was not run because it is
  live/db-write coverage that creates, imports into, and deletes decks.
- No live route call, PostgreSQL write, deck `6` mutation, swap, commit, or push
  was performed.

What changed since the earlier import recheck:

- `DeckImportListDialog` now parses `/import/to-deck` `warnings`,
  `missing_commander`, and `commander_preserved`.
- The dialog keeps review details visible after successful import-to-existing
  when any warnings, missing commander, preserved commander, localized matches,
  or not-found lines require review.
- The focused widget test now proves the modal remains open and renders
  not-found, warning, missing-commander, and commander-preserved sections.

What remains true:

- `/import/to-deck` is a write route. It validates inside a transaction, then
  deletes/reinserts `deck_cards`.
- `/import/validate` is preview-only and uses `oracle_id`/physical-copy-key
  warning logic.
- `DeckRulesService` remains the canonical physical identity gate for imports;
  successful route warnings are advisory status, not the full validation
  contract.

Additional required adjustments:

232. Mark previous import item `136` as resolved in current app source/tests.
233. Keep non-live `/import/to-deck` route-handler coverage open for response
     shape, merge semantics, and commander-preserved/missing-commander details.
234. Document that `/import/to-deck` can reject physical-copy, commander-in-99,
     color-identity, or max-size violations through `DeckRulesService` instead
     of returning a successful warning response.
235. Treat successful import-to-existing with review details as draft-only in
     chat "Ajustar deck" until fresh fetch, strict validation, and
     learned/reference package review pass.

## Generate / Learned Deck Entry Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/generate/index.dart 'routes/ai/generate/jobs/[id].dart' routes/ai/commander-learning/index.dart lib/ai_generate_job.dart lib/ai_generate_internal_url_support.dart lib/generated_deck_validation_service.dart lib/ai/commander_learned_deck_support.dart lib/ai/commander_reference_generate_fallback_support.dart test/ai_generate_learning_boundary_test.dart test/generated_deck_validation_service_test.dart test/commander_learned_deck_support_test.dart test/ai_generate_job_authorization_source_test.dart test/ai_generate_internal_url_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/ai_generate_learning_boundary_test.dart test/generated_deck_validation_service_test.dart test/commander_learned_deck_support_test.dart test/ai_generate_job_authorization_source_test.dart test/ai_generate_internal_url_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `45/45` tests passed.
- `cd app && flutter analyze lib/features/decks/screens/deck_generate_screen.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/providers/deck_provider.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: `32/32` tests passed.
- No live route call, PostgreSQL write, deck `6` mutation, swap, commit, or push
  was performed.

What is coherent now:

- `/ai/generate` is a draft generation route that can use commander reference
  profile, card stats, corpus guidance, usage hot cards, compatible archetype
  stats, and active promoted learned-deck evidence.
- `/ai/commander-learning` is the explicit promoted learned-deck product route.
  Detail mode returns a validated recommended deck; list mode returns safe
  summary fields only.
- `GeneratedDeckValidationService` is the current strict legality/shape gate
  for generated and recommended learned decks.
- `DeckGenerateScreen` keeps generation and learned-deck loading as reviewable
  previews. Saving creates a new deck payload through `createDeck(...)` and does
  not mutate Lorehold deck `6`.
- Current UI tests keep raw learned-deck source refs out of the preview.

What remains true:

- Live `POST /ai/generate` is not read-only in production behavior because valid
  Commander generations can be logged for learning.
- Validation success is not the same as strategic coherence. It does not prove
  Lorehold package balance, win lines, recursion density, removal mix, ramp, or
  card-role intent.
- Learned/generated previews are candidate drafts until fresh deck fetch,
  strict validation, oracle/identity checks, learned/reference package review,
  strategy review, and explicit approval all pass.

Additional required adjustments:

236. Keep `/ai/generate` out of read-only audit runs unless using non-live tests
     or a controlled fixture path.
237. Keep `/ai/commander-learning` as the learned-deck product contract and
     avoid treating `/ai/generate` diagnostics as promoted-deck truth.
238. Surface validation `quality_evidence` and fallback repair state as review
     blockers or warnings, not as hidden internals.
239. Treat learned-deck save as new-deck creation; never infer that it updated
     or corrected deck `6`.
240. Preserve product-safe UI boundaries around learned decks; do not expose raw
     Hermes metadata or raw source refs.
241. For chat "Ajustar deck", learned/generated suggestions can seed a candidate
     list, but cannot be applied without explicit approval.
242. Require explicit generation diagnostics source/package coverage before
     using diagnostics to claim Lorehold package completeness or absence.
243. Keep non-live tests around async job ownership, fallback quality evidence,
     product-safe learned-deck payloads, and sync fallback commander propagation.

## Optimize Current Route Recheck

Safe evidence collected:

- `cd server && dart analyze routes/ai/optimize/index.dart lib/ai/optimize_request_support.dart lib/ai/optimize_route_async_support.dart lib/ai/optimize_route_color_identity_filter_support.dart lib/ai/optimize_route_warnings_support.dart test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimize_route_final_gate_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimize_route_virtual_analysis_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart`
  - result: no issues found.
- `cd server && dart test test/optimize_route_color_identity_filter_support_test.dart test/optimize_route_warnings_support_test.dart test/optimize_route_diagnostics_support_test.dart test/optimize_route_final_gate_support_test.dart test/optimize_route_quality_rejection_support_test.dart test/optimize_route_post_validation_support_test.dart test/optimize_route_virtual_analysis_support_test.dart test/optimize_route_suggestion_filter_support_test.dart test/optimize_route_bracket_policy_filter_support_test.dart -r expanded`
  - result: `29/29` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider_support_ai.dart lib/features/decks/widgets/deck_optimize_flow_support.dart lib/features/decks/widgets/deck_optimize_dialogs.dart lib/features/decks/widgets/deck_optimize_sheet_widgets.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/widgets/deck_optimize_dialogs_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `103/103` tests passed.
- No live `/ai/optimize` call, PostgreSQL write, deck `6` mutation, swap,
  commit, or push was performed.

What changed since earlier optimize notes:

- Missing addition identity is now blocked by
  `filterOptimizeAdditionsByCommanderIdentity(...)` and surfaced through
  `warnings.filtered_by_missing_identity`.
- The previous finding that missing identity was treated as colorless is closed
  for current source/tests.

What remains true:

- Live `/ai/optimize` is write-capable. It can persist `ai_optimize_jobs`,
  `optimization_analysis_logs`, feedback, cache/fallback telemetry, and user
  preferences.
- Optimize is a candidate generator with quality gates, not final Lorehold
  truth.
- App-side optimize still requires preview, user confirmation, and an apply plan
  before any deck mutation.
- Detailed ID apply is stronger than name-only apply; name-only apply depends
  on generic card search and needs extra review.

Additional required adjustments:

244. Keep `/ai/optimize` out of read-only audit runs unless a future no-write
     fixture/dry-run mode is introduced and proven.
245. Treat old optimize item `41` as closed in current source/tests.
246. Keep mock optimize (`is_mock:true`) out of product evidence.
247. Do not treat cached optimize responses as current deck truth without
     deck-signature/fresh-state review.
248. Require preview, selection, and explicit confirmation before any optimize
     apply path.
249. Prefer detailed ID optimize apply over name-only apply; name-only apply
     remains weaker and needs extra review.
250. Keep optimize loaders on `card_intelligence_snapshot` or per-card
     aggregated semantic/function subqueries.
251. Treat semantic v2 optimize diagnostics as gate/diagnostic evidence, not
     proof of Lorehold package completeness.
252. After optimize apply in chat "Ajustar deck", require strict validation,
     fresh fetch, and learned/reference package review.
253. Keep expanding non-live coverage for async accepted shape, job ownership,
     cache hits, mock safeguard behavior, and any future dry-run mode.

## Final Validation Gate Current Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/validate/index.dart' lib/deck_rules_service.dart lib/generated_deck_validation_service.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart -r expanded`
  - result: `66/66` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/providers/deck_provider_support_common.dart lib/features/decks/widgets/deck_details_actions.dart lib/features/decks/widgets/deck_details_overview_tab.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/widgets/deck_details_actions_test.dart test/features/decks/widgets/deck_details_overview_tab_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/widgets/deck_details_actions_test.dart test/features/decks/widgets/deck_details_overview_tab_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `42/42` tests passed.
- No live validation route call, PostgreSQL write, deck `6` mutation, swap,
  commit, or push was performed.

What is coherent now:

- `DeckRulesService` remains the canonical legality/shape service for saved
  deck state.
- It validates unsupported sections, commander slot format, copy/singleton
  identity through `oracle_id` when available, commander-in-main-deck identity,
  banned/not-legal/restricted statuses, commander eligibility, combined
  commander color identity, and strict size.
- `/decks/:id/validate` runs that service with `strict:true`.
- The API contract row now documents the current success and rule-failure body
  shapes, so the older contract-shape item is reduced/closed for current docs.

What remains true:

- `/decks/:id/validate` is final legality/shape proof, not strategy proof.
- Current not-found/permission failure in the route is a generic HTTP `500`.
- Current non-live tests still do not directly exercise the handler response
  contract for owner-scope miss, method rejection, success body, or rule body.
- `DeckRulesService` still prints debug copy-limit logs during validation.

Additional required adjustments:

254. Treat previous validation contract item `141` as closed for current API docs.
255. Keep previous validation route-test item `142` open.
256. Add focused non-live handler tests for `/decks/:id/validate` method
     rejection, owner-scope miss, success shape, and `DeckRulesException` shape.
257. Fix or explicitly document owner-scope miss behavior; current route returns
     HTTP `500` for deck not found or permission denied.
258. Remove or gate `DeckRulesService` debug copy-limit prints.
259. Keep strict validation required after any mutation in chat "Ajustar deck",
     but follow it with learned/reference package and strategy checks.
260. Treat post-write strict validation failure as failed or rollback-worthy,
     not as harmless warning.

## Final Validation Route Follow-up Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/validate/index.dart' lib/deck_validation_route_support.dart lib/deck_rules_service.dart lib/generated_deck_validation_service.dart test/deck_validation_route_support_test.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_validation_route_support_test.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart -r expanded`
  - result: `71/71` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/providers/deck_provider_support_common.dart lib/features/decks/widgets/deck_optimize_flow_support.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `92/92` tests passed.
- No live validation route call, PostgreSQL write, deck `6` mutation, swap,
  code edit, commit, or push was performed.

What changed in current evidence:

- The backend route now returns HTTP `404` with
  `{ok:false, error, error_code:deck_not_found}` for deck not found or
  permission denied.
- The API contract row now matches the current route/helper shape.
- Route support tests now cover helper/static evidence for method rejection,
  owner-scope SQL, not-found body, success body, and rule-failure body.
- The provider now returns `false` when post-save strict validation is not ok
  and refreshes deck details.

What still remains:

- The route still needs true handler-level non-live tests if we want proof
  beyond helper/static wiring.
- `deck_optimize_flow_support.dart` still models apply callbacks as
  `Future<void>`, so a provider `false` can be ignored by the flow.
- There is no current app-flow test proving a post-save validation failure
  blocks `updateDeckStrategy(...)` and `onSuccess()`.
- `DeckRulesService` debug copy-limit prints remain visible in validation
  tests.

Additional required adjustments:

261. Close old item `257` for current backend behavior; owner-scope miss is now
     HTTP `404` with `error_code:deck_not_found`.
262. Reduce old item `256`, but keep a stricter variant open for true handler
     tests rather than helper/static source tests only.
263. Treat old item `260` as reduced at provider level only.
264. Change the optimize apply flow contract to consume boolean apply failure
     or throw on failure before strategy persistence and success callbacks.
265. Add flow-level tests proving validation failure after save blocks
     `updateDeckStrategy(...)` and user-facing success handling.
266. Keep strict validation as a mandatory legality gate, then run
     learned/reference and Lorehold strategy gates.
267. Keep `DeckRulesService` debug print cleanup open.

## Learned Deck Metadata Fleet Recheck

Safe evidence collected:

- `cd server && dart analyze lib/ai/commander_learned_deck_support.dart lib/ai/commander_reference_helpers.dart lib/ai/commander_reference_generate_fallback_support.dart routes/ai/commander-learning/index.dart routes/ai/generate/index.dart routes/ai/commander-reference/index.dart test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/commander_reference_card_stats_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/commander_reference_card_stats_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `52/52` tests passed.
- `python3 -m unittest server.test.learned_deck_coherence_audit_test -v`
  - result: `14/14` tests passed.
- `python3 server/bin/learned_deck_coherence_audit.py --stdout --gate-active-learned-deck-metadata`
  - result: exited `1` because the read-only active metadata gate failed.
  - active learned decks: `60`
  - `metadata_total_lands_mismatch`: `58`
  - `metadata_zero_lands`: `54`
  - `all_core_metadata_zero`: `54`
  - gate failure count: `166`
- `cd server && dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --source-ref=learned_deck:82 --include-unchanged`
  - result: `PASS`, `dry_run`, `db_mutations=false`, checked `1`,
    changed `1`, applied `0`.
  - Lorehold before metadata: lands `30`, ramp `17`, draw `16`, removal `8`,
    tutor `5`, engine `33`, wincon `13`, protection `8`, recursion `4`,
    board wipe `2`.
  - Lorehold after canonical recomputation: lands `33`, ramp `20`, draw `18`,
    removal `8`, tutor `5`, engine `36`, wincon `13`, protection `13`,
    recursion `4`, board wipe `2`.
- No code edit, PostgreSQL write, deck `6` mutation, swap, commit, or push was
  performed.

Current learning:

- `card_identity_bridge` remains the right identity layer for learned-deck
  canonicalization and response card ids.
- Lorehold learned deck `82` is currently resolvable enough to recompute `33`
  lands in dry-run, so the active Lorehold blocker is stale persisted metadata,
  not a current bridge mapping gap.
- The fleet-level learned deck metadata state is still not coherent: the active
  metadata gate fails on persisted rows.
- `canonicalizeCommanderLearnedDeckMetadata(...)` catches all errors and returns
  `input.metadata`. That is a code-derived risk, not an observed runtime
  failure in this pass: if bridge/tag canonicalization fails, detail-mode
  `role_summary` can silently degrade to stale metadata.
- `/ai/generate` uses active learned decks as first-precedence source evidence
  through support helpers; it does not directly embed `commander_learned_decks`
  SQL.

Additional required adjustments:

268. Keep Lorehold `learned_deck:82` backfill pending until explicit PostgreSQL
     mutation approval.
269. Add a fleet metadata backfill/gate plan for the `58` land mismatches and
     `54` zeroed core metadata rows.
270. Add coverage or diagnostics for silent canonicalization fallback to stale
     `input.metadata`.
271. Do not mark detail-mode `role_summary` fully robust until fallback
     behavior is observable, tested, or blocked.
272. Keep `card_identity_bridge` fix work closed for current Lorehold evidence.
273. Preserve additive multi-role learned-deck role counts.
274. In chat "Ajustar deck", use active learned deck as first source candidate
     only with strict validation, freshness checks, and Lorehold package review.

## Import Flow Incremental Recheck

Safe evidence collected:

- `cd server && dart analyze lib/import_card_lookup_service.dart lib/import_list_service.dart lib/import_to_deck_merge_support.dart routes/import/index.dart routes/import/validate/index.dart routes/import/to-deck/index.dart test/import_parser_test.dart test/import_list_service_test.dart test/import_to_deck_merge_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/import_parser_test.dart test/import_list_service_test.dart test/import_to_deck_merge_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `35/35` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_import.dart lib/features/decks/widgets/deck_import_list_dialog.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart`
  - result: `30/30` tests passed.
- `cd app && flutter analyze lib/features/decks/screens/deck_import_screen.dart test/features/decks/screens/deck_import_screen_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/screens/deck_import_screen_test.dart`
  - result: `3/3` tests passed.
- `cd server && dart test test/external_commander_meta_import_support_test.dart -r expanded`
  - result: `6/6` tests passed.
- `python3 server/test/run_import_resolution_test.py -v`
  - result: `2/2` tests passed.
- Live `server/test/import_to_deck_flow_test.dart` was inspected but not run
  because it is tagged `live`, `live_backend`, and `live_db_write`.
- No live route call, PostgreSQL write, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/import` is a write/create path and uses strict Commander/Brawl validation
  before persistence.
- `/import/validate` is preview-only and non-mutating; it returns oracle-backed
  identity evidence and warning feedback, but write routes own blocking.
- `/import/to-deck` is owner-scoped, rejects unsupported sections, preserves a
  Commander/Brawl commander on replace-all when the list has no commander, then
  validates final merged cards before deleting/reinserting `deck_cards`.
- Flutter import-to-existing refreshes deck details and keeps review details
  visible for warnings, missing commander, preserved commander, localized
  matches, or not-found lines.
- Import is ingress/draft evidence, never Lorehold strategy proof.

Additional required adjustments:

275. Do not run live import write routes during read-only Lorehold audits.
276. Keep full non-live `/import/to-deck` handler coverage open; current
     non-live proof is helper/source/widget focused.
277. Treat `/import/validate` as preview-only.
278. Treat successful import-to-existing with review details as draft-only in
     chat "Ajustar deck" until fresh fetch, strict validation, and
     learned/reference package review pass.
279. Preserve import lookup identity behavior: `preferredFormat`, `oracle_id`,
     localized names, and split/DFC aliases.

## Deck Cards Bulk Mutation Recheck

Safe evidence collected:

- `cd server && dart analyze lib/deck_cards_bulk_support.dart 'routes/decks/[id]/cards/bulk/index.dart' test/deck_cards_bulk_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_cards_bulk_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `9/9` tests passed.
- `cd app && flutter test test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: `57/57` tests passed.
- No live route call, PostgreSQL write, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/decks/:id/cards/bulk` is owner-scoped, rejects commanders, rejects
  unsupported sections, merges increments into current `deck_cards`, preserves
  existing `condition`, defaults new-row condition to `NM`, and validates the
  merged list with `DeckRulesService(... strict:false)` before delete/reinsert.
- The app complete-mode optimize path uses bulk only for detailed additions and
  refreshes deck details after successful bulk apply.
- The previous condition-loss divergence is closed in current source/tests.
- Bulk remains additive persistence evidence, not Lorehold strategy evidence.
  Any chat "Ajustar deck" path using it still needs strict validation and
  strategy/package review afterward.

Additional required adjustments:

280. Keep previous bulk condition-preservation item closed unless source stops
     carrying `deck_cards.condition`.
281. Treat `/cards/bulk` as additive persistence only; never use it by itself as
     proof that deck `6` or any other deck is strategically coherent.
282. Keep true handler-level non-live bulk coverage optional/open if future
     audit standards require fake-DB route execution evidence.
283. Guard complete-mode optimize apply if future complete previews include
     removals or full-rebuild semantics; those payloads must not be reduced to
     bulk add.

## Manual Set/Replace Mutation Contract Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/cards/set/index.dart' 'routes/decks/[id]/cards/replace/index.dart' test/deck_manual_mutation_route_contract_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_manual_mutation_route_contract_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `14/14` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart`
  - result: `33/33` tests passed.
- Live `server/test/decks_incremental_add_test.dart` was inspected but not run
  because it is tagged `live`, `live_backend`, and `live_db_write`.
- No live route call, PostgreSQL write, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/cards/set` is absolute-quantity mutation. With `replace_same_name=true`, it
  consolidates by case-insensitive `cards.name`, preserves commander-slot
  semantics, and documents response fields including `condition` and
  `replace_same_name`.
- `/cards/replace` is same-name-only edition swap. It does not use
  `oracle_id`/`physicalCopyKey`, validates the resulting deck with
  `DeckRulesService(... strict:false)`, and returns only replacement status/id
  fields rather than a full card object.
- API contracts and source-contract tests now protect these response shapes and
  identity boundaries.
- Manual mutation remains persistence evidence only. It still needs strict
  validation and strategy/package review before a chat flow can call a deck
  coherent.

Additional required adjustments:

284. Treat previous manual mutation response-shape items as closed at
     source-contract/API guard level.
285. Treat same-name-only edition replacement as the documented current
     contract, not a hidden bug.
286. Keep true handler-level non-live set/replace execution coverage optional
     open if future audits require fake-DB route execution proof.
287. For chat "Ajustar deck", require fresh detail fetch, strict validation,
     and strategy/package review after any set/replace mutation.
288. If canonical identity replacement is wanted later, create a new explicit
     tested route/contract instead of broadening current same-name behavior.

## Pricing, Export, And Community Contract Recheck

Safe evidence collected:

- `cd server && dart analyze 'routes/decks/[id]/pricing/index.dart' 'routes/decks/[id]/export/index.dart' 'routes/community/decks/[id].dart' test/deck_pricing_export_community_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `6/6` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/community/providers/community_provider_test.dart test/features/community/providers/social_provider_test.dart`
  - result: `43/43` tests passed.
- `cd server && dart test test/deck_pricing_export_community_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: originally failed because overbroad source-string assertions matched
    internal implementation names. Current revalidation now passes `9/9` after
    those assertions were narrowed in the worktree.
- `cd server && dart analyze 'routes/decks/[id]/pricing/index.dart' 'routes/decks/[id]/export/index.dart' 'routes/community/decks/[id].dart' test/deck_pricing_export_community_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found on current revalidation.
- No live route call, PostgreSQL write, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/decks/:id/pricing` is write-capable even with `force:false`: it updates the
  deck pricing snapshot and may update card prices before returning
  `estimated_total_usd`, `missing_price_cards`, and `items`.
- `/decks/:id/export` returns presentation text and exported-line `card_count`,
  not total quantity and not `deck_id`.
- `/community/decks/:id` copy returns `{success:true, deck}` and copies only
  basic card fields (`card_id`, `quantity`, `is_commander`), not condition,
  pricing, analysis, or strict-validation proof.
- API contracts and the focused source-contract test are aligned for these
  rows in the current worktree.

Additional required adjustments:

289. Treat pricing response-field and write-side-effect documentation as closed
     at API-contract/source-read level.
290. Treat export `card_count` semantics as closed at API-contract/source-read
     level.
291. Treat community copy response shape as closed at API-contract/source-read
     level.
292. Treat the focused pricing/export/community test item as closed in the
     current worktree: `deck_pricing_export_community_contract_test.dart` now
     passes with `api_contracts_data_map_guard_test.dart`.
293. For chat "Ajustar deck", never use pricing/export/community presentation
     stats as strategy proof; require fresh details, strict validation, and
     package review for copied/exported/imported decks.

## Battle Learned-Opponent Provenance Closure Recheck

Safe evidence collected:

- `jq` read of
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_002832/summary.json`
  confirmed `battle_replay_final_status=blocked`,
  `mandatory_gate_divergences=["forensic_audit=blocked"]`,
  `learned_deck_source_lookup_status=loaded`,
  `learned_deck_source_lookup_rows=120`,
  `learned_opponent_source_counts={"pg_meta_decks":48}`,
  `opponent_deck_provenance.learned_opponent_appearance_count=48`,
  `opponent_deck_provenance.learned_opponent_unique_count=12`,
  `opponent_deck_provenance.source_url_missing_count=0`, and `12`
  `learned_deck_opponents`.
- `jq -e` structured assertion against the same summary passed for `12`
  learned opponents, `48` appearances, `source_url_missing_count=0`, and every
  row carrying present `pg:meta_decks:*` source URLs.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_decision_strategy_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
  - result: PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_decision_strategy_auditor.py`
  - result: `19/19` checks printed PASS.
- `bash -n /Users/desenvolvimentomobile/.manaloom-agents/bin/manaloom-battle-strategy-audit.sh`
  - result: PASS.
- No live route call, PostgreSQL write, deck `6` mutation, swap, recurring
  battle run, code edit, commit, or push was performed.

Current learning:

- `BV-075` is closed as a source-deck provenance gap. The principal battle
  `summary.json` now publishes learned-opponent aggregate rows, source counts,
  explicit construction/coherence waivers, and stable PG meta-deck identity via
  `source_url=pg:meta_decks:<uuid>`.
- This does not make the battle replay trusted for strategy learning. The same
  artifact remains blocked by `forensic_audit=blocked`, so `BV-067` stays active
  for `Aura of Silence` forensic lineage/waiver work.
- For deck builder and chat "Ajustar deck", battle learned-opponent provenance
  is now interpretable, but battle replay output remains advisory until the
  forensic gate is clean or explicitly waived/tested.

Additional required adjustments:

294. Remove `BV-075` from active battle/deck-builder pending work.
295. Keep `BV-067` active as the current latest battle replay blocker.
296. Do not use `20260620_002832` battle replay results as Lorehold deck `6`
     strategy proof while `battle_replay_final_status=blocked`.

## Aura Of Silence Focused Forensic Blocker Closure Recheck

Safe evidence collected:

- This section supersedes item `295` above, which was based on artifact
  `20260620_002832` before the focused `20260620_003647` rerun existed.
- Read
  `docs/hermes-analysis/master_optimizer_reports/battle_latest_003647_aura_of_silence_forensic_blocker_closure_20260619_213732.md`.
- `jq` read of
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_003647/summary.json`
  confirmed `seeds_completed=1`, `start_seed=63210031`,
  `battle_replay_final_status=trusted_for_strategy_learning`,
  `mandatory_gate_divergences=[]`, `forensic_rule_findings=0`,
  `forensic_turn_findings=0`, zero unaccepted card-id/semantic-hash/logical-key
  gaps, `test_results_total=16`, `test_results_status_counts={"pass":16}`,
  and `test_result_failures=[]`.
- `rg` over `seed_63210031/replay.events.jsonl` confirmed the `Aura of Silence`
  cast/resolution events now use `rule_source=manual_runtime_waiver`,
  `rule_review_status=verified`, `rule_confidence=1.0`, stable `card_id`,
  stable `semantic_hash`, stable `rule_logical_key`,
  `effect=remove_permanent`, and `target_type=artifact_or_enchantment`.
- Current `battle_analyst_v9.py` includes `Aura of Silence` in the handcrafted
  runtime rules, `MANUAL_RULE_RUNTIME_WAIVERS`, and waiver metadata.
- Current `test_battle_forensic_audit_supported_effects.py` includes
  `test_aura_of_silence_manual_runtime_waiver_has_identity_for_forensic`.
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
  - result: PASS.
- `python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_forensic_audit_supported_effects.py`
  - result: `13/13` checks printed PASS.
- `jq -e` structured assertion against the focused `summary.json`
  - result: PASS.
- Python event assertion over `seed_63210031/replay.events.jsonl`
  - result: PASS for the two `Aura of Silence` events and required lineage
    fields.
- No live route call, PostgreSQL write, deck `6` mutation, swap, recurring
  multi-seed battle run, code edit by this executor, commit, or push was
  performed.

Current learning:

- `BV-067` is closed for the reproduced `Aura of Silence` blocker. Seed
  `63210031` no longer resolves that card through `functional_tags_json`, and
  the focused forensic gate is clean.
- This is not full-fleet battle proof. The closure artifact used
  `--seeds 1 --start-seed 63210031`; deck-builder strategy decisions still need
  a clean full/current battle gate or equivalent multi-seed evidence before
  using battle replay as strong Lorehold deck `6` strategy evidence.
- The current implementation relies on a temporary manual runtime waiver, so
  the remaining durable adjustment is canonical battle-rule promotion or another
  backend-owned reviewed-rule path.

Additional required adjustments:

297. Remove `BV-067` from active reproduced-blocker pending work.
298. Keep battle replay output advisory for chat "Ajustar deck" until a
     full/current battle gate or equivalent multi-seed evidence is clean.
299. Track `Aura of Silence` manual runtime waiver as temporary battle-engine
     data debt until promoted to canonical reviewed rule data.

## Saved Deck Fetch And Hydration Closure Revalidation

Safe evidence collected:

- Re-read current saved-deck contract evidence in
  `server/test/deck_fetch_hydration_contract_test.dart`,
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`,
  `server/test/api_contracts_data_map_guard_test.dart`,
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart`, and
  `app/test/features/decks/providers/deck_provider_support_test.dart`.
- `server/test/deck_fetch_hydration_contract_test.dart` guards:
  - `GET /decks` returning the legacy raw JSON array with owner scoping,
    `card_count`, and presentation `color_identity`;
  - `GET /decks/:id` returning root-level fields, `stats.total_cards`,
    `unique_cards`, mana curve/color distribution, `commander`, `main_board`,
    and `all_cards_flat`;
  - saved-detail card rows exposing display fields such as `condition`,
    `collector_number`, `foil`, `color_identity`, and set metadata while not
    exposing `oracle_id`, `layout`, `card_faces`, or `scryfall_id`.
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md` and
  `server/test/api_contracts_data_map_guard_test.dart` document/guard that list
  and detail `color_identity` are presentation metadata, saved-detail identity
  fields remain backend-owned, and background detail hydration records non-200
  responses as failed enrichment.
- `fetchMissingDeckColorIdentities(...)` now appends a deck id to
  `failedDeckIds` when `fetchDeckDetailsRequest(...)` returns a non-200 state,
  and the provider test covers `deck-2` returning HTTP `500`.
- `cd server && dart analyze routes/decks/index.dart 'routes/decks/[id]/index.dart' test/deck_fetch_hydration_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_fetch_hydration_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `9/9` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider_support_fetch.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_support_test.dart -r expanded`
  - result: `33/33` tests passed.
- No live `GET /decks`, live deck `6` fetch, PostgreSQL write, deck `6`
  mutation, swap, code edit by this executor, commit, or push was performed.

Current learning:

- Saved-deck fetch/hydration is closed at source-contract/API-doc/provider-test
  level in the current worktree.
- It remains a read model only. It proves current persisted card-list and
  display/aggregate hydration shape, not Lorehold strategy coherence,
  commander legality, or readiness after mutation.
- For chat "Ajustar deck", saved-deck fetch is still mandatory after mutation,
  import, optimize apply, or community copy, but it must be followed by strict
  validation and learned/reference package review before calling the deck
  coherent.

Additional required adjustments:

300. Treat saved-deck fetch/hydration follow-up as closed at source-contract and
     provider-test level.
301. Keep saved-detail `oracle_id`/layout/card-face exposure as a future explicit
     API contract decision, not an assumed current field.
302. Continue treating list/detail `color_identity` and mana/color aggregates as
     presentation metadata, not commander legal identity or strategy proof.

## PG Oracle And Lorehold Deck 6 Recheck

Safe evidence collected:

- `python3 server/bin/learned_deck_coherence_audit.py --hermes-deck-id 6 --stdout`
  - result: checked `60` active learned decks; current summary still reports
    `metadata_total_lands_mismatch=58`, `metadata_zero_lands=54`,
    `off_color_cards=5`, `partner_identity_not_modeled=9`, high issues `173`,
    medium issues `21`.
- `python3 server/bin/learned_deck_coherence_audit.py --hermes-deck-id 6`
  - result: generated
    `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.json`
    and
    `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_005400.md`.
- Direct aggregated PostgreSQL `SELECT` via `db_helper.connect()` and `server/.env`
  reported:
  - `card_intelligence_snapshot.total_cards=34329`
  - `oracle_structured_cards=33966`
  - `missing_oracle_id=4`
  - `missing_oracle_text=360`
  - `missing_type_line=1`
  - all `deck_cards` rows have `card_identity_bridge` and
    `card_intelligence_snapshot` rows;
  - `deck_cards` rows missing `oracle_id=22`, missing `oracle_text=34`, missing
    `type_line=0`, and strict oracle-structured rows `50785` out of `50841`.
- Linked PG deck `528c877f-f829-4207-95e6-73981776c323` for Hermes deck `6`
  reported `100` rows / `100` quantity, commander quantity `1`, land quantity
  `33`, missing identity/snapshot/oracle/type-line rows `0`, off-color rows `0`,
  and strict oracle-structured rows `100`.
- No full decklist, full oracle text, secret, token, PostgreSQL write, route
  write, deck mutation, swap, commit, or push was performed.

Current learning:

- Lorehold deck `6` is clean at the materialized PG saved-deck oracle/identity
  level: all `100` cards resolve through `card_identity_bridge`,
  `card_intelligence_snapshot`, `oracle_id`, `oracle_text`, and `type_line`.
- The active Lorehold learned row `learned_deck:82` still has exactly one
  focused metadata divergence: cached `metadata.total_lands=30` versus resolved
  `33`.
- Strategy package coverage remains positive in the current audit: commander
  identity `1/1`, copy combo core `7/4`, topdeck/miracle setup `5/3`,
  graveyard/spell value `5/4`, big spell finishers `7/4`,
  protection/stack control `10/6`, mana acceleration `14/10`.
- The broader PostgreSQL card catalog is not fully oracle-clean. There are `363`
  base cards outside the strict structured predicate and `56` affected
  `deck_cards` rows, even though identity bridge/snapshot coverage is complete.

Additional required adjustments:

303. Keep Lorehold deck `6` card-list/oracle status marked clean at current
     read-only evidence level.
304. Keep the active learned-deck metadata canonicalization task open: only with
     explicit DB-write approval, change Lorehold learned deck `82` cached
     `total_lands` from `30` to resolved `33`.
305. Keep broader strict-oracle backlog open for the `363` base-card gaps and
     `56` impacted `deck_cards` rows; do not conflate that global backlog with
     the clean materialized Lorehold deck `6` list.

## Commander-Learning Role Summary Revalidation

Safe evidence collected:

- Re-read `server/routes/ai/commander-learning/index.dart`,
  `server/lib/ai/commander_learned_deck_support.dart`,
  `server/test/commander_learned_deck_support_test.dart`,
  `server/doc/COMMANDER_LEARNING_API_2026-06-03.md`, and
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- `cd server && dart analyze routes/ai/commander-learning/index.dart lib/ai/commander_learned_deck_support.dart lib/ai/commander_reference_helpers.dart test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `29/29` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/ai/commander-learning` list mode remains a safe availability summary with
  `source = pg_commander_learned_deck_summary`; it does not expose
  `role_summary`, `win_conditions`, decklists, cards, or raw `metadata`.
- `/ai/commander-learning?commander=...` detail mode still calls
  `canonicalizeCommanderLearnedDeckMetadata(pool, learnedDeck)` before building
  both `promoted_deck.role_summary` and `recommended_deck.role_summary`.
- The normal-path detail `role_summary` is coherent with the current Lorehold
  evidence because the canonicalizer uses `card_identity_bridge`,
  `card_function_tags`, land detection from resolved `type_line`, deterministic
  Lorehold role overrides, and additive multi-role counts.
- The remaining risk is unchanged: if canonicalization throws, the helper
  returns `input.metadata`, so stale learned-deck metadata can still be shown
  silently in detail mode.

Additional required adjustments:

306. Keep the list/detail `/ai/commander-learning` contract closed under current
     static tests.
307. Keep Lorehold learned deck `82` metadata backfill pending until explicit DB
     mutation approval.
308. Add fallback observability/coverage for
     `canonicalizeCommanderLearnedDeckMetadata(...)` before calling detail-mode
     `role_summary` fully robust.

## Create And Full-Persist Name Resolution Revalidation

Safe evidence collected:

- Re-read app create/full-persist code, `DeckGenerateScreen`, backend
  `POST /decks` and `PUT /decks/:id`, `/cards/resolve/batch`, card resolution
  support, provider/screen tests, and API contract guards.
- `cd server && dart analyze routes/cards/resolve/batch/index.dart routes/decks/index.dart 'routes/decks/[id]/index.dart' lib/card_resolution_support.dart test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart test/commander_learned_deck_support_test.dart`
  - result: no issues found.
- `cd server && dart test test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart test/commander_learned_deck_support_test.dart -r expanded`
  - result: `30/30` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/screens/deck_generate_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart -r expanded`
  - result: `70/70` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- App `createDeck(...)` now normalizes incoming cards before `POST /decks`:
  direct `card_id` entries are preserved and name-only entries must resolve via
  `/cards/resolve/batch`; unresolved or ambiguous names fail before create.
- Learned-deck save tests currently prove the expected `POST /decks` payload is
  card-id based when resolver data is available: 1 commander plus 99 main cards.
- Backend create/update still support name fallback. `POST /decks` resolves
  names against `cards.name` ordered by format legality; `PUT /decks/:id`
  resolves names by exact case-insensitive `cards.name` with `LIMIT 1`.
- `/cards/resolve/batch` uses direct `cards` substring matching and
  `resolveCardCandidateNames(...)`, not `card_identity_bridge`. This is weaker
  than learned-deck/import identity resolution for localized, alias, and
  split-face cases.
- App create helpers still do not carry `archetype` or `bracket` into
  `POST /decks`, although backend create can persist those fields if supplied.

Additional required adjustments:

309. Treat app create name normalization as source/test-proven, but keep backend
     name fallback policy open until `/cards/resolve/batch` and write-route
     fallbacks share `card_identity_bridge` or the API formally requires
     `card_id`-only payloads for full writes.
310. Keep `archetype`/`bracket` preservation on app create open if generated or
     learned deck previews should seed strategy metadata at deck creation time.
311. For chat "Ajustar deck", never treat a successful `POST /decks` as final
     strategy proof; require resolved `card_id` payload, fresh detail fetch,
     strict validation, and package review.

## Optimize Signature Printing Metadata Revalidation

Safe evidence collected:

- Re-read app deck-card models, optimize signature/apply code, optimize preview
  flow support, server optimize cache/signature support, swap-integrity support,
  `/decks/:id` detail hydration, `/decks/:id/cards/replace`, and
  `/cards/printings`.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/widgets/deck_optimize_flow_support.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
  - result: no issues found.
- `cd server && dart analyze lib/ai/optimize_cache_support.dart lib/ai/optimize_request_support.dart lib/ai/optimize_swap_integrity.dart routes/ai/optimize/index.dart 'routes/decks/[id]/cards/replace/index.dart' 'routes/decks/[id]/index.dart' routes/cards/printings/index.dart test/optimize_cache_support_test.dart test/api_contracts_data_map_guard_test.dart test/deck_manual_mutation_route_contract_test.dart test/deck_fetch_hydration_contract_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart -r expanded`
  - result: `89/89` tests passed.
- `cd server && dart test test/optimize_cache_support_test.dart test/api_contracts_data_map_guard_test.dart test/deck_manual_mutation_route_contract_test.dart test/deck_fetch_hydration_contract_test.dart -r expanded`
  - result: `16/16` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- Saved deck printing identity is the persisted `deck_cards.card_id`, not a
  separate deck-owned set/collector field.
- `/cards/printings` exposes printing options from `cards`, including the
  selected row `id`, `set_code`, `collector_number`, and `foil`; choosing a
  different edition means choosing a different `card_id`.
- `/decks/:id/cards/replace` enforces same-name replacement and updates
  `deck_cards.card_id`, so any edition swap changes the optimize signature
  through the existing `card_id:quantity:condition` entry.
- Deck detail hydration exposes `dc.condition` as deck-owned physical state and
  `c.set_code`, `c.collector_number`, `c.foil`, set name, and release date as
  card-row display metadata.
- Server optimize and app apply now agree on the state boundary: card id,
  quantity, and condition. Tests prove condition-only drift is rejected before
  app PUT, and server cache/signature normalizes missing condition to `NM`.
- Binder has per-item `is_foil`, but the audited deck routes do not currently
  persist deck-owned foil/finish/language fields.

Additional required adjustments:

312. Close the stale-signature printing metadata question for the current deck
     model: do not add `set_code`, `collector_number`, `foil`, rarity, set name,
     or release date to optimize signatures unless those become deck-owned
     physical fields rather than card-row display fields.
313. If saved decks later support per-copy foil/finish/language, first add and
     preserve those fields through deck mutations/fetch, then expand the optimize
     signature beyond `card_id:quantity:condition`.
314. Keep backend create/update and `/cards/resolve/batch` identity policy open
     until they share `card_identity_bridge` or formally require `card_id`-only
     write payloads.
315. Keep app create `archetype`/`bracket` persistence open only if generated or
     learned deck previews should seed those strategy fields at creation time.

## Deck Write Name Resolution Bridge Revalidation

Safe evidence collected:

- Re-read `server/lib/deck_card_name_resolution_support.dart`,
  `server/lib/card_resolution_support.dart`, `/cards/resolve/batch`, backend
  `POST /decks`, backend full `PUT /decks/:id`, app `createDeck(...)`,
  `normalizeCreateDeckCards(...)`, `createDeckRequest(...)`, and matching tests
  and API-contract guards.
- `cd server && dart analyze lib/deck_card_name_resolution_support.dart lib/card_resolution_support.dart routes/cards/resolve/batch/index.dart routes/decks/index.dart 'routes/decks/[id]/index.dart' test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/providers/deck_provider_support_mutation.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart`
  - result: no issues found.
- `cd server && dart test test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `14/14` tests passed.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart -r expanded`
  - result: `65/65` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- The current worktree already has a shared deck-card name resolver. It tries
  `card_identity_bridge` first and supports canonical/localized lookup names,
  canonical names, split-face halves, preferred-format legality ranking, and
  bridge priority.
- `/cards/resolve/batch`, backend create, and backend full update now all route
  through that shared resolver. The old direct `cards.name` write-route fallback
  note is stale for the current source state.
- `cards_fallback` remains only as an older-database compatibility path when the
  bridge view is missing or undefined. It is not a silent fallback for a present
  but incomplete bridge; bridge incompleteness should be repaired in data.
- App create still pre-resolves name-only cards through `/cards/resolve/batch`
  and fails unresolved/ambiguous names before `POST /decks`.
- App create still does not pass `archetype` or `bracket` at creation time; the
  app has a separate `updateDeckStrategyRequest(...)` path after deck creation.

Additional required adjustments:

316. Close the active name-resolution divergence for create/update/batch under
     current source/test state.
317. Keep bridge freshness/backfill as the right adjustment if a migrated DB has
     missing aliases or stale `card_identity_bridge` rows; do not bypass it with
     raw `cards` matching.
318. Keep app-create `archetype`/`bracket` persistence open if generated/learned
     deck previews should seed strategy metadata at `POST /decks` time.
319. For chat "Ajustar deck", treat a create/save as identity-safe only after
     bridge-backed resolution, fresh detail fetch, strict validation, and
     Lorehold/general package review.

## App Create Strategy Metadata Revalidation

Safe evidence collected:

- Re-read `DeckProvider.createDeck(...)`, `createDeckRequest(...)`,
  `DeckGenerateScreen` generated/learned save helpers, backend `POST /decks`,
  and matching app/server tests.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/providers/deck_provider_support_mutation.dart lib/features/decks/screens/deck_generate_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
  - result: no issues found.
- `cd server && dart analyze routes/decks/index.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart -r expanded`
  - result: `69/69` tests passed.
- `cd server && dart test test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `6/6` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- The current app create path now carries strategy metadata. `createDeck(...)`
  accepts optional `archetype` and `bracket`, `createDeckRequest(...)` trims and
  posts them to `/decks`, and backend create can persist both fields when deck
  metadata columns exist.
- Generated deck save extracts `archetype` and `bracket` from root,
  `generated_deck`, diagnostics `recommended_deck`, and diagnostics
  `promoted_deck`.
- Learned-deck loading stores `recommended_deck` and `promoted_deck` in
  diagnostics before save, so learned previews can seed create-time strategy
  metadata when those fields are present.
- Tests prove both direct provider create and learned-deck screen save carry
  `archetype`/`bracket` in the `/decks` body.
- This closes adjustment 318 for current source/test state. It does not prove
  Lorehold coherence by itself; metadata persistence remains separate from
  package validation and strategy review.

Additional required adjustments:

320. Close app-create `archetype`/`bracket` persistence under current
     source/test state.
321. Keep generated/learned create proof bounded to metadata persistence, not
     strategy coherence.
322. Keep future route tests/signature expansion only conditional on new
     write-shape semantics or new deck-owned physical fields.

## Simulate Matchup Advisory Boundary Revalidation

Safe evidence collected:

- Re-read `server/routes/ai/simulate-matchup/index.dart`,
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`,
  `server/test/experimental_deck_ai_authorization_source_test.dart`, and
  `server/test/api_contracts_data_map_guard_test.dart`.
- `cd server && dart analyze routes/ai/simulate-matchup/index.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `17/17` tests passed.
- No live route call, PostgreSQL write, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- `/ai/simulate-matchup` is improved for saved/public decks: it prefers
  `card_intelligence_snapshot`, falls back to per-card aggregated
  `card_function_tags` and `card_semantic_tags_v2`, uses
  `resolveCardFunctionalRoles(...)`, and exposes commander-vs-observed color
  identity provenance.
- It remains a write route because `_analyzeMatchup(...)` reads and then
  attempts to upsert `deck_matchups`.
- Meta-deck opponents remain sparse. The meta path reads `meta_decks` and parses
  effective card count, but it does not hydrate canonical roles/stats like a
  saved/public deck opponent.
- Counterspell counting is partly canonical but still has a limited
  `counter target` oracle-text fallback.
- The current API contract and source guards preserve these caveats, so item 7
  should remain active as guidance rather than being closed as a deck-builder
  proof.

Additional required adjustments:

323. Keep `/ai/simulate-matchup` advisory-only for chat "Ajustar deck"; never
     use it as standalone Lorehold or general deck-construction proof.
324. Require fresh deck fetch, strict validation, learned/reference package
     review, and strategy package review before acting on matchup output.
325. If the product wants this endpoint to become a stronger deck-builder gate,
     first split out a non-writing fixture-safe analysis path and hydrate
     meta-deck opponents with canonical role/stats payloads.

## Lorehold Learned Metadata Dry-Run Revalidation

Safe evidence collected:

- Re-read `server/bin/canonicalize_learned_deck_metadata.dart` and confirmed
  PostgreSQL mutation is gated behind `--apply`.
- `cd server && dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --source-ref=learned_deck:82 --include-unchanged`
  - result: `status=PASS`, `mode=dry_run`, `db_mutations=false`
  - checked/reported: `1/1`
  - changed/applied: `1/0`
  - row id: `f46c0421-71b4-4de3-bb79-05a916b4988b`
  - commander: `Lorehold, the Historian`
  - card count / parsed card count: `100/100`
  - before: `total_lands=30`, `ramp_count=17`, `draw_count=16`,
    `engine_count=33`, `protection_count=8`
  - after: `total_lands=33`, `ramp_count=20`, `draw_count=18`,
    `engine_count=36`, `protection_count=13`
- `cd server && dart analyze bin/canonicalize_learned_deck_metadata.dart lib/ai/commander_learned_deck_support.dart test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `25/25` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- Lorehold `learned_deck:82` still has stale persisted metadata. The current
  canonicalizer would correct `total_lands` from `30` to resolved `33` and also
  increase ramp/draw/engine/protection counts, but dry-run correctly applies
  nothing.
- This confirms the problem is persisted cache/backfill state, not the current
  learned deck card list or the canonicalizer's ability to resolve it.
- Until approved backfill runs, chat "Ajustar deck" must treat direct
  `commander_learned_decks.metadata` reads as stale cache for Lorehold and use
  read-time canonicalized route output or fresh audit/dry-run evidence instead.

Additional required adjustments:

326. Keep Lorehold metadata canonicalization active until explicit PostgreSQL
     mutation approval allows `--apply --source-ref=learned_deck:82`.
327. After any approved apply, rerun dry-run or learned-deck coherence audit and
     only close the item when persisted `total_lands` equals resolved `33`.
328. For chat "Ajustar deck", never use direct persisted
     `commander_learned_decks.metadata.total_lands=30` as deck-construction
     truth.

## Lorehold Role Backfill Gap Revalidation

Safe evidence collected:

- Re-read `server/lib/ai/commander_learned_deck_support.dart`,
  `server/test/commander_learned_deck_support_test.dart`, and
  `server/test/api_contracts_data_map_guard_test.dart`.
- Ran a read-only PostgreSQL query over `card_identity_bridge`, `cards`,
  `card_function_tags`, `card_semantic_tags_v2`, and
  `commander_card_synergy` for `Orim's Chant`, `Ruby Medallion`,
  `Scroll Rack`, and `Victory Chimes`.
- `cd server && dart analyze lib/ai/commander_learned_deck_support.dart test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `25/25` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- The focused Lorehold runtime gap is covered in learned-deck summaries by
  deterministic role-tag overrides for `Orim's Chant`, `Ruby Medallion`,
  `Scroll Rack`, and `Victory Chimes`.
- The PostgreSQL rows are still missing durable card intelligence: all four
  cards resolve through `card_identity_bridge`, but still show
  `function_tags=[]`, `semantic_v2_rows=0`, and
  `lorehold_synergy_rows=0`.
- This means runtime `role_summary_source=card_list_canonicalized` is safe as
  current product evidence, while direct PG role/synergy table reads remain
  incomplete until backfill.

Additional required adjustments:

329. Keep item 2 active until approved PostgreSQL backfill creates functional
     tags, semantic v2 rows, and Lorehold commander-synergy rows for the focused
     gap cards.
330. In chat "Ajustar deck", use canonicalized learned-deck role summary for
     these four cards; do not treat empty PG role/synergy rows as proof the
     cards lack Lorehold function.
331. After any approved backfill, rerun the read-only PG gap query and
     commander learned-deck tests before closing item 2.

## Learned-Deck Identity Resolution Revalidation

Safe evidence collected:

- Ran `python3 server/bin/learned_deck_coherence_audit.py --stdout`.
  - result: `active_learned_decks=60`, `off_color_cards=5`,
    `partner_identity_not_modeled=9`, `metadata_total_lands_mismatch=58`,
    `metadata_zero_lands=54`, `high=173`, `medium=21`.
- Imported `server/bin/learned_deck_coherence_audit.py` safely and called
  `build_payload(...)` without writing artifacts.
  - result: `off_color_resolution_plan.status=ready_for_review`,
    `db_mutations=false`, `apply_requires_explicit_approval=true`,
    `entry_count=5`.
- Ran read-only PostgreSQL checks against `commander_learned_decks`,
  `card_identity_bridge`, and `card_intelligence_snapshot`.
- Ran `python3 -m unittest server/test/learned_deck_coherence_audit_test.py`.
  - result: `14` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- Lorehold `learned_deck:82` is not part of the current off-color identity
  blocker: its audit state remains `off_color_candidates=[]`, commander
  identity `R,W`, and the only active issue is stale lands metadata
  `expected=33 actual=30`.
- The fleet blocker is real for five active learned-deck plan entries:
  `learned_deck:126` and `learned_deck:114` resolve raw `Vendetta` as
  `Vengeance/W`; `learned_deck:3` and `learned_deck:131` resolve raw
  `Endurance` as `Endure/W`; `learned_deck:116` needs persisted combined
  commander identity for `K-9, Mark I + The Fourteenth Doctor`.
- Direct PG evidence shows `card_identity_bridge` has both correct and wrong
  alias rows for `Vendetta` and `Endurance`. The effective audit lookup chooses
  the wrong identities because `load_card_lookup(...)` reads the bridge without
  deterministic precedence and keeps the first normalized alias with
  `lookup.setdefault(...)`.
- Therefore the correct adjustment is not simply "add a missing row". It is
  either bridge/view/source-data de-duplication or a resolver precedence rule
  that prefers exact canonical-name matches over fuzzy/same-alias candidates.

Additional required adjustments:

332. Keep item 3 active until the duplicate alias/preference problem is fixed
     and the learned-deck coherence audit reports no false `Vendetta` or
     `Endurance` off-color entries.
333. Do not mutate Lorehold deck 6 for this item; it is not affected by the
     `Vendetta`/`Endurance` or K-9 combined-identity findings.
334. If fixing in data, require explicit PostgreSQL mutation approval and rerun
     the read-only bridge lookup plus `learned_deck_coherence_audit.py`.
335. If fixing in code/view logic instead, add tests proving exact
     `Vendetta/B` and `Endurance/G` precedence before closing the item.

## PostgreSQL Oracle Structure Revalidation

Safe evidence collected:

- Ran direct read-only PostgreSQL counts over `cards` and
  `card_intelligence_snapshot`.
  - result for both sources: `34,329` total rows, `33,966` strict
    oracle-structured rows, `98.9426%` structured rate, `4` missing
    `oracle_id`, `360` missing `oracle_text`, `1` missing `type_line`, and
    `363` outside the strict predicate.
- Ran direct read-only `deck_cards` counts using `card_intelligence_snapshot`
  plus `EXISTS` for `card_identity_bridge`.
  - result: `50,841` deck rows / `79,145` quantity; `0/0` missing identity
    bridge; `0/0` missing intelligence snapshot; `22/22` missing `oracle_id`;
    `34/34` missing `oracle_text`; `0/0` missing `type_line`;
    `50,785/79,089` strict oracle-structured rows/quantity.
- Ran direct read-only PG control query for linked Lorehold PG deck
  `528c877f-f829-4207-95e6-73981776c323`.
  - result: `100` rows, `100` quantity, commander quantity `1`, land quantity
    `33`, and `100/100` strict oracle-structured rows.
- Ran `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall`.
  - result: `status=PASS`, `db_mutations=false`, `active_learned_gap_items=0`,
    `deck_card_gap_items=6`, `planned_items=6`, `backfill_ready=0`.
- Ran `python3 server/bin/plan_oracle_text_backfill.py --limit=6 --delay-ms=75 --timeout-seconds=20`.
  - result: `status=PASS`, `db_mutations=false`, `scryfall_found=4`,
    `backfill_ready=0`.
- Ran `python3 server/bin/learned_deck_coherence_audit.py --stdout`.
  - result: no active learned-deck oracle-text issue; remaining active counts
    are metadata/identity: `metadata_total_lands_mismatch=58`,
    `metadata_zero_lands=54`, `off_color_cards=5`,
    `partner_identity_not_modeled=9`.
- Ran `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`.
  - result: `17` tests passed.
- Ran `python3 -m py_compile server/bin/learned_deck_coherence_audit.py server/bin/plan_oracle_text_backfill.py server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`.
  - result: passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  commit, or push was performed.

Current learning:

- The global PostgreSQL catalog is mostly oracle-structured but not fully clean:
  `363` base cards fail the strict `oracle_id + oracle_text + type_line`
  predicate.
- Persisted deck impact is narrow: `56` deck rows across 6 names:
  `Isamaru, Hound of Konda`, `A-Alrund's Epiphany`, `Grizzly Bears`,
  `Runeclaw Bear`, `A-Omnath, Locus of Creation`, and `Yargle and Multani`.
- Scryfall exact-name found the four non-`A-` names but with
  `oracle_text_present=false`, so they are not automatic oracle-text backfill
  candidates. The two `A-` names returned exact-name `404` and need separate
  Arena/Alchemy identity modeling.
- Lorehold deck `6` remains clean for this dimension: `100/100` saved PG rows
  are strict oracle-structured, and no decklist adjustment is indicated.
- Query guard learned again: direct `deck_cards -> card_identity_bridge` joins
  can fan out counts because bridge has multiple alias rows. Use
  `card_intelligence_snapshot` plus `EXISTS`/pre-aggregation for deck-card
  counting.

Additional required adjustments:

336. Keep item 4 active until the `363` base-card strict-oracle gaps are either
     backfilled or explicitly modeled as accepted-empty/source-specific cases.
337. Do not change Lorehold deck `6` for global oracle backlog; it is clean at
     the saved PG deck level.
338. Add accepted-empty handling for official no-rules-text cards that appear in
     persisted decks, or document why strict non-empty `oracle_text` should keep
     counting them as data gaps.
339. Model `A-Alrund's Epiphany` and `A-Omnath, Locus of Creation` through the
     Arena/Alchemy identity path instead of exact-name Scryfall backfill.
340. Preserve the no-fanout query pattern for any future deck-card oracle
     reporting: no raw `deck_cards -> card_identity_bridge` count joins without
     pre-aggregation or `EXISTS`.

## Latest Battle Coverage and BV-076 Revalidation

Safe evidence collected:

- Resolved
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/latest`
  to `20260620_014808`, superseding the prior `20260620_004504` trusted
  checkpoint.
- Read current `summary.json`.
  - result: `timestamp_utc=2026-06-20T01:48:08Z`, `seeds_requested=16`,
    `seeds_completed=16`, `start_seed=63210148`,
    `battle_replay_final_status=review_required`,
    `battle_replay_final_status_reason=one_or_more_mandatory_gates_require_review`,
    and `mandatory_gate_divergences=["forensic_audit=review_required"]`.
- Parsed current seed forensic/strategy artifacts.
  - result: one forensic rule finding in seed `63210153` for
    `Machine God's Effigy`, effect `ramp_permanent`, event `spell_cast`, source
    `functional_tags_json`; six low-confidence strategy seeds
    `63210149`, `63210150`, `63210158`, `63210160`, `63210161`,
    `63210162`, all `forced_keep_after_bad_mulligan`.
- Parsed current seed `replay.events.jsonl` rows for `Deflecting Swat` /
  `redirect_removal`.
  - result: 34 rows total; distribution `cast_announced=8`, `cost_paid=8`,
    `spell_cast=8`, `miracle_cast=1`, `spell_resolved=9`; no observed
    `redirect_removal_resolved`, `old_target`, `new_target`, or
    `target_change_applied`.
- Read current `event_contract_static.json` for `redirect_removal_resolved`.
  - result: static contract exists with expected consumer
    `battle_action_critic.py`, but `observed_count=0`.
- Read current `battle_analyst_v9.py` around lines `4761-4832`.
  - result: source branch can emit `redirect_removal_resolved` and write
    `entry["target"] = new_target`, but the latest artifact did not exercise
    that branch.
- Updated
  `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
  active items `5` and `6`, plus the final detailed section.
- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, swap,
  code edit, battle-engine edit, commit, or push was performed.

Current learning:

- Current battle latest is not trusted for strategy learning even though it
  completed 16 seeds and has 16 passing test-result entries. The blocker is a
  real forensic lineage issue: `Machine God's Effigy` still depends on
  heuristic `functional_tags_json`.
- `BV-076` is still open. The engine has code that can model retargeting, but
  current artifacts only prove `Deflecting Swat` can be cast and resolved as a
  `redirect_removal` spell. They do not prove actual target mutation.
- The current coverage backlog remains separate from Lorehold deck construction:
  `unknown_template_backlog_cards=0`, residual effect coverage is accepted, but
  `needs_review_rule_names=1457`, `non_runtime_safe_rule_names=1457`, and
  `global_learning_eligible_seeds=[]` remain active battle/rule-coverage
  signals.
- No Lorehold deck `6` card swap or PostgreSQL data mutation is indicated by
  this recut.

Additional required adjustments:

341. Keep active item `5` open until a targeted regression or natural replay
     observes `redirect_removal_resolved` with old target, new target, legal
     redirect opportunity, and `target_change_applied=True`.
342. Keep active item `6` open and treat current battle latest `20260620_014808`
     as `review_required`, not trusted.
343. Add verified active `card_battle_rules` coverage for `Machine God's
     Effigy` before using current battle runs for global learning.
344. Continue separating coverage queues from Lorehold decklist adjustments:
     the latest battle blocker does not justify deck `6` swaps.
345. Preserve the distinction between static contract readiness and observed
     runtime evidence for `redirect_removal_resolved`.

## Simulate Matchup Advisory Boundary Current Recheck

Safe evidence collected:

- Read current `server/routes/ai/simulate-matchup/index.dart`.
  - result: route still owner-scopes `my_deck_id` with `context.read<String>()`
    and permits opponent decks only when owned by user or public; meta-deck
    opponent fallback is separate.
- Read current saved/public deck role-loading path.
  - result: route prefers `card_intelligence_snapshot`, falls back to
    aggregated `card_function_tags` and `card_semantic_tags_v2` by `card_id`,
    and uses `resolveCardFunctionalRoles(...)` for ramp/removal/counter-style
    counts.
- Read current meta-deck path.
  - result: `_getMetaDeckData(...)` reads `id`, `format`, `archetype`,
    `card_list`, and `placement`, parses effective count, but does not build
    the same canonical stats payload as saved/public deck opponents.
- Read current matchup persistence path.
  - result: `_analyzeMatchup(...)` reads from `deck_matchups` and attempts
    `INSERT ... ON CONFLICT ... DO UPDATE`, so a live call remains a PostgreSQL
    write route.
- Read current response/seed path.
  - result: response remains nested under `simulation` and `stored_matchup`,
    does not expose top-level `win_rate` or `stats`, clamps simulations to
    `1..5000`, and derives a stable seed when no request seed is supplied.
- Read current API contract and source guards.
  - result: contract still labels `/ai/simulate-matchup` as a write route and
    warns not to treat it as authoritative competitive prediction,
    deck-construction proof, or swap input.
- Ran `cd server && dart analyze routes/ai/simulate-matchup/index.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`.
  - result: no issues found.
- Ran `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`.
  - result: `17/17` tests passed.
- Updated
  `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
  active item `7` and added the final current recheck section.
- No live `POST /ai/simulate-matchup`, PostgreSQL write, deck `6` mutation,
  swap, code edit, battle-engine edit, commit, or push was performed.

Current learning:

- `/ai/simulate-matchup` is aligned enough to be supporting context for
  saved/public deck matchups because it now uses canonical role aggregation and
  commander identity when available.
- It is still not a deck-builder proof surface: it writes `deck_matchups`,
  meta-deck opponents are not role-complete, and counterspell counting still
  has a narrow oracle-text fallback.
- For Lorehold deck `6`, no swap or decklist adjustment is justified by this
  route unless a future run is explicitly approved and its findings are
  cross-checked against deck fetch, strict validation, learned/reference
  packages, and strategy constraints.

Additional required adjustments:

346. Keep active item `7` open as advisory-only guidance.
347. Do not call live `/ai/simulate-matchup` in read-only audits because it can
     write `deck_matchups`.
348. If product wants matchup output as a stronger proof surface, create a
     non-writing fixture/dry-run mode or separate read-only analyzer.
349. If meta-deck opponents are used for Lorehold decisions, load canonical
     role/stats payloads for their card lists before comparing ramp/removal,
     counters, curve, or hate-card gaps.
350. Keep matchup recommendations out of swap decisions until they are
     validated by strict deck validation and learned/reference strategy review.

## Learned-Deck Metadata Canonicalizer Current Dry-Run

Safe evidence collected:

- Re-read `server/bin/canonicalize_learned_deck_metadata.dart`.
  - result: default mode is dry-run; `--apply` is the only branch that executes
    `UPDATE commander_learned_decks SET metadata = ...`; output reports
    `db_mutations=false` unless `--apply` is present.
- Ran `cd server && dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --source-ref=learned_deck:82 --include-unchanged`.
  - result: `status=PASS`, `mode=dry_run`, `db_mutations=false`, `checked=1`,
    `reported=1`, `changed=1`, `applied=0`.
  - row id: `f46c0421-71b4-4de3-bb79-05a916b4988b`.
  - source ref: `learned_deck:82`.
  - commander: `Lorehold, the Historian`.
  - card counts: `card_count=100`, `parsed_card_count=100`.
  - before selected metadata: `total_lands=30`, `ramp_count=17`,
    `draw_count=16`, `removal_count=8`, `tutor_count=5`, `engine_count=33`,
    `wincon_count=13`, `protection_count=8`, `recursion_count=4`,
    `board_wipe_count=2`.
  - after selected metadata: `total_lands=33`, `ramp_count=20`,
    `draw_count=18`, `removal_count=8`, `tutor_count=5`, `engine_count=36`,
    `wincon_count=13`, `protection_count=13`, `recursion_count=4`,
    `board_wipe_count=2`.
- Ran `python3 server/bin/learned_deck_coherence_audit.py --stdout`.
  - result: `active_learned_decks=60`,
    `metadata_total_lands_mismatch=58`, `metadata_zero_lands=54`,
    `all_core_metadata_zero=54`, `some_core_metadata_zero=4`,
    `off_color_cards=5`, `partner_identity_not_modeled=9`; the single active
    Hermes source row still has `metadata_total_lands_mismatch=1`.
- Ran `cd server && dart analyze bin/canonicalize_learned_deck_metadata.dart lib/ai/commander_learned_deck_support.dart test/commander_learned_deck_support_test.dart`.
  - result: no issues found.
- Ran `cd server && dart test test/commander_learned_deck_support_test.dart -r expanded`.
  - result: `19/19` tests passed.
- Ran `python3 -m unittest server/test/learned_deck_coherence_audit_test.py`.
  - result: `14` tests passed.
- Updated
  `docs/hermes-analysis/LOREHOLD_DECK6_STRATEGY_COHERENCE_AUDIT_2026-06-19.md`
  active item `1` and added the final current dry-run section.
- No `--apply`, PostgreSQL write, live route call, deck `6` mutation, swap,
  code edit, battle-engine edit, commit, or push was performed.

Current learning:

- Lorehold `learned_deck:82` still has stale persisted metadata, but the
  canonicalizer can deterministically derive the intended selected metadata
  from the existing 100-card list.
- The correction is metadata-only: the dry-run does not indicate a card-list
  change, swap, or deck `6` mutation.
- The fleet-level learned-deck metadata backlog remains broad
  (`metadata_total_lands_mismatch=58`), so closing Lorehold alone requires a
  focused apply plus post-apply verification, not a change to the audit
  threshold.

Additional required adjustments:

351. Keep active item `1` open until explicit PostgreSQL mutation approval
     permits `--apply --source-ref=learned_deck:82`.
352. After any approved apply, rerun the dry-run or
     `learned_deck_coherence_audit.py` and close only if persisted
     `total_lands=33` and Lorehold no longer reports
     `metadata_total_lands_mismatch`.
353. Do not change Lorehold deck `6` composition for this item; the evidence is
     metadata-only over a parsed 100-card list.
354. When presenting Lorehold learned-deck metrics before apply, prefer
     read-time canonicalized route output or dry-run evidence over persisted
     `commander_learned_decks.metadata`.
355. Treat the broader `58` learned-deck metadata mismatches as fleet backfill
     work separate from the focused Lorehold row.

## Lorehold Role Backfill Gap Current Recheck

Safe evidence collected:

- Re-read `server/lib/ai/commander_learned_deck_support.dart`,
  `server/routes/ai/commander-learning/index.dart`,
  `server/test/commander_learned_deck_support_test.dart`, and
  `server/test/api_contracts_data_map_guard_test.dart`.
- Ran a read-only PostgreSQL query using `card_identity_bridge` plus aggregated
  `card_function_tags`, `card_semantic_tags_v2`, and
  `commander_card_synergy` reads for `Orim's Chant`, `Ruby Medallion`,
  `Scroll Rack`, `Victory Chimes`, and `Lorehold, the Historian`.
  - focused gap cards all resolved with oracle text present but still returned
    `function_tags=[]`, `semantic_v2_rows=0`, and
    `lorehold_synergy_rows=0`.
  - `Lorehold, the Historian` returned
    `function_tags=['draw','enabler','engine','loot']`,
    `semantic_v2_rows=1`, and `lorehold_synergy_rows=0`.
- Ran `cd server && dart analyze lib/ai/commander_learned_deck_support.dart test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart`.
  - result: no issues found.
- Ran `cd server && dart test test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`.
  - result: `25/25` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  battle-engine edit, commit, or push was performed.

Current learning:

- Lorehold learned-deck role summaries are currently coherent at runtime because
  the route canonicalizes role metadata from the card list and deterministic
  critical-card overrides before returning `role_summary`.
- Durable PostgreSQL card intelligence is still incomplete for the focused
  Lorehold cards. Direct reads from PG role/synergy tables still understate
  `Orim's Chant`, `Ruby Medallion`, `Scroll Rack`, and `Victory Chimes`.
- The commander itself has local function tags and semantic v2 coverage, but no
  Lorehold-specific commander synergy row; that belongs to the same backfill
  family.

Additional required adjustments:

356. Keep active item `2` open until approved PG backfill creates durable
     functional tags, semantic v2 rows, and Lorehold commander-synergy rows for
     the focused gap cards.
357. Do not convert the missing PG rows into deck-composition advice; the
     current evidence supports keeping these cards as strategic Lorehold pieces,
     with runtime overrides as a temporary bridge.
358. Any future consumer that reads `card_function_tags`,
     `card_semantic_tags_v2`, or `commander_card_synergy` directly must treat
     empty rows for these focused cards as incomplete data, not absence of role.
359. After approved backfill, rerun the same read-only PG gap query plus
     `commander_learned_deck_support_test.dart` and
     `api_contracts_data_map_guard_test.dart` before closing item `2`.
360. Keep documenting commander-specific synergy separately from generic
     function tags, because `Lorehold, the Historian` currently proves that a
     card can have generic tags while still lacking Lorehold synergy rows.

## Learned-Deck Identity Resolution Current Recheck

Safe evidence collected:

- Re-read `server/bin/learned_deck_coherence_audit.py` and
  `server/test/learned_deck_coherence_audit_test.py`.
- Ran `python3 server/bin/learned_deck_coherence_audit.py --stdout`.
  - result: `active_learned_decks=60`, `off_color_cards=5`,
    `partner_identity_not_modeled=9`, `metadata_total_lands_mismatch=58`,
    `metadata_zero_lands=54`, `high=173`, `medium=21`.
- Imported `server/bin/learned_deck_coherence_audit.py` safely and called
  `build_payload(...)` without writing artifacts.
  - result: `off_color_resolution_plan.status=ready_for_review`,
    `db_mutations=false`, `apply_requires_explicit_approval=true`,
    `entry_count=5`.
  - current plan entries remain `learned_deck:126` and `learned_deck:114`
    resolving raw `Vendetta` as `Vengeance/W`, `learned_deck:3` and
    `learned_deck:131` resolving raw `Endurance` as `Endure/W`, plus
    `learned_deck:116` combined commander identity modeling.
- Ran a direct read-only PostgreSQL query against `card_identity_bridge` and
  `card_intelligence_snapshot` for normalized aliases `vendetta` and
  `endurance`.
  - correct `Vendetta/B` and `Endurance/G` rows exist with `match_priority=0`.
  - wrong alias rows also exist: `Vengeance/W` has `lookup_name=Vendetta` and
    `Endure/W` has `lookup_name=Endurance`, both with `match_priority=1`.
- Inspected current lookup code: `load_card_lookup(...)` has no explicit
  `ORDER BY` and keeps the first normalized alias through `lookup.setdefault`.
- Extracted Lorehold `learned_deck:82` from the same payload.
  - result: `off_color_candidates=[]`,
    `off_color_after_partner_inference=[]`, commander identity `R,W`, and only
    `metadata_total_lands_mismatch expected=33 actual=30`.
- Ran `python3 -m py_compile server/bin/learned_deck_coherence_audit.py server/test/learned_deck_coherence_audit_test.py`.
  - result: pass.
- Ran `python3 -m unittest server/test/learned_deck_coherence_audit_test.py`.
  - result: `14` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  battle-engine edit, commit, or push was performed.

Current learning:

- The current PG data contains enough signal to resolve these aliases correctly:
  exact canonical `Vendetta` and `Endurance` rows have `match_priority=0`.
- The effective audit path can still resolve them incorrectly because alias
  insertion is order-sensitive. The real fix is deterministic identity
  precedence or bridge/view data cleanup, not a learned-deck card replacement.
- Lorehold deck `6` remains outside this blocker. Its learned-deck issue is
  stale lands metadata, not off-color identity resolution.

Additional required adjustments:

361. Keep active item `3` open until current audit/product resolver evidence
     proves exact canonical `Vendetta/B` and `Endurance/G` win over
     `Vengeance/W` and `Endure/W`.
362. Do not advise swaps for `Vendetta` or `Endurance` in chat "Ajustar deck";
     treat current white resolutions as identity defects.
363. If the fix is data-side, require explicit PostgreSQL mutation approval and
     rerun the bridge query plus `learned_deck_coherence_audit.py --stdout`.
364. If the fix is code/view-side, add evidence that lookup precedence uses exact
     canonical name and `match_priority=0` before alias rows, then rerun
     `learned_deck_coherence_audit_test.py`.
365. Keep K-9 combined commander identity modeling separate from the
     `Vendetta`/`Endurance` alias-precedence defect.

## PostgreSQL Oracle Structure Current Recheck

Safe evidence collected:

- Ran direct read-only PostgreSQL counts over `cards` and
  `card_intelligence_snapshot`.
  - result for both sources: `34,329` total rows, `33,966` strict
    oracle-structured rows, `363` outside strict predicate, `4` missing
    `oracle_id`, `360` missing `oracle_text`, and `1` missing `type_line`.
- Ran direct read-only `deck_cards` counts using `card_intelligence_snapshot`
  plus `EXISTS` for `card_identity_bridge`.
  - result: `50,841` deck rows / `79,145` quantity; `0/0` missing identity
    bridge; `0/0` missing intelligence snapshot; `22/22` missing `oracle_id`;
    `34/34` missing `oracle_text`; `0/0` missing `type_line`;
    `50,785/79,089` strict oracle rows/quantity.
- The persisted deck-card gap names remain unchanged:
  `Isamaru, Hound of Konda`, `A-Alrund's Epiphany`, `Grizzly Bears`,
  `Runeclaw Bear`, `A-Omnath, Locus of Creation`, and `Yargle and Multani`.
- Ran direct read-only PG control query for linked Lorehold PG deck
  `528c877f-f829-4207-95e6-73981776c323`.
  - result: `100` rows, `100` quantity, commander quantity `1`, land quantity
    `33`, strict oracle rows/quantity `100/100`, and `0` unstructured rows.
- Ran `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall`.
  - result: `status=PASS`, `db_mutations=false`, `active_learned_gap_items=0`,
    `deck_card_gap_items=6`, `planned_items=6`, `backfill_ready=0`.
- Ran `python3 server/bin/plan_oracle_text_backfill.py --limit=6 --delay-ms=75 --timeout-seconds=20`.
  - result: `status=PASS`, `db_mutations=false`, `scryfall_found=4`,
    `backfill_ready=0`.
  - Scryfall exact-name found four official no-rules-text cards with
    `oracle_text_present=false`; both `A-` variants returned exact-name `404`.
- Ran `python3 server/bin/learned_deck_coherence_audit.py --stdout`.
  - result: no active learned-deck oracle-text issue; remaining current counts
    are metadata/identity: `metadata_total_lands_mismatch=58`,
    `metadata_zero_lands=54`, `off_color_cards=5`,
    `partner_identity_not_modeled=9`.
- Ran `python3 -m py_compile server/bin/learned_deck_coherence_audit.py server/bin/plan_oracle_text_backfill.py server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`.
  - result: pass.
- Ran `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`.
  - result: `17` tests passed.
- No PostgreSQL write, live route call, deck `6` mutation, swap, code edit,
  battle-engine edit, commit, or push was performed.

Current learning:

- The item `4` numbers are unchanged from the previous recheck and still real:
  the catalog has `363` strict-oracle gaps, but the persisted deck impact is
  narrow and no active learned deck currently fails on oracle text.
- Four impacted persisted-deck names look like official no-rules-text cards,
  not automatic text-backfill candidates.
- `A-Alrund's Epiphany` and `A-Omnath, Locus of Creation` are Arena/Alchemy
  identity-modeling work, not Scryfall exact-name backfill.
- Lorehold deck `6` remains clean for oracle structure and should not be changed
  for this backlog.

Additional required adjustments:

366. Keep active item `4` open until global strict-oracle gaps are either
     backfilled or modeled as accepted-empty / source-specific exceptions.
367. Do not advise Lorehold deck `6` swaps from this oracle backlog; linked PG
     deck evidence is `100/100` strict oracle-structured.
368. Add or approve a policy for official no-rules-text cards in persisted decks
     before treating missing `oracle_text` as either accepted or actionable.
369. Handle `A-Alrund's Epiphany` and `A-Omnath, Locus of Creation` through an
     Arena/Alchemy identity path, not exact-name Scryfall backfill.
370. Preserve the no-fanout deck-card counting pattern: use
     `card_intelligence_snapshot` plus `EXISTS`/pre-aggregation, not raw
     `deck_cards -> card_identity_bridge` joins.

## Import Flow Current Recheck

Safe evidence collected:

- Re-read `server/routes/import/index.dart`,
  `server/routes/import/validate/index.dart`,
  `server/routes/import/to-deck/index.dart`,
  `server/lib/import_card_lookup_service.dart`,
  `server/lib/import_to_deck_merge_support.dart`,
  Flutter import provider support, `DeckImportListDialog`, and
  `DeckImportScreen`.
- `/import/validate` remains preview-only and non-mutating: it resolves names
  with `resolveImportCardNames(..., preferredFormat: normalizedFormat)`,
  includes `oracle_id` in `found_cards`, consolidates preview quantities by
  `card_id`, and reports warnings without persistence.
- `/import/to-deck` remains owner-scoped by `deck_id + user_id`, rejects
  unsupported sideboard/maybeboard sections before persistence, merges imported
  cards with current deck rows, validates the final merged list in the
  transaction with `DeckRulesService(..., strict:false)`, then deletes/reinserts
  `deck_cards`.
- `replace_all=true` for Commander/Brawl still preserves the existing commander
  when the imported list has no commander and exposes `commander_preserved`.
- `/import` still creates a new deck only after parsed content passes
  `DeckRulesService(..., strict: requiresCommander)`.
- Current import identity ordering is exact `cards` lookup first, then
  localized/bridge/split fallback. The helper still exposes
  `card_identity_bridge`, localized-name lookup, split/DFC aliases, `oracle_id`,
  and `preferredFormat` legality ordering, but this should not be described as
  bridge-first.
- App consumers preserve review state: existing-deck import refreshes deck
  details, parses `warnings`, `missing_commander`, `commander_preserved`,
  localized-match counts, and not-found lines, and keeps the dialog open when
  review details exist. Full import keeps partial results in draft-review
  before analysis or optimization.
- `server/test/import_to_deck_flow_test.dart` was intentionally not run because
  it is tagged `live`, `live_backend`, and `live_db_write`.

Validation evidence:

- `cd server && dart analyze lib/import_card_lookup_service.dart lib/import_list_service.dart lib/import_to_deck_merge_support.dart routes/import/index.dart routes/import/validate/index.dart routes/import/to-deck/index.dart test/import_parser_test.dart test/import_list_service_test.dart test/import_to_deck_merge_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/import_parser_test.dart test/import_list_service_test.dart test/import_to_deck_merge_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `35/35` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_import.dart lib/features/decks/widgets/deck_import_list_dialog.dart lib/features/decks/screens/deck_import_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/screens/deck_import_screen_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/screens/deck_import_screen_test.dart`
  - result: `70/70` tests passed.

Current learning:

- Import remains coherent as deck ingress and draft/review workflow, not final
  construction proof.
- `/import/validate` cannot prove persisted coherence.
- Successful `/import/to-deck` is stronger because it validates the final merged
  deck before persistence, but any review detail keeps the result draft-only
  until fresh fetch, strict validation, learned/reference package review, and
  Lorehold strategy checks pass.
- Lorehold deck `6` was not mutated and does not need a swap from this recheck.

Additional required adjustments:

371. Keep import flow classified as draft/review ingress, not construction
     proof for Lorehold or any other deck.
372. Keep `/import/to-deck` live/db-write route execution out of read-only
     audits; non-live handler-level route coverage remains open.
373. Preserve import review fields in app/provider/UI and keep review dialogs
     open whenever successful import returns warnings, not-found lines,
     localized matches, missing commander, or preserved commander details.
374. Be precise about import identity order: current code uses direct exact
     `cards` lookup first, with localized, `card_identity_bridge`, and
     split/DFC fallback after that. If import must become bridge-first, that
     needs an explicit code/test change in a later approved scope.
375. For chat "Ajustar deck", require fresh deck fetch, strict validation,
     learned/reference strategy review, and Lorehold package coherence review
     before using any imported deck or imported-to-deck response for
     optimize/apply decisions.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## PG095 Winds of Abandon Reading - 2026-06-23 11:02 UTC

What changed:

- PG095 closed `Winds of Abandon` for deck `607`.
- The previous state had two generated `needs_review/review_only` generic
  `remove_creature` rows that incorrectly modeled the card as `instant`.
- The new durable source is one PostgreSQL `curated active/auto` rule:
  `battle_rule_v1:4f844346b4b2b03ff68c2935fd399f9c`.
- Raw Oracle hash:
  `05e38c4458b7b803d038978b46f11f72`.
- Runtime executable subset:
  single-target Sorcery exile for a creature the controller does not control.
- Annotation-only subset:
  basic-land search/tapped placement for the target controller and overload
  `target` to `each` rewrite.

Evidence:

- PostgreSQL precheck/apply/postcheck:
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_battle_rule_pg095_precheck_20260623_105512.out`,
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_battle_rule_pg095_apply_20260623_105512.out`,
  and
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_battle_rule_pg095_postcheck_20260623_105512.out`.
- Rollback:
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_battle_rule_pg095_rollback_20260623_105512.sql`.
- Final PG -> SQLite/canonical runtime sync:
  `docs/hermes-analysis/master_optimizer_reports/pg095_winds_of_abandon_runtime_sync_report_20260623_105512.json`
  with `include_needs_review=false`, `pg_rows_loaded=1830`, and
  `canonical_snapshot_rows_exported=3201`.
- Focused event proof:
  `docs/hermes-analysis/master_optimizer_reports/winds_of_abandon_pg095_focused_events_20260623_105512.jsonl`.
- Full wrapper output:
  `docs/hermes-analysis/master_optimizer_reports/pg095_test_battle_analyst_v10_3_runtime_post_20260623_110204.out`.

Current candidate status:

- Deck `6`: `pass=100`.
- Deck `606`: `pass=81`.
- Deck `607`: `high=16`, `medium=4`, `pass=74`.
- Deck `608`: `high=14`, `medium=3`, `pass=51`.
- Global card-rule queue: `high=30`, `medium=4`, `pass=171`.
- No deck swap, no `deck_cards` mutation, no learned-deck promotion, and no
  new multi-seed battle baseline.

Next recommended queue:

- Continue deck `607` battle-critical high cards before support/passive rows.
- Highest-risk next choices are not simple metadata fixes:
  `Avatar's Wrath` needs airbend/non-hand-cast-lock modeling,
  `Call Forth the Tempest` needs opponent-only dynamic damage from spells cast
  this turn, and `High Noon` needs a static one-spell-per-turn model rather than
  the current generic removal shape.

## Role Summary Runtime Recheck

Timestamp: 2026-06-20 06:10 -03.

Current learning:

- Current detail-mode `/ai/commander-learning?commander=...` still computes
  learned-deck role metadata through
  `canonicalizeCommanderLearnedDeckMetadataWithStatus(...)` before building
  both `promoted_deck.role_summary` and `recommended_deck.role_summary`.
- The role summary path still uses `card_identity_bridge`, aggregated
  `card_function_tags`, split/alias matching, additive multi-role counts, and
  land separation.
- Lorehold overrides still cover `Orim's Chant`, `Ruby Medallion`,
  `Scroll Rack`, `Victory Chimes`, and `Lorehold, the Historian`.
- Dry-run canonicalization for `learned_deck:82` returned `status=PASS`,
  `mode=dry_run`, `db_mutations=false`, `checked=1`, `changed=0`, `applied=0`.
- Lorehold before/after role metadata stayed identical:
  `total_lands=33`, `ramp_count=20`, `draw_count=18`,
  `removal_count=8`, `tutor_count=5`, `engine_count=37`,
  `wincon_count=13`, `protection_count=13`, `recursion_count=4`,
  `board_wipe_count=2`.
- Focused app search still found no direct `role_summary` rendering/parsing
  contract. App flow consumes learned `recommended_deck` cards plus diagnostics
  for preview/save.

Validation evidence:

- Server role summary analyze: no issues found.
- Server role summary tests:
  `dart test test/commander_learned_deck_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `25/25` tests passed.
- App learned-deck preview analyze: no issues found.
- App learned-deck preview tests:
  `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
  - result: `33/33` tests passed.

Required adjustments:

525. Treat learned deck `82` role metadata as current for this audit slice:
     dry-run canonicalizer returned `changed=0` and `db_mutations=false`.
526. Keep using exact Lorehold role counts as coverage evidence, not as a
     one-card-one-role partition that must add to `100`.
527. Do not claim the mobile app displays `role_summary`; current evidence only
     proves learned preview/save diagnostics and `recommended_deck` cards.
528. Keep `role_summary_source=persisted_metadata_fallback` as review-only.
529. Treat canonicalizer dry-run as validation evidence only; applying metadata
     backfill is a PostgreSQL write that requires explicit approval.
530. Preserve Lorehold role overrides unless source-backed role audit and tests
     prove a change.
531. In chat "Ajustar deck", combine role summary with exact identity, strict
     validation, legality, and strategy-package evidence before card action.
532. Keep no-commander learned list mode free of role summaries, raw metadata,
     decklists, and cards.
533. For other learned decks, `changed>0` dry-run output is metadata/backfill
     divergence first, not a deck swap request.
534. Deck `6` has no active role-summary repair from this recheck.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Saved-Deck Fetch/Hydration Read-Model Recheck

Timestamp: 2026-06-20 00:28 -03.

Current learning:

- `GET /decks` is an owner-scoped legacy raw-array route. It returns deck list
  display fields, `card_count`, commander display metadata, and a presentation
  union of `cards.color_identity`.
- `GET /decks/:id` is an owner-scoped detail read model with root deck fields,
  `commander`, `main_board`, `all_cards_flat`, and route-side `stats`.
- Detail cards include persisted physical `condition` and display/runtime card
  fields such as `id`, `name`, `mana_cost`, `type_line`, `oracle_text`,
  `colors`, `color_identity`, image, set, rarity, collector number, and foil.
- Detail cards currently do not expose `oracle_id`, `layout`, `card_faces`, or
  `scryfall_id`; current tests assert this boundary.
- App list hydration fills missing list colors from cached/fetched details on a
  best-effort basis. Non-200 detail fetches are failed enrichment, not legality
  evidence.
- App mutation payloads derive from hydrated `DeckCardItem.id`, quantity,
  commander flag, and physical condition. Canonical identity and singleton
  legality remain backend-owned.
- Name-only create/update resolution is handled separately through
  `card_identity_bridge` first, ranked with `card_legalities`, with `cards`
  fallback only when the bridge view is unavailable.

Validation evidence:

- Server fetch/hydration analyze: no issues found.
- Server fetch/hydration tests:
  `dart test test/deck_fetch_hydration_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `9/9` tests passed.
- App fetch/hydration analyze: no issues found.
- App fetch/hydration/provider tests:
  `flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart`
  - result: `65/65` tests passed.

Required adjustments:

435. Treat `GET /decks` color identity as list display metadata only; never use
     it as Commander legality, deck `6` coherence, or swap authority.
436. Treat `GET /decks/:id` as the fresh persisted-state read model for
     quantities, grouping, saved conditions, and visible card text.
437. Do not use detail `all_cards_flat` to infer canonical identity beyond
     persisted `card_id`; fetch/detail currently lacks `oracle_id`, `layout`,
     `card_faces`, and `scryfall_id`.
438. For chat "Ajustar deck", require fresh detail fetch before planning, then
     backend strict validation and strategy/package review before any apply.
439. Keep app-side commander identity filtering as a convenience prefilter only;
     backend `DeckRulesService` remains the authority.
440. Preserve physical `condition` through every app mutation payload derived
     from fetched details.
441. If future UX needs canonical identity in deck detail, add tested additive
     fields instead of inferring from display names or set metadata.
442. Keep `card_identity_bridge` usage in create/update/name resolution and
     batch resolve; do not move canonical identity decisions into the mobile
     detail parser.
443. Treat route-side `mana_curve`, `color_distribution`, and `stats` as UI
     approximations only; use analysis/functional tags and deck audits for
     strategic role evidence.
444. Keep failed list color enrichment non-blocking; it is missing display
     enrichment, not proof that the deck is illegal or strategically incoherent.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Manual/Bulk Deck Mutation Boundary Recheck

Timestamp: 2026-06-20 00:32 -03.

Current learning:

- `POST /decks/:id/cards`, `POST /decks/:id/cards/bulk`,
  `POST /decks/:id/cards/set`, and `POST /decks/:id/cards/replace` are live
  write routes over `deck_cards`.
- Single-card add validates owner scope, card existence, legality, copy limits,
  Commander/Brawl total caps, commander eligibility, commander color identity,
  and the composed next deck through `DeckRulesService(... strict:false)` before
  writing.
- Single-card `is_commander=true` is commander-slot editing. It forces quantity
  `1`, can replace a single existing commander, and protects multi-commander
  decks from blind replacement.
- Bulk add rejects commander rows, merges increments into current rows,
  preserves existing physical `condition`, defaults new rows to `NM`, and
  validates the normalized full list before delete/reinsert.
- `cards/set` uses absolute quantity. `replace_same_name=true` is same-name
  printing consolidation, not canonical `oracle_id` or `physicalCopyKey`
  replacement.
- `cards/replace` is same-name-only edition replacement and does not use
  `oracle_id`/`physicalCopyKey`. In-place replacement keeps row condition; merge
  into an existing target row cannot preserve per-copy old condition under the
  current one-condition-per-row model.
- App add/remove/set/replace/bulk flows refresh details after success and
  invalidate related caches, but they do not automatically call strict
  `/decks/:id/validate`. Strict validation remains an explicit follow-up gate.

Validation evidence:

- Server manual/bulk mutation analyze: no issues found.
- Server manual/bulk mutation tests:
  `dart test test/deck_cards_bulk_support_test.dart test/deck_manual_mutation_route_contract_test.dart test/api_contracts_data_map_guard_test.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart -r expanded`
  - result: `20/20` tests passed.
- App mutation analyze: no issues found.
- App mutation/provider tests:
  `flutter test test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart -r expanded`
  - result: `65/65` tests passed.

Required adjustments:

445. Do not call manual/bulk mutation routes during read-only deck `6` audits;
     all four write `deck_cards`.
446. Treat single-card add as a guarded write path, not final strategy proof.
447. Treat bulk add as atomic construction validation only; it rejects commander
     rows and preserves/defaults physical condition, but still needs post-action
     strict validation for Commander readiness.
448. Treat `cards/set` quantity as absolute and `replace_same_name` as
     same-name printing consolidation only.
449. Treat `cards/replace` as edition replacement only; it is not
     `oracle_id`/canonical identity replacement and not an archetype swap.
450. After any manual add/remove/set/replace/bulk change, require fresh detail
     fetch plus explicit strict `/decks/:id/validate` before success is claimed
     for chat "Ajustar deck".
451. Preserve physical `condition` in app-derived payloads and bulk merges.
452. Document or redesign condition behavior when replacing into an existing
     target printing if per-copy condition fidelity becomes product-critical.
453. Keep app-side commander/color checks as convenience only; backend rules are
     authoritative for legality and singleton/canonical identity.
454. Never use manual mutation response bodies as strategy evidence; use them
     only as mutation acknowledgements.
455. Keep remove-card full-list `PUT` in the same safety bucket as optimize
     apply: route construction validation first, strict validation still
     required afterward.
456. For Lorehold deck `6`, any future manual mutation must be preceded by user
     approval and followed by strict validation plus package/role coherence
     review.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Card Identity Batch Resolution Boundary Recheck

Timestamp: 2026-06-20 00:37 -03.

Current learning:

- `POST /cards/resolve/batch` is the read-side name-to-card-id gate used before
  generated/learned/manual deck creation. It rejects invalid payloads, caps
  requests at `200` names, and returns explicit `data`, `unresolved`, and
  `ambiguous` buckets.
- The shared resolver queries `card_identity_bridge` first and falls back to
  `cards` only when the bridge is unavailable.
- Bridge ranking is `match_rank`, then bridge `match_priority`, then
  `legality_rank`; this preserves canonical/localized bridge priority before
  preferred-printing legality rank.
- The app `normalizeCreateDeckCards(...)` sends only `names` to the batch
  endpoint, keeps direct `card_id` rows, and blocks `POST /decks` when batch
  resolution fails, is unresolved, or is ambiguous.
- Batch success proves name mapping, not legality or strategy coherence. Deck
  write validation and strict `/decks/:id/validate` remain required for
  Commander shape/legal proof, and package/role review remains required for
  Lorehold strategy coherence.

Validation evidence:

- Server card-resolution analyze: no issues found.
- Server card-resolution tests:
  `dart test test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `14/14` tests passed.
- App create/generation analyze: no issues found.
- App create/generation/runtime tests:
  `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart -r expanded`
  - result: `70/70` tests passed.

Required adjustments:

457. Use `/cards/resolve/batch` only as a pre-create identity gate, not as
     legality, singleton, or strategy proof.
458. Keep `card_identity_bridge` as the first identity source and keep `cards`
     fallback limited to missing-bridge compatibility.
459. Treat unresolved/ambiguous name resolution as blocking for create/save.
460. Never call `POST /decks` after unresolved or ambiguous batch resolution.
461. Because batch resolve does not send `preferredFormat`, require write-route
     validation and strict validation for format legality.
462. Treat bridge `match_priority` before legality rank as canonical/localized
     identity preference, not preferred-printing proof.
463. For chat "Ajustar deck", prefer durable `card_id` evidence from fresh
     detail/optimizer/artifact outputs before using names.
464. Keep exact/prefix/contains strategy labels diagnostic only; do not use
     them as automatic mutation confidence.
465. Preserve split/DFC support in the shared resolver and avoid ad-hoc
     lowercase `cards.name` lookup in deck writes.
466. Add a tested format field later if batch resolution needs to become
     format-aware.
467. Verify current DB/validation evidence before claiming exact deck `6`
     identity from resolver output.
468. Treat learned/generated save as new deck creation; batch success does not
     prove Lorehold role/package coherence.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Import Flow Boundary Recheck

Timestamp: 2026-06-20 00:41 -03.

Current learning:

- `POST /import/validate` is a non-mutating preview route. It parses
  string/list payloads, resolves card names, returns `found_cards`,
  `not_found_lines`, localized match metadata, warnings, and totals, but does
  not create or update a deck.
- Preview import intentionally treats unsupported sections softly by surfacing
  them through review output; `POST /import` and `POST /import/to-deck` reject
  unsupported raw/parsed sections before persistence.
- `POST /import` creates a new deck and inserts deck rows in a transaction
  after `DeckRulesService`; Commander/Brawl imports use strict validation
  before insert.
- `POST /import/to-deck` mutates an existing owner-scoped deck. `replace_all`
  rewrites deck rows, while Commander/Brawl can preserve an existing commander
  when the imported replacement list has none.
- `/import/to-deck` validates with `DeckRulesService(... strict:false)` before
  delete/reinsert, so strict `/decks/:id/validate` remains required after
  success before Commander readiness can be claimed.
- Import lookup is format-aware and oracle-aware in important places, but it is
  not the same resolver as `/cards/resolve/batch`: current source uses
  `cards`, optional `card_localized_names`, static aliases, and split/DFC
  fallback rather than the shared bridge-backed deck name resolver.
- App import screens/dialogs surface partial state, warnings,
  `missing_commander`, `commander_preserved`, and not-found lines as review
  state; success refreshes deck details but does not make a strategy claim.

Validation evidence:

- Server import analyze: no issues found.
- Server import tests:
  `dart test test/import_parser_test.dart test/import_list_service_test.dart test/import_to_deck_merge_support_test.dart test/unsupported_deck_sections_route_contract_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `35/35` tests passed.
- App import analyze: no issues found.
- App import/provider tests:
  `flutter test test/features/decks/screens/deck_import_screen_test.dart test/features/decks/widgets/deck_import_list_dialog_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart -r expanded`
  - result: `70/70` tests passed.

Required adjustments:

469. Use `/import/validate` only as preview/review evidence; never as final
     legality, singleton, or strategy proof.
470. Keep unsupported section handling distinct: preview may surface review
     lines, but write routes must reject unsupported sections before
     persistence.
471. Do not call `POST /import` during read-only Lorehold/deck `6` audits.
472. Treat `POST /import` partial success or warnings as draft/review state,
     not ready-to-optimize.
473. Keep Commander/Brawl `POST /import` strict validation before insert.
474. Do not call `POST /import/to-deck` during read-only deck `6` audits.
475. Treat `replace_all=true` as destructive deck-row rewrite, even with
     commander preservation.
476. After `/import/to-deck` success, require fresh details plus strict
     `/decks/:id/validate`.
477. Treat `warnings`, `missing_commander`, and `commander_preserved` as review
     status, not strategy proof.
478. Keep app review dialogs visible for partial import status and avoid
     auto-routing partial imports into optimize/battle learning.
479. Reconcile import identity lookup with the shared `card_identity_bridge`
     resolver later, or document it as a separate legacy/localized lookup
     surface.
480. Do not assume import uses `/cards/resolve/batch`; current source uses
     `cards`, optional `card_localized_names`, static aliases, and split/DFC
     fallback.
481. Preserve `preferredFormat` propagation in import entry points.
482. Preserve oracle-aware physical copy warnings in `/import/validate`.
483. Treat `/import/to-deck` name-grouped warning text as advisory until strict
     validation proves canonical singleton state.
484. For chat "Ajustar deck", imported lists need the same post-write checklist
     as optimize/manual edits: fresh details, strict validation, package/role
     review, and explicit approval.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Learned-Deck Metadata Current Recheck

Timestamp: 2026-06-20 00:46 -03.

Current learning:

- Newest learned-deck coherence artifact currently present is
  `learned_deck_coherence_audit_20260620_034458.json/.md`, generated at
  `2026-06-20T03:44:55.241649+00:00`, with `read_only=true`.
- The official `python3 server/bin/learned_deck_coherence_audit.py --stdout`
  summary now reports `active_learned_decks=60`,
  `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`,
  `all_core_metadata_zero=54`, `some_core_metadata_zero=4`,
  `partner_identity_not_modeled=10`, and severity `high=167`,
  `medium=22`.
- Lorehold `learned_deck:82` currently has `metadata.total_lands=33`,
  `derived_metadata.total_lands=33`, and `issues=[]`.
- Linked PG saved deck
  `528c877f-f829-4207-95e6-73981776c323` remains `100` rows / `100` quantity /
  `33` lands / `1` commander.
- Active-vs-PG and active-vs-SQLite name diffs are empty.
- Lorehold strategy packages pass: commander identity `1/1`, copy combo
  `7/4`, topdeck/miracle `5/3`, graveyard/spell value `5/4`, big finishers
  `7/4`, protection/stack control `10/6`, and mana acceleration `14/10`.
- Premium Mox policy remains satisfied: no `Chrome Mox`, `Mox Diamond`, or
  `Mox Opal`.
- `dart run bin/canonicalize_learned_deck_metadata.dart --dry-run --source-ref=learned_deck:82 --include-unchanged`
  returned `status=PASS`, `mode=dry_run`, `db_mutations=false`, `changed=0`,
  and identical before/after selected metadata.

Validation evidence:

- Python learned-deck audit compile: pass.
- Python learned-deck audit tests:
  `python3 -m unittest server/test/learned_deck_coherence_audit_test.py`
  - result: `17` tests passed.
- Dart canonicalizer/learned support analyze: no issues found.
- Commander learned support tests:
  `dart test test/commander_learned_deck_support_test.dart -r expanded`
  - result: `19/19` tests passed.

Required adjustments:

485. Mark the focused Lorehold `learned_deck:82` stale metadata item as closed
     for current state.
486. Supersede older notes that say Lorehold active metadata has
     `total_lands=30`; current evidence is `33`.
487. Keep the global learned-deck metadata backlog open with current counts:
     `metadata_total_lands_mismatch=57`, `metadata_zero_lands=54`, and
     `partner_identity_not_modeled=10`.
488. Do not mutate deck `6` because of global learned-deck metadata backlog.
489. Treat `Wheel of Misfortune` absence as non-blocking because the current
     graveyard/spell-value package still passes `5/4`.
490. Keep Premium Mox exclusion satisfied for Lorehold.
491. For chat "Ajustar deck", use this artifact as evidence that deck `6`
     does not need learned-metadata card swaps.
492. For non-Lorehold learned decks, split remediation by zero metadata,
     partner identity, and quantity mismatch.
493. Reopen Lorehold metadata only if future artifact plus source-ref dry-run
     prove new drift.
494. Require artifact, stdout aggregate, and source-ref dry-run evidence before
     closing or reopening learned metadata items.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## PostgreSQL Card Oracle Structure Current Recheck

Timestamp: 2026-06-20 00:50 -03.

Current learning:

- Latest learned-deck coherence artifact
  `learned_deck_coherence_audit_20260620_034458.json/.md` reports the current
  PostgreSQL Oracle inventory from `card_intelligence_snapshot`.
- Oracle-structured definition for this audit: `oracle_id`, `oracle_text`, and
  `type_line` present.
- Current counts:
  - total cards: `34,329`
  - Oracle-structured cards: `33,966`
  - structured rate: `0.9894`
  - with `oracle_id`: `34,325`
  - with `oracle_text`: `33,969`
  - with `type_line`: `34,328`
  - missing `oracle_id`: `4`
  - missing `oracle_text`: `360`
  - missing `type_line`: `1`
- Read-only planner `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall`
  returned `status=PASS`, `mode=read_only`, `db_mutations=false`,
  `missing_any=363`, `active_learned_gap_items=0`, `deck_card_gap_items=6`,
  `planned_items=6`, and `backfill_ready=0`.
- Saved-deck impacted names are `Isamaru, Hound of Konda`,
  `A-Alrund's Epiphany`, `Grizzly Bears`, `Runeclaw Bear`,
  `A-Omnath, Locus of Creation`, and `Yargle and Multani`.
- Lorehold active learned deck and linked PG saved deck currently have no
  missing `oracle_id` or `oracle_text` impact.

Validation evidence:

- Python compile for Oracle/learned audit scripts: pass.
- Oracle/learned audit tests:
  `python3 -m unittest server/test/plan_oracle_text_backfill_test.py server/test/learned_deck_coherence_audit_test.py`
  - result: `20` tests passed.

Required adjustments:

495. Use the current artifact inventory as the Oracle-structure answer:
     `34,329` total cards, `33,966` structured, `363` with a relevant gap.
496. Track gap classes separately: `4` missing `oracle_id`, `360` missing
     `oracle_text`, and `1` missing `type_line`.
497. Do not propose deck `6` swaps from Oracle-structure backlog.
498. Keep the `6` saved-deck impacted names as data-quality follow-up, not
     strategy work.
499. Treat `active_learned_gap_items=0` as the current learned-deck safety
     signal for this backlog.
500. Do not invent oracle text for official no-rules-text cards; model accepted
     empty text explicitly.
501. Treat Arena/Alchemy `A-` names as identity-policy work.
502. Do not write PostgreSQL from this planner without explicit approval.
503. If Scryfall probing is needed later, keep read-only `backfill_ready`
     separate from approval to write.
504. For chat "Ajustar deck", use Oracle gaps only as data-quality caveats
     unless the target deck itself has current missing-oracle impact.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Learned-Deck Partner Identity Persistence Recheck

Timestamp: 2026-06-20 00:53 -03.

Current learning:

- Latest artifact `learned_deck_coherence_audit_20260620_034458.json/.md`
  reports `partner_identity_not_modeled=10`.
- The same artifact reports `off_color_resolution_plan.status =
  no_current_off_color_manual_entries`, `entry_count=0`, `db_mutations=false`,
  and `apply_requires_explicit_approval=true`.
- Lorehold `learned_deck:82` is not part of this backlog:
  `commander_identity_model.status=single_commander_identity`,
  `combined_color_identity=['R','W']`, `identity_components=[]`, and
  `requires_first_class_persistence=false`.
- `plan_learned_deck_partner_identity_backfill.py` has no apply mode. It loads
  the current learned-deck audit model and emits dry-run metadata patches plus
  scoped update/rollback SQL for rows whose inferred combined commander model
  is not yet persisted.
- Dry-run planner result:
  `status=PASS`, `mode=dry_run`, `planned_row_count=10`,
  `db_mutations=false`, `apply_supported=false`.
- Planned rows:
  `learned_deck:112` Akiri + Thrasios,
  `learned_deck:93` Dargo + Tymna,
  `learned_deck:110` Ishai + Rograkh,
  `learned_deck:100` Jeska + Tymna,
  `learned_deck:116` K-9 + The Fourteenth Doctor,
  `learned_deck:173` Krark + Sakashima,
  `learned_deck:89` Kraum + Tymna,
  `learned_deck:90` Malcolm + Vial Smasher plus Kediss inferred from partner
  text,
  `learned_deck:85` Rograkh + Silas Renn,
  and `learned_deck:87` Thrasios + Yoshimaru.

Validation evidence:

- Partner planner Python compile: pass.
- Partner planner + learned audit tests:
  `python3 -m unittest server/test/plan_learned_deck_partner_identity_backfill_test.py server/test/learned_deck_coherence_audit_test.py`
  - result: `19` tests passed.

Required adjustments:

505. Treat `off_color_resolution_plan.entry_count=0` as off-color review
     closure, not durable partner persistence.
506. Keep `partner_identity_not_modeled=10` open until combined commander
     identity is persisted or modeled as first-class product data.
507. Do not apply partner identity metadata without explicit PostgreSQL
     mutation approval.
508. Keep Lorehold/deck `6` out of partner identity backfill scope.
509. For chat "Ajustar deck", do not use the `10` affected learned decks as
     authoritative color-identity examples until persistence or explicit
     inference acceptance exists.
510. Preserve provenance: deck-name component, partner text, and mixed
     inference are different evidence classes.
511. If persistence is approved later, require rollback SQL/artifact evidence
     and post-apply coherence audit proof.
512. Treat Malcolm/Vial Smasher/Kediss as mixed inference.
513. Do not turn partner identity remediation into card-list swaps.
514. Keep partner/background limitations visible in global builder quality
     summaries until the planned rows are resolved.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Card Identity Bridge Coverage And Fanout Recheck

Timestamp: 2026-06-20 06:05 -03.

Current learning:

- Current read-only PostgreSQL counts:
  - `cards_total=34329`
  - `card_identity_bridge` rows: `305905`
  - distinct bridge card ids: `34329`
  - cards missing bridge rows: `0`
  - distinct bridge oracle ids: `34077`
  - distinct normalized lookup names: `169190`
  - canonical `cards/en` rows: `34329`
  - non-`cards` localized/source rows: `271576`
- Bridge localization/source rows are mainly Scryfall localized aliases:
  French `60576`, German `60298`, Spanish `55227`, Italian `54030`,
  Portuguese `41445`, plus English canonical `34329`.
- Fanout is expected and material:
  average aliases per card `8.91`, max aliases for one card id `1922`,
  `29579` cards with more than one bridge row, and `361` normalized lookup
  names mapping to multiple card ids.
- Linked PG deck `528c877f-f829-4207-95e6-73981776c323` for Lorehold deck `6`
  has `100` rows / `100` quantity and `0` rows or quantity missing bridge.
- Latest learned-deck artifact `034458` has `60` active learned decks with
  `0` unresolved names, `0` missing-oracle quantity, and `0` off-color cards
  after partner inference.

Validation evidence:

- Bridge resolver analyze: no issues found.
- Bridge resolver tests:
  `dart test test/card_resolution_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `14/14` tests passed.
- Commander learned bridge usage analyze: no issues found.
- Commander learned support tests:
  `dart test test/commander_learned_deck_support_test.dart -r expanded`
  - result: `19/19` tests passed.

Required adjustments:

515. Treat current bridge coverage as complete for base `cards`: `34329/34329`
     card ids covered.
516. Do not treat `card_identity_bridge` as one-row-per-card; it has `305905`
     rows and expected alias/localization fanout.
517. Never join `deck_cards` directly to raw bridge rows for counts or deck
     composition without `EXISTS`, aggregation, or representative selection.
518. Preserve resolver-helper usage for deck create/update/batch and learned
     canonicalization.
519. Treat multi-card localized lookup names as expected ambiguity requiring
     ranking/review, not automatic bad data.
520. Keep bridge fanout separate from Oracle-structure backlog.
521. Keep deck `6` out of bridge-coverage remediation.
522. For chat "Ajustar deck", require durable `card_id` or bridge-backed
     resolver output before name-based card action.
523. If analytics need bridge fields, use a one-row-per-card projection or
     `card_intelligence_snapshot`, not raw bridge grain.
524. Keep localized bridge data as internal resolution support, not normal
     user-facing raw metadata.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, source-code edit, battle-engine edit, commit, or push was performed.

## Saved-Deck Strict Validation Current Recheck

Timestamp: 2026-06-20 00:24 -03.

Current learning:

- `POST /decks/:id/validate` is `POST`-only, owner-scoped by `deck_id + user_id`,
  reloads persisted `deck_cards`, and calls `DeckRulesService(... strict:true)`.
- The current response contract is `{ok:true, format, deck_id}` on success,
  `404 {ok:false,error,error_code:"deck_not_found"}` on owner-scope miss,
  `400 {ok:false,error,card_name?}` for `DeckRulesException`, and
  `500 {ok:false,error}` for unexpected failures.
- `deck_validation_route_support.dart` and
  `deck_validation_route_support_test.dart` now cover the SQL and response-body
  helpers without a live PostgreSQL route call.
- App `validateDeckRequest(...)` accepts the current `ok` response shape while
  retaining compatibility with older `valid`/`is_valid` shapes.
- App persisted apply still validates after `PUT`. Failed strict validation is
  surfaced as failed apply plus detail refresh, but it does not automatically
  rollback the write attempt.
- Strict validation remains legality/shape proof only. It does not prove
  Lorehold strategy coherence, package density, role balance, or non-Lorehold
  builder archetype fit.

Validation evidence:

- Server validate analyze: no issues found.
- Server validate tests:
  `dart test test/deck_validation_route_support_test.dart test/deck_rules_service_test.dart test/deck_rules_service_identity_test.dart test/generated_deck_validation_service_test.dart test/api_contracts_data_map_guard_test.dart test/deck_validation_test.dart -r expanded`
  - result: `72/72` tests passed.
- App validate analyze: no issues found.
- App validate tests:
  `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `74/74` tests passed.

Required adjustments:

428. Keep `/decks/:id/validate` as the final legality/shape gate after any
     generated, imported, optimized, or manual persisted mutation.
429. Do not treat strict validation success as strategic coherence; every
     Lorehold or non-Lorehold builder path still needs package/role review.
430. Treat post-write validation failure as failed and rollback-worthy/manual
     review, not as a completed deck adjustment.
431. Add transactional apply or rollback design later if product wants automatic
     safety after failed post-`PUT` strict validation.
432. Preserve owner-scope `404` behavior and generic client display for unknown
     validation issue types.
433. Keep app compatibility for `ok`/`valid`/`is_valid` only as response-shape
     compatibility; the current backend contract is `ok`.
434. During read-only Lorehold/deck `6` audits, do not call the live validation
     route against deck `6` unless explicitly approved; rely on code/tests and
     read-only current deck evidence.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## PostgreSQL Oracle / Learned Identity Refresh

Timestamp: 2026-06-20 00:20 -03.

Safe evidence collected:

- `python3 server/bin/plan_oracle_text_backfill.py --no-scryfall`
  - result: `status=PASS`, `mode=read_only`, `db_mutations=false`,
    `total_cards=34329`, `missing_oracle_id=4`,
    `missing_oracle_text=360`, `missing_any=363`,
    `active_learned_gap_items=0`, `deck_card_gap_items=6`,
    `planned_items=6`, `backfill_ready=0`.
- `python3 server/bin/plan_oracle_text_backfill.py --limit=6 --delay-ms=75 --timeout-seconds=20`
  - result: `status=PASS`, `mode=read_only`, `db_mutations=false`,
    `scryfall_found=4`, `backfill_ready=0`.
- Direct read-only PostgreSQL query for Lorehold linked PG deck
  `528c877f-f829-4207-95e6-73981776c323`
  - result: `100` rows, `100` quantity, commander quantity `1`,
    land quantity `33`, and `0` missing identity bridge, intelligence
    snapshot, `oracle_id`, `oracle_text`, or `type_line` rows/quantity.
- Latest full learned-deck artifact inspected:
  `docs/hermes-analysis/master_optimizer_reports/learned_deck_coherence_audit_20260620_031157.json`,
  generated at `2026-06-20T03:11:54.074960+00:00`, `read_only=true`.
- `python3 server/bin/learned_deck_coherence_audit.py --stdout`
  - result: current summary reports `active_learned_decks=60`,
    `metadata_total_lands_mismatch=58`, `metadata_zero_lands=54`,
    `off_color_cards=1`, `partner_identity_not_modeled=9`.
- `python3 -m py_compile server/bin/learned_deck_coherence_audit.py server/bin/plan_oracle_text_backfill.py server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`
  - result: pass.
- `python3 -m unittest server/test/learned_deck_coherence_audit_test.py server/test/plan_oracle_text_backfill_test.py`
  - result: `18` tests passed.

Current learning:

- The global oracle-structure count remains stable: `363/34,329` card rows fail
  the strict `oracle_id + oracle_text` predicate.
- Persisted deck impact remains narrow and unchanged: `6` names, `0` active
  learned-deck oracle gaps, and `0` automatic backfill-ready items.
- Scryfall exact-name lookup still confirms four impacted cards have official
  empty oracle text, while the two `A-` cards need Arena/Alchemy identity
  handling instead of normal exact-name backfill.
- Lorehold deck `6` is not affected by this backlog. Its linked PG deck is
  `100/100`, has `33` lands, and has complete bridge/snapshot/oracle/type-line
  coverage.
- Latest learned-deck coherence evidence supersedes the older off-color count:
  aggregate `off_color_cards=1`, while `off_color_resolution_plan.entry_count=5`
  remains open for identity-bridge misresolution and combined commander identity
  modeling.
- Lorehold `learned_deck:82` remains strategically coherent in the current
  artifact and has no oracle/identity gap; its active issue is stale cached
  lands metadata (`metadata.total_lands=30` vs resolved `33`).

Additional required adjustments:

419. Keep global oracle/backfill policy open; do not treat it as a deck `6`
     mutation or swap task.
420. Model official empty oracle text explicitly instead of inventing text for
     vanilla/no-rules-text cards.
421. Handle `A-` Arena/Alchemy identities separately from exact-name Scryfall
     card lookup.
422. Keep deck `6` out of the oracle backlog unless a future fresh query shows
     bridge/snapshot/oracle/type-line gaps.
423. For chat "Ajustar deck", use oracle gaps only as data-quality warnings, not
     as card replacement advice.
424. Use the current learned-deck off-color count `1`, while keeping the
     5-entry resolution plan active for identity/modeling work.
425. Keep `learned_deck:82` scoped to stale land metadata, not oracle/card
     identity.
426. Preserve the no-fanout query pattern: `card_intelligence_snapshot` plus
     `EXISTS`/pre-aggregation, not direct `card_identity_bridge` joins.
427. Require explicit approval before any PostgreSQL mutation or backfill.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Generate / Learned Deck Async+Save Recheck

Timestamp: 2026-06-20 00:13 -03.

Safe evidence collected:

- Re-read current async `/ai/generate`, job polling, generate cache,
  generated-deck validation, learning-event support, app generation provider,
  learned-deck preview, and save path.
- `cd server && dart analyze routes/ai/generate/index.dart 'routes/ai/generate/jobs/[id].dart' routes/ai/commander-learning/index.dart lib/ai_generate_job.dart lib/ai_generate_internal_url_support.dart lib/ai_generate_performance_support.dart lib/generated_deck_validation_service.dart lib/ai/commander_learned_deck_support.dart lib/ai/commander_reference_generate_fallback_support.dart lib/ai/deck_learning_event_support.dart test/ai_generate_learning_boundary_test.dart test/generated_deck_validation_service_test.dart test/commander_learned_deck_support_test.dart test/ai_generate_job_authorization_source_test.dart test/ai_generate_internal_url_support_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/ai_generate_learning_boundary_test.dart test/generated_deck_validation_service_test.dart test/commander_learned_deck_support_test.dart test/ai_generate_job_authorization_source_test.dart test/ai_generate_internal_url_support_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `46/46` tests passed.
- `cd app && flutter analyze lib/features/decks/screens/deck_generate_screen.dart lib/features/decks/providers/deck_provider_support_generation.dart lib/features/decks/providers/deck_provider.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart test/features/decks/screens/deck_runtime_widget_flow_test.dart`
  - result: `70/70` tests passed.
- No live route call, PostgreSQL write, OpenAI call, deck `6` mutation, swap,
  code edit, commit, or push was performed.

Current learning:

- Async `/ai/generate` is auth-required and write-capable. It creates
  `ai_generate_jobs` rows, can lazily create the job table/indexes, persists
  completed results or failures, and owner-scopes polling.
- Sync generate is also not read-only: it can write valid/fallback responses to
  `EndpointCache` and can log valid Commander generations to
  `deck_learning_events`.
- Edge divergence found: `logGeneratedDeckForLearning(...)` is fired before the
  invalid-card fallback branch. If a primary generation has unresolved cards but
  no validation errors, the learning event can represent the cleaned primary
  deck while the app receives deterministic fallback.
- App `generateDeck(...)` can return a completed async `422` result as a map, so
  provider success means "reviewable preview", not "valid deck". The save gate
  is `validation.is_valid`.
- Generated-deck validation returns names/quantities, not durable `card_id`s.
  App create resolves names through `/cards/resolve/batch` and blocks unresolved
  or ambiguous rows before `POST /decks`.
- Saving generated or learned previews creates a new deck and can write learning
  telemetry (`commander_card_usage`, `deck_learning_events`) plus app activation
  events. It does not mutate deck `6`.
- Backend `POST /decks` validates create payloads with `DeckRulesService`
  `strict:false`; after save, a fresh fetch plus strict validation is still
  required before strategy or optimize claims.

Additional required adjustments:

409. Keep `/ai/generate` out of read-only audits unless using non-live tests or
     controlled fixtures.
410. Classify both async and sync generate as write-capable: jobs, cache, and
     learning events.
411. Fix or document the pre-fallback learning-event drift in
     `logGeneratedDeckForLearning(...)`.
412. Treat generated provider results as previews; `validation.is_valid`, not
     returned-map success, controls save eligibility.
413. Do not treat generate cache hits as deck freshness evidence.
414. Preserve `/cards/resolve/batch` as the name-to-identity gate before
     generated/learned save.
415. Treat learned/generated save as new-deck creation plus telemetry, never deck
     `6` mutation.
416. After generated/learned save, require fresh fetch and strict validation
     before optimizer or chat "Ajustar deck" decisions.
417. Keep raw Hermes/source refs hidden from normal learned-deck preview UI.
418. Keep strategic coherence separate from legality: every archetype still
     needs package, role, curve, win-line, recursion, ramp, draw, interaction,
     and land-plan review.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Role Summary Current Boundary Recheck

Safe evidence collected:

- Re-read the current `role_summary` runtime and contract surfaces:
  `server/routes/ai/commander-learning/index.dart`,
  `server/lib/ai/commander_learned_deck_support.dart`,
  `server/lib/ai/commander_reference_helpers.dart`,
  `server/lib/ai/commander_reference_deck_corpus_support.dart`,
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`,
  `server/doc/COMMANDER_LEARNING_API_2026-06-03.md`,
  focused server tests, `app/lib/features/decks/providers/deck_provider.dart`,
  `app/lib/features/decks/screens/deck_generate_screen.dart`, and focused app
  tests.
- Product learned-deck `role_summary` is still detail-only in
  `GET /ai/commander-learning?commander=...`. The no-commander list route
  returns safe availability summary fields and does not expose
  `win_conditions`, `role_summary`, deck payloads, card lists, or raw
  `metadata`.
- Detail mode calls
  `canonicalizeCommanderLearnedDeckMetadataWithStatus(pool, learnedDeck)` and
  both `promoted_deck.role_summary` and `recommended_deck.role_summary` use
  `_roleSummaryFromMetadata(roleMetadata)`.
- Normal canonicalization resolves names through `card_identity_bridge`,
  handles normalized aliases/split-card names, reads `card_function_tags`, and
  computes role counts from the persisted `card_list`.
- The role count model is additive across multi-tags. Lands are counted as
  `total_lands` and skipped from nonland role accumulation; nonlands can
  contribute to multiple role counts.
- Canonicalized detail responses expose
  `role_summary_source=card_list_canonicalized`; fallback responses expose
  `role_summary_source=persisted_metadata_fallback` and a safe
  `role_summary_fallback_reason`.
- Lorehold-specific overrides currently cover `Orim's Chant`,
  `Ruby Medallion`, `Scroll Rack`, `Victory Chimes`, and
  `Lorehold, the Historian`.
- `commander_reference_decks.role_summary` exists in the reference-corpus
  support path but is separate package/corpus evidence, not the same as the
  promoted learned-deck detail `role_summary`.
- App code fetches learned-deck detail and uses `recommended_deck` cards,
  validation/legality, score, source confidence, archetype, and bracket for the
  preview/save flow. No direct app rendering/parsing contract for
  `role_summary` was found by focused search.

Validation evidence:

- `cd server && dart analyze routes/ai/commander-learning/index.dart lib/ai/commander_learned_deck_support.dart lib/ai/commander_reference_helpers.dart lib/ai/commander_reference_deck_corpus_support.dart test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart test/commander_reference_deck_corpus_support_test.dart`
  - result: no issues found.
- `cd server && dart test test/commander_learned_deck_support_test.dart test/ai_generate_learning_boundary_test.dart test/api_contracts_data_map_guard_test.dart test/commander_reference_deck_corpus_support_test.dart -r expanded`
  - result: `39/39` tests passed.
- `cd app && flutter analyze lib/features/decks/providers/deck_provider.dart lib/features/decks/screens/deck_generate_screen.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart`
  - result: `33/33` tests passed.
- Focused `rg` checks found app learned-deck fetch/preview/save usage but no
  direct app `role_summary` rendering/parsing contract.

Current learning:

- Use detail-mode learned-deck `role_summary` as current runtime evidence only
  when `role_summary_source=card_list_canonicalized`.
- Treat `role_summary_source=persisted_metadata_fallback` as review-only,
  especially for Lorehold learned deck `82`, where stale persisted metadata has
  previously been observed.
- Do not interpret role counts as a one-card-one-role deck partition; they are
  additive coverage counts.
- Keep reference-corpus role summaries separate from promoted learned-deck role
  summaries in "Ajustar deck" reasoning.
- The app currently validates the learned deck through preview/save behavior,
  not through visible role-count UI.

Additional required adjustments:

391. In chat "Ajustar deck", accept learned-deck `role_summary` as current
     evidence only when detail response reports
     `role_summary_source=card_list_canonicalized`.
392. If `role_summary_source=persisted_metadata_fallback`, keep the summary in
     review, show/use the fallback reason as a blocker, and do not use it to
     justify swaps or closure.
393. Treat learned-deck role counts as additive multi-role coverage, not as an
     exclusive 100-card partition.
394. Keep reference-corpus `commander_reference_decks.role_summary` separate
     from promoted learned-deck `promoted_deck/recommended_deck.role_summary`;
     the former is package evidence, the latter is product detail evidence.
395. Preserve the list/detail boundary: no-commander `/ai/commander-learning`
     must stay safe-summary only and must not expose raw metadata or role
     counts.
396. If role counts need to appear in app UX, add a visible source label and
     fallback handling before exposing them; current app tests only prove
     preview/save behavior, not role-count display.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Deck Analysis / AI Analysis Current Boundary Recheck

Safe evidence collected:

- Re-read the current saved-deck analysis stack:
  `server/routes/decks/[id]/analysis/index.dart`,
  `server/routes/decks/[id]/ai-analysis/index.dart`,
  `server/lib/ai/functional_card_tags.dart`,
  `server/lib/ai/candidate_quality_data_support.dart`,
  `app/lib/features/decks/models/deck_analysis.dart`,
  `app/lib/features/decks/providers/deck_provider.dart`,
  `app/lib/features/decks/providers/deck_provider_support_fetch.dart`,
  `app/lib/features/decks/widgets/deck_analysis_tab.dart`,
  `app/lib/features/decks/widgets/deck_diagnostic_panel.dart`, and focused
  provider/widget/model tests.
- `GET /decks/:id/analysis` is owner-scoped and read-only in current source.
  It prefers `card_intelligence_snapshot`; when the snapshot is unavailable,
  fallback SQL aggregates functional and semantic rows per card before deck-row
  use.
- `card_intelligence_snapshot` is one-row-per-card for this purpose: current
  view SQL exposes `c.id AS id` and `c.id AS card_id` after aggregating
  function tags, semantic v2 rows, battle rules, and legalities.
- `GET /decks/:id/analysis` does not call `DeckRulesService` and does not use
  `oracle_id` / `card_identity_bridge` for singleton identity, commander
  presence, or commander color identity. Its `legality` block is therefore a
  local/basic signal only.
- `GET /decks/:id/analysis` still provides useful diagnostic data:
  composition, functional counts/samples, mana curve, color distribution,
  local legality, and `meta_analysis.suggested_adds`.
- `POST /decks/:id/ai-analysis` is owner-scoped and uses the same
  snapshot/fallback aggregate card loading pattern, but it is not read-only:
  fresh execution can call OpenAI and updates `decks.synergy_score`,
  `decks.strengths`, and `decks.weaknesses`.
- Cached `POST /ai-analysis` responses return existing summary fields with
  `cached=true`; fresh responses compute metrics, return the new summary, and
  persist it.
- Flutter `DeckAnalysisData` prefers backend `functional_tags` counts/samples
  and falls back to legacy `stats.composition`. `DeckProvider.fetchDeckAnalysis`
  caches/coalesces analysis reads and invalidates them after card mutations or
  AI-analysis refresh.
- `DeckAnalysisTab` fetches `/analysis` but can auto-trigger
  `POST /decks/:id/ai-analysis` for complete unanalyzed decks, so opening that
  tab is not guaranteed read-only in normal app usage.
- `DeckDiagnosticPanel` consumes backend analysis counts/samples when present,
  falls back to local heuristics when absent, and currently treats Commander
  `33-38` lands as the expected band.

Validation evidence:

- `cd server && dart analyze 'routes/decks/[id]/analysis/index.dart' 'routes/decks/[id]/ai-analysis/index.dart' lib/ai/functional_card_tags.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart test/functional_card_tags_test.dart`
  - result: no issues found.
- `cd server && dart test test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart test/functional_card_tags_test.dart -r expanded`
  - result: `24/24` tests passed.
- `cd app && flutter analyze lib/features/decks/models/deck_analysis.dart lib/features/decks/providers/deck_provider.dart lib/features/decks/providers/deck_provider_support_fetch.dart lib/features/decks/widgets/deck_analysis_tab.dart lib/features/decks/widgets/deck_diagnostic_panel.dart lib/features/decks/widgets/deck_details_overview_tab.dart lib/features/decks/screens/deck_details_screen.dart test/features/decks/models/deck_analysis_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart`
  - result: no issues found.
- `cd app && flutter test test/features/decks/models/deck_analysis_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_analysis_tab_test.dart test/features/decks/widgets/deck_diagnostic_panel_test.dart`
  - result: `77/77` tests passed.
- Focused `rg` checks confirmed owner scope, snapshot usage, fallback aggregate
  fields, local land formula, OpenAI key branch, `UPDATE decks` persistence,
  and absence of `DeckRulesService` / `oracle_id` / `card_identity_bridge` in
  the two route files.

Current learning:

- Use `GET /decks/:id/analysis` as the main saved-deck functional diagnostic
  surface for Lorehold deck `6`, especially for ramp/draw/removal/wipe counts
  and samples.
- Do not use `GET /analysis.legality.is_valid` as final legal/coherence truth.
  Strict validation, identity bridge, learned/reference package evidence, and
  optimize/preview approval remain higher priority.
- Do not run live `POST /decks/:id/ai-analysis` as read-only evidence. It is a
  persisted summary route and can call OpenAI when configured.
- Treat `DeckDiagnosticPanel` as a diagnostic UI, not swap authority. It is
  coherent when it consumes backend analysis first and local heuristics only as
  fallback.
- Treat `meta_analysis.suggested_adds` as advisory only because textual
  `meta_decks` overlap is not bridge-backed learned/reference truth.

Additional required adjustments:

383. Keep `GET /decks/:id/analysis` as supporting diagnosis, not final legality
     or construction authority.
384. Keep `POST /decks/:id/ai-analysis` out of read-only deck `6` audits; it
     can persist summary fields and may call OpenAI.
385. If the product needs a guaranteed read-only analysis view, separate
     `DeckAnalysisTab` functional fetch from its auto `POST /ai-analysis`
     behavior.
386. Preserve backend functional-tag priority in the app: backend
     `functional_tags` counts/samples first, local heuristics only as fallback.
387. Reconcile `GET /analysis` land warning formula
     `(31 + avgCmc * 2.5).round()` with the Commander `33-38` band used by
     `ai-analysis` and `DeckDiagnosticPanel`, or label it explicitly generic.
388. Keep `meta_analysis.suggested_adds` advisory-only until reconciled through
     `card_identity_bridge`, learned/reference package truth, and strict
     validation.
389. Add true non-live handler tests for `GET /analysis` and
     `POST /ai-analysis` cached/fresh/error/status shapes; current source and
     helper/widget coverage is strong but not full handler execution proof.
390. For chat "Ajustar deck", use `/analysis` and `/ai-analysis` only as
     explanation; actual swaps still require fresh deck fetch, identity and
     legality checks, learned/reference package review, optimize or preview,
     strict validation, and explicit approval.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.

## Saved-Deck Recommendations Current Contract Recheck

Safe evidence collected:

- Re-read `server/routes/decks/[id]/recommendations/index.dart`,
  `server/lib/deck_recommendations_fallback_support.dart`,
  `server/lib/deck_recommendations_advisory_support.dart`,
  `server/lib/deck_recommendations_power_level_support.dart`,
  `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, and the focused recommendation
  tests/guards.
- Current route remains owner-scoped by `deck_id + user_id` before reading deck
  rows.
- Current route prefers `card_intelligence_snapshot` when present and otherwise
  uses per-card subqueries for `card_function_tags` and
  `card_semantic_tags_v2`, so the inspected deck-card read path does not join
  raw multi-row tag tables directly into deck rows.
- `_findCardsForCategory(...)` is DB-backed, role/tag/legal/color-aware, uses
  `EXISTS` predicates for functional/semantic tags, filters candidates by
  `cards.color_identity <@ commander/observed deck colors`, excludes cards
  already in the deck, groups by card name, and does not use fixed staple
  literals or rarity as impact proxy.
- No-key fallback branch logic is extracted into
  `buildHeuristicRecommendationsForDeck(...)` with injectable
  `RecommendationCandidateFinder` and `RecommendationTrendFinder`. The route
  still owns the live `Pool` deck read, candidate lookup, and EDHREC trend
  callback.
- OpenAI parsed, malformed, and HTTP-error payloads are normalized through
  `buildOpenAiRecommendationsAdvisoryBody(...)` /
  `buildOpenAiRecommendationsErrorBody(...)`, set `source=openai`,
  `advisory=true`, and include `recommendation_validation.status =
  unvalidated_ai_text`.
- Current heuristic fallback response is different: it returns
  `source=heuristic`, `message`, `statistics`, `trending`,
  `candidate_color_identity`, and `color_identity_source`, but
  `server/test/deck_recommendations_fallback_support_test.dart` explicitly
  asserts that the fallback body does not contain `recommendation_validation`.
  It also does not set a top-level `advisory` key in the helper body.
- Current API contract row says the route response fields include
  `advisory` and `recommendation_validation`, then later clarifies OpenAI
  paths. That wording is too broad for the current heuristic fallback unless
  the product intentionally adds the same advisory envelope to fallback output.

Validation evidence:

- `cd server && dart analyze lib/deck_recommendations_advisory_support.dart lib/deck_recommendations_fallback_support.dart lib/deck_recommendations_power_level_support.dart 'routes/decks/[id]/recommendations/index.dart' lib/ai/edhrec_trend_service.dart lib/ai/optimization_functional_roles.dart test/deck_recommendations_advisory_support_test.dart test/deck_recommendations_fallback_support_test.dart test/deck_recommendations_power_level_support_test.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart`
  - result: no issues found.
- `cd server && dart test test/deck_recommendations_advisory_support_test.dart test/deck_recommendations_fallback_support_test.dart test/deck_recommendations_power_level_support_test.dart test/experimental_deck_ai_authorization_source_test.dart test/api_contracts_data_map_guard_test.dart -r expanded`
  - result: `28/28` tests passed.
- `rg -n "advisory|recommendation_validation|source|message" server/lib/deck_recommendations_fallback_support.dart server/test/deck_recommendations_fallback_support_test.dart server/doc/API_CONTRACTS_AND_DATA_MAP.md`
  - result: fallback helper/test evidence shows `source` and `message`, test
    asserts no `recommendation_validation`, while the API row still mentions
    `advisory`/`recommendation_validation` broadly.

Current learning:

- Item `233` is reduced but not closed. Helper-level and source-guard evidence
  now covers no-key fallback body shape, candidate-color filtering, EDHREC trend
  promotion, OpenAI advisory/error envelope, and power-level bracket `1..4`.
- The remaining real gap is handler-level execution without live DB/OpenAI:
  no-key route path, OpenAI HTTP-error route path, and Pool-backed
  candidate/trend callbacks are still not proven through a fake request/context.
- Saved-deck recommendations remain advisory suggestions-for-review. They must
  not drive Lorehold deck `6` swaps or any "Ajustar deck" action without fresh
  fetch, strict validation, learned/reference package review, optimize/preview,
  and explicit user approval.
- The current heuristic-vs-OpenAI envelope mismatch is a contract clarity issue:
  either document fallback as a distinct heuristic shape or add the same
  `advisory`/`recommendation_validation` envelope to fallback later.

Additional required adjustments:

376. Keep item `233` open only for true non-live Dart Frog handler execution of
     `/decks/:id/recommendations`, including no-key fallback, real OpenAI HTTP
     error routing, and Pool-backed candidate/trend callback behavior.
377. Treat helper-level recommendation tests as strong evidence for branch
     logic, but not as proof that route context, `Pool` reads, and response
     status wiring execute end-to-end.
378. Clarify or align the recommendation response contract: current heuristic
     fallback lacks `recommendation_validation` and top-level `advisory`, while
     OpenAI paths include both.
379. Keep `/decks/:id/recommendations` advisory-only for chat "Ajustar deck";
     never use this route as standalone construction proof or swap authority.
380. Preserve the no-fanout source pattern for recommendations: use
     `card_intelligence_snapshot` or per-card `EXISTS`/subquery aggregation,
     not raw `deck_cards -> card_function_tags/card_semantic_tags_v2` joins.
381. Preserve Commander color identity as the candidate filter source when a
     commander row exists; observed deck colors are only fallback provenance.
382. If fallback recommendations become user-actionable UI, require the same
     before-action checklist as OpenAI output: identity/legality check,
     learned/reference package review, optimize or preview, strict validation,
     and explicit approval.

## Optimize / Ajustar Deck Boundary Recheck

Timestamp: 2026-06-20 00:03 -03.

Current backend learning:

- `/ai/optimize` is owner-scoped and prefers `card_intelligence_snapshot`; it
  builds deck signatures from `card_id:quantity:condition`.
- The route is not read-only: success can write optimize cache and preferences,
  and the common response path writes `optimization_analysis_logs` plus ML
  feedback when deck/user context exists. Fallback telemetry can also be
  persisted.
- The route returns preview suggestions and diagnostics; it does not mutate
  `deck_cards`.
- Backend safety gates include unsafe-swap filtering, color/bracket checks,
  virtual post-analysis, final validation score/verdict gate, and optional
  semantic v2 partial enforcement.
- Important cache divergence: `saveOptimizeCache(...)` happens before
  `respondWithOptimizeTelemetry(...)` attaches `swap_integrity`, and cache hits
  return `buildCachedOptimizeResponse(...)` directly. A cached detailed response
  can therefore reach the app without `expectedDeckSignature`; the cache key
  protects generation-time state but not apply-time drift between preview and
  confirmation.

Current app learning:

- `requestOptimizePreview(...)` validates `swap_integrity` when it exists, but
  missing integrity is accepted.
- `buildOptimizeApplyPlan(...)` routes complete mode to `addBulk`, detailed
  swaps to `applyOptimizationWithIds(...)`, and name-only swaps to
  `applyOptimization(...)`.
- `applyOptimizationWithIds(...)` rejects stale signatures before `PUT`,
  including condition-only drift, and refilters additions outside commander
  identity.
- Name-only apply is weaker because it resolves current names but has no
  expected deck signature.
- `PUT` apply calls `/decks/:id/validate` after persistence; tests prove a
  failed post-save validation returns `false` and refreshes details, but the
  mutation was already attempted.
- Complete-mode `addBulk` uses `POST /decks/:id/cards/bulk`; the backend route
  owner-scopes and validates with `DeckRulesService(strict:false)` inside the
  transaction before delete/reinsert, but the app does not run the same
  explicit post-save `/validate` step after bulk.

Validation evidence:

- Server optimize analyze: no issues found.
- Server optimize tests:
  `dart test test/ai_optimize_authorization_source_test.dart test/ai_optimize_semantic_enforcement_route_contract_test.dart test/optimize_route_final_gate_support_test.dart test/optimize_cache_support_test.dart test/optimization_quality_gate_test.dart test/optimize_route_request_support_test.dart test/optimize_runtime_support_test.dart test/optimize_route_async_support_test.dart test/optimize_payload_support_test.dart -r expanded`
  - result: `78/78` tests passed.
- App optimize analyze: no issues found.
- App optimize tests:
  `flutter test test/features/decks/widgets/deck_optimize_flow_support_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart`
  - result: `97/97` tests passed.
- Bulk route/support analyze: no issues found.
- Bulk support tests:
  `dart test test/deck_cards_bulk_support_test.dart -r expanded`
  - result: `3/3` tests passed.

Required adjustments:

397. Do not run live `/ai/optimize` during read-only Lorehold/deck `6` audits;
     it is write-capable through cache, preferences, logs, telemetry, and ML
     feedback.
398. Treat `/ai/optimize` as preview/suggestion only; no deck `6` swap without
     explicit user approval.
399. Prefer detailed card-id swaps with valid `swap_integrity`; name-only apply
     is review-only until a fresh signature path exists.
400. Fix or document the cache-hit integrity gap by saving after integrity is
     attached or recomputing integrity in the cache-hit response.
401. If cached/name-only optimize output lacks `expectedDeckSignature`, require
     fresh deck fetch and fresh preview before mutation.
402. Add pre-mutation or transactional validation/rollback for optimize apply;
     current strict validation happens after `PUT`.
403. Give complete-mode `addBulk` the same explicit post-apply strict
     validation/reporting contract as the `PUT` apply path, or surface backend
     bulk validation clearly.
404. Keep semantic v2 optimize enforcement as additive safety only.
405. Treat `rebuild_guided` as draft/repair workflow, not automatic replacement.
406. Preserve physical condition codes in signatures/cache keys.
407. Force fresh optimize preview when strategy context changes outside
     deckSignature/intensity/bracket/keepTheme.
408. After any applied optimize/bulk change, require fresh details plus strict
     validation; failed validation means no success claim.

Scope guard:

- No PostgreSQL write, live route call, OpenAI call, deck `6` mutation, deck
  swap, code edit, battle-engine edit, commit, or push was performed.
