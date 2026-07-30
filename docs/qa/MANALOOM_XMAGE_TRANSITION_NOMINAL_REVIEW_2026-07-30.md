# XMage transition nominal review

- Status: `pass`
- Changed cards: `169`
- Exact nominal references: `5`
- Exact non-executable clearances: `11`
- Reviews before exact clearance: `168`
- Reviews after exact clearance: `157`
- Catalog resolution used as semantic proof: `false`
- Exact semantic clearance activates a runtime card: `false`

## Exact non-executable clearances

- `Avengers Tower`: exact token proof; no direct nominal reference
- `Black Panther, Vanguard`: exact token proof; no direct nominal reference
- `Bullseye, Death Dealer`: exact token proof; no direct nominal reference
- `Currency Converter`: exact token proof; no direct nominal reference
- `Doorman`: exact token proof; no direct nominal reference
- `Metallic Mimic`: exact token proof plus pinned nominal references
- `Repulsor Bots`: exact token proof; no direct nominal reference
- `Restorative Technique`: exact token proof; no direct nominal reference
- `The Ruinous Wrecking Crew`: exact token proof; no direct nominal reference
- `Villainous Hideout`: exact token proof; no direct nominal reference
- `Wondrous Revival`: exact token proof; no direct nominal reference

## Existing nominal reference cards

- `Krark, the Thumbless`: `no_executable_card_delta_known_upstream_risk` (1 scenarios)
- `Metallic Mimic`: `exact_non_executable_tokens_clearance` (6 scenarios)
- `Mjolnir, Hammer of Thor`: `nominal_tests_do_not_cover_executable_hunk` (1 scenarios)
- `SP//dr, Piloted by Peni`: `added_nominal_test_already_passed` (1 scenarios)
- `Sting, Bilbo's Sword`: `added_nominal_test_card_data_warning` (2 scenarios)

## Next actions

- P1 `Swordsman, Sharp Scoundrel`: Keep the card executable/review-required and add controller-boundary scenarios: an equipped creature you control must trigger once, while an opponent's equipped attacker must not trigger.
- P1 `Mjolnir, Hammer of Thor`: Add and pass a transition-specific Channel timing scenario; the existing tests cover equip and damage doubling, not the changed TimingRule.INSTANT hunk.
- P1 `Krark, the Thumbless`: Exercise the copy/LKI branch referenced by upstream issue 12911 or quarantine the card; the existing nominal test does not close that TODO.
- P1 `Mandate of Peace`: Add a copy/LKI stack-removal scenario for upstream issue 12911 or quarantine the card.
- P2 `added_without_exact_nominal_test`: Prioritize released/current product-scope cards, then add focused positive and negative scenarios. Catalog support alone remains non-promoting.
- P2 `modified_executable_without_exact_nominal_test`: Review exact executable hunks and add one hunk-specific scenario per card before changing its disposition.
