# Aggressive Candidate Quality v2 - dry_run

- Schema version: `aggressive_candidate_quality_v2_stage1`
- DB mutations: `false`
- Cards scanned: `33312`
- Cards with deterministic tags: `20007`
- Function tag rows planned: `33021`
- Role score rows planned: `30997`
- Commander synergy rows planned: `5000`
- Rejection penalty rows planned: `371`
- Stale generated rows before apply/prune: `{card_function_tags: 0, card_role_scores: 0, commander_card_synergy: 0, optimize_rejection_penalties: 0}`
- Pruned stale role scores: `0`

## Guardrails

Samples and lookup SQL keep commander legal/restricted/null status and commander color identity filters; tags never override legalities, color_identity, or bracket policy.

## Top tags

| Tag | Count |
|---|---:|
| sacrifice | 5610 |
| graveyard | 4723 |
| removal | 4700 |
| token | 3912 |
| draw | 3619 |
| ramp | 3092 |
| mana_fixing | 1616 |
| protection | 1234 |
| recursion | 1209 |
| board_wipe | 834 |
| aristocrats | 702 |
| tutor | 633 |
| counterspell | 439 |
| wincon | 402 |
| stax | 149 |
| combo_piece | 147 |
