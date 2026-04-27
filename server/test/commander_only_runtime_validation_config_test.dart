import 'package:test/test.dart';

import '../bin/run_commander_only_optimization_validation.dart';

void main() {
  group('RuntimeValidationConfig.parse', () {
    test('usa dry-run por padrao', () {
      final config = RuntimeValidationConfig.parse(const <String>[]);

      expect(config.dryRun, isTrue);
      expect(config.apply, isFalse);
    });

    test('aceita --apply explicito', () {
      final config = RuntimeValidationConfig.parse(const <String>['--apply']);

      expect(config.apply, isTrue);
      expect(config.dryRun, isFalse);
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
  });
}
