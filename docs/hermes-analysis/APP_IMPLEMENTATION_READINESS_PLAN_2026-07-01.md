# ManaLoom App Implementation Readiness Plan - 2026-07-01

Status: `launch_readiness_plan_phase1_started`.

Scope:

- Flutter app deck experience.
- Backend API contracts for deck analysis, generation, optimize/rebuild,
  Commander deckbuilding diagnostics, and battle readiness.
- PostgreSQL remains product truth. Hermes/XMage artifacts are internal
  evidence unless explicitly converted into safe app-facing summaries.

This plan is intentionally ordered for a two-week launch window. It avoids
new product surfaces that depend on raw Hermes, raw XMage, or unverified battle
rules.

Implementation update:

- First app slice started on 2026-07-01.
- `/decks/:id/analysis` now emits app-facing `readiness`,
  `battle_readiness`, and `understanding_summary` aggregates.
- Flutter now has typed models for those three aggregates and the deck
  diagnostic panel renders a conservative launch-readiness strip when the
  backend provides the contract.
- Live backend contract assertions were updated, but the live test remains
  opt-in because it creates auth/deck records against the configured backend.

## Current Structure Snapshot

Validated locally:

- `cd server && dart test test/commander_deckbuilding_contract_support_test.dart test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart`
  passed `18` tests.
- `cd app && flutter analyze` returned `No issues found`.

Current app/backend shape:

- The Flutter app already has deck details, deck generation, optimize/rebuild,
  deck analysis, import, and recommendation flows.
- Before the first implementation slice, `DeckAnalysisData` modeled only:
  - deck id;
  - format;
  - legacy composition counts;
  - functional tag counts, samples, source, and coverage.
- It now also models:
  - deck readiness;
  - deck-level battle readiness;
  - deck understanding/coverage summary.
- `/decks/:id/analysis`, `/decks/:id/ai-analysis`,
  `/decks/:id/recommendations`, `/ai/weakness-analysis`,
  `/ai/optimize`, `/ai/rebuild`, and `/ai/generate` already consume or produce
  useful intelligence.
- `/ai/generate` already emits `deckbuilding_contract`, including gates,
  blockers, warnings, next actions, source lanes, planning flow, and
  card-source samples.
- The Flutter generation screen currently treats most of that response as raw
  maps and does not have a first-class model/UI for the deckbuilding contract.

Current data/evidence shape:

- `card_intelligence_snapshot` is the safe one-row-per-card surface for app
  consumption.
- Raw `card_function_tags`, `card_semantic_tags_v2`, and `card_battle_rules`
  are multi-row sources and must be aggregated before deck-card joins.
- Current generated all-card battle readiness has `34331` known cards,
  `3303` cards with any rule in snapshot, and `1923` with verified rules.
- The global battle gap is still large, but the XMage-authoritative queue has
  strong source coverage: `27445/27759` Commander-legal battle-gap identities
  resolved to local XMage source, with `314` missing-source exceptions.
- PG283-PG300 promoted multiple exact adapter waves and the current blocker is
  no longer "does XMage know the card"; it is "does ManaLoom have the matching
  adapter/runtime and app-facing confidence contract."

Current Commander/deckbuilding shape:

- Global Commander deck contract audit status is `action_required`.
- Product/user Commander scope has `16` likely user decks; `6` are
  `structure_ready` and `10` need repair or exclusion.
- Global strategy matrix status is `pass`, with `10` commanders considered:
  - ready for strategy matrix: Lorehold, Kaalia, Kefka, Y'shtola;
  - source missing before strategy matrix: Sauron, Valgavoth, Animar,
    Jin-Gitaxias // The Great Synthesis;
  - blocked before promotion: Auntie Ool and Jin-Gitaxias, Core Augur paths.
- Lorehold deck `607` is the current protected champion snapshot. It should be
  exposed as "current best tested Lorehold shell", not as a universal template
  for all commanders.

## Must Fix Before New App Features

### 1. App-Facing DTOs For Intelligence

Problem:

- The backend already emits useful contracts, but the app often treats them as
  loose `Map<String, dynamic>`.
- That makes UI work fragile and encourages direct use of internal field names.

Fix:

- Add typed Flutter models for:
  - `DeckbuildingContractData`;
  - `DeckbuildingGateStatus`;
  - `DeckSourceLaneSummary`;
  - `CardSourceSample`;
  - `BattleReadinessSummary`;
  - `CardUnderstandingStatus`.

Acceptance:

- App code never reads `deckbuilding_contract['some_key']` directly outside
  parsing/model files.
- Unknown fields are ignored safely.
- Missing contract returns a clear "diagnostics unavailable" state.

### 2. Safe Backend App Contract

Problem:

- `/ai/generate` exposes `deckbuilding_contract`, but deck details and analysis
  do not yet provide one consolidated app-ready intelligence payload for an
  existing deck.

Fix:

- Add or extend a backend endpoint with a stable app contract:
  - preferred: extend `/decks/:id/analysis` with `commander_contract`,
    `battle_readiness`, and `understanding_summary`;
  - alternative: add `/decks/:id/intelligence`.

The payload must use only:

- `card_intelligence_snapshot`;
- aggregated role/source summaries;
- generated contract summaries;
- battle readiness labels derived from trusted/verified rule status.

Do not expose:

- raw Hermes paths;
- raw SQLite fields;
- `effect_json`;
- `logical_rule_key`;
- `oracle_hash`;
- `xmage_*_review_v1`;
- generated/needs_review as executable truth.

Acceptance:

- One endpoint can hydrate the deck analysis page with all app-facing
  intelligence.
- It returns stable labels and counts even when internal battle metadata is
  incomplete.

### 3. Deck Hygiene Gate For Product Decks

Problem:

- Current global Commander audit reports `10` user-product decks that need
  repair or exclusion before global promotion.
- Showing advanced strategy/battle confidence for incomplete one-card decks
  will confuse users and pollute launch screenshots.

Fix:

- Add an app-visible deck readiness gate:
  - `valid_commander_deck`;
  - `incomplete_deck`;
  - `needs_commander`;
  - `illegal_card`;
  - `unresolved_card`;
  - `not_commander_scope`.

Acceptance:

- Advanced Commander intelligence is hidden or downgraded for incomplete decks.
- User sees practical repair actions first.

### 4. Battle Readiness Vocabulary

Problem:

- Battle work is strong internally, but the coverage is not universal.
- "Battle ready" can be misread as "all Magic rules simulated perfectly."

Fix:

Use four app-facing labels:

- `verified_simulation`: trusted/verified executable behavior exists.
- `partial_simulation`: some trusted behavior exists, but not complete.
- `rules_text_only`: card understood for identity/deckbuilding, not simulated.
- `pending_adapter`: XMage/source exists but ManaLoom adapter/runtime is not
  executable yet.

Acceptance:

- No user-facing screen says or implies "100% simulated" globally.
- Battle labels are explanatory and conservative.

### 5. Feature Flags / Progressive Exposure

Problem:

- Deckbuilding, battle, and source provenance are not equally mature across all
  decks and commanders.

Fix:

Add feature flags or server-provided capabilities for:

- `show_deckbuilding_contract`;
- `show_battle_readiness`;
- `show_source_provenance`;
- `show_strategy_matrix_beta`;
- `show_replay_evidence_beta`.

Acceptance:

- Launch can expose safe intelligence broadly and keep deeper battle/replay
  evidence beta/admin-only.

## What To Implement In The App

### Phase 0 - Contract Freeze And QA

Goal:

- Lock the app-facing contract before adding UI.

Tasks:

1. Define the final JSON schema for `/decks/:id/analysis` or
   `/decks/:id/intelligence`.
2. Add backend tests that prove no raw multi-row fanout reaches deck rows.
3. Add parser tests in Flutter for all new models.
4. Add fixture payloads for:
   - complete Commander deck;
   - incomplete deck;
   - no battle coverage;
   - partial battle coverage;
   - ready-for-battle-gate generated deck.

Ship criteria:

- Backend and Flutter tests pass.
- No UI implementation depends on raw maps.

### Phase 1 - Deck Readiness Panel

Goal:

- Make the deck page immediately useful and honest.

UI:

- Top card/panel in deck details:
  - legality and structure status;
  - commander status;
  - card count;
  - unresolved/illegal cards;
  - next repair action.

Backend data:

- Existing validation plus product deck audit concepts.

Why first:

- It prevents users from seeing advanced advice on invalid or incomplete decks.

### Phase 2 - Functional Role Intelligence

Goal:

- Strengthen the analysis tab using data already modeled in the app.

UI:

- Improve the existing functional buckets:
  - ramp;
  - draw/selection;
  - removal;
  - board wipes;
  - protection;
  - tutors;
  - recursion;
  - win conditions;
  - engines/payoffs.

Backend data:

- `card_intelligence_snapshot.function_tag_details`.
- Existing `DeckFunctionalTags` model.

Ship criteria:

- Every bucket has count, sample cards, coverage, and source label.
- Missing coverage is shown as "not classified yet", not as zero value.

### Phase 3 - Commander Plan / Deckbuilding Contract

Goal:

- Turn the internal deckbuilding contract into a user-facing plan.

UI:

- Add a "Plano do comandante" section:
  - commander plan sentence;
  - power bracket target;
  - primary/backup win lines;
  - role counts versus targets;
  - known risks;
  - next actions.

Backend data:

- `deckbuilding_contract` from generation.
- For existing decks, compute or return a summarized `commander_contract`.

Ship criteria:

- If reference/source lanes are missing, UI says what is missing.
- Source lanes are human-readable, not internal system names.

### Phase 4 - Recommendation Explanation

Goal:

- Make optimize/rebuild feel trustworthy.

UI:

- Each add/cut suggestion shows:
  - role gained;
  - role removed;
  - same-lane or cross-lane;
  - source reason;
  - legality/bracket warning;
  - confidence/caveat.

Backend data:

- Existing optimize diagnostics, quality gate warnings, source provenance, and
  functional tags.

Ship criteria:

- No suggestion can be applied without preview.
- Rebuild remains draft-first.

### Phase 5 - Battle Readiness Badges

Goal:

- Surface battle/rule coverage without overpromising.

UI:

- Per-card badges in deck/card list:
  - verified simulation;
  - partial simulation;
  - rules text only;
  - pending adapter.
- Deck-level summary:
  - verified cards;
  - partial cards;
  - pending cards;
  - not relevant/no rules text.

Backend data:

- Aggregated `card_intelligence_snapshot.battle_rules` fields.
- Do not expose raw `effect_json` or hashes.

Ship criteria:

- User can understand why simulation may be unavailable for a card.
- No internal identifiers are displayed.

### Phase 6 - Strategy Matrix Beta

Goal:

- Expose commander/deck strategy comparison only where evidence is mature.

Initial scope:

- Lorehold only, or admin/beta users only.

UI:

- Champion/current shell.
- Challenger status.
- Gates passed/failed.
- Battle-gate result summary.
- "Why not promoted" explanation.

Rules:

- Do not show structure-only ranking as final deck quality.
- Do not treat forced-access tests as promotion evidence.

### Phase 7 - Replay / Battle Evidence Beta

Goal:

- Use battle traces for trust, not as the default product surface.

UI:

- Optional evidence drawer:
  - card was drawn/cast/used;
  - matchup result;
  - seed window;
  - reason a candidate failed.

Initial scope:

- Admin/beta only.

Ship criteria:

- No raw event JSON in normal UI.
- Evidence is summarized in product language.

## Implementation Order For Two-Week Launch

Week 1:

1. Freeze `/decks/:id/intelligence` or extended `/decks/:id/analysis`.
2. Add Flutter models for intelligence/contract/battle labels.
3. Build deck readiness panel.
4. Expand functional analysis buckets and copy.
5. Add tests for parsers and backend contract payload.

Week 2:

1. Add commander plan section.
2. Add recommendation explanation cards.
3. Add battle readiness badges with conservative labels.
4. Hide beta strategy/replay behind feature flags.
5. Run release QA on:
   - complete Lorehold deck;
   - incomplete user deck;
   - commander with missing source lane;
   - deck with partial battle coverage;
   - optimize/rebuild preview.

## Do Not Build Before Launch

- Full public replay explorer.
- Full XMage coverage screen.
- Raw battle-rule inspector.
- Automatic global "best deck" promotion.
- Universal "all cards simulated" claim.
- UI that exposes generated/needs_review rules as trusted behavior.
- One-off Lorehold logic hardcoded as the global Commander experience.

## Launch Positioning

Use this product promise:

> ManaLoom understands your deck structure, roles, commander plan, legality, and
> rule-readiness level. It gives safe recommendations with explainable evidence,
> and simulates verified card behavior where the runtime is ready.

Avoid this promise:

> ManaLoom simulates every Magic card perfectly.
