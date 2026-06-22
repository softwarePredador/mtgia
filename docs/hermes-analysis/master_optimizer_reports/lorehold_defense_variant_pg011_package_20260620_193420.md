# PG-011 Lorehold Defense Variant Package

Timestamp: 2026-06-20 19:34:20 -0300
Owner: Auditor Central

## Scope

- Target deck: `528c877f-f829-4207-95e6-73981776c323`
- Target learned deck: `f46c0421-71b4-4de3-bb79-05a916b4988b`
- Target tables: `deck_cards`, `commander_learned_decks`,
  `card_battle_rules`, `card_function_tags`

## Variant Evidence

- Official post-combat-fix baseline:
  `/Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260620_221318/summary.json`
  reported trusted strategy-learning gates with 1 Lorehold win, 1 stall, and
  14 opponent wins across the 16 seed window.
- Direct temp-db variant B screen:
  `/tmp/manaloom_lorehold_variant_b_mE2pHv/run_20260620_192657`
  replayed the same 16 seeds and produced 3 Lorehold wins, 0 stalls, and
  13 opponent wins.
- Variant B runtime evidence:
  `Ghostly Prison` and `Crawlspace` resolved 5 times each; attack restrictions
  fired 80 times, restricted 52 attackers, and charged 192 generic tax.

## Deck Delta

Out:

- `Storm Herd`
- `Worldfire`
- `Rite of the Dragoncaller`
- `Fiery Emancipation`
- `Mana Geyser`
- `Rise of the Eldrazi`

In:

- `Ghostly Prison`
- `Crawlspace`
- `Chaos Warp`
- `Austere Command`
- `Get Lost`
- `Professional Face-Breaker`

## Battle Rule Delta

- `Crawlspace`: promote existing rule key
  `battle_rule_v1:cefbed3716a64a7d8c9b2497a4986591` to curated verified
  `attack_limit` with `max_attackers_against_you=2`.
- `Ghostly Prison`: promote existing rule key
  `battle_rule_v1:99151859bece89ba3ead032e05b1f65a` to curated verified
  `attack_tax` with `attack_tax_per_creature=2`.
- `Get Lost`: promote existing rule key
  `battle_rule_v1:8e7da3df51386d58c857a596433f73ea` to curated verified
  `remove_creature`.
- Disable stale generated duplicate rows for those three card names.
- Add curated `stax` function tag for `Ghostly Prison` and `Crawlspace`.

## Files

- `lorehold_defense_variant_pg011_precheck_20260620_193420.sql`
- `lorehold_defense_variant_pg011_apply_20260620_193420.sql`
- `lorehold_defense_variant_pg011_rollback_20260620_193420.sql`
- `lorehold_defense_variant_pg011_postcheck_20260620_193420.sql`
