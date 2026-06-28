# Lorehold Focus Access Package Decision - 2026-06-28

- Scope: candidate `candidate_607_squee_hashseed0_isolated_cached_timeout_v3`
- Source trace audit: `docs/hermes-analysis/master_optimizer_reports/lorehold_failure_targeted_trace_audit_20260628_v3_focus_access.json`
- Planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260628_v12_focus_access_trace.json`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Decision

The next deck-learning package should target early access and conversion, not another blind payoff swap.

Do not repeat the rejected tutor-over-Land Tax lane. The current evidence says the weak seeds need more reliable access to the existing miracle/topdeck engine while preserving protected pieces until a same-lane cut model proves otherwise.

## Local Evidence

- Seed `7`: candidate went `0-9`. `Squee, Goblin Nabob` stayed in library across all early snapshots; `Sensei's Divining Top` stayed in library through early snapshots; `Library of Leng` stayed in library through early snapshots. `Urza's Saga` appeared, so the failure is not simply "no Saga".
- Seed `20260625`: candidate went `0-9`. `Land Tax` stayed in library across all early snapshots; `Squee, Goblin Nabob` stayed in library; `The Mind Stone` appeared early but did not convert into a winning window.
- Seed `42`: candidate went `7-2`. `Squee` reached hand early and later hit graveyard/return lines; topdeck manipulation and miracle counts were high. This is the positive regression anchor.
- The v3 trace audit status changed from missing payload to `focus_access_trace_available_review_sequence` and `focus_access_trace_available_review_conversion`.

## External Strategy Check

- EDHREC's Lorehold deck tech frames the commander as a miracle/topdeck deck and calls out `Sensei's Divining Top`, `Scroll Rack`, and `Library of Leng` as key cards for setting up miracle draws: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
- EDHREC's budget Lorehold article emphasizes balance, high instant/sorcery density, and support cards like `Hidden Retreat` and `Brainstone` to put expensive spells back on top: https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget
- Card Kingdom's Lorehold synergy article highlights turn-cycle mana and topdeck manipulation as support for repeated miracle turns: https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/
- GameTyrant's deck tech describes the core plan as manipulating the top of the deck, casting huge spells through Miracle, and using discard as a resource: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech

## Local Candidate Availability

Present in current candidate deck/cache:

- `Sensei's Divining Top`
- `Scroll Rack`
- `Library of Leng`
- `Land Tax`
- `Squee, Goblin Nabob`
- `The Mind Stone`
- `Urza's Saga`
- `Bender's Waterskin`
- `Monument to Endurance`
- `Big Score`
- `Unexpected Windfall`
- `Reforge the Soul`

Available in local oracle cache but not in the candidate:

- `Enlightened Tutor`
- `Gamble`
- `Hidden Retreat`
- `Penance`
- `Brainstone`
- `Sevinne's Reclamation`

## Next Package Contract

Build the next package only if it satisfies all conditions:

- Adds access/manipulation density for Top/Rack/Library/Squee/large miracle spells.
- Does not cut `Land Tax`, `Squee`, `Top`, `Scroll Rack`, `Library of Leng`, `Urza's Saga`, or `The Mind Stone` unless a same-lane cut model explicitly proves the cut.
- Preserves the seed `42` positive telemetry: high miracle count, high topdeck manipulation count, Squee graveyard/return still observed.
- Targets seeds `7` and `20260625` as failure seeds and must improve at least one without collapsing seed `42`.
- Routes any card lacking executable runtime behavior to XMage/runtime implementation before a battle gate.

## Candidate Package Direction

Primary direction: access package preserving current engine.

Suggested package candidates for modeling, not automatic promotion:

- `Brainstone`: one-shot topdeck setup, directly aligned with miracle sequencing.
- `Hidden Retreat`: puts expensive cards from hand on top for the next draw window.
- `Penance`: hand-to-top setup already fits the trace concept if runtime remains coherent.
- `Enlightened Tutor`: can find `Top`, `Library`, `The Mind Stone`, `Land Tax`, or other engine artifacts/enchantments, but prior tutor/Land Tax cuts are rejected.
- `Gamble`: can find `Squee` or engine pieces, but random discard must be modeled as benefit only when the discard target is resilient.

Immediate next action: use the planner's `review_focus_access_trace_then_define_next_deck_or_runtime_package` action to create a gate-ready package with a safe cut model, then run an equal gate against seeds `7`, `20260625`, and `42`.
