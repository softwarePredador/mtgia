import 'package:server/deck_request_support.dart';
import 'package:test/test.dart';

void main() {
  group('deck request support', () {
    test('requires a JSON object and typed optional fields', () {
      expect(
        () => requireJsonObject(const <Object>[]),
        throwsA(isA<DeckRequestException>()),
      );
      expect(
        () => readOptionalBool({'is_public': 'true'}, 'is_public'),
        throwsA(isA<DeckRequestException>()),
      );
      expect(
        () => readOptionalList({'cards': <String, dynamic>{}}, 'cards'),
        throwsA(isA<DeckRequestException>()),
      );
    });

    test(
      'rejects non-object list entries instead of silently dropping them',
      () {
        expect(
          () => requireObjectList([
            {'card_id': 'card-1'},
            null,
          ]),
          throwsA(
            isA<DeckRequestException>().having(
              (error) => error.message,
              'message',
              contains('cards[1]'),
            ),
          ),
        );
      },
    );

    test('normalizes positive integer input', () {
      expect(requirePositiveInteger({'quantity': '3'}, 'quantity'), 3);
      expect(
        () => requirePositiveInteger({'quantity': 0}, 'quantity'),
        throwsA(isA<DeckRequestException>()),
      );
    });
  });
}
