# Lorehold Manual Cut Review - 2026-06-28

- Generated at: `2026-06-30T16:07:33Z`
- Strategy audit: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Cut model: `docs/hermes-analysis/master_optimizer_reports/lorehold_access_cut_model_20260630_post_pg282_final_eight.json`
- Exposure profiles: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_card_exposure_profile_20260627_v2_role_fix.json, /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_cut_exposure_profile_20260628_v1.json`
- Safe-cut replanner: `docs/hermes-analysis/master_optimizer_reports/lorehold_safe_cut_replanner_20260630_post_pg282_final_eight.json`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Manual cut reviews: `0`
- Contextual lane reviews: `0`
- Decision counts: `{}`
- Automatic gate-ready count: `0`
- Cut evidence status counts: `{"blocked_by_cut_safety": 8, "blocked_by_prior_rejection": 23, "measured_cut_exposure_needs_same_lane_benchmark": 1, "measured_high_cut_exposure": 7, "never_cut": 29, "same_lane_only": 2, "structural_dependency": 24}`
- Cut evidence action counts: `{"blocked": 62, "commander": 1, "mana_base": 28, "manual_same_lane_only": 1, "requires_same_lane_gate": 2}`
- Safe next action: No automatic gate is justified from this cut review; build a seed-safe tutor cut, a non-Squee recursion package, or a lane-specific exposure model before battle.

## External Research Used As Heuristic Context

- [EDHREC - Miracles Every Turn With Lorehold, the Historian](https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander): Lorehold's core loop is first-draw miracle timing, opponent-upkeep rummage, topdeck manipulation, Library of Leng, and high-impact instant/sorcery hits. Use: `heuristic_context_only`.
- [EDHREC - Lorehold, the Historian: Boros Miracles on a Budget](https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget): The deck needs a high instant/sorcery density so miracle draws do not become dead non-spell hits. Use: `heuristic_context_only`.
- [Card Kingdom - 10 Crazy Synergy Cards for Lorehold, the Historian](https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/): Community deck tech highlights Library of Leng and reanimation/discard routes as real Lorehold subpackages. Use: `heuristic_context_only`.
- [Reddit r/EDHBrews - Commander Deck Tech: Lorehold, the Historian](https://www.reddit.com/r/EDHBrews/comments/1ssny05/commander_deck_tech_lorehold_the_historian/): Community discussion reinforces discard, topdeck control, suspend/miracle, and reanimation as plausible lanes, but not as promotion evidence by itself. Use: `heuristic_context_only`.

## Cut Evidence Expansion

| Card | Status | Action | Lorehold Variants | Exposure | Reasons |
| --- | --- | --- | ---: | ---: | --- |

## Profiled Same-Lane Cut Candidates

| Card | Status | Action | Exposure | Role | Reasons |
| --- | --- | --- | ---: | --- | --- |
| Creative Technique | `same_lane_only` | `requires_same_lane_gate` | 0 | unmeasured | Cut-safety permits only a same-lane win after prior strong-seed regression. |
| Bender's Waterskin | `same_lane_only` | `requires_same_lane_gate` | 0 | unmeasured | Cut-safety permits only a same-lane win after prior strong-seed regression. |
| Winds of Abandon | `measured_cut_exposure_needs_same_lane_benchmark` | `manual_same_lane_only` | 60 | spot_removal | Replay profile measured 60 deduplicated exposures, so this is not a blind low-use cut.; Measured role is spot_removal.; Exposure signals: paid_cast_exposure, spot_removal. |

## Protected By Measured Exposure

| Card | Exposure | Role | Reasons |
| --- | ---: | --- | --- |
| Generous Gift | 249 | spot_removal | Replay profile measured 249 deduplicated exposures for this cut slot.; Measured role is spot_removal.; Exposure signals: miracle_hit, paid_cast_exposure, spot_removal, tutor_target. |
| Path to Exile | 412 | spot_removal | Replay profile measured 412 deduplicated exposures for this cut slot.; Measured role is spot_removal.; Exposure signals: miracle_hit, paid_cast_exposure, spot_removal. |
| Swords to Plowshares | 228 | spot_removal | Replay profile measured 228 deduplicated exposures for this cut slot.; Measured role is spot_removal.; Exposure signals: miracle_hit, paid_cast_exposure, spot_removal. |
| Esper Sentinel | 672 | draw_filter_value | Replay profile measured 672 deduplicated exposures for this cut slot.; Measured role is draw_filter_value.; Exposure signals: draw_filter_value, paid_cast_exposure, tutor_target. |
| Monument to Endurance | 375 | discard_ramp_value | Replay profile measured 375 deduplicated exposures for this cut slot.; Measured role is discard_ramp_value.; Exposure signals: discard_payoff, paid_cast_exposure, ramp_engine. |
| Smothering Tithe | 340 | ramp_engine | Replay profile measured 340 deduplicated exposures for this cut slot.; Measured role is ramp_engine.; Exposure signals: discard_or_rummage_context, paid_cast_exposure, ramp_engine, tutor_target. |
| Sensei's Divining Top | 1669 | draw_filter_value | Replay profile measured 1669 deduplicated exposures for this cut slot.; Measured role is draw_filter_value.; Exposure signals: draw_filter_value, paid_cast_exposure. |

## Manual Cut Reviews

| Candidate | Proposed Cut | Decision | Action | Main Reasons |
| --- | --- | --- | --- | --- |

## Contextual Lane Reviews

| Candidate | Decision | Action | Prior Evidence | Cut Search |
| --- | --- | --- | --- | --- |

## Next Actions

- P1 `preserve_squee_while_testing_recursion_variants`: Squee is an observed champion/probation recursion engine; Volcanic Vision and Restoration Seminar need another cut or multi-card package.
- P2 `gate_austere_over_emeria_only_as_tradeoff`: Emeria now has measured token/protection exposure; Austere Command must prove board-reset value beats rebuild/protection loss.
- P3 `rebuild_tutor_tests_around_seed_safe_cuts`: Gamble and Enlightened Tutor are runtime-ready, but prior tests over Thor/Creative regressed the protected seed.
