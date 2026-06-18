# Hermes WR Suspicion Audit - 2026-06-15

## Verdict

The Lorehold optimizer win rate is still suspicious and must not be promoted as product truth yet.

The replay-level forensic audit is clean after rule fixes, but the broader effect coverage audit still shows too many unmodeled or heuristic card effects across the real opponent field. That means the current 91.7% baseline can be used as an internal comparison signal only, not as evidence that the deck is truly optimized.

## What Was Fixed

- `Sami's Curiosity` no longer resolves as a false tutor. It is now modeled as `lander_token_maker`, gaining 2 life and creating a Lander token.
- `Sticky Fingers` is promoted from generated `needs_review` to manual verified semantics as a combat-damage treasure aura.
- `Miscast` is promoted from heuristic `card_effect_field` to manual verified counterspell semantics.
- `Runaway Steam-Kin` is no longer treated as an instant `ramp_ritual`; it is modeled conservatively as a creature/permanent engine.

## Validation Evidence

- Local battle test suite: passed all `battle_*_tests.py`.
- Hermes forensic replay audit after fixes:
  - status: `ready_for_review`
  - findings_total: 0
  - critical: 0
  - high: 0
  - medium: 0
  - low: 0
  - evidence: `/opt/data/artifacts/hermes_master_optimizer/wr_suspicion_audit_20260614_235559/baseline_replays_after_fix2/`
  - report: `/opt/data/workspace/mtgia_wr_audit_20260614_235559/docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_20260615_000846.md`
- Hermes baseline after fixes:
  - games: 600
  - opponents: 12 real learned decks
  - WR: 91.7%
  - record: 550W/50L/0S
  - report: `/opt/data/workspace/mtgia_wr_audit_20260614_235559/docs/hermes-analysis/master_optimizer_reports/master_optimizer_baseline_20260615_001813.md`
- Hermes effect coverage audit:
  - total_card_instances: 1288
  - unique_cards: 556
  - unknown_effect: 33
  - heuristic_effect: 156
  - trigger_not_explicit: 147
  - temporary_effect_not_explicit: 65
  - land_utility_ability_not_modeled: 48
  - status: blocked for trusting WR as final
  - report: `/opt/data/workspace/mtgia_wr_audit_20260614_235559/docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260615_002219.md`

## Interpretation

The old high/medium replay findings were real and are now fixed. However, the aggregate WR stayed high after those fixes, which points to a larger modeling issue: the real opponent decks still contain many cards whose semantics are unknown, heuristic, or missing important triggered/temporary behavior.

This likely makes opponents weaker or less interactive than they should be. Until the highest-risk opponent cards are modeled, slot scan deltas can still be useful for relative experimentation, but they should not be copied into a real product deck automatically.

## Required Next Work

1. Promote the highest-risk opponent cards from the coverage audit into `battle_card_rules` with verified semantics.
2. Prioritize cards that affect interaction, tempo, protection, and combo pressure:
   - `Valley Floodcaller`
   - `Ragavan, Nimble Pilferer`
   - `Veil of Summer`
   - `Ephemerate`
   - `Dispel`
   - `Tibalt's Trickery`
   - `Consecrated Sphinx`
   - `Wandering Archaic`
   - `Tormod's Crypt`
   - unknown cards listed in the coverage report
3. Rerun:
   - `battle_effect_coverage_audit.py --fail-on-high-risk`
   - `battle_forensic_audit.py --seed 700 --generate 10 --fail-on-high`
   - `master_optimizer_baseline.py --deck-id 6 --games 50 --report`
4. Only trust slot optimizer candidates after both audits pass and the baseline WR stabilizes under the updated ruleset hash.

## Current Promotion Rule

Do not apply Lorehold swaps to a real/product deck while effect coverage still reports high-risk heuristic or unknown card behavior in the real opponent field.
