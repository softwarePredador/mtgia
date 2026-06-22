# Lorehold PG023 Candidate Scan - 2026-06-21

Status: `no_promotion`

## Baseline

- Current canonical runtime deck: PG023 Brainstone over Generous Gift.
- Post-sync smoke:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_121648/summary.json`.
- Result: `4/16`, trusted, `mandatory_gate_divergences=[]`,
  target pressure to Lorehold `222`, `forced_keep_after_bad_mulligan=2`.
- Post-sync full:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`.
- Result: `14/64`, trusted, `mandatory_gate_divergences=[]`.

## Candidate Results

All candidates were temporary SQLite swaps only. The local SQLite deck was
restored after every run.

| Candidate | Artifact | Result | Gate | Decision |
| --- | --- | ---: | --- | --- |
| `Expedition Map` over `Electroduplicate` | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131126/summary.json` | `1/16` | trusted, clean | reject |
| `Reforge the Soul` over `Boros Charm` | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_131606/summary.json` | `3/16` | trusted, clean | reject |
| `Thrill of Possibility` over `Boros Charm` | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132027/summary.json` | `2/16` | trusted, clean | reject |
| `Reprieve` over `Boros Charm` | `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_132537/summary.json` | `4/16` | trusted, clean | reject |

## Reasoning

- `Expedition Map` tested the hypothesis that land tutoring/access to utility
  lands would improve consistency. It materially worsened the 16-seed result.
- `Reforge the Soul` tested another Brainstone/Top/Scroll Rack compatible
  miracle wheel. It underperformed the PG023 smoke and raised low-confidence
  mulligan noise.
- `Thrill of Possibility` tested cheap instant-speed filtering over a
  loss-skewed modal protection slot. It underperformed.
- `Reprieve` tied PG023 on win count, but worsened pressure to Lorehold
  (`267` versus `222`) and increased `forced_keep_after_bad_mulligan`
  (`5` versus `2`) in the 16-seed smoke.

## State After Scan

- No PostgreSQL apply was performed for these candidates.
- No package was generated for these candidates.
- Local SQLite focused check after scans:
  `Boros Charm=1`, `Brainstone=1`, `Electroduplicate=1`, no `Reprieve`,
  `Thrill of Possibility`, `Reforge the Soul`, or `Expedition Map` persisted
  in `deck_id=6`.
- The `latest` symlink points to the last rejected candidate
  `20260621_132537`; canonical runtime validation remains PG023 full
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260621_122732/summary.json`.

## Next Search Direction

- Do not pursue simple land-tutor or generic cantrip substitutions from this
  sample.
- Next useful work should inspect losses where Lorehold keeps a high-scoring
  opener but fails to convert, especially cards that appear in many losses:
  `Birgi`, `Lightning Greaves`, `Electroduplicate`, `Heat Shimmer`, and
  redundant protection/copy packages.
- Any next candidate should first explain which specific losing seeds it is
  expected to flip before running another smoke.
