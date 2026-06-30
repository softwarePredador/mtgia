# Lorehold Storm-Kiln / Arcane Signet Runtime Decision

- generated_at: `2026-06-30`
- status: `rejected_for_deck_promotion_pressure_regression`
- protected_baseline: `deck_607`
- candidate_package: `+Storm-Kiln Artist / -Arcane Signet`
- lane: `spellchain_mana`
- postgres_writes: `false`
- deck_change: `none`

## Why This Was Reopened

The earlier natural confirmation treated `Storm-Kiln Artist` as a creature body
with artifact-power annotation only. That made the card strategically
under-modeled for the Lorehold spell-chain lane, because its relevant deck
function is the magecraft Treasure trigger.

Runtime was upgraded on 2026-06-30 so `Storm-Kiln Artist` now creates one
Treasure whenever its controller casts or copies an instant or sorcery. The
artifact-power bonus remains `annotation_only`; this deck gate only relies on
the mana trigger.

## Runtime Evidence

- Runtime scope:
  `creature_body_artifact_power_annotation_magecraft_treasure_runtime_v1`
- Reviewed rule key:
  `battle_rule_v1:128e222b4de1e6308d98743711b54985`
- Focused runtime test:
  `docs/hermes-analysis/manaloom-knowledge/scripts/test_storm_kiln_artist_runtime.py`
- Executor path:
  `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- Reviewed rule overlay:
  `docs/hermes-analysis/manaloom-knowledge/scripts/reviewed_battle_card_rules.json`
- PostgreSQL sync dry-run:
  `docs/hermes-analysis/master_optimizer_reports/storm_kiln_pg_sync_dry_run_20260630.md`

The focused test proves:

- instant spells trigger Treasure creation;
- sorcery spells trigger Treasure creation;
- non-instant/non-sorcery spells do not trigger it;
- copied instant/sorcery spells are accepted by the trigger path;
- replay events include `trigger_resolved` and `treasure_created` with rule
  provenance.

PostgreSQL/Hermes status:

- `sync_battle_card_rules_pg.py --skip-generated --only-card "Storm-Kiln Artist"`
  selected exactly `1` curated reviewed row.
- No PostgreSQL or SQLite write was executed in this cycle:
  `apply_pg=false`, `apply_sqlite_from_pg=false`.
- The local shell had no PostgreSQL target configured
  (`unknown-host:5432/unknown-db`), so durable PG promotion and PG -> Hermes
  cache refresh remain an operational follow-up before treating the runtime
  rule as globally deployed truth.

## Natural Confirmation

Command family:

```bash
PYTHONHASHSEED=0 python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_seed_matrix.py \
  --source-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --packages storm_kiln_artist_cut_arcane_signet \
  --seeds 20260630,123,999 \
  --games 3 \
  --opponent-limit 8 \
  --opponent-seed 20260629 \
  --ignore-prior-results \
  --stem lorehold_storm_kiln_runtime_confirm_seed_matrix_20260630
```

Primary aggregate report:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_runtime_confirm_seed_matrix_20260630_20260630_165429.md`

Aggregate result:

| Deck | Record | Games | Win rate |
| --- | ---: | ---: | ---: |
| `deck_607` | `27W/44L/1S` | `72` | `38.03%` |
| `+Storm-Kiln Artist / -Arcane Signet` | `29W/43L/0S` | `72` | `40.28%` |

Seed detail:

| Seed | Baseline | Candidate | Delta | Seed decision |
| ---: | --- | --- | ---: | --- |
| `20260630` | `11W/12L/1S` | `10W/14L/0S` | `-4.16pp` | `reject_or_rework` |
| `123` | `5W/19L/0S` | `11W/13L/0S` | `+25.00pp` | `promote_to_deeper_gate` |
| `999` | `11W/13L/0S` | `8W/16L/0S` | `-12.50pp` | `reject_or_rework` |

Direct card-use/runtime evidence across the matrix:

| Event | Count |
| --- | ---: |
| `cost_paid:Storm-Kiln Artist` | `23` |
| `trigger_resolved:Storm-Kiln Artist` | `17` |
| `treasure_created:Storm-Kiln Artist` | `17` |
| Total Storm-Kiln recorded events | `57` |

Strategy telemetry moved in the right Lorehold direction:

| Metric | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| `miracle_cast` | `122` | `191` | `+69` |
| `topdeck_manipulation_activated` | `113` | `178` | `+65` |
| `discard_to_top_replacement` | `62` | `169` | `+107` |
| `lorehold_spell_cast` | `670` | `729` | `+59` |
| `lorehold_spell_rummage` | `19` | `82` | `+63` |
| `lorehold_spell_rummage_discard_to_top` | `3` | `40` | `+37` |
| `lorehold_upkeep_rummage` | `298` | `297` | `-1` |
| `static_cost_reduction_total` | `177` | `190` | `+13` |

## Promotion Decision

Do not promote this swap to the deck.

The candidate has a real positive signal after the runtime fix, but it fails
the frozen Lorehold promotion contract because the fast-pressure Winota slice
regressed:

| Matchup slice | `deck_607` | Candidate |
| --- | ---: | ---: |
| Winota, Joiner of Forces | `4W/5L` | `3W/6L` |

This means `Storm-Kiln Artist` is now a valid positive signal, not a final deck
upgrade over `Arcane Signet`.

## Next Hypothesis

Keep `Arcane Signet` protected in `deck_607`.

If `Storm-Kiln Artist` is revisited, it must be tested as a pressure-safe
package, not as a direct one-card replacement for the generic two-mana rock.
The next valid hypothesis must either:

- preserve the fast-mana/early-stability lane while adding Storm-Kiln, or
- cut a same-function spell-chain slot with weaker pressure performance, then
  rerun the same natural seed matrix against protected `deck_607`.
