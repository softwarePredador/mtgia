# Lorehold Profiled Cut Queue Closed Decision - 2026-06-30

Status: `current_profiled_one_for_one_queue_closed`.

Scope:

- protected baseline: deck `607`;
- source queue: profiled same-lane one-for-one package generator;
- variant decks considered: `608` through `616`;
- gate policy: natural equal package gates against real opponents, with deck
  `607` protected as the comparison baseline;
- PostgreSQL writes: `false`;
- source DB mutated: `false`.

What was learned:

- The current one-for-one profiled queue is exhausted for promotion work.
- The latest all-lanes generator evaluated `1080` candidate/cut pairs and
  found `0` preflight-ready packages.
- `31` exact package signatures are now blocked by prior evidence, preventing
  the builder from re-running failed swaps as if they were new hypotheses.
- The protected deck `607` remains unchanged. No current package has earned
  promotion into the ideal Lorehold deck.

Closed package groups:

| Group | Package(s) | Decision |
| --- | --- | --- |
| `spot_removal` | `chaos_warp_same_lane_benchmark_cut_generous_gift` | rejected despite positive aggregate because Winota/fast-pressure critical matchup regressed |
| `discard_ramp_value` | `cool_but_rude_same_lane_benchmark_cut_monument_to_endurance`, `currency_converter_same_lane_benchmark_cut_monument_to_endurance`, `glint_horn_buccaneer_same_lane_benchmark_cut_monument_to_endurance`, `magmakin_artillerist_same_lane_benchmark_cut_monument_to_endurance`, `surly_badgersaur_same_lane_benchmark_cut_monument_to_endurance` | all current direct replacements over `Monument to Endurance` rejected; keep `Monument` protected |
| `big_spell_value` | `possibility_storm_same_lane_benchmark_cut_creative_technique` | rejected for deck promotion; lost the smoke gate, regressed Winota, and had insufficient used-game outcome sample |

Decision:

- Stop the current profiled one-for-one queue here.
- Do not generate more natural same-lane one-for-one gates from the current
  queue until a new cut model or package hypothesis changes the candidate/cut
  space.
- Keep `607` as the baseline protected deck.
- The next deck-learning cycle must use one of these modes:
  - a new safe-cut model that can identify cuts by strategic budget instead of
    direct lane equality only;
  - a multi-card package hypothesis that preserves the fast-pressure matchup
    instead of replacing a protected support card directly;
  - a forced-access diagnostic only when the natural gate failed because the
    card was not meaningfully drawn/cast/used, and only as diagnosis, not as
    direct promotion evidence.

Current next-action planner:

- `gate_ready_now_count=0`;
- `prior_rejected_package_count=59`;
- recommended next action:
  `review_focus_access_trace_then_define_next_deck_or_runtime_package`;
- practical next work: review focus-access traces for weak seeds and design a
  new package around early Top/Rack/Library/Squee/Land Tax reach, or route the
  candidate cards to XMage/runtime implementation before battle if rules are
  missing.

Evidence artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_decision_20260630_goal_learning.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_discard_ramp_value_monument_decision_20260630_goal_learning.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_possibility_storm_creative_technique_decision_20260630_goal_learning.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_discard_ramp_value_monument_closed.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_spot_removal_closed.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_generator_20260630_goal_learning_all_lanes_closed.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_goal_learning_queue_closed.md`
