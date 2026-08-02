# ADR 0007 — Commander reference generation budgets

- Status: accepted
- Date: 2026-08-02
- Scope: async AI deck generation for Commander/Brawl with reference guidance

## Context

The production onboarding journey was executed from a new account with
`Lorehold, the Historian`, Bracket 2 and a `Miracle Big Spells` brief. Two
consecutive async jobs failed closed at the exact 24-second OpenAI deadline.
The failure happened before legality and structural validation could finish;
the UI correctly remained responsive and exposed a retry, but no deck could be
created.

The 24-second default came from an earlier small benchmark. It is no longer
representative of the current reference package and provider latency. The job
is asynchronous, so extending its server-side provider budget does not hold an
HTTP request or freeze the app.

After the first timeout correction was deployed, the same fresh-account flow
found two additional production facts:

- one response completed in 21.3 seconds but ignored the Bracket 2 instruction
  and was correctly rejected for two Game Changers;
- the following response consumed exactly the configured 3,800 output tokens
  and ended with an incomplete JSON object, so a 100-card singleton proposal
  could not be decoded.

The reference prompt also listed learned/reference cards after the abstract
bracket instruction. That ordering made it unnecessarily easy for a suggested
Game Changer to conflict with the selected hard cap.

## Decision

Use 75 seconds as the default
`OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` budget for Commander and Brawl
when reference guidance is enabled. Reserve 6,000 output tokens by default for
Commander generation, with an explicit Commander-only 800–8,000 operational
clamp. Append the
exact governed Game Changer list and bracket cap after all reference material,
making clear that the hard cap overrides every learned, staple, collection,
budget and theme suggestion. Invalidate old generation cache entries with
contract `v6` and reference-prompt policy `v8`.

Preserve all existing boundaries:

- the legacy path without reference guidance keeps its existing timeout;
- explicit operational overrides remain supported;
- the timeout remains clamped to 3–90 seconds;
- explicit output-token overrides remain supported and bounded;
- timeout continues to fail closed with a sanitized user message and log;
- provider truncation is classified separately and never yields a saveable
  partial deck;
- bracket and structural gates remain fail-closed after provider output;
- the async job continues to report durable progress and cancellation state.

## Consequences

- Reference-guided onboarding has enough time and output space for 99 distinct
  main-deck entries without changing the synchronous API contract.
- A provider outage can keep one worker occupied for up to 75 seconds, but the
  user can leave the screen and the persisted job remains observable.
- The official list adds prompt input tokens, but removes ambiguity and avoids
  spending an entire generation on a proposal the backend can predictably
  reject.
- Production E2E must prove a real reference-guided generation after deploy;
  unit tests alone do not approve this decision.

## Rejected alternatives

- Retry indefinitely: hides provider failure and consumes quota unpredictably.
- Disable reference guidance: produces a faster but materially weaker deck and
  stops validating the product path requested by the user.
- Raise every AI timeout: unrelated routes and the legacy generation path did
  not exhibit this failure.
- Accept or silently save a partial/provider-truncated list: violates the
  100-card, legality, singleton, bracket and learning boundaries.
- Remove the bracket gate: would turn a provider mistake into a player-facing
  mislabeled deck.
