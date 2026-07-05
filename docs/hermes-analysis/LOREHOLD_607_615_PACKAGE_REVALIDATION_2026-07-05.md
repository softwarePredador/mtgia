# Lorehold 607/615 Package Revalidation - 2026-07-05

## Authorization And Boundary

The user explicitly granted full authorization to test and validate the deck
work. This run used that authorization for read-only battle gates, package
analysis, and report generation.

No deck was materialized, promoted, or modified because the evidence did not
clear the promotion bar. This is an evidence decision, not a permission
blocker.

## Inputs

- Protected baseline: deck `607`.
- Challenger shell: deck `615`.
- Source DB:
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Existing battle gate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8.json`.
- Opponent-rotated battle gate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260705_total_authorization_focused_607_vs_615_g8_seed2026070502.json`.
- Package reports:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_615_shell_package_delta_20260705_current.md`
  and
  `docs/hermes-analysis/master_optimizer_reports/lorehold_615_shell_package_delta_20260705_seed2026070502.md`.
- Official Commander references checked:
  `https://magic.wizards.com/en/news/announcements/introducing-commander-brackets-beta`,
  `https://magic.wizards.com/en/news/announcements/commander-brackets-beta-update-february-9-2026`,
  and `https://mtgcommander.net/index.php/banned-list/`.

## Battle Result

| window | 607 | 615 | result |
| --- | --- | --- | --- |
| seed `20260705`, 4 opponents, 8 games each | 11/32 | 14/32 | 615 +3 wins |
| seed `2026070502`, 4 opponents, 8 games each | 12/32 | 8/32 | 607 +4 wins |
| combined read | 23/64 | 22/64 | 607 +1 win |

Interpretation:

- `615` is a real challenger and can outperform `607` in a short window.
- The rotated opponent/seed window rejected whole-shell promotion.
- Across the two comparable windows, `607` remains slightly ahead on wins.
- `615` wins faster when it wins, but was less stable after opponent rotation.

## Package Delta

`615` is not a small swap. It changes `57` card quantity units against `607`:

- `57` added quantity into `615` across `49` cards or quantity shifts.
- `57` removed quantity from `607` across `57` cards or quantity shifts.
- Major added groups: mana-base shift, resource/card advantage, spell-chain
  conversion, protection, burst ramp, interaction, and finishers.
- Major removed groups: 607 mana base, protection, static cost reduction/ramp,
  interaction, spell value, board control, finishers, and topdeck access.

This means `615` should not be promoted or rejected as a single-card lesson.
It is a package-learning shell.

## Power Watch

`615` adds three official Commander Brackets/Game Changer watch cards compared
with `607`:

- `Mana Vault`: fast mana.
- `The One Ring`: resource advantage.
- `Underworld Breach`: combo/storm engine.

`Farewell` is already shared by both shells and remains a shared power-watch
card after the 2026-02-09 Brackets update.

The opponent-rotated gate confirms that the key `615` power package was not
invisible:

- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`: 47 observed events.
- `The One Ring`: 46 observed events.
- `Underworld Breach`: 21 observed events.
- `Mana Vault`: cast/cost-paid events were recorded.

Therefore, the second-window rejection is not explained by failure to sample
or access those cards.

## Strategic Findings

In the positive window for `615`:

- `615` had more miracle casts: 86 vs 62.
- `615` had more discard-to-top replacements: 39 vs 17.
- `615` had real Birgi mana triggers and One Ring activity.

In the opponent-rotated window:

- `607` had more miracle casts: 69 vs 49.
- `607` had far more static cost reduction total: 90 vs 2.
- `607` had more Lorehold spell casts: 301 vs 239.
- `607` preserved topdeck/ramp artifacts that were actively used:
  `Bender's Waterskin`, `Scroll Rack`, and `The Mind Stone`.

The practical lesson is that `615` can spike with stronger raw cards, but it
loses too much of the 607 cadence package in some opponent windows.

## Decision

Keep `607` as protected Lorehold baseline.

Do not promote `615` as a whole-shell replacement. Do not mutate deck `607`
from this evidence.

Keep `615` as the best package-learning challenger, especially for:

- Birgi and spell-cast mana conversion;
- Underworld Breach or recursion pressure;
- One Ring/card advantage windows;
- fast mana pressure from Mana Vault;
- the Plateau/Cavern/Boseiju-style mana-base shift.

Any future candidate should preserve the 607 cadence package unless a same-lane
cut proves otherwise:

- preserve `Bender's Waterskin` until a same-lane replacement beats 607;
- preserve `Scroll Rack`/topdeck access unless a replacement keeps miracle
  conversion;
- preserve static cost reduction density unless battle traces prove the new
  package replaces that role;
- test power-watch additions under bracket review, not only win rate.
