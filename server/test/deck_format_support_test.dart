import 'package:server/deck_format_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck format support', () {
    test('normalizes canonical formats and the EDH alias', () {
      expect(normalizeSupportedDeckFormat(' Commander '), 'commander');
      expect(normalizeSupportedDeckFormat('EDH'), 'commander');
      expect(normalizeSupportedDeckFormat('STANDARD'), 'standard');
    });

    test('rejects empty, non-string and unsupported formats', () {
      expect(normalizeSupportedDeckFormat(''), isNull);
      expect(normalizeSupportedDeckFormat(42), isNull);
      expect(normalizeSupportedDeckFormat('invented'), isNull);
      expect(
        unsupportedDeckFormatMessage('invented'),
        contains('Supported formats'),
      );
    });
  });
}
