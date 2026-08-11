import 'package:server/ai/commander_reference_readiness_cli_support.dart';
import 'package:test/test.dart';

void main() {
  group('scorecard commander selection', () {
    test('preserves repeated --commander selection', () {
      final selection = parseCommanderReferenceReadinessSelection(const [
        '--commander= Zimone, Infinite Analyst ',
        '--commander=Dina, Soul Steeper',
      ]);

      expect(selection.allActiveProfiles, isFalse);
      expect(selection.commanders, [
        'Dina, Soul Steeper',
        'Zimone, Infinite Analyst',
      ]);
    });

    test('preserves semicolon and newline --commanders selection', () {
      final selection = parseCommanderReferenceReadinessSelection(const [
        '--commanders=Zimone, Infinite Analyst;Dina, Soul Steeper\nLorehold, the Historian',
      ]);

      expect(selection.allActiveProfiles, isFalse);
      expect(selection.commanders, [
        'Dina, Soul Steeper',
        'Lorehold, the Historian',
        'Zimone, Infinite Analyst',
      ]);
    });

    test('selects PostgreSQL discovery only when explicitly requested', () {
      final selection = parseCommanderReferenceReadinessSelection(const [
        '--all-active-profiles',
      ]);

      expect(selection.allActiveProfiles, isTrue);
      expect(selection.commanders, isEmpty);
    });

    for (final args in <List<String>>[
      ['--all-active-profiles', '--commander=Dina, Soul Steeper'],
      [
        '--all-active-profiles',
        '--commanders=Dina, Soul Steeper;Lorehold, the Historian',
      ],
      [
        '--commander=Dina, Soul Steeper',
        '--commanders=Lorehold, the Historian',
      ],
    ]) {
      test('rejects ambiguous selection: ${args.join(' + ')}', () {
        expect(
          () => parseCommanderReferenceReadinessSelection(args),
          throwsArgumentError,
        );
      });
    }

    test('rejects missing or empty selection', () {
      expect(
        () => parseCommanderReferenceReadinessSelection(const []),
        throwsArgumentError,
      );
      expect(
        () =>
            parseCommanderReferenceReadinessSelection(const ['--commander=  ']),
        throwsArgumentError,
      );
    });
  });

  group('active usable profile discovery', () {
    test('normalizes query rows without a live connection', () async {
      String? capturedSql;
      final commanders = await discoverActiveUsableCommanderReferenceProfiles(
        query: (sql) async {
          capturedSql = sql;
          return const <Object?>[
            ' Zimone, Infinite Analyst ',
            'Dina, Soul Steeper',
            'dina, soul steeper',
            null,
            '',
            'Lorehold, the Historian',
          ];
        },
      );

      expect(capturedSql, activeUsableCommanderReferenceProfilesSql);
      expect(commanders, [
        'Dina, Soul Steeper',
        'Lorehold, the Historian',
        'Zimone, Infinite Analyst',
      ]);
    });

    test('uses a SELECT-only confidence activation criterion', () {
      final sql = activeUsableCommanderReferenceProfilesSql;
      expect(sql.trimLeft().toUpperCase(), startsWith('SELECT '));
      expect(sql, contains('FROM commander_reference_profiles'));
      expect(sql, contains("profile_json->>'confidence'"));
      expect(sql, contains("IN ('medium', 'medium_high', 'high')"));
      expect(
        RegExp(
          r'\b(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE)\b',
          caseSensitive: false,
        ).hasMatch(sql),
        isFalse,
      );
    });
  });
}
