# XMage Test Scenario Miner

- Generated at: `2026-06-23T18:45:40+00:00`
- Status: `ready`
- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- Mutations performed: `[]`

## Summary

- `cards_with_test_reference`: `2`
- `requested_card_count`: `13`
- `status_counts`: `{'no_exact_test_reference_found': 11, 'test_reference_found': 2}`
- `test_files_scanned`: `2009`
- `usable_scenario_candidate_count`: `1`

## Cards

### Bender's Waterskin

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Emeria's Call // Emeria, Shattered Skyclave

- Status: `test_reference_found`
- Test files: `1`
- Usable scenario candidates: `1`
- `Mage.Tests/src/test/java/org/mage/test/cards/cost/modaldoublefaced/ModalDoubleFacedCardsTest.java` method hits `1`
  - `test_PlayFromNonHand_GraveyardByFlashback` usable=`True` setup=`['addCard', 'removeAllCardsFromLibrary']` actions=`['castSpell', 'activateAbility', 'waitStackResolved']` assertions=`['checkPermanentCount', 'checkGraveyardCount', 'checkPlayableAbility']`

### Molecule Man

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Monument to Endurance

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Pearl Medallion

- Status: `test_reference_found`
- Test files: `1`
- Usable scenario candidates: `0`
- `Mage.Tests/src/test/java/org/mage/test/cards/abilities/keywords/DisturbTest.java` method hits `1`
  - `test_ConditionalCostModifications` usable=`False` setup=`['addCard']` actions=`['activateAbility']` assertions=`[]`

### Promise of Loyalty

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Starfall Invocation

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Surge to Victory

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### The Mind Stone

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### The Scarlet Witch

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Thor, God of Thunder

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Tragic Arrogance

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

### Victory Chimes

- Status: `no_exact_test_reference_found`
- Test files: `0`
- Usable scenario candidates: `0`

## Boundary

- XMage tests are reference evidence only; ManaLoom still needs local focused tests before PG promotion.
- no_exact_test_reference_found does not mean XMage has no card implementation; it only means the test corpus did not reference the card by scanned terms.
