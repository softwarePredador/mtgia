# ADR 0006 — Commander optimizer bracket and apply safety

- Status: accepted
- Date: 2026-07-30
- Scope: `POST /ai/optimize`, Complete, deck apply and Commander diagnostics

## Context

A Bracket 2 Lorehold deck received Lion's Eye Diamond, Grim Monolith and Mox
Diamond. These are official Game Changers and therefore incompatible with
Brackets 1 and 2. Cori-Steel Cutter appeared in the same result for a different
reason: it is legal and is not an official Game Changer, but it is a weak fit
for the deck's `Miracle Big Spells` intent.

The previous flow mixed independent questions:

1. Is the card legal and allowed by the selected bracket?
2. Does it satisfy a structural role and preserve mana/interaction floors?
3. Does it advance the commander, archetype and selected theme?
4. Is it available or within the requested purchase budget?
5. Is the applied mutation exactly one produced by the reviewed preview?

A provider prompt or a high role/popularity score could influence selection
without every fallback and apply path repeating those checks.

## Decision

Use defense in depth with explicit boundaries:

1. Commander legality, singleton and color identity remain hard format rules.
2. The current official Game Changer list is the only hard bracket card cap:
   B1/B2 zero, B3 at most three, B4/B5 unlimited.
3. Bracket intent is preserved independently from that hard cap:

   | Bracket | Label | Earliest intended ending | Lane |
   |---|---|---:|---|
   | 1 | Exhibition | turn 9+ | theme-first social |
   | 2 | Core | turn 8+ | straightforward, telegraphed social |
   | 3 | Upgraded | turn 6+ | synergistic, accrued-resource social |
   | 4 | Optimized | turn 4+ | optimized non-cEDH |
   | 5 | cEDH | no turn floor | competitive cEDH metagame |

   Only B5 may automatically consume competitive cEDH meta references.
4. Other power signals are advisory. They may affect ranking and user
   diagnostics but do not create a product ban.
5. Functional floors are evaluated on the quantity-aware projected/final deck.
   Complete reserves or repairs slots for wipes and mana before accepting a
   result.
6. Commander-specific synergy and theme affinity rank legal candidates before
   generic popularity. Lorehold's Miracle plan favors top-deck setup,
   hand-filtering, instant/sorcery and big-spell conversion.
7. Collection and budget constraints participate in selection and are audited
   again on all new Complete additions. Missing price under an active budget is
   a blocker; zero budget means no purchase.
8. Every actionable preview receives an expiring HMAC authorization bound to
   deck, deck signature, target bracket, exact swap pairs and the functional
   role floor. Both mutation routes validate the actual before/after delta,
   forbid condition/commander-role drift and recompute the role floor inside
   the owner transaction before destructive writes.
9. The persistent optimize cache contract advances to `v16`. Actionable
   Commander cache hits require internally satisfied bracket and
   functional-role policies, then receive a fresh apply authorization.
10. Apply signing is fail-closed. Runtime secrets follow the shared `.env` plus
   process-environment precedence; all deck-card writers lock the owner deck
   row so the signed signature cannot race a concurrent mutation.

The intent matrix follows the Wizards Commander Brackets update of
2025-10-21. The Game Changer set follows the official 2026-02-09 update,
including Biorhythm and Farewell.

Official references:

- https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-october-21-2025
- https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026

## Consequences

- A B2 preview cannot contain or apply Lion's Eye Diamond, Grim Monolith, Mox
  Diamond or any other official Game Changer.
- Cori-Steel Cutter is not mislabeled as illegal; it can be deprioritized as
  off-plan for Miracle Big Spells.
- An already contaminated deck must remove every excess Game Changer before a
  B2 preview becomes actionable.
- B3/B4 cannot silently inherit cEDH reference lists; B5 remains the explicit
  competitive lane.
- Complete, Optimize, Generate and Rebuild return or persist only a final deck
  that passes the selected bracket policy.
- Provider, fallback and stale-cache mistakes fail closed at final payload and
  apply.
- Secret rotation invalidates outstanding preview tokens. The dedicated
  `OPTIMIZATION_APPLY_SIGNING_SECRET` is optional; `JWT_SECRET` is the runtime
  fallback, but at least one must be configured for an actionable preview.
- Structural improvement still requires Battle/replay evidence before it is
  treated as a promoted learned strategy.

## Rejected alternatives

- Ban every fast-mana or high-power signal: this invents rules not present in
  the official bracket contract.
- Trust prompt wording alone: deterministic fallbacks, cache and apply remain
  outside provider control.
- Treat popularity or engine coverage as deck fit: neither proves commander
  intent.
- Accept an unsigned client hash: a client can recompute it after changing the
  payload.
- Validate only after replacing `deck_cards`: this weakens atomicity and risks
  contaminating optimization history.
