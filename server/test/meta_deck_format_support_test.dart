import 'package:test/test.dart';

import '../lib/meta/meta_deck_format_support.dart';

void main() {
  group('describeMetaDeckFormat', () {
    test('maps legacy MTGTop8 EDH to duel commander semantics', () {
      final descriptor = describeMetaDeckFormat('EDH');

      expect(descriptor.formatFamily, 'commander');
      expect(descriptor.commanderSubformat, 'duel_commander');
      expect(descriptor.label, contains('Duel Commander'));
    });

    test('maps legacy MTGTop8 cEDH to competitive commander semantics', () {
      final descriptor = describeMetaDeckFormat('cEDH');

      expect(descriptor.formatFamily, 'commander');
      expect(descriptor.commanderSubformat, 'competitive_commander');
      expect(descriptor.label, contains('Competitive Commander'));
    });
  });

  group('meta deck format scopes', () {
    test('keeps broad commander scope as explicit union', () {
      expect(
        metaDeckFormatCodesForCommanderScope('commander'),
        ['EDH', 'cEDH'],
      );
      expect(
        commanderSubformatsForScope('commander'),
        ['duel_commander', 'competitive_commander'],
      );
    });

    test('supports explicit duel and competitive commander scopes', () {
      expect(
        metaDeckFormatCodesForCommanderScope('duel_commander'),
        ['EDH'],
      );
      expect(
        metaDeckFormatCodesForCommanderScope('competitive_commander'),
        ['cEDH'],
      );
    });

    test('maps deck format names to MTGTop8 format codes', () {
      expect(metaDeckFormatCodesForDeckFormat('Commander'), ['EDH', 'cEDH']);
      expect(
        metaDeckFormatCodesForDeckFormat(
          'Commander',
          commanderScope: 'competitive_commander',
        ),
        ['cEDH'],
      );
      expect(metaDeckFormatCodesForDeckFormat('cEDH'), ['cEDH']);
      expect(metaDeckFormatCodesForDeckFormat('duel_commander'), ['EDH']);
      expect(metaDeckFormatCodesForDeckFormat('standard'), ['ST']);
      expect(metaDeckFormatCodesForDeckFormat('modern'), ['MO']);
    });
  });

  group('analytics keys', () {
    test('promotes commander format codes to derived analytics subformats', () {
      expect(metaDeckAnalyticsFormatKey('EDH'), 'duel_commander');
      expect(metaDeckAnalyticsFormatKey('cEDH'), 'competitive_commander');
      expect(metaDeckAnalyticsFormatKey('ST'), 'ST');
    });
  });
}
