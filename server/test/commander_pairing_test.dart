import 'package:server/commander_pairing.dart';
import 'package:test/test.dart';

void main() {
  group('normalizePhysicalCardCopyName', () {
    test('uses the front physical card name for split or MDFC labels', () {
      expect(
        normalizePhysicalCardCopyName('Legion Leadership // Legion Stronghold'),
        'legion leadership',
      );
      expect(normalizePhysicalCardCopyName('  Sol   Ring  '), 'sol ring');
    });
  });

  group('areCommanderPairingCompatible', () {
    test('accepts two generic partner commanders', () {
      final first = CommanderPairingCard(
        name: 'Tymna the Weaver',
        typeLine: 'Legendary Creature — Human Cleric',
        oracleText: 'Partner',
      );
      final second = CommanderPairingCard(
        name: 'Thrasios, Triton Hero',
        typeLine: 'Legendary Creature — Merfolk Wizard',
        oracleText: 'Partner',
      );

      expect(areCommanderPairingCompatible(first, second), isTrue);
    });

    test('does not mix generic Partner with partner-text variants', () {
      final generic = CommanderPairingCard(
        name: 'Tymna the Weaver',
        typeLine: 'Legendary Creature — Human Cleric',
        oracleText: 'Partner',
      );
      final friendsForever = CommanderPairingCard(
        name: 'Cecily, Haunted Mage',
        typeLine: 'Legendary Creature — Human Wizard',
        oracleText: 'Partner — Friends forever',
      );

      expect(hasGenericPartnerCommanderPairAbility(generic), isTrue);
      expect(hasGenericPartnerCommanderPairAbility(friendsForever), isFalse);
      expect(areCommanderPairingCompatible(generic, friendsForever), isFalse);
    });

    test('requires an exact matching partner-text variant', () {
      final friendsForever = CommanderPairingCard(
        name: 'Cecily, Haunted Mage',
        typeLine: 'Legendary Creature — Human Wizard',
        oracleText: 'Partner—Friends forever',
      );
      final legacyFriendsForever = CommanderPairingCard(
        name: 'Sophina, Spearsage Deserter',
        typeLine: 'Legendary Creature — Human Soldier',
        oracleText: 'Friends forever',
      );
      final survivors = CommanderPairingCard(
        name: 'Rick, Steadfast Leader',
        typeLine: 'Legendary Creature — Human Soldier',
        oracleText: 'Partner—Survivors',
      );

      expect(
        areCommanderPairingCompatible(friendsForever, legacyFriendsForever),
        isTrue,
      );
      expect(areCommanderPairingCompatible(friendsForever, survivors), isFalse);
    });

    test(
      'accepts exact partner-with pairs and rejects mismatched partners',
      () {
        final captain = CommanderPairingCard(
          name: 'Blaring Captain',
          typeLine: 'Legendary Creature — Azra Warrior',
          oracleText: 'Partner with Blaring Recruiter',
        );
        final recruiter = CommanderPairingCard(
          name: 'Blaring Recruiter',
          typeLine: 'Legendary Creature — Elf Warrior',
          oracleText: 'Partner with Blaring Captain',
        );
        final imposter = CommanderPairingCard(
          name: 'Blaring Recruiter Adept',
          typeLine: 'Legendary Creature — Elf Warrior',
          oracleText: 'Partner',
        );
        final oneSidedRecruiter = CommanderPairingCard(
          name: 'Blaring Recruiter',
          typeLine: 'Legendary Creature — Elf Warrior',
          oracleText: 'Partner',
        );

        expect(areCommanderPairingCompatible(captain, recruiter), isTrue);
        expect(areCommanderPairingCompatible(captain, imposter), isFalse);
        expect(
          areCommanderPairingCompatible(captain, oneSidedRecruiter),
          isFalse,
          reason: 'CR 702.124j requires each card to name the other.',
        );
      },
    );

    test('accepts choose-a-background plus a legendary Background', () {
      final commander = CommanderPairingCard(
        name: 'Gale, Waterdeep Prodigy',
        typeLine: 'Legendary Creature — Human Wizard',
        oracleText: 'Choose a Background',
      );
      final background = CommanderPairingCard(
        name: 'Scion of Halaster',
        typeLine: 'Legendary Enchantment — Background',
        oracleText: 'Commander creatures you own have ...',
      );

      expect(areCommanderPairingCompatible(commander, background), isTrue);
    });

    test('accepts friends forever pairs', () {
      final first = CommanderPairingCard(
        name: 'Cecily, Haunted Mage',
        typeLine: 'Legendary Creature — Human Wizard',
        oracleText: 'Friends forever',
      );
      final second = CommanderPairingCard(
        name: 'Sophina, Spearsage Deserter',
        typeLine: 'Legendary Creature — Human Soldier',
        oracleText: 'Friends forever',
      );

      expect(areCommanderPairingCompatible(first, second), isTrue);
    });

    test('accepts doctors companion only with a Time Lord Doctor', () {
      final doctor = CommanderPairingCard(
        name: 'The Tenth Doctor',
        typeLine: 'Legendary Creature — Time Lord Doctor',
        oracleText: 'Allons-y!',
      );
      final companion = CommanderPairingCard(
        name: 'Rose Tyler',
        typeLine: 'Legendary Creature — Human',
        oracleText: "Doctor's companion",
      );
      final nonDoctor = CommanderPairingCard(
        name: 'River Song',
        typeLine: 'Legendary Creature — Human Time Lord',
        oracleText: "Doctor's companion",
      );
      final doctorWithExtraType = CommanderPairingCard(
        name: 'The Human Doctor',
        typeLine: 'Legendary Creature — Human Time Lord Doctor',
        oracleText: 'Allons-y!',
      );
      final nonLegendaryCompanion = CommanderPairingCard(
        name: 'A Passing Companion',
        typeLine: 'Creature — Human',
        oracleText: "Doctor's companion",
      );

      expect(areCommanderPairingCompatible(doctor, companion), isTrue);
      expect(areCommanderPairingCompatible(nonDoctor, companion), isFalse);
      expect(
        areCommanderPairingCompatible(doctorWithExtraType, companion),
        isFalse,
        reason: 'CR 702.124m forbids other creature types on the Doctor.',
      );
      expect(
        areCommanderPairingCompatible(doctor, nonLegendaryCompanion),
        isFalse,
        reason: 'Doctor\'s companion must itself be a legendary creature.',
      );
    });
  });
}
