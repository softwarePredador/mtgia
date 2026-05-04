import 'package:test/test.dart';

import '../lib/deck_rules_service.dart';
import '../lib/generated_deck_validation_service.dart';

void main() {
  group('GeneratedDeckValidationService', () {
    test('keeps a valid 60-card deck even when one unknown card is removed',
        () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'mountain': _basicLand('mountain-id', 'Mountain', 'R'),
          },
          suggestionsByName: {
            'Mountan': ['Mountain'],
          },
        ),
      );

      final result = await service.validate(
        format: 'standard',
        cards: [
          {'name': 'Mountain', 'quantity': 60},
          {'name': 'Mountan', 'quantity': 1},
        ],
      );

      expect(result.isValid, isTrue);
      expect(result.generatedDeck['commander'], isNull);
      expect(result.invalidCards, equals(['Mountan']));
      expect(result.suggestions['Mountan'], equals(['Mountain']));
      expect((result.generatedDeck['cards'] as List).single, {
        'name': 'Mountain',
        'quantity': 60,
      });
    });

    test('repairs constructed deck below 60 cards with color-matched basics',
        () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'goblin guide': {
              'id': 'goblin-guide-id',
              'name': 'Goblin Guide',
              'type_line': 'Creature - Goblin Scout',
              'color_identity': ['R'],
              'colors': ['R'],
              'mana_cost': '{R}',
            },
            'lightning bolt': {
              'id': 'lightning-bolt-id',
              'name': 'Lightning Bolt',
              'type_line': 'Instant',
              'color_identity': ['R'],
              'colors': ['R'],
              'mana_cost': '{R}',
            },
            'mountain': _basicLand('mountain-id', 'Mountain', 'R'),
          },
        ),
      );

      final result = await service.validate(
        format: 'Standard',
        cards: [
          {'name': 'Goblin Guide', 'quantity': 4},
          {'name': 'Lightning Bolt', 'quantity': 4},
          {'name': 'Mountain', 'quantity': 50},
        ],
      );

      expect(result.isValid, isTrue);
      expect(result.warnings.join('\n'), contains('Auto-reparo'));
      expect(
        (result.generatedDeck['cards'] as List).fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        ),
        equals(60),
      );
      expect(
        (result.generatedDeck['cards'] as List)
            .whereType<Map>()
            .singleWhere((card) => card['name'] == 'Mountain')['quantity'],
        equals(52),
      );
    });

    test('repairs constructed non-basic quantities before validation',
        () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'goblin guide': {
              'id': 'goblin-guide-id',
              'name': 'Goblin Guide',
              'type_line': 'Creature - Goblin Scout',
              'color_identity': ['R'],
              'colors': ['R'],
              'mana_cost': '{R}',
            },
            'mountain': _basicLand('mountain-id', 'Mountain', 'R'),
          },
        ),
      );

      final result = await service.validate(
        format: 'standard',
        cards: [
          {'name': 'Goblin Guide', 'quantity': 8},
          {'name': 'Mountain', 'quantity': 52},
        ],
      );

      expect(result.isValid, isTrue);
      final cards = (result.generatedDeck['cards'] as List).whereType<Map>();
      expect(
        cards.singleWhere((card) => card['name'] == 'Goblin Guide')['quantity'],
        equals(4),
      );
      expect(
        cards.singleWhere((card) => card['name'] == 'Mountain')['quantity'],
        equals(56),
      );
    });

    test('fails commander generation when commander field is missing',
        () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'plains': {'id': 'plains-id', 'name': 'Plains'},
          },
        ),
      );

      final result = await service.validate(
        format: 'commander',
        cards: [
          {'name': 'Plains', 'quantity': 99},
        ],
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(
            'Deck commander precisa de um comandante válido no campo "commander".'),
      );
    });

    test('ignores commander duplicated inside cards list', () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'isamaru, hound of konda': {
              'id': 'cmdr-id',
              'name': 'Isamaru, Hound of Konda',
            },
            'plains': {'id': 'plains-id', 'name': 'Plains'},
          },
        ),
      );

      final result = await service.validate(
        format: 'commander',
        commanderName: 'Isamaru, Hound of Konda',
        cards: [
          {'name': 'Plains', 'quantity': 99},
          {'name': 'Isamaru, Hound of Konda', 'quantity': 1},
        ],
      );

      expect(result.isValid, isTrue);
      expect(result.generatedDeck['commander'],
          {'name': 'Isamaru, Hound of Konda'});
      expect((result.generatedDeck['cards'] as List).single, {
        'name': 'Plains',
        'quantity': 99,
      });
    });

    test(
        'fails commander generation when unresolved cards break exact deck size',
        () async {
      final service = GeneratedDeckValidationService(
        _FakeGeneratedDeckRepository(
          cardsByName: {
            'isamaru, hound of konda': {
              'id': 'cmdr-id',
              'name': 'Isamaru, Hound of Konda',
            },
            'plains': {'id': 'plains-id', 'name': 'Plains'},
          },
          suggestionsByName: {
            'Plins': ['Plains'],
          },
        ),
      );

      final result = await service.validate(
        format: 'commander',
        commanderName: 'Isamaru, Hound of Konda',
        cards: [
          {'name': 'Plains', 'quantity': 98},
          {'name': 'Plins', 'quantity': 1},
        ],
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(
          'Regra violada: deck commander deve ter exatamente 100 cartas (atual: 99).',
        ),
      );
      expect(result.suggestions['Plins'], equals(['Plains']));
    });
  });
}

Map<String, dynamic> _basicLand(String id, String name, String color) {
  final subtype = color == 'C'
      ? ''
      : {
          'W': 'Plains',
          'U': 'Island',
          'B': 'Swamp',
          'R': 'Mountain',
          'G': 'Forest',
        }[color]!;
  return {
    'id': id,
    'name': name,
    'type_line': subtype.isEmpty ? 'Basic Land' : 'Basic Land - $subtype',
    'color_identity': <String>[],
    'colors': <String>[],
    'mana_cost': '',
  };
}

class _FakeGeneratedDeckRepository implements GeneratedDeckRepository {
  _FakeGeneratedDeckRepository({
    required this.cardsByName,
    this.suggestionsByName = const {},
  });

  final Map<String, Map<String, dynamic>> cardsByName;
  final Map<String, List<String>> suggestionsByName;

  @override
  Future<Map<String, List<String>>> findSuggestions(List<String> names) async {
    return {
      for (final name in names)
        if (suggestionsByName.containsKey(name)) name: suggestionsByName[name]!,
    };
  }

  @override
  Future<Map<String, Map<String, dynamic>>> resolveCardNames(
    List<Map<String, dynamic>> parsedItems,
  ) async {
    final resolved = <String, Map<String, dynamic>>{};

    for (final item in parsedItems) {
      final name = (item['name'] as String).trim().toLowerCase();
      final card = cardsByName[name];
      if (card != null) {
        resolved[name] = card;
      }
    }

    return resolved;
  }

  @override
  Future<void> validateDeck({
    required String format,
    required List<Map<String, dynamic>> cards,
  }) async {
    final normalizedFormat = format.trim().toLowerCase();
    final total =
        cards.fold<int>(0, (sum, card) => sum + (card['quantity'] as int));
    final commanders =
        cards.where((card) => card['is_commander'] == true).toList();

    if (normalizedFormat == 'commander') {
      if (commanders.isEmpty) {
        throw DeckRulesException(
          'Regra violada: deck commander precisa de 1 comandante selecionado.',
        );
      }
      if (total != 100) {
        throw DeckRulesException(
          'Regra violada: deck commander deve ter exatamente 100 cartas (atual: $total).',
        );
      }
      return;
    }

    if (normalizedFormat == 'brawl') {
      if (commanders.isEmpty) {
        throw DeckRulesException(
          'Regra violada: deck brawl precisa de 1 comandante selecionado.',
        );
      }
      if (total != 60) {
        throw DeckRulesException(
          'Regra violada: deck brawl deve ter exatamente 60 cartas (atual: $total).',
        );
      }
      return;
    }

    for (final card in cards) {
      final name = (card['name'] ?? '').toString();
      final typeLine = (card['type_line'] ?? '').toString().toLowerCase();
      final isBasic = typeLine.contains('basic land') ||
          {
            'plains',
            'island',
            'swamp',
            'mountain',
            'forest',
            'wastes',
          }.contains(name.toLowerCase());
      final quantity = card['quantity'] as int;
      if (!isBasic && quantity > 4) {
        throw DeckRulesException(
          'Regra violada: "$name" excede o limite de 4 cópia(s) para o formato $normalizedFormat.',
          cardName: name,
        );
      }
    }

    if (total < 60) {
      throw DeckRulesException(
        'Regra violada: deck $normalizedFormat precisa de pelo menos 60 cartas (atual: $total).',
      );
    }
  }
}
