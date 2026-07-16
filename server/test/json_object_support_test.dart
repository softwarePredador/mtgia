import 'package:server/json_object_support.dart';
import 'package:test/test.dart';

void main() {
  group('JSON object input support', () {
    test('copies object input into a typed map', () {
      final parsed = requireJsonObject(<Object, Object?>{
        'deck_id': ' deck-1 ',
      });

      expect(parsed, equals({'deck_id': ' deck-1 '}));
      expect(readOptionalJsonString(parsed, 'deck_id'), equals('deck-1'));
    });

    test('rejects non-object JSON roots and non-string fields', () {
      expect(
        () => requireJsonObject(const ['deck-1']),
        throwsA(isA<JsonObjectValidationException>()),
      );
      expect(
        () => readOptionalJsonString({'deck_id': 42}, 'deck_id'),
        throwsA(isA<JsonObjectValidationException>()),
      );
    });

    test('bounds user-provided strings before route work starts', () {
      expect(
        () => readOptionalJsonString(
          {'archetype': 'x' * 41},
          'archetype',
          maxLength: 40,
        ),
        throwsA(isA<JsonObjectValidationException>()),
      );
    });

    test(
      'optional object body accepts empty input but rejects malformed JSON',
      () {
        expect(decodeOptionalJsonObject('  '), isEmpty);
        expect(decodeOptionalJsonObject('{"force":true}'), {'force': true});
        expect(
          () => decodeOptionalJsonObject('{not-json'),
          throwsA(isA<JsonObjectValidationException>()),
        );
        expect(
          () => decodeOptionalJsonObject('[]'),
          throwsA(isA<JsonObjectValidationException>()),
        );
      },
    );

    test('optional booleans preserve the declared type contract', () {
      expect(readOptionalJsonBool(const {}, 'force'), isFalse);
      expect(readOptionalJsonBool({'force': true}, 'force'), isTrue);
      expect(
        () => readOptionalJsonBool({'force': 'true'}, 'force'),
        throwsA(isA<JsonObjectValidationException>()),
      );
    });
  });
}
