import 'package:server/commander_bracket.dart';
import 'package:test/test.dart';

void main() {
  test('accepts the five Commander brackets and normalizes strings', () {
    for (
      var bracket = commanderBracketMin;
      bracket <= commanderBracketMax;
      bracket++
    ) {
      expect(parseCommanderBracket(bracket).value, bracket);
      expect(parseCommanderBracket(' $bracket ').value, bracket);
    }
  });

  test(
    'distinguishes omitted values from malformed and out-of-range input',
    () {
      final omitted = parseCommanderBracket(null);
      expect(omitted.wasProvided, isFalse);
      expect(omitted.value, isNull);
      expect(omitted.error, isNull);

      for (final invalid in <Object>[0, 6, 2.5, true, 'three']) {
        final result = parseCommanderBracket(invalid);
        expect(result.wasProvided, isTrue, reason: 'invalid=$invalid');
        expect(result.value, isNull, reason: 'invalid=$invalid');
        expect(result.error, isNotNull, reason: 'invalid=$invalid');
      }
    },
  );
}
