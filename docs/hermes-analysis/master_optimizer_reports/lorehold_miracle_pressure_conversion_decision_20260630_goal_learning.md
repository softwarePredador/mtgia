# Lorehold Miracle Pressure Conversion Decision - 2026-06-30

Status: `rejected_current_from_scratch_shell`.

Scope:

- protected baseline: deck `607`;
- shell:
  `challenger_lorehold_miracle_pressure_conversion_v1`;
- policy: from-scratch shell generated from the Lorehold `607-616` corpus, with
  the `607` land base and protected miracle/protection floor intentionally
  preserved;
- gate: natural equal smoke gate, no forced access, `4` opponents, `1` game per
  opponent, fixed opponent deck `607`.

Why this was tested:

- The current planner found no seed-safe one-card cut and rejected the current
  from-scratch recursion shells.
- This shell was materially different from the rejected pressure-repair shell:
  it kept the `607` land base, kept `Bender's Waterskin`, `Victory Chimes`,
  `The Mind Stone`, `Molecule Man`, `The Scarlet Witch`, `Insurrection`,
  `Storm Herd`, and `Creative Technique`, and added a compact conversion
  package instead of replacing broad pressure/card-flow density.

Result:

| Package | Baseline | Candidate | Winota Baseline | Winota Candidate | Main telemetry | Decision |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `miracle_pressure_conversion_shell_v1` | `1W/3L/0S` | `0W/4L/0S` | `0W/1L/0S` | `0W/1L/0S` | candidate miracle games `2/4`, Squee to graveyard `1/4`, Squee returns `0/4`, Birgi mana games `0/4` | `reject_or_rework` |

Decision:

- Do not confirm this shell to an 8x3 gate.
- Do not promote this shell or use it as proof that any added card belongs in
  the ideal deck.
- Do not rerun this exact add/cut package automatically. It lost the natural
  smoke gate, reduced miracle frequency, and did not convert Squee/Birgi
  telemetry into wins.
- The useful learning is negative: preserving the `607` floor was necessary but
  not sufficient. The next shell must improve actual closing-window execution,
  not just add compact conversion cards.

Evidence artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_matrix.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_from_scratch_challengers_20260630_goal_pressure_conversion_v1_miracle_pressure_conversion_fixed607_gate.md`
