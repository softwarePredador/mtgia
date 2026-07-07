import 'dart:math';

import 'package:test/test.dart';

import '../lib/ai/battle_simulator.dart';

void main() {
  test('battle simulator emits visual snapshots with card images', () {
    final deckA = [
      _card(
        id: 'a-land',
        name: 'Plains',
        typeLine: 'Basic Land - Plains',
        quantity: 16,
        imageUrl: 'https://cards.example/plains.jpg',
      ),
      _card(
        id: 'a-creature',
        name: 'Seasoned Hallowblade',
        typeLine: 'Creature - Human Warrior',
        quantity: 44,
        imageUrl: 'https://cards.example/hallowblade.jpg',
        cmc: 2,
        power: '3',
        toughness: '1',
      ),
    ];
    final deckB = [
      _card(
        id: 'b-land',
        name: 'Island',
        typeLine: 'Basic Land - Island',
        quantity: 16,
        imageUrl: 'https://cards.example/island.jpg',
      ),
      _card(
        id: 'b-creature',
        name: 'Wind Drake',
        typeLine: 'Creature - Drake',
        quantity: 44,
        imageUrl: 'https://cards.example/wind-drake.jpg',
        cmc: 3,
        power: '2',
        toughness: '2',
      ),
    ];

    final result = BattleSimulator(
      deckACards: deckA,
      deckBCards: deckB,
      maxTurns: 1,
      random: Random(1),
    ).simulate();
    final json = result.toJson();
    final snapshots = json['visual_snapshots'] as List;

    expect(snapshots, isNotEmpty);
    final first = snapshots.first as Map;
    expect(first['players'], isA<List>());
    final players = first['players'] as List;
    expect(players, hasLength(2));
    final playerA = players.first as Map;
    expect(playerA['hand'], isA<List>());
    expect(playerA['battlefield'], isA<List>());

    final visibleCards = [
      ...(playerA['hand'] as List),
      ...(playerA['battlefield'] as List),
      ...(playerA['graveyard'] as List),
    ].whereType<Map>().toList();
    expect(visibleCards, isNotEmpty);
    expect(
      visibleCards
          .any((card) => card['image_url']?.toString().isNotEmpty ?? false),
      isTrue,
    );
  });
}

Map<String, dynamic> _card({
  required String id,
  required String name,
  required String typeLine,
  required int quantity,
  required String imageUrl,
  int cmc = 0,
  String? power,
  String? toughness,
}) {
  return {
    'id': id,
    'name': name,
    'type_line': typeLine,
    'quantity': quantity,
    'image_url': imageUrl,
    'cmc': cmc,
    'power': power,
    'toughness': toughness,
    'colors': const <String>[],
    'oracle_text': '',
  };
}
