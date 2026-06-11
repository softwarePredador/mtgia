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

    test('accepts exact partner-with pairs and rejects mismatched partners',
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

      expect(areCommanderPairingCompatible(captain, recruiter), isTrue);
      expect(areCommanderPairingCompatible(captain, imposter), isFalse);
    });

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

      expect(areCommanderPairingCompatible(doctor, companion), isTrue);
      expect(areCommanderPairingCompatible(nonDoctor, companion), isFalse);
    });
  });
}
