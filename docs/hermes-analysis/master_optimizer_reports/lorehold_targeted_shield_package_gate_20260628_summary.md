# Lorehold Targeted Shield Package Gate - 2026-06-28

- source_db: `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- postgres_writes: `false`
- packages tested:
  - `gods_willing_commander_shield_cut_promise`: add `Gods Willing`, cut `Promise of Loyalty`
  - `sejiri_shelter_commander_shield_cut_promise`: add `Sejiri Shelter // Sejiri Glacier`, cut `Promise of Loyalty`
- runtime prerequisite: targeted protection responses are executable for Gods Willing / Sejiri-style effects.
- gate runner changes validated: isolated deck process writes game checkpoints, result handoff uses temp JSON instead of large multiprocessing queue payloads, package subprocess has process-group timeout, and package summaries are compact.

## Result

Do not promote either package.

`Gods Willing` proves the new runtime can matter: on seed 7 it improved the weak window from `0-3-0` to `1-2-0` and produced `targeted_protection_granted=1`. It still fails the promotion contract because it collapses seed 42 from `3-0-0` to `1-2-0`. The cheap shield is real, but this exact cut weakens the strong miracle/topdeck conversion pattern too much.

`Sejiri Shelter // Sejiri Glacier` is worse in this model. It does not improve seed 7, regresses seed 20260625, and collapses seed 42. Because the runtime currently evaluates it as the spell face rather than as flexible MDFC land timing, it should not be promoted as a deck-6 replacement.

## Gate Matrix

| Package | Seed | Baseline | Candidate | Delta pp | Targeted protection granted | Miracle casts | Topdeck activations | Verdict |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `Gods Willing` over `Promise of Loyalty` | `7` | `0-3-0` | `1-2-0` | `+33.33` | `1` | `5` | `7` | Positive weak-seed signal only |
| `Gods Willing` over `Promise of Loyalty` | `20260625` | `1-2-0` | `1-2-0` | `0.00` | `0` | `5` | `3` | No aggregate gain |
| `Gods Willing` over `Promise of Loyalty` | `42` | `3-0-0` | `1-2-0` | `-66.67` | `1` | `4` | `0` | Reject |
| `Sejiri Shelter` over `Promise of Loyalty` | `7` | `0-3-0` | `0-3-0` | `0.00` | `1` | `0` | `0` | No gain |
| `Sejiri Shelter` over `Promise of Loyalty` | `20260625` | `1-2-0` | `0-3-0` | `-33.33` | `0` | `1` | `0` | Reject |
| `Sejiri Shelter` over `Promise of Loyalty` | `42` | `3-0-0` | `0-3-0` | `-100.00` | `1` | `2` | `2` | Reject |

## Evidence Files

- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.md`

Package detail markdown kept in repo:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1_gods_willing_commander_shield_cut_promise.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1_sejiri_shelter_commander_shield_cut_promise.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_gods_willing_commander_shield_cut_promise.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed20260625_targeted_shield_v3_sejiri_shelter_commander_shield_cut_promise.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise.md`

## Next Decision

The next search should not be "add one more protection card and cut a five-mana spell" blindly. The stronger route is to preserve the seed-42 topdeck/Squee/Scroll Rack pattern and test protection as either:

- a land-slot or MDFC model that does not reduce high-impact spell density;
- a same-lane replacement for a card with repeated low exposure across winning seeds;
- a runtime-backed play-pattern improvement that changes when existing `Mother of Runes`, `Giver of Runes`, `Dawn's Truce`, or free protection is held up.
