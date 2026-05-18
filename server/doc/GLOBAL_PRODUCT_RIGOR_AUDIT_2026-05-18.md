# ManaLoom Global Product Rigor Audit - 2026-05-18

## Verdict

**PASS_WITH_RISKS for controlled internal product testing.**

ManaLoom is in a stronger state than the 2026-05-15 internal-test baseline. The
public backend is deployed at `20837c42d84ea4345ed6c156a12777276b28491b`, health
is green, localized Portuguese import is live, deck analysis now explains
functional roles, and the functional-tag classifier was mass-audited against the
real card database.

This is **not yet a clean public-release PASS** because scanner/camera/OCR,
physical push/APNs/FCM coverage for the current build, aggressive optimize apply
quality, and a few social/trade error-state/runtime edges remain accepted risks.

No secrets, tokens, JWTs, `DATABASE_URL`, `SENTRY_DSN`, `OPENAI_API_KEY`, full QA
e-mails, raw prompts, private messages or complete generated decklists are
included in this report.

## Current deployment baseline

| Item | Status | Evidence |
|---|---|---|
| Branch | PASS | `master` synchronized with `origin/master` at `20837c4`. |
| Public backend | PASS | `GET /health` returned healthy production response. |
| Public backend SHA | PASS | `/health.git_sha=20837c42d84ea4345ed6c156a12777276b28491b`. |
| Automated test inventory | PASS | 167 test files: 97 app tests and 70 server tests. |
| Runtime harness inventory | PASS | Broad non-scanner integration harnesses exist for decks, import, Commander Reference, functional tags, Binder/Marketplace/Trades, notifications and Life Counter. |
| Scanner/camera/OCR | DEFERRED | Existing harness/docs remain historical or deferred; not a current acceptance gate. |

## What materially improved after the 2026-05-15 global audit

| Area | Product impact | Current status |
|---|---|---|
| Localized import names | Portuguese decklists no longer fail just because cards are in Portuguese. Backend resolves localized aliases from local DB table, not live per-card network calls. | PASS_WITH_RISKS: PT synced and runtime-proven; other languages require controlled sync. |
| Import to deck Commander handling | Existing Commander/Brawl commander is preserved when importing a list without commander. This addresses tester reports around commander loss and stale deck counts. | PASS. |
| Functional deck analysis | Users can see what the app counts as ramp, draw, removal, wipes and protection, including bounded card samples. This directly answers tester feedback that the app should explain why counts differ from user expectations. | PASS_WITH_RISKS: deterministic tags are audited; edge heuristics remain triage items. |
| Functional tag classifier | 33,435 card rows were processed in a safe mass audit with 66.613% row coverage. Clear heuristic bugs were fixed. | PASS_WITH_RISKS: not every card should receive a tag; FP/FN reason codes remain. |
| Commander AI deck generation | Commander Reference profiles, card stats and corpus-guided generation have been proven across multiple commander batches and app runtimes. | PASS_WITH_RISKS: expansion can pause while users test. |
| State/cache leakage | Auth, messages, notifications and trades have generation guards against late responses after logout/clear or active context switch. | PASS_WITH_RISKS: lower-risk providers still could receive the same pattern later. |

## Product capability matrix

| Capability | Product status | Notes |
|---|---|---|
| Auth/register/login/profile | PASS_WITH_RISKS | Core flows tested; stale profile response guarded. Error/success UI keys can improve. |
| Cards/search/sets | PASS | Public backend and runtime coverage exist. Search localized import is separate and now improved for PT imports. |
| Deck create/detail/validate/pricing | PASS | Backend CRUD and runtime deck flows are repeatedly proven. |
| Deck import | PASS_WITH_RISKS | PT localized import is live and runtime-proven. Other languages need sync/proof before claiming support. |
| Commander AI generate | PASS_WITH_RISKS | Strongest in curated commanders/reference-backed cases. Generic commander/no-commander flows still rely more on legacy AI + validation. |
| Deck analysis functional roles | PASS_WITH_RISKS | UI/backend runtime-proven against public backend. Counts are explainable but heuristic, not oracle-perfect. |
| Optimize focused | PASS_WITH_RISKS | Preview/apply paths have tests and prior runtime coverage; quality still depends on candidate availability. |
| Optimize aggressive | PARTIAL | UX-safe no-op/friendly failure was validated; broad apply-quality proof remains incomplete. |
| Binder/collection | PASS_WITH_RISKS | CRUD and runtime coverage exist; filter/list error/empty keys should improve. |
| Marketplace/trades | PASS_WITH_RISKS | Lifecycle has runtime coverage, but trade-chat persistence and list/detail stale UX remain areas to re-prove under lower rate-limit pressure. |
| Messages/notifications | PASS_WITH_RISKS | Realtime/polling refresh exists and stale-state guards were added. Empty-vs-error UI needs stronger keyed states. |
| Life Counter/Lotus | PASS | Large runtime harness inventory and prior proofs exist; not the current risk center. |
| Push delivery | PASS_WITH_RISKS | Android FCM real delivery was proven previously, but current internal-test cycle treats real push/APNs as deferred unless rerun for the build. |
| Scanner/camera/OCR/MLKit | DEFERRED | Must not be claimed as ready until a dedicated physical-device scanner sprint passes. |

## Current non-negotiable gates before broader public release

1. **Optimize aggressive apply proof**: run a real non-empty deck through aggressive optimize where suggestions are returned, previewed, partially applied, saved, and validated. Current proof is safe UX, not quality/apply confidence.
2. **Trade/message persistence re-proof**: rerun trade chat and direct messages with pacing/backoff to avoid `429`, then confirm list preview, unread counts, detail refresh and persisted messages.
3. **Error/empty state UI hardening**: Messages, Notifications, Binder, Marketplace, Community and Card Search should expose stable keyed loading/error/empty states so tests can distinguish backend failure from genuinely empty data.
4. **Localized import language policy**: decide whether product copy says “Portuguese supported” or “multi-language supported”. Only PT is synced/proven today; ES/FR/DE/IT/JA/KO/RU/ZHS/ZHT need operational sync and proof.
5. **Scanner decision**: either keep scanner explicitly out of release scope or run a physical-device scanner/OCR validation sprint. Do not leave this ambiguous for testers.
6. **Release build proof**: before TestFlight/Play internal distribution, rerun a signed/internal build smoke with the exact `API_BASE_URL` and public backend, plus secret-scan and store-label/icon verification.

## Product risks to communicate to testers

- Deck analysis counts are deterministic heuristics. They now show samples and coverage, but they are not a human judge of every card. Reports should include the specific card names users believe are misclassified.
- Localized import currently has proven Portuguese support. Other languages should be treated as pending until synced and tested.
- AI generation is strongest when the user sets a commander and the commander has a reference profile/stats/corpus or archetype reuse. Without commander input, validation still protects legality, but theme quality is less guaranteed.
- Aggressive optimize may return no actionable changes or a friendly failure when the backend cannot find safe upgrades. That is acceptable UX, but not proof of optimization quality.
- Rate limit can affect repeated QA auth/message flows on the public backend. Testers should avoid rapid account churn and report timestamps when `429` appears.
- Scanner/camera/OCR findings are out of scope unless a scanner-specific build/test is requested.

## Recommended next execution order

1. Close documentation for this product audit and keep it as the current global status source.
2. Run the current public runtime smoke set on iPhone 15 Simulator: localized import, functional deck analysis, generate/save/validate, focused optimize, binder/trade/message/notification.
3. Run one physical-device Android or iPhone internal build smoke only if the next milestone is actual tester distribution, not just engineering validation.
4. Patch keyed error/empty states for Messages and Notifications first, then Binder/Marketplace/Community.
5. Re-run trade/direct-message persistence proof with pacing after the UI-state patch.
6. Decide whether to pause Commander expansion until after internal tester feedback. Current recommendation: **pause expansion** and spend the next pass on product UX correctness.

## Final product classification

**Internal testing:** GO with documented risks.

**External/public release:** NO-GO until optimize aggressive apply, trade/message persistence, release-build smoke and scanner scope decision are closed.

**Engineering direction:** prioritize product feedback loops and UI correctness over adding more Commander profiles right now.
