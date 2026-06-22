# PG-016 Anti-Combat Candidate Rules Package

- Scope: curate battle rules and protection tags for Norn's Annex, Windborn Muse, Silent Arbiter, Ensnaring Bridge, and Magus of the Moat.
- Purpose: create executable anti-combat candidates for Lorehold deck testing after the trusted battle audit showed 238 opponent combat actions into Lorehold and only 6 into other players.
- Deck mutation: none.
- PostgreSQL source of truth: yes, with reversible backup table `manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500`.
- Runtime caveat: Silent Arbiter, Magus of the Moat, and Norn's Annex are candidate-pass approximations focused on the attack-pressure behavior relevant to Lorehold. Full creature body, global table restriction, one-blocker clause, upkeep costs, and Phyrexian life-payment choice are not fully modeled in this pass.

## Files

- `anti_combat_candidate_rules_pg016_precheck_20260621_011500.sql`
- `anti_combat_candidate_rules_pg016_apply_20260621_011500.sql`
- `anti_combat_candidate_rules_pg016_postcheck_20260621_011500.sql`
- `anti_combat_candidate_rules_pg016_rollback_20260621_011500.sql`

## Expected Postcheck

- `card_rows=5`
- `commander_legal_rows=5`
- `curated_executable_rows=5`
- `stale_enabled_generated_rows=0`
- `protection_function_tag_rows=5`
