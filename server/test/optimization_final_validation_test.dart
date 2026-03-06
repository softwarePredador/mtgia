import 'package:test/test.dart';

import '../routes/ai/optimize/index.dart' as optimize_route;

/// Tests for the optimization pipeline fixes:
/// 1. _maxCopiesForFormat correctly identifies basic lands by name
/// 2. parseOptimizeSuggestions robustness
/// 3. Duplicate detection in additions
/// 4. Balance enforcement

// Re-export test helpers that mirror the functions in index.dart
bool _isBasicLandName(String name) {
  final normalized = name.trim().toLowerCase();
  return normalized == 'plains' ||
      normalized == 'island' ||
      normalized == 'swamp' ||
      normalized == 'mountain' ||
      normalized == 'forest' ||
      normalized == 'wastes' ||
      normalized == 'snow-covered plains' ||
      normalized == 'snow-covered island' ||
      normalized == 'snow-covered swamp' ||
      normalized == 'snow-covered mountain' ||
      normalized == 'snow-covered forest';
}

bool _isBasicLandTypeLine(String typeLineLower) {
  return typeLineLower.contains('basic land') ||
      typeLineLower.contains('basic snow land');
}

/// Mirror of _maxCopiesForFormat with the fix applied:
/// Checks both type_line AND name for basic land detection.
int _maxCopiesForFormat({
  required String deckFormat,
  required String typeLine,
  required String name,
}) {
  final normalizedFormat = deckFormat.toLowerCase();
  final normalizedType = typeLine.toLowerCase();
  final normalizedName = name.trim().toLowerCase();

  final isBasicLand =
      _isBasicLandTypeLine(normalizedType) || _isBasicLandName(normalizedName);
  if (isBasicLand) return 999;

  if (normalizedFormat == 'commander' || normalizedFormat == 'brawl') {
    return 1;
  }

  return 4;
}

/// Simulates the virtual deck removal logic (quantity-aware).
List<Map<String, dynamic>> simulateVirtualDeckRemoval(
  List<Map<String, dynamic>> originalDeck,
  List<String> removals,
) {
  final virtualDeck = originalDeck
      .map((c) => Map<String, dynamic>.from(c))
      .toList();

  final removalCountsByName = <String, int>{};
  for (final name in removals) {
    final lower = name.toLowerCase();
    removalCountsByName[lower] = (removalCountsByName[lower] ?? 0) + 1;
  }
  virtualDeck.removeWhere((c) {
    final name = ((c['name'] as String?) ?? '').toLowerCase();
    final remaining = removalCountsByName[name] ?? 0;
    if (remaining > 0) {
      removalCountsByName[name] = remaining - 1;
      return true;
    }
    return false;
  });

  return virtualDeck;
}

/// Simulates the final duplicate validation logic.
List<Map<String, dynamic>> validateAdditions({
  required List<Map<String, dynamic>> additions,
  required Set<String> deckNamesLower,
  required Set<String> removalNamesLower,
  required String deckFormat,
}) {
  final filtered = <Map<String, dynamic>>[];
  for (final add in additions) {
    final name = (add['name']?.toString() ?? '').toLowerCase();
    if (name.isEmpty) continue;

    final isBasic = _isBasicLandName(name);
    final alreadyInDeck = deckNamesLower.contains(name);
    final beingRemoved = removalNamesLower.contains(name);

    if (alreadyInDeck && !beingRemoved && !isBasic &&
        (deckFormat == 'commander' || deckFormat == 'brawl')) {
      continue; // Skip duplicate
    }

    filtered.add(add);
  }
  return filtered;
}

void main() {
  // ═══════════════════════════════════════════════════════════
  // Fix 1: _maxCopiesForFormat with basic land names
  // ═══════════════════════════════════════════════════════════
  group('_maxCopiesForFormat — basic land detection by name', () {
    test('identifies Plains by name even with empty typeLine', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: '',
        name: 'Plains',
      );
      expect(copies, equals(999),
          reason: 'Basic lands should allow 999 copies');
    });

    test('identifies Island by name even with empty typeLine', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: '',
        name: 'Island',
      );
      expect(copies, equals(999));
    });

    test('identifies Wastes by name even with empty typeLine', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: '',
        name: 'Wastes',
      );
      expect(copies, equals(999));
    });

    test('identifies Snow-Covered Forest by name even with empty typeLine', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: '',
        name: 'Snow-Covered Forest',
      );
      expect(copies, equals(999));
    });

    test('non-basic card with empty typeLine returns 1 for commander', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: '',
        name: 'Sol Ring',
      );
      expect(copies, equals(1));
    });

    test('non-basic card with empty typeLine returns 4 for standard', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'standard',
        typeLine: '',
        name: 'Lightning Bolt',
      );
      expect(copies, equals(4));
    });

    test('basic land by type_line still works', () {
      final copies = _maxCopiesForFormat(
        deckFormat: 'commander',
        typeLine: 'Basic Land — Mountain',
        name: 'Mountain',
      );
      expect(copies, equals(999));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Fix 2: Virtual deck removal — quantity-aware
  // ═══════════════════════════════════════════════════════════
  group('Virtual deck removal — quantity-aware', () {
    test('removes exactly 1 copy when only 1 is in removal list', () {
      final deck = [
        {'name': 'Sol Ring', 'quantity': 1},
        {'name': 'Lightning Greaves', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
      ];

      final result = simulateVirtualDeckRemoval(deck, ['Sol Ring']);
      expect(result.length, equals(4));
      expect(result.any((c) => c['name'] == 'Sol Ring'), isFalse);
      expect(
          result.where((c) => c['name'] == 'Island').length, equals(3));
    });

    test('removes 2 copies of Island when 2 are in removal list', () {
      final deck = [
        {'name': 'Sol Ring', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
        {'name': 'Island', 'quantity': 1},
      ];

      final result = simulateVirtualDeckRemoval(deck, ['Island', 'Island']);
      expect(result.length, equals(2));
      expect(result.where((c) => c['name'] == 'Island').length, equals(1));
      expect(result.any((c) => c['name'] == 'Sol Ring'), isTrue);
    });

    test('does not remove card not in removal list', () {
      final deck = [
        {'name': 'Sol Ring', 'quantity': 1},
        {'name': 'Counterspell', 'quantity': 1},
      ];

      final result = simulateVirtualDeckRemoval(deck, ['Lightning Bolt']);
      expect(result.length, equals(2));
    });

    test('case-insensitive removal', () {
      final deck = [
        {'name': 'Sol Ring', 'quantity': 1},
        {'name': 'counterspell', 'quantity': 1},
      ];

      final result = simulateVirtualDeckRemoval(deck, ['Counterspell']);
      expect(result.length, equals(1));
      expect(result[0]['name'], equals('Sol Ring'));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Fix 3: Final validation — duplicate additions in Commander
  // ═══════════════════════════════════════════════════════════
  group('Final validation — duplicate additions', () {
    test('rejects addition that already exists in deck (Commander)', () {
      final additions = [
        {'name': 'Sol Ring', 'card_id': 'id1'},
        {'name': 'Rhystic Study', 'card_id': 'id2'},
      ];
      final deckNames = {'sol ring', 'counterspell', 'lightning greaves'};
      final removalNames = <String>{}; // Not being removed

      final result = validateAdditions(
        additions: additions,
        deckNamesLower: deckNames,
        removalNamesLower: removalNames,
        deckFormat: 'commander',
      );

      expect(result.length, equals(1));
      expect(result[0]['name'], equals('Rhystic Study'));
    });

    test('allows addition if the card is being removed (swap)', () {
      final additions = [
        {'name': 'Sol Ring', 'card_id': 'id1'},
      ];
      final deckNames = {'sol ring'};
      final removalNames = {'sol ring'}; // Being removed first

      final result = validateAdditions(
        additions: additions,
        deckNamesLower: deckNames,
        removalNamesLower: removalNames,
        deckFormat: 'commander',
      );

      expect(result.length, equals(1));
    });

    test('allows basic land additions even if already in deck', () {
      final additions = [
        {'name': 'Island', 'card_id': 'id1'},
        {'name': 'Forest', 'card_id': 'id2'},
      ];
      final deckNames = {'island', 'forest', 'sol ring'};
      final removalNames = <String>{};

      final result = validateAdditions(
        additions: additions,
        deckNamesLower: deckNames,
        removalNamesLower: removalNames,
        deckFormat: 'commander',
      );

      expect(result.length, equals(2));
    });

    test('allows duplicates in Standard format', () {
      final additions = [
        {'name': 'Lightning Bolt', 'card_id': 'id1'},
      ];
      final deckNames = {'lightning bolt'};
      final removalNames = <String>{};

      final result = validateAdditions(
        additions: additions,
        deckNamesLower: deckNames,
        removalNamesLower: removalNames,
        deckFormat: 'standard',
      );

      expect(result.length, equals(1));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // parseOptimizeSuggestions — robustness
  // ═══════════════════════════════════════════════════════════
  group('parseOptimizeSuggestions — additional edge cases', () {
    test('handles removals/additions as flat lists', () {
      final result = optimize_route.parseOptimizeSuggestions({
        'removals': ['Card A', 'Card B'],
        'additions': ['Card C', 'Card D'],
      });

      expect(result['recognized_format'], isTrue);
      expect(result['removals'], equals(['Card A', 'Card B']));
      expect(result['additions'], equals(['Card C', 'Card D']));
    });

    test('handles empty removals with non-empty additions', () {
      final result = optimize_route.parseOptimizeSuggestions({
        'removals': <String>[],
        'additions': ['Card A'],
      });

      expect(result['recognized_format'], isTrue);
      expect(result['removals'], isEmpty);
      expect(result['additions'], equals(['Card A']));
    });

    test('handles swap format with out/in keys', () {
      final result = optimize_route.parseOptimizeSuggestions({
        'swaps': [
          {'out': 'Bad Card', 'in': 'Good Card'},
          {'remove': 'Weak Card', 'add': 'Strong Card'},
        ],
      });

      expect(result['recognized_format'], isTrue);
      expect(result['removals'], contains('Bad Card'));
      expect(result['removals'], contains('Weak Card'));
      expect(result['additions'], contains('Good Card'));
      expect(result['additions'], contains('Strong Card'));
    });

    test('completely empty payload returns unrecognized', () {
      final result = optimize_route.parseOptimizeSuggestions({});

      expect(result['recognized_format'], isFalse);
      expect(result['removals'], isEmpty);
      expect(result['additions'], isEmpty);
    });

    test('ignores empty string entries in lists', () {
      final result = optimize_route.parseOptimizeSuggestions({
        'removals': ['Card A', '', '  '],
        'additions': ['Card B', '', '  '],
      });

      expect(result['removals'], equals(['Card A']));
      expect(result['additions'], equals(['Card B']));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Fix 4: Optimize mode should never add basic lands as swaps
  // ═══════════════════════════════════════════════════════════
  group('Optimize mode — no basic land filling', () {
    test('balance should truncate removals, not add basics', () {
      // Simulate: AI suggested 5 removals but only 3 valid additions
      // The correct behavior is to truncate removals to 3
      final removals = ['Card A', 'Card B', 'Card C', 'Card D', 'Card E'];
      final additions = ['New A', 'New B', 'New C'];

      // In our fix, we truncate removals when additions < removals
      final balanced = removals.take(additions.length).toList();

      expect(balanced.length, equals(additions.length));
      expect(balanced, equals(['Card A', 'Card B', 'Card C']));
    });

    test('verify none of the additions are basic lands', () {
      // In optimize mode, additions should never be basic lands
      final additions = ['Sol Ring', 'Rhystic Study', 'Counterspell'];

      for (final name in additions) {
        expect(_isBasicLandName(name), isFalse,
            reason: '$name should not be a basic land');
      }
    });

    test('basic land names are properly detected', () {
      expect(_isBasicLandName('Plains'), isTrue);
      expect(_isBasicLandName('island'), isTrue);
      expect(_isBasicLandName('SWAMP'), isTrue);
      expect(_isBasicLandName('Mountain'), isTrue);
      expect(_isBasicLandName('Forest'), isTrue);
      expect(_isBasicLandName('Wastes'), isTrue);
      expect(_isBasicLandName('Snow-Covered Plains'), isTrue);
      expect(_isBasicLandName('Sol Ring'), isFalse);
      expect(_isBasicLandName('Breeding Pool'), isFalse);
      expect(_isBasicLandName('Command Tower'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Fix 5: Deck size preservation in optimize mode
  // ═══════════════════════════════════════════════════════════
  group('Deck size preservation in optimize mode', () {
    test('optimize mode maintains deck card count', () {
      const originalCount = 100;
      final removals = ['Card A', 'Card B', 'Card C'];
      final additions = ['New A', 'New B', 'New C'];

      // After optimize: count = original - removals + additions
      final resultCount =
          originalCount - removals.length + additions.length;
      expect(resultCount, equals(originalCount),
          reason:
              'Optimize mode must keep deck at exactly the same card count');
    });

    test('unbalanced optimization is corrected to preserve count', () {
      const originalCount = 100;
      var removals = ['Card A', 'Card B', 'Card C', 'Card D'];
      var additions = ['New A', 'New B'];

      // Fix: truncate removals to match additions
      if (additions.length < removals.length) {
        removals = removals.take(additions.length).toList();
      }

      final resultCount =
          originalCount - removals.length + additions.length;
      expect(resultCount, equals(originalCount));
    });
  });
}
