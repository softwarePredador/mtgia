import 'dart:convert';

import 'package:server/battle/battle_replay_payload_sanitizer.dart';
import 'package:test/test.dart';

void main() {
  test('removes private_state recursively and counts only public own_hand', () {
    final sanitized = sanitizeBattleReplayForStorage({
      'private_state': {
        'own_hand': [
          {'id': 'card-1', 'name': 'Secret Plains'},
          {'id': 'card-2', 'name': 'Secret Commander'},
        ],
      },
      'events': [
        {
          'payload': {
            ' Private-State ': {
              'own_hand': [
                {'id': 'card-3', 'name': 'Nested Private Identity'},
              ],
            },
            'own_hand': [
              {'id': 'card-4', 'name': 'Public Container Secret'},
            ],
          },
        },
      ],
    });

    expect(_normalizedKeys(sanitized), isNot(contains('private_state')));
    expect(_normalizedKeys(sanitized), isNot(contains('own_hand')));
    final event = (sanitized['events'] as List).single as Map;
    final payload = event['payload'] as Map;
    expect(payload['hand_size'], 1);
    final encoded = jsonEncode(sanitized);
    for (final secret in [
      'Secret Plains',
      'card-1',
      'Nested Private Identity',
      'card-3',
      'Public Container Secret',
      'card-4',
    ]) {
      expect(encoded, isNot(contains(secret)));
    }
  });

  test('drops object-shaped hands and derives bounded safe counts', () {
    final sanitized = sanitizeBattleReplayForStorage({
      'players': [
        {
          'name': 'Human',
          'hand': {
            'cards': [
              {'id': 'human-card-1', 'name': 'Hidden One'},
              {'id': 'human-card-2', 'name': 'Hidden Two'},
            ],
            'owner': {'name': 'Private Human Identity'},
          },
        },
        {
          'name': 'Opponent',
          'zones': {
            'own_hand': {
              'count': 3,
              'card_by_id': {
                'opponent-card-1': {'name': 'Hidden Three'},
              },
            },
          },
        },
        {
          'name': 'Malformed',
          'hand_cards': {'card': 'Must Disappear'},
        },
      ],
    });

    final players = sanitized['players'] as List;
    expect((players[0] as Map), containsPair('hand_size', 2));
    final zones = (players[1] as Map)['zones'] as Map;
    expect(zones, containsPair('hand_size', 3));
    expect(zones, isNot(contains('own_hand')));
    expect((players[2] as Map), isNot(contains('hand_cards')));
    expect((players[2] as Map), isNot(contains('hand_size')));

    final encoded = jsonEncode(sanitized);
    for (final secret in [
      'Hidden One',
      'human-card-1',
      'Private Human Identity',
      'opponent-card-1',
      'Hidden Three',
      'Must Disappear',
    ]) {
      expect(encoded, isNot(contains(secret)));
    }
  });

  test('metadata sanitizer removes normalized private_state containers', () {
    final sanitized = sanitizeBattleReplayMetadata({
      'metadata': {
        'private-state': {
          'own_hand': [
            {'id': 'metadata-card', 'name': 'Metadata Secret'},
          ],
        },
      },
    });

    expect(_normalizedKeys(sanitized), isNot(contains('private_state')));
    expect(_normalizedKeys(sanitized), isNot(contains('own_hand')));
    expect(jsonEncode(sanitized), isNot(contains('Metadata Secret')));
    expect(jsonEncode(sanitized), isNot(contains('metadata-card')));
  });
}

Iterable<String> _normalizedKeys(Object? value) sync* {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) {
        yield key.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), '_');
      }
      yield* _normalizedKeys(entry.value);
    }
  } else if (value is List) {
    for (final entry in value) {
      yield* _normalizedKeys(entry);
    }
  }
}
