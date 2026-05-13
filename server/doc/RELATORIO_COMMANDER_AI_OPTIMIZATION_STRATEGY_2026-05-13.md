# Commander AI Optimization Strategy — 2026-05-13

## Executive Summary

Outcome: **PASS WITH RISKS**.

ManaLoom now has a credible Commander AI foundation for controlled expansion, but the next step must be a small, measured architecture increment rather than a mass rollout. The strongest current proof is Lorehold v5: deterministic reference-guided generation with `fallback 0/5`, timeout fallback `0/5`, off-color generated/repair `0/5`, commander in 99 `0/5`, core coverage `26/26`, top40 overlap average `36.0`, and p95 `1648ms`. That proves the product direction: DB-backed reference evidence plus deterministic assembly can outperform long model prompts for exact commanders with strong corpus.

The main strategic risk is that the v5 win is not yet generalized. Exact profiles and card stats exist for more commanders, but only Lorehold has the strongest corpus-backed deterministic path. Optimize has a separate deterministic-first engine with candidate-quality signals, intensity targets, and quality gates, but it does not yet reuse the same commander reference packages as generate. The app already handles async generate/optimize, preview, partial apply, rebuild-guided outcomes, and aggregate aggressive diagnostics, but explainability is still mostly operational rather than user-trust oriented.

Top 5 recommended ideas:

1. **P1 — Commander readiness gate and scorecard before mini-batch expansion.**
2. **P1 — Shared Commander Candidate Pool service for generate and optimize.**
3. **P1 — Role/package coverage evaluator per commander and per result.**
4. **P1 — Commander-aware deterministic fallback selection for non-corpus exact profiles.**
5. **P2 — App explainability layer for generation/optimization evidence and apply mode.**

Top 5 rejected ideas:

1. **Reject — Mass corpus rollout without per-commander readiness gates.**
2. **Reject — Runtime scraping of public decklists or copying raw lists into prompts.**
3. **Reject — Increasing OpenAI timeout again as the primary quality strategy.**
4. **Reject — Exposing raw diagnostic payloads, raw decklists, or technical buckets to users.**
5. **Reject — Bypassing legal/color/bracket validation because a reference source says a card is good.**

No web research was used for this audit. The recommendations are based on repository docs, contracts, code inspection, and existing local/public runtime reports.

## Current Flow Map

### Generate: from prompt to final deck

Evidence: `server/routes/ai/generate/index.dart`, `server/lib/ai_generate_job.dart`, `server/lib/ai_generate_performance_support.dart`, `server/lib/generated_deck_validation_service.dart`, `server/lib/deck_rules_service.dart`, `server/lib/import_card_lookup_service.dart`, `server/lib/ai/commander_reference_*`, `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, and the Commander Reference reports.

Current decision tree:

1. App `DeckGenerateScreen` collects prompt, format, optional `commander_name` for Commander/Brawl, and calls provider support.
2. `deck_provider_support_generation.dart` sends `POST /ai/generate` with `async=true` by default and preserves `commander_name`; it falls back to sync only when async/polling is unsupported, not for normal job failures.
3. Backend async opt-in creates an `ai_generate_jobs` row through `AiGenerateJobStore` and returns `202` with `job_id`, `poll_url`, `poll_interval_ms`, and progress metadata.
4. The async executor runs the same sync contract internally.
5. The sync executor normalizes prompt/format/bracket/commander context and checks cache.
6. If `commander_name` matches an exact usable Commander Reference Profile, the backend loads:
   - `commander_reference_profiles`;
   - `commander_reference_card_stats` with unresolved rows excluded;
   - `commander_reference_deck_analysis`/corpus guidance when available.
7. If an exact profile has strong corpus evidence, Lorehold v5 now takes the deterministic reference-guided primary path via `buildDeterministicReferenceDeck`, validates normally, preserves diagnostics, and does not mark this primary path as fallback.
8. If no strong deterministic exact path is selected, the backend builds prompt guidance from exact profile/card stats/corpus or lower-confidence archetype reuse, chooses OpenAI timeout with `selectAiGenerateOpenAiTimeout`, and calls the configured model.
9. OpenAI output is parsed, optionally pre-filtered for exact reference profile color identity, repaired/fill-completed when needed, and validated by `GeneratedDeckValidationService` and `DeckRulesService`.
10. On missing API key, timeout, auth/API errors, or validation failure, the endpoint attempts deterministic fallback when possible.
11. Final response returns `generated_deck`, `validation`, optional `diagnostics`, `warnings`, `cache`, and `timings`. App preview/save uses `generated_deck` plus `validation` as source of truth.

### Optimize: from deck to recommendations/apply

Evidence: `server/routes/ai/optimize/index.dart`, `server/lib/ai/optimize_runtime_support.dart`, `server/lib/ai/optimization_quality_gate.dart`, `server/lib/ai/rebuild_guided_service.dart`, `app/lib/features/decks/providers/deck_provider.dart`, `deck_provider_support_ai.dart`, and optimize widgets.

Current decision tree:

1. App `DeckDetailsScreen` lets the user choose intensity: `light`, `focused`, `aggressive`, or `rebuild`.
2. Provider sends `POST /ai/optimize` with `deck_id`, archetype, bracket, `keep_theme`, and `intensity`.
3. Backend resolves intensity targets: light `3-5`, focused `6-10`, aggressive `10-20`, rebuild as guided rebuild outcome.
4. Aggressive and complete flows may return `202`; app polls `/ai/optimize/jobs/:id`.
5. Deterministic optimize builds removal/replacement candidates from deck/card context, role scores, function tags, commander synergy, meta signals, bracket/budget advisory signals, and rejection penalties.
6. `optimization_quality_gate.dart` filters unsafe swaps by role preservation, curve/mana/land safety, color identity, and archetype critical roles.
7. Final optimization validation rejects weak results; 422 quality outcomes can instruct the app to use rebuild-guided flow.
8. If deterministic suggestions are empty, the backend can attempt an AI fallback, but quality gates still control final output.
9. App displays preview with additions/removals, reasoning, intensity labels, quality warnings, and aggregate aggressive diagnostics; user can deselect individual swaps before applying.
10. If rebuild is selected or forced, app calls `/ai/rebuild`, which creates a draft clone rather than destructively applying a full rebuild.

## Data Sources And Trust Boundaries

DB-backed and trusted as operational evidence:

- `cards`, `card_legalities`, `sets`: canonical local card identity, legality, color identity, printings.
- `decks`, `deck_cards`: user deck state for optimize, validation, rebuild.
- `commander_reference_profiles`: curated commander profile JSON with confidence, themes, role targets, expected packages, avoid patterns.
- `commander_reference_card_stats`: normalized package-card guidance; only resolved/non-unresolved rows should guide runtime.
- `commander_reference_decks`, `commander_reference_deck_cards`, `commander_reference_deck_analysis`: accepted corpus deck structure and aggregates; consumed as aggregate evidence, not copied raw lists.
- `card_function_tags`, `card_role_scores`, `commander_card_synergy`, `optimize_rejection_penalties`, `optimize_candidate_quality_summary`: optimize candidate-quality metadata; advisory only.
- `meta_decks`, `card_meta_insights`: meta/card signals; useful but not allowed to bypass legality, color, bracket, or validation.
- `ai_generate_jobs`, optimize job store/cache tables: async lifecycle and cache support.

Model-driven or lower-trust sources:

- OpenAI completions for non-deterministic generate and optional optimize fallback.
- Prompt/theme interpretation and archetype matching when no exact profile exists.
- Approximate user prompt intent not anchored by a selected commander.
- Meta/archetype reuse from similar commanders; useful when color identity and theme tokens match, but explicitly lower confidence than exact profiles.

Trust boundaries:

- Backend owns all external API/AI orchestration. Mobile must not call OpenAI, Scryfall, EDHREC, MTGJSON, or similar sources directly.
- Raw prompts, tokens, JWTs, database URLs, DSNs, API keys, raw decklists, and raw Authorization headers must not appear in docs/logs/diagnostics.
- Reference corpus must remain aggregate and sanitized. The product should continue using decks as statistical/structural evidence, not copied decklists.
- Candidate-quality and profile metadata are advisory. `DeckRulesService`, card legality, color identity, singleton checks, bracket policy, and final validation remain authoritative.

## Generate Quality Audit

The generate path has improved materially. Earlier corpus/profile attempts suffered from timeout fallback, off-color repair, and insufficient overlap. Lorehold v5 solved the target case by moving exact profile plus strong corpus to a deterministic primary path. This is the best-quality architecture pattern currently proven in the repository.

What is deterministic:

- Async job creation/polling lifecycle.
- Cache key normalization and prompt/cache policy versioning.
- Exact profile/card stats/corpus loading and confidence gates.
- Deterministic reference deck construction for strong exact corpus.
- Off-color pre-filtering for exact reference generated candidates.
- Fallback deck construction from profile/stats/corpus packages and basic lands.
- Validation, singleton, color identity, legalities, commander preservation, and deck size repair.

What is model-driven:

- OpenAI deck construction when deterministic exact corpus path is not selected.
- Interpretation of broad prompts without a selected commander.
- Lower-confidence archetype reuse prompt guidance when no exact profile exists.
- Any card choice inferred from model knowledge rather than DB-backed candidates.

Where illegal/off-color/off-theme suggestions can enter:

- OpenAI can infer off-color cards from generic Commander/miracle/topdeck knowledge.
- Archetype reuse can overfit a source commander if color/theme compatibility is too permissive.
- Profile/card-stat/corpus data could become polluted by a bad apply if runner gates regress.
- Fallback can become off-theme if it fills too much from generic lands or weak packages.
- App users can submit a vague prompt without `commander_name`, making commander preservation impossible.

What prevents bad suggestions today:

- Corpus apply gates require resolved commander, exactly one commander, 99 main cards, no unresolved cards, no off-color cards, and no singleton violations.
- `commander_reference_card_stats` excludes unresolved rows from runtime guidance.
- Exact profiles force commander, role targets, identity, and avoid patterns.
- v4/v5 exact-profile pre-validation filters generated candidates against commander identity.
- `GeneratedDeckValidationService` and `DeckRulesService` enforce final validation.
- Lorehold v5 uses deterministic reference-guided primary path and normal validation.

Gaps:

- Strong deterministic path is proven for Lorehold only; exact profiles without corpus still rely more on model or weaker fallback.
- Metrics show top40/core coverage for Lorehold, but expansion decisions need a standardized readiness score per commander.
- Similar-commander reuse exists, but there is no shared evidence object consumed consistently by generate and optimize.
- App preview surfaces diagnostics lightly; it does not yet explain role/package coverage in user language.

## Optimize Quality Audit

Optimize differs from generate in that it starts from an existing deck and should preserve user intent, card ownership context, and deck identity. Its deterministic-first architecture is appropriate: fewer changes, high safety, and explainable rejection are better than broad model rewrites.

Current strengths:

- Intensity is explicit and app-facing: light/focused/aggressive/rebuild.
- Aggressive candidate quality has DB-backed tags/scores/synergy/rejection metadata.
- Quality gate remains after candidate ranking and can reduce scope or safe no-op.
- App handles sync `200`, async `202`, quality `422`, failed job quality errors, and rebuild-guided outcomes.
- Preview supports partial selection/deselection before apply.

Current weaknesses:

- Generate reference packages and optimize candidate pools are parallel worlds. Optimize does not consistently reuse exact commander profile packages, corpus core/theme/support, or role coverage expectations.
- Aggressive diagnostics are operationally useful but not always translated into an actionable user choice.
- Light tune-up vs full rebuild is technically present but not enough of a product narrative: users need to know why swaps are safe, why a full rebuild was recommended, and what identity will be preserved.
- App does not clearly show apply mode (`addBulk`, `applyWithIds`, `applyByNames`, `rebuild`) or why that mode was chosen.

Where logic should be shared:

- Commander candidate evidence: exact profile, stats, corpus packages, archetype reuse, color identity, role tags, and confidence should be one backend support object usable by both generate and optimize.
- Role/package coverage evaluator should be shared by generated decks, optimized results, and rebuild drafts.
- Card legality/color identity/name resolution should remain centralized through existing validation and import lookup services.
- Cache/version metadata should be centralized enough that prompt/policy-only changes can invalidate stale AI responses safely.

## Rebuild/Repair/Fallback Audit

Generate fallback today is a cascade: no API key, timeout, OpenAI auth/API failure, invalid/failed validation, or final fallback can trigger deterministic construction. For exact strong corpus, Lorehold v5 changes the framing: deterministic is not fallback; it is the primary path.

Fallback selection can be more commander-aware by:

- Using exact profile/card stats/corpus packages first whenever confidence is sufficient.
- Ranking candidates by role/package gaps rather than only package priority and score.
- Using similar-commander evidence only after identity/theme compatibility and with lower confidence labels.
- Recording fallback reason and coverage deltas in sanitized diagnostics for QA.
- Avoiding generic model retry when a deterministic package can satisfy role gaps faster and more safely.

Rebuild-guided path:

- Optimize returns `mode=rebuild_guided`, `outcome_code=rebuild_guided`, and `next_action` when micro-swaps are unsafe.
- App treats this as a normal AI outcome and can call `/ai/rebuild`.
- `/ai/rebuild` supports draft clone/preview semantics and should remain non-destructive.

Repair risk:

- Repair is necessary for safety but should not hide quality problems. The v3/v4 Lorehold evidence shows why counting off-color repair separately matters: a deck can validate while still exposing that model output was unsafe before repair.
- Expansion gates should continue tracking generated off-color and repaired off-color separately.

## Metrics And Observability Gaps

Current useful metrics:

- Generate: HTTP status, `validation.is_valid`, commander preservation, main quantity, profile/stats/corpus used, fallback warnings, timeout budget, p50/p95, top40 overlap, core coverage.
- Corpus: accepted/rejected deck count, unresolved/off-color/singleton counts, average role counts, package counts.
- Optimize: intensity target/returned swaps, aggressive candidates analyzed, pairs generated/evaluated, rejection buckets, safe swaps returned, stage telemetry.
- App: async accepted/completed timings, preview/apply runtime proofs, user-facing no-op/rebuild branches.

Gaps to close before scaling:

- Per-commander readiness score combining commander resolution, profile confidence, card-stats coverage, corpus accepted count, role coverage, off-color risk, deterministic fallback validity, and runtime p95.
- Role/package coverage by commander, not just aggregate overlap/top40.
- Fallback reason distribution by commander/profile version.
- Off-color generated vs off-color repaired counts for every reference-guided proof.
- Optimize success/no-op/rebuild-guided rate by intensity and archetype.
- Shared generate/optimize candidate source attribution: profile, stats, corpus, synergy, meta, model, fallback.
- Cache hit/miss and cache invalidation metrics by commander/profile/corpus policy version.

## Similar Commander Reuse Opportunities

Similar-commander reuse is already present as lower-confidence archetype/package guidance when no exact profile exists and color identity/theme tokens match. Public proof for Velomachus showed archetype reuse can preserve commander and validation, but the reports also show approximate on-theme scoring and timeout sensitivity. It is useful, but not sufficient as the main expansion mechanism.

Best opportunities:

- Treat similar commander reuse as a candidate pool supplement, not as a source of truth.
- Reuse role skeletons and package labels across related commanders while requiring exact commander color identity and prompt/theme compatibility.
- Store reusable archetype evidence as normalized role/package templates with confidence, source commanders, and avoid-pattern inheritance rules.
- Use similar-commander evidence in optimize to identify likely upgrades for decks whose commander lacks exact corpus, while marking low confidence and allowing safe no-op.

Risks:

- Source commander overfitting can create off-theme decks.
- Color identity compatibility is necessary but not sufficient; commanders can share colors but not game plan.
- Prompt token matching can be brittle.
- User trust suffers if the app says it optimized for one commander but suggestions clearly belong to another archetype.

## Ideas Considered

### P1 next sprint — Commander readiness gate and scorecard before mini-batch expansion

- Classification: P1 next sprint.
- Title: Commander readiness gate and scorecard.
- Module: data/backend/QA.
- Problem: Lorehold v5 passed, but expansion readiness is not represented as a single repeatable gate for each commander.
- Proposed change: Add a deterministic scorecard runner/report that evaluates commander card resolution, profile confidence, card-stats unresolved count, package coverage, corpus accepted count, off-color risk, deterministic fallback validity, role coverage, and p95 proof status.
- Files likely touched: `server/bin/commander_reference_profile.dart`, `server/bin/commander_reference_deck_corpus.dart`, `server/lib/ai/commander_reference_*`, `server/test/commander_reference_*`, new doc artifacts under `server/test/artifacts`.
- Expected impact: Prevents another broad rollout with hidden resolution/corpus gaps; makes expansion data-driven.
- Complexity: M.
- Risk: Gate may initially block too many commanders until thresholds are tuned.
- Validation plan: Run on Lorehold as known PASS baseline and on 3-5 candidate commanders; compare output to existing reports and ensure no raw decklists/secrets.
- Rollout strategy: Report-only first, then require scorecard PASS for mini-batch.
- Blocks commander expansion: Yes, for any corpus/deterministic expansion beyond Lorehold.
- Type: data/backend/product decision.

### P1 next sprint — Shared Commander Candidate Pool service for generate and optimize

- Classification: P1 next sprint.
- Title: Shared Commander Candidate Pool.
- Module: backend.
- Problem: Generate uses profile/stats/corpus packages while optimize uses candidate-quality metadata; the two systems can disagree about what is core/on-theme.
- Proposed change: Create a support service that emits normalized candidates with card name/id, role, package, source, confidence, color/legal status, and commander fit. Generate deterministic fallback and optimize candidate ranking both consume it.
- Files likely touched: `server/lib/ai/commander_reference_card_stats_support.dart`, `server/lib/ai/commander_reference_deck_corpus_support.dart`, `server/lib/ai/commander_reference_generate_fallback_support.dart`, `server/lib/ai/optimize_runtime_support.dart`, `server/routes/ai/generate/index.dart`, `server/routes/ai/optimize/index.dart`, tests for both flows.
- Expected impact: Better theme consistency, less duplicate ranking logic, more explainable suggestions.
- Complexity: L.
- Risk: Refactor can perturb proven Lorehold path or aggressive optimize ranking if not feature-flagged.
- Validation plan: Golden tests for Lorehold v5 output constraints; optimize tests proving same pool does not bypass quality gate; diff candidate source attribution.
- Rollout strategy: Read-only diagnostics first, then use for one exact commander, then mini-batch.
- Blocks commander expansion: Yes for quality-scaled expansion; no for profile-only experiments.
- Type: backend/data.

### P1 next sprint — Role/package coverage evaluator per commander and result

- Classification: P1 next sprint.
- Title: Role/package coverage evaluator.
- Module: backend/observability.
- Problem: Current metrics include top40/core coverage for Lorehold, but not a reusable result evaluator for all commanders and optimize/rebuild outputs.
- Proposed change: Build a shared evaluator that reports role coverage, package coverage, core missing cards, overrepresented roles, and source attribution for generated, optimized, and rebuilt decks.
- Files likely touched: `server/lib/ai/commander_reference_deck_corpus_support.dart`, `server/lib/ai/commander_reference_card_stats_support.dart`, `server/lib/generated_deck_validation_service.dart`, `server/lib/ai/rebuild_guided_service.dart`, tests.
- Expected impact: Converts subjective quality into regression gates; improves explainability.
- Complexity: M.
- Risk: Over-optimizing for known packages could reduce creative variety.
- Validation plan: Lorehold must keep `26/26` core coverage and valid deck; run on exact profile commanders without corpus to identify missing data rather than fail runtime.
- Rollout strategy: Diagnostics-only, then acceptance gate for reference-guided generation.
- Blocks commander expansion: Yes for corpus-backed expansion.
- Type: backend/data/model-prompt observability.

### P1 next sprint — Commander-aware deterministic fallback for non-corpus exact profiles

- Classification: P1 next sprint.
- Title: Commander-aware deterministic fallback for exact profiles without corpus.
- Module: backend.
- Problem: Strong deterministic primary path requires strong corpus; many exact profiles may still fall back to generic/model-heavy behavior.
- Proposed change: Extend deterministic fallback to use profile role targets and card stats packages as a gap-filling skeleton even when corpus is absent or weak, with confidence-labeled diagnostics.
- Files likely touched: `server/lib/ai/commander_reference_generate_fallback_support.dart`, `server/routes/ai/generate/index.dart`, `server/lib/ai/commander_reference_profile_support.dart`, `server/lib/ai/commander_reference_card_stats_support.dart`, tests.
- Expected impact: Lower timeout/fallback risk and better commander preservation for exact profiles beyond Lorehold.
- Complexity: M.
- Risk: Decks may become too formulaic or underfilled in roles with sparse stats.
- Validation plan: N=5 local/public probes for 3 exact profiles; require validation, commander preservation, off-color `0/5`, and no hidden repair.
- Rollout strategy: Feature flag by scorecard readiness; do not apply globally.
- Blocks commander expansion: Yes for safe exact-profile expansion.
- Type: backend/data.

### P2 useful after mini-batch — App explainability layer for evidence and apply mode

- Classification: P2 useful after mini-batch.
- Title: User-facing AI evidence and apply mode explanation.
- Module: app/product.
- Problem: App previews show swaps/reasoning but not clearly which evidence was used, which apply mode will run, or why rebuild was forced.
- Proposed change: Add compact UI copy: “Used exact commander profile + core package evidence”, role coverage summary, apply mode label, rebuild-guided explanation, and post-apply diff summary.
- Files likely touched: `app/lib/features/decks/widgets/deck_optimize_sheet_widgets.dart`, `deck_optimize_dialogs.dart`, `deck_optimize_flow_support.dart`, `deck_details_screen.dart`, `deck_generate_screen.dart`, app tests.
- Expected impact: Higher user trust and fewer surprises.
- Complexity: M.
- Risk: Too much technical copy can confuse users if not product-designed.
- Validation plan: Widget tests for all branches; iPhone 15 runtime for generate preview, optimize preview/apply, quality rejected, and rebuild-guided.
- Rollout strategy: Start with concise labels and expandable details; no backend contract requirement beyond existing optional diagnostics.
- Blocks commander expansion: No.
- Type: app/product decision.

### Needs data proof — Synergy graph across commander/card/package

- Classification: Needs data proof.
- Title: Commander synergy graph.
- Module: data/backend.
- Problem: Current synergy is partly table-based and partly profile/package-based; there is no unified graph to infer missing package candidates.
- Proposed change: Build a local graph from accepted profiles, card stats, corpus aggregates, role scores, and commander-card synergy; use it for offline candidate scoring, not direct runtime authorization.
- Files likely touched: `server/lib/ai/candidate_quality_data_support.dart`, new graph support, runners, tests.
- Expected impact: Better coverage for new commanders and similar archetypes.
- Complexity: L.
- Risk: False positives, stale meta, and opaque scoring.
- Validation plan: Offline precision audit against known PASS commanders before runtime use.
- Rollout strategy: Diagnostics-only for at least one mini-batch.
- Blocks commander expansion: No, but useful after initial scorecard.
- Type: data proof/backend.

### P2 useful after mini-batch — Cache by commander/profile/corpus version

- Classification: P2 useful after mini-batch.
- Title: Versioned commander evidence cache.
- Module: backend/performance.
- Problem: Generate cache is in-memory and policy-versioned, while reference evidence loading/ranking may be repeated across requests.
- Proposed change: Add safe, sanitized cache for candidate pool/evaluator artifacts keyed by commander id, profile version, card-stats version, corpus version, and policy version; do not cache raw prompts or raw decklists.
- Files likely touched: `server/lib/ai_generate_performance_support.dart`, `server/lib/ai/commander_reference_*`, possibly a new cache table or in-memory layer.
- Expected impact: Lower p95 for non-Lorehold exact paths and less DB pressure.
- Complexity: M.
- Risk: Stale evidence after profile/corpus updates.
- Validation plan: Unit tests for cache invalidation keys; runtime timing comparison; assert cache keys contain no prompt/decklist/secrets.
- Rollout strategy: In-memory first; persistent only after contract/security review.
- Blocks commander expansion: No.
- Type: backend/performance.

### Needs product decision — Budget/power bracket-aware generation and optimize

- Classification: Needs product decision.
- Title: Budget and power bracket policy.
- Module: product/backend/app.
- Problem: Optimize has bracket/budget advisory penalties, but generate does not yet make budget/power bracket a first-class quality target.
- Proposed change: Define product copy and backend interpretation for budget/power bracket, then include it in candidate scoring and user preview.
- Files likely touched: `server/routes/ai/generate/index.dart`, `server/lib/ai/optimize_runtime_support.dart`, `app/lib/features/decks/screens/deck_generate_screen.dart`, optimize widgets.
- Expected impact: Better user fit and fewer “too expensive/too strong” suggestions.
- Complexity: M.
- Risk: Requires reliable price/power data and clear UX.
- Validation plan: Sample decks by bracket; ensure legal/color gates still dominate.
- Rollout strategy: Product decision first, then diagnostics, then selectable UI.
- Blocks commander expansion: No.
- Type: Needs product decision.

### P3 later — Cheap multi-pass local reranking

- Classification: P3 later.
- Title: Cheap multi-pass local reranking.
- Module: backend/model-prompt.
- Problem: A single model output can be valid but low-theme.
- Proposed change: Generate more candidates or local variants and rerank deterministically by role/package coverage.
- Files likely touched: `server/routes/ai/generate/index.dart`, evaluator service, tests.
- Expected impact: Better quality for sparse commanders.
- Complexity: L.
- Risk: Latency and cost if model calls multiply; deterministic variants may reduce diversity.
- Validation plan: Offline only until p95/cost proof.
- Rollout strategy: Only after candidate pool/evaluator exists.
- Blocks commander expansion: No.
- Type: model/backend.

## Recommended Next Sprints

Sprint 1 — Measurement and shared evidence foundation.

Acceptance criteria:

- Commander readiness scorecard runs locally without runtime code behavior changes.
- Lorehold scorecard reproduces known PASS indicators: no fallback, no timeout fallback, no off-color generated/repair, commander not in 99, `26/26` core coverage, p95 baseline documented from existing proof.
- At least 3 candidate commanders are evaluated and classified as ready/not ready with explicit reasons.
- Shared candidate pool is introduced in diagnostics-only mode or designed with test coverage before runtime consumption.
- No app-facing contract drift; `API_CONTRACTS_AND_DATA_MAP.md` remains unchanged unless an actual contract change is made later.

Sprint 2 — Controlled mini-batch deterministic expansion.

Acceptance criteria:

- Select 3-5 commanders from scorecard PASS or PASS WITH RISKS with product approval.
- Deterministic fallback/primary path uses exact profile/card-stats packages and corpus where available.
- Public or local-live probes per commander: N>=5, validation `5/5`, commander preserved `5/5`, main 99 `5/5`, off-color generated/repair `0/5`, commander in 99 `0/5`, fallback target justified per path, p95 target defined before run.
- Role/package coverage report is produced per commander.
- Any commander failing gates is not rolled into general runtime.

Sprint 3 — Optimize/generate convergence and UX trust.

Acceptance criteria:

- Optimize can read shared commander candidate evidence for at least one exact commander without weakening quality gates.
- App preview shows concise evidence label, apply mode, and rebuild-guided reason in tests.
- Aggressive safe no-op and rebuild-guided outcomes remain user-friendly and avoid raw payloads.
- iPhone 15 runtime covers generate preview/save, optimize preview/apply or safe no-op, and rebuild-guided branch.

## Rejected Ideas

### Reject — Mass corpus rollout without scorecard

- Classification: Reject.
- Title: Mass corpus rollout without scorecard.
- Module: data/backend.
- Problem: Would multiply hidden commander resolution, off-color, role-classifier, and latency risks.
- Proposed change: Do not do it.
- Files likely touched if ignored: corpus runners, reference support, generate route.
- Expected impact: Avoids regressions.
- Complexity: S to reject.
- Risk: Slower perceived expansion.
- Validation plan: Require scorecard before expansion.
- Rollout strategy: Controlled mini-batch only.
- Blocks commander expansion: Yes, intentionally.
- Type: data/backend.

### Reject — Runtime scraping or copying raw public decklists into prompts

- Classification: Reject.
- Title: Runtime scraping or copying raw public decklists into prompts.
- Module: data/legal/operations.
- Problem: Adds legal/operational fragility and violates the current aggregate-evidence design.
- Proposed change: Continue curated/sanitized aggregate corpus only; no runtime scraping.
- Files likely touched if ignored: corpus runners, prompt builders.
- Expected impact: Reduces legal and stability risk.
- Complexity: S to reject.
- Risk: Less data volume.
- Validation plan: Corpus docs and artifacts must stay aggregate/sanitized.
- Rollout strategy: Keep current gates.
- Blocks commander expansion: No, but constrains data acquisition.
- Type: data/legal/operations.

### Reject — Increase OpenAI timeout again as primary strategy

- Classification: Reject.
- Title: Increase OpenAI timeout again as primary strategy.
- Module: backend/performance.
- Problem: v5 proved deterministic reference-guided path can reduce p95 to `1648ms`; longer timeouts increase UX and proxy risk.
- Proposed change: Prefer deterministic/cache/evaluator improvements.
- Files likely touched if ignored: `ai_generate_performance_support.dart`, generate route.
- Expected impact: Protects latency.
- Complexity: S to reject.
- Risk: Some sparse cases may still fallback.
- Validation plan: Track fallback reasons; use deterministic fallback first.
- Rollout strategy: Timeout changes only by explicit operational experiment.
- Blocks commander expansion: No.
- Type: backend/performance/product decision.

### Reject — Expose raw diagnostics to users

- Classification: Reject.
- Title: Expose raw diagnostics to users.
- Module: app/product/security.
- Problem: Raw buckets and payloads are confusing and may leak technical implementation details.
- Proposed change: Show derived copy only.
- Files likely touched if ignored: optimize widgets, generate screen.
- Expected impact: Better trust without sensitive detail.
- Complexity: S to reject.
- Risk: Less debug information in UI.
- Validation plan: Widget tests assert no raw payload labels.
- Rollout strategy: Keep detailed diagnostics for QA artifacts/logs only.
- Blocks commander expansion: No.
- Type: app/product/security.

### Reject — Let reference/meta signals bypass validation

- Classification: Reject.
- Title: Let reference/meta signals bypass validation.
- Module: backend/safety.
- Problem: Advisory data can be stale or wrong; bypassing `card_legalities`, color identity, singleton, or bracket gates would reintroduce illegal/off-color suggestions.
- Proposed change: Keep validation authoritative.
- Files likely touched if ignored: optimize quality gate, validation services, generate route.
- Expected impact: Maintains legality and trust.
- Complexity: S to reject.
- Risk: Some desirable cards may be filtered until data is fixed.
- Validation plan: Existing validation tests plus off-color generated/repair counters.
- Rollout strategy: Data fixes must go through runners/backfills, not runtime bypass.
- Blocks commander expansion: Yes if someone proposes bypass as shortcut.
- Type: backend/safety/data.

## Validation Plan

Minimum validation for this documentation-only audit:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
git diff --check
cd server
dart analyze lib routes test
```

Validation for future implementation:

- Backend unit tests for candidate pool, readiness scorecard, evaluator, fallback, and quality gates.
- Existing generate/optimize integration tests: `ai_generate_create_optimize_flow_test.dart`, `generated_deck_validation_service_test.dart`, `ai_generate_performance_support_test.dart`, `commander_reference_*_test.dart`, `ai_optimize_flow_test.dart`, `optimization_quality_gate_test.dart`, `optimization_pipeline_integration_test.dart`.
- Corpus runner dry-run/apply/idempotency for each candidate commander.
- Public or local-live N>=5 probes per commander with sanitized artifacts only.
- App widget/provider tests for async generate, optimize intensity, aggressive diagnostics, preview/apply, rebuild-guided, and validation error rendering.
- iPhone 15 runtime only when app UX changes are implemented.

## Open Product Decisions

- What power/budget brackets should users choose during generate and optimize, and how strict should those brackets be?
- Should deterministic exact-profile generation be labeled to users as “reference-guided” or remain invisible behind quality metrics?
- How much evidence should app UI show by default vs behind an expandable “why these cards?” section?
- What is the acceptable mini-batch size after Lorehold v5: 3, 5, or 8 commanders?
- Should similar-commander reuse be exposed to users (“inspired by similar Boros big-spell commanders”) or kept as internal diagnostics?
- What is the minimum p95 target for exact deterministic paths beyond Lorehold?

## Final Recommendation

Final outcome: **PASS WITH RISKS**.

The Commander AI system is ready for a **controlled mini-batch planning sprint**, not a broad expansion. The smallest next architecture improvement before scaling is a **Commander readiness scorecard plus shared candidate/evaluator foundation**. This preserves the Lorehold v5 success pattern, prevents hidden data gaps, and creates a common quality language for generate, optimize, rebuild, fallback, and app explainability.

Do not change runtime behavior in the next step until the scorecard identifies which commanders are actually ready. Do not update `server/manual-de-instrucao.md` for this audit alone; there is no material operational runtime change, only a strategy document.
