# Hermes validation request: semantic fallback fixes

Date: 2026-05-26

Repository: `softwarePredador/mtgia`

Product branch to validate: `master`

Product commit to validate: `f57bb8d3` (`Fix semantic role classification fallbacks`)

Hermes memory branch: `codex/hermes-analysis-docs`

## Objective

Validate the semantic role fallback patch applied to ManaLoom and return a concise, evidence-based response with:

- what was verified;
- whether the patch is safe;
- whether any regression or documentation drift was found;
- which follow-up validations are still required before stronger Semantic Layer v2 enforcement.

Do not invent tasks. Only report findings with concrete file/line or command evidence.

## Context

The product patch was intentionally conservative. It does not replace `semantic_tags_v2` and does not turn Semantic Layer v2 into a hard gate.

The patch improves deterministic fallback classification for known cards where pure oracle-text heuristics were misleading.

Main examples that must stay correct:

- `Walking Ballista` should be treated as `wincon`, not generic `removal`.
- `The One Ring` should be treated as `engine`, not just `draw`.
- `Basalt Monolith` should be treated as `combo_piece`, not only `ramp`.
- `Fierce Guardianship` should be treated as `protection` by curated fallback, not by a global counterspell rule.
- `Endurance` should be treated as `protection`.
- `Fierce Guardianship` should also be detected as bracket `freeInteraction` because it can be cast without paying mana.

## Files to inspect

Product files:

- `server/lib/ai/optimization_functional_roles.dart`
- `server/lib/edh_bracket_policy.dart`
- `server/test/optimization_quality_gate_test.dart`
- `server/test/optimize_runtime_support_test.dart`

Hermes memory files to cross-check:

- `docs/hermes-analysis/manaloom-knowledge/PATCH_PLAN.md`
- `docs/hermes-analysis/PROJECT_MEMORY.md`
- `docs/hermes-analysis/OPEN_RISKS.md`

If the local branch does not contain `docs/hermes-analysis`, switch to `codex/hermes-analysis-docs` only for memory validation. Do not commit product changes to `master`.

## Required validation steps

Run from the Hermes workspace:

```bash
cd /opt/data/workspace/mtgia
git fetch --all --prune
git checkout master
git pull --ff-only origin master
git rev-parse --short HEAD
```

Expected short SHA:

```text
f57bb8d
```

Then run:

```bash
cd /opt/data/workspace/mtgia/server
dart analyze lib/ai/optimization_functional_roles.dart lib/edh_bracket_policy.dart test/optimization_quality_gate_test.dart test/optimize_runtime_support_test.dart
dart test test/optimization_quality_gate_test.dart test/optimization_validator_test.dart test/optimize_runtime_support_test.dart -r expanded
```

If time allows, also run:

```bash
cd /opt/data/workspace/mtgia/server
dart analyze bin lib routes test
dart test
```

## Public backend check

If the production backend has already deployed this SHA, validate the health endpoint:

```bash
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Report the `git_sha`.

If the public backend is not on `f57bb8d3...`, say so explicitly and do not claim public validation.

## Optional optimize scorecard

Only run this if the public backend reports the expected full SHA for the patch:

```bash
cd /opt/data/workspace/mtgia/server
SEMANTIC_SCORECARD_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
SEMANTIC_SCORECARD_LIMIT=10 \
python3 bin/semantic_layer_v2_optimize_scorecard.py \
  --expected-sha <full-public-git-sha> \
  --output test/artifacts/semantic_layer_v2_quality_gate_2026-05-26/optimize_scorecard_after_f57bb8d.json
```

Expected decision is not necessarily hard PASS. The important checks are:

- `semantic_shadow_would_block_approved_jobs` remains `0`;
- `false_positive_candidates` remains `0`;
- no commander loss;
- no unresolved/off-color regression;
- no unexpected actual blocks while enforcement is disabled.

## Questions Hermes must answer

1. Is the patch actually present on `master` at `f57bb8d3`?
2. Do the new tests directly cover the listed examples?
3. Is the `Fierce Guardianship` bracket behavior covered by test?
4. Did any analyzer/test command fail?
5. Does the implementation avoid a broad/global rule that would classify every counterspell as protection?
6. Does the implementation avoid changing production enforcement or enabling Semantic Layer v2 hard gate?
7. Is public backend deployed to this SHA? If yes, what is the public health `git_sha`?
8. If a scorecard was run, did it show any semantic blocker or false positive?
9. Are the Hermes memory docs consistent with the product patch?
10. What exact follow-up remains before considering `SEMANTIC_LAYER_V2_OPTIMIZE_ENFORCEMENT=partial` beyond controlled testing?

## Expected response format

Return a short report in this format:

```markdown
# Hermes response: semantic fallback fixes

Status: PASS | PASS_WITH_RISKS | BLOCKED

Validated product SHA:
- local master:
- public backend:

Commands run:
- ...

Findings:
- P0/P1/P2/P3 or "No findings".

Evidence:
- file:line references and command summaries.

Risks / limits:
- ...

Recommended next action:
- ...
```

## Safety rules

- Do not print secrets, tokens, DSNs, connection strings, decklists, or raw private payloads.
- Do not commit to `master`.
- If updating memory, commit only to `codex/hermes-analysis-docs` and only under `docs/hermes-analysis/`.
- If running a scorecard, save only sanitized summaries.
