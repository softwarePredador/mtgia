import 'dart:convert';

import 'package:server/card_identity_support.dart';
import 'package:test/test.dart';

void main() {
  group('scryfallIdentityPayload', () {
    test('keeps printing id and oracle id as separate identities', () {
      final payload = scryfallIdentityPayload({
        'id': '11111111-1111-1111-1111-111111111111',
        'oracle_id': '22222222-2222-2222-2222-222222222222',
        'layout': 'normal',
      });

      expect(payload['scryfall_id'], '11111111-1111-1111-1111-111111111111');
      expect(payload['oracle_id'], '22222222-2222-2222-2222-222222222222');
      expect(payload['layout'], 'normal');
      expect(payload['card_faces_json'], isNull);
    });

    test('serializes card faces for face-aware future rules', () {
      final payload = scryfallIdentityPayload({
        'id': '11111111-1111-1111-1111-111111111111',
        'oracle_id': '22222222-2222-2222-2222-222222222222',
        'layout': 'transform',
        'card_faces': [
          {'name': 'Front', 'mana_cost': '{1}{U}'},
          {'name': 'Back', 'type_line': 'Creature'},
        ],
      });

      final decoded = jsonDecode(payload['card_faces_json']!) as List<dynamic>;
      expect(decoded, hasLength(2));
      expect(decoded.first['name'], 'Front');
      expect(payload['layout'], 'transform');
    });

    test('trims empty identity strings to null', () {
      final payload = scryfallIdentityPayload({
        'id': ' ',
        'oracle_id': '',
        'layout': null,
        'card_faces': [],
      });

      expect(payload['scryfall_id'], isNull);
      expect(payload['oracle_id'], isNull);
      expect(payload['layout'], isNull);
      expect(payload['card_faces_json'], isNull);
    });
  });
}
