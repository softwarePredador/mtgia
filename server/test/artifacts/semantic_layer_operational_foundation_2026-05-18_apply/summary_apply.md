# Aggressive Candidate Quality v2 - apply

- Schema version: `aggressive_candidate_quality_v2_stage1`
- DB mutations: `true`
- Cards scanned: `33324`
- Cards with deterministic tags: `23434`
- Function tag rows planned: `59712`
- Role score rows planned: `45425`
- Commander synergy rows planned: `5000`
- Rejection penalty rows planned: `371`
- Stale generated rows before apply/prune: `{card_function_tags: 294, card_role_scores: 1134, commander_card_synergy: 1912, optimize_rejection_penalties: 0}`
- Pruned stale role scores: `1134`

## Guardrails

Samples and lookup SQL keep commander legal/restricted/null status and commander color identity filters; tags never override legalities, color_identity, or bracket policy.

## Top tags

| Tag | Count |
|---|---:|
| draw | 5686 |
| sacrifice | 5611 |
| removal | 5031 |
| graveyard | 4742 |
| graveyard_synergy | 4742 |
| token | 3916 |
| token_maker | 3916 |
| big_spell | 3876 |
| ramp | 3093 |
| protection | 2338 |
| recursion | 1936 |
| lifegain | 1799 |
| mana_fixing | 1617 |
| artifact_synergy | 1407 |
| sacrifice_outlet | 1358 |
| exile_value | 1307 |
| land | 1132 |
| enchantment_synergy | 731 |
| aristocrats | 727 |
| board_wipe | 688 |
