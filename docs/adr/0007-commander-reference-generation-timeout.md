# ADR 0007 — Commander reference generation timeout

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

## Decision

Use 60 seconds as the default
`OPENAI_TIMEOUT_GENERATE_REFERENCE_SECONDS` budget for Commander and Brawl
when reference guidance is enabled. Preserve all existing boundaries:

- the legacy path without reference guidance keeps its existing timeout;
- explicit operational overrides remain supported;
- the value remains clamped to 3–90 seconds;
- timeout continues to fail closed with a sanitized user message and log;
- the async job continues to report durable progress and cancellation state.

## Consequences

- Reference-guided onboarding has enough headroom for the current prompt and
  validation context without changing the synchronous API contract.
- A provider outage can keep one worker occupied for up to 60 seconds, but the
  user can leave the screen and the persisted job remains observable.
- Production E2E must prove a real reference-guided generation after deploy;
  unit tests alone do not approve this decision.

## Rejected alternatives

- Retry indefinitely: hides provider failure and consumes quota unpredictably.
- Disable reference guidance: produces a faster but materially weaker deck and
  stops validating the product path requested by the user.
- Raise every AI timeout: unrelated routes and the legacy generation path did
  not exhibit this failure.
