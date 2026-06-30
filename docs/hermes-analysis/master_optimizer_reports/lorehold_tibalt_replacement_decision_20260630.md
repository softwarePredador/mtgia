# Lorehold Tibalt Replacement Decision 2026-06-30

- status: `ready`
- scope: pressure/spell-protection lane for protected baseline `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`
- decision: `reject_tested_replacements_keep_deck_607`

## Question

Recent 72-game evidence showed `Tibalt's Trickery` had zero card events in the
current `607` baseline, while many pressure, wipe, miracle, ramp, and protection
anchors were exercised. The question was whether that low-exposure spell
protection slot could be upgraded without cutting already-protected cards.

The tested replacements were:

| Candidate | Add | Cut | Structural result |
| --- | --- | --- | --- |
| `candidate_607_boros_charm_tibalts_trickery_v1` | `Boros Charm` | `Tibalt's Trickery` | tied `607`, score `141.036`, intent `100.0` |
| `candidate_607_silence_tibalts_trickery_v1` | `Silence` | `Tibalt's Trickery` | tied `607`, score `141.036`, intent `100.0` |
| `candidate_607_grand_abolisher_tibalts_trickery_v1` | `Grand Abolisher` | `Tibalt's Trickery` | tied `607`, score `141.036`, intent `100.0` |

Local/source signals supported the test but not promotion by themselves:

- `Boros Charm` appears in Lorehold variants `609`, `612`, `613`, `614`, and
  `615`; EDHREC local snapshot has `3482/7651` inclusion.
- `Silence` appears in variants `612`, `613`, `614`, `615`, and `616`; EDHREC
  local snapshot has `501/7651` inclusion.
- `Grand Abolisher` appears in variants `613`, `615`, and `616`; EDHREC local
  snapshot has `901/7651` inclusion.
- All three have executable local battle rules.

## Smoke Gate

Smoke used `opponent_seed=20260630`, `simulation_seed=20260630`, 8 real
opponents, and 3 games per opponent.

| Candidate | Baseline `607` | Candidate | Added-card evidence | Decision |
| --- | ---: | ---: | --- | --- |
| `Boros Charm` over `Tibalt's Trickery` | `6/24` | `8/24` | `Boros Charm` resolved `6`, spell cast `3`, miracle cast `3` | confirm |
| `Silence` over `Tibalt's Trickery` | `6/24` | `10/24` | `Silence` cost paid `1`, spell cast `1` | confirm because result was high but exposure was low |
| `Grand Abolisher` over `Tibalt's Trickery` | `6/24` | `4/24` | `Grand Abolisher` cost paid `4`, spell cast `4`, resolved `3` | reject smoke |

`Grand Abolisher` is rejected from this exact slot. It reduced the already-hard
pressure sample and did not justify losing an instant/sorcery spell.

## Confirmed Gates

Confirmed gates used the same opponent window as the current 2026-06-30
promotion checks: `opponent_seed=20260629`, seeds `20260630`, `123`, and `999`,
8 real opponents, and 3 games per opponent per seed.

| Candidate | `607` aggregate | Candidate aggregate | Added-card evidence | Fast pressure result | Decision |
| --- | ---: | ---: | --- | --- | --- |
| `Boros Charm` over `Tibalt's Trickery` | `30/72` | `21/72` | `Boros Charm` resolved `8`, spell cast `4`, miracle cast `4`, cost paid `1` | Winota `0/9` vs `607` `3/9` | reject |
| `Silence` over `Tibalt's Trickery` | `30/72` | `27/72` | `Silence` accessed `22/72`, drawn `12/72`, spell cast `15`, resolved `13` | Winota `1/9` vs `607` `3/9` | reject |

Strategic telemetry also rejected promotion:

| Candidate | Miracle casts | Topdeck activations | Lorehold spell casts | Note |
| --- | ---: | ---: | ---: | --- |
| `607` baseline | `137` | `132` | `729` | protected baseline |
| `Boros Charm` candidate | `129` | `105` | `613` | lower conversion and lower pressure result |
| `Silence` candidate | `129` | `95` | `744` | more spells but weaker topdeck/miracle and lower wins |

## Decision

Do not promote any tested `Tibalt's Trickery` replacement.

`Tibalt's Trickery` remains protected until a same-function replacement beats
`607` in the confirmed real-opponent gate. The reason is not that the card had
high recent exposure. The reason is that three same-lane replacements were
tested and the two confirmable ones lost after real use.

## Evidence Paths

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_boros_charm_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_silence_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260630_grand_abolisher_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_boros_charm_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_silence_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260630_grand_abolisher_tibalts_trickery_v1.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed123_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_silence_tibalt_confirm_20260630_seed20260630_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_silence_tibalt_confirm_20260630_seed123_real8_games3.md`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_silence_tibalt_confirm_20260630_seed999_real8_games3.md`

## Next Step

Continue from `607` as protected baseline. The next candidate should not cut
`Tibalt's Trickery`, `High Noon`, `Promise of Loyalty`, `Avatar's Wrath`, or
the protected miracle/ramp/value anchors unless a new candidate is a direct
same-function replacement and beats the confirmed gate.
