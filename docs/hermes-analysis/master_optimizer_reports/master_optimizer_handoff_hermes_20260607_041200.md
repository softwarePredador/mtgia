# Hermes Master Optimizer Handoff

- deck_id: 6
- baseline_id: 2
- baseline_wr: 45.0%
- baseline_record: 27W/31L/2S
- status: approved_swaps_ready_for_manual_apply

## Confirmed Candidates

| Verdict | Phase | Add | Cut | Confirm WR | Delta | Record |
| --- | --- | --- | --- | ---: | ---: | --- |
| approve_manual_review | full_confirmation | Sticky Fingers | Storm-Kiln Artist | 55.8% | +10.8pp | 67W/53L/0S |
| reject_or_retest | confirmation | Flare of Duplication | Past in Flames | 41.7% | -3.3pp | 15W/21L/0S |
| candidate_needs_full_confirmation | confirmation | Sticky Fingers | Storm-Kiln Artist | 52.8% | +7.8pp | 19W/17L/0S |

## Quality Blocks

| Add | Cut | Reasons |
| --- | --- | --- |
| Spectral Sailor | Resupply | color_identity_outside_commander:U not subset RW |
| Korvold, Fae-Cursed King | Resupply | color_identity_outside_commander:BGR not subset RW |
| Imperial Seal | Resupply | color_identity_outside_commander:B not subset RW |
| Aether Channeler | Fiery Emancipation | color_identity_outside_commander:U not subset RW |
| Greater Good | Resupply | color_identity_outside_commander:G not subset RW |
| Sylvan Scrying | Imperial Recruiter | color_identity_outside_commander:G not subset RW |
| Valgavoth, Harrower of Souls | Resupply | color_identity_outside_commander:BR not subset RW |
| Eladamri's Call | Imperial Recruiter | color_identity_outside_commander:GW not subset RW |
| Spectral Sailor | Resupply | color_identity_outside_commander:U not subset RW |
| Korvold, Fae-Cursed King | Resupply | color_identity_outside_commander:BGR not subset RW |
| Imperial Seal | Resupply | color_identity_outside_commander:B not subset RW |
| Aether Channeler | Fiery Emancipation | color_identity_outside_commander:U not subset RW |
| Aether Channeler | Fiery Emancipation | missing_card_oracle_cache |
| Humble Defector | Resupply | missing_card_oracle_cache |
| Eladamri's Call | Imperial Recruiter | missing_card_oracle_cache |
| Trumpeting Carnosaur | Generous Gift | missing_card_oracle_cache |
| Siege-Gang Commander | Generous Gift | missing_card_oracle_cache |
| Lotus Vale | Storm-Kiln Artist | missing_card_oracle_cache |
| Sticky Fingers | Storm-Kiln Artist | missing_card_oracle_cache |
| Spectral Sailor | Resupply | color_identity_outside_commander:U not subset RW |

## Next Action

Manual review can inspect the approved rows, then apply with a dedicated rollback-aware apply script. No automatic apply happened in this run.
