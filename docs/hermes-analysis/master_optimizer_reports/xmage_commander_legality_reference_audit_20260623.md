# XMage Commander Legality Reference Audit

Generated at: `2026-06-23T15:37:18+00:00`

Read-only artifact. `mutations_performed=[]`.

- XMage root: `/Users/desenvolvimentomobile/Downloads/mage-master`
- References found: `9/9`
- Metadata rows checked: `0`

| Reference | Status | Signals | Path |
| --- | --- | --- | --- |
| `abstract_commander_deck_validation` | `found` | `color_identity, partner, background, companion, commander_tax, commander_damage` | `Mage.Server.Plugins/Mage.Deck.Constructed/src/mage/deck/AbstractCommander.java` |
| `partner` | `found` | `partner` | `Mage/src/main/java/mage/util/validation/PartnerValidator.java` |
| `partner_with` | `found` | `partner` | `Mage/src/main/java/mage/util/validation/PartnerWithValidator.java` |
| `choose_a_background` | `found` | `partner, background` | `Mage/src/main/java/mage/util/validation/ChooseABackgroundValidator.java` |
| `doctors_companion` | `found` | `partner, companion` | `Mage/src/main/java/mage/util/validation/DoctorsCompanionValidator.java` |
| `commander_game` | `found` | `color_identity, companion, command_zone, commander_tax, commander_damage` | `Mage/src/main/java/mage/game/GameCommanderImpl.java` |
| `commander_replacement` | `found` | `command_zone` | `Mage/src/main/java/mage/abilities/effects/common/continuous/CommanderReplacementEffect.java` |
| `commander_tax` | `found` | `command_zone, commander_tax` | `Mage/src/main/java/mage/abilities/effects/common/cost/CommanderCostModification.java` |
| `commander_damage` | `found` | `command_zone, commander_damage` | `Mage/src/main/java/mage/watchers/common/CommanderInfoWatcher.java` |
