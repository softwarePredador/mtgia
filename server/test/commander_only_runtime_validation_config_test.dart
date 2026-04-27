import 'package:test/test.dart';

import '../bin/run_commander_only_optimization_validation.dart';

void main() {
  group('RuntimeValidationConfig.parse', () {
    test('usa dry-run por padrao', () {
      final config = RuntimeValidationConfig.parse(const <String>[]);

      expect(config.dryRun, isTrue);
      expect(config.apply, isFalse);
      expect(config.skipHealthCheck, isFalse);
      expect(config.proveCacheHit, isFalse);
    });

    test('aceita --apply explicito', () {
      final config = RuntimeValidationConfig.parse(const <String>['--apply']);

      expect(config.apply, isTrue);
      expect(config.dryRun, isFalse);
    });

    test('aceita skip health check apenas no dry-run', () {
      final config = RuntimeValidationConfig.parse(
        const <String>['--dry-run', '--skip-health-check'],
      );

      expect(config.dryRun, isTrue);
      expect(config.skipHealthCheck, isTrue);
    });

    test('aceita prova de cache apenas com apply', () {
      final config = RuntimeValidationConfig.parse(
        const <String>['--apply', '--prove-cache-hit'],
      );

      expect(config.apply, isTrue);
      expect(config.proveCacheHit, isTrue);
    });

    test('bloqueia --apply com --dry-run', () {
      expect(
        () => RuntimeValidationConfig.parse(
          const <String>['--apply', '--dry-run'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('Use apenas um modo'),
          ),
        ),
      );
    });

    test('bloqueia skip health check com apply', () {
      expect(
        () => RuntimeValidationConfig.parse(
          const <String>['--apply', '--skip-health-check'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('--skip-health-check so pode ser usado com dry-run'),
          ),
        ),
      );
    });

    test('bloqueia prova de cache no dry-run', () {
      expect(
        () => RuntimeValidationConfig.parse(
          const <String>['--dry-run', '--prove-cache-hit'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            contains('--prove-cache-hit exige --apply'),
          ),
        ),
      );
    });
  });
}
