import 'package:postgres/postgres.dart';
import 'package:server/deck_rules_service.dart';
import 'package:test/test.dart';

void main() {
  group('DeckRulesService canonical identity', () {
    test('detects unsupported deck sections before persistence', () {
      expect(
        unsupportedDeckSectionLabels(const [
          {
            'card_id': 'blast-id',
            'quantity': 1,
            'zone': 'sideboard',
          },
          {
            'card_id': 'wish-id',
            'quantity': 1,
            'is_wishboard': true,
          },
        ]),
        equals(['sideboard', 'wishboard']),
      );

      expect(
        () => validateNoUnsupportedDeckSections(cards: const [
          {
            'card_id': 'blast-id',
            'quantity': 1,
            'zone': 'outside the game',
          },
        ]),
        throwsA(
          isA<DeckRulesException>().having(
            (error) => error.message,
            'message',
            contains('outside the game'),
          ),
        ),
      );
    });

    test('detects unsupported raw list maps before import parsing', () {
      expect(
        unsupportedRawDeckSectionLabels(const [
          {
            'card_id': 'card-a',
            'quantity': 1,
            'section': 'Maybeboard',
          },
          '1 Sol Ring',
          {
            'card_id': 'card-b',
            'quantity': 1,
            'is_outside_game': 'true',
          },
        ]),
        equals(['Maybeboard', 'outside-game']),
      );

      expect(unsupportedRawDeckSectionLabels('1 Sol Ring'), isEmpty);
    });

    test('uses oracle_id to enforce Commander singleton across printings',
        () async {
      final session = _DeckRulesFakeSession(
        hasIdentityColumns: true,
        cards: {
          'print-a': _cardRow(
            id: 'print-a',
            oracleId: 'oracle-sol-ring',
            name: 'Sol Ring',
            typeLine: 'Artifact',
          ),
          'print-b': _cardRow(
            id: 'print-b',
            oracleId: 'oracle-sol-ring',
            name: 'Sol Ring',
            typeLine: 'Artifact',
          ),
        },
      );

      await expectLater(
        DeckRulesService(session).validateAndThrow(
          format: 'commander',
          cards: const [
            {'card_id': 'print-a', 'quantity': 1, 'is_commander': false},
            {'card_id': 'print-b', 'quantity': 1, 'is_commander': false},
          ],
        ),
        throwsA(
          isA<DeckRulesException>().having(
            (error) => error.message,
            'message',
            contains('excede o limite de 1'),
          ),
        ),
      );
    });

    test('blocks the commander oracle identity from entering the 99', () async {
      final session = _DeckRulesFakeSession(
        hasIdentityColumns: true,
        cards: {
          'cmd-print-a': _cardRow(
            id: 'cmd-print-a',
            oracleId: 'oracle-lorehold',
            name: 'Lorehold, the Historian',
            typeLine: 'Legendary Creature — Elder Dragon',
            colorIdentity: const ['R', 'W'],
            manaCost: '{R}{W}',
            power: '4',
            toughness: '4',
          ),
          'cmd-print-b': _cardRow(
            id: 'cmd-print-b',
            oracleId: 'oracle-lorehold',
            name: 'Lorehold, the Historian',
            typeLine: 'Legendary Creature — Elder Dragon',
            colorIdentity: const ['R', 'W'],
            manaCost: '{R}{W}',
            power: '4',
            toughness: '4',
          ),
        },
      );

      await expectLater(
        DeckRulesService(session).validateAndThrow(
          format: 'commander',
          cards: const [
            {'card_id': 'cmd-print-a', 'quantity': 1, 'is_commander': true},
            {'card_id': 'cmd-print-b', 'quantity': 1, 'is_commander': false},
          ],
        ),
        throwsA(
          isA<DeckRulesException>().having(
            (error) => error.message,
            'message',
            contains('já está selecionada como comandante'),
          ),
        ),
      );
    });
  });
}

List<Object?> _cardRow({
  required String id,
  required String oracleId,
  required String name,
  required String typeLine,
  List<String> colors = const [],
  List<String> colorIdentity = const [],
  String? oracleText,
  String? manaCost,
  double? cmc,
  String? power,
  String? toughness,
}) {
  return [
    id,
    name,
    typeLine,
    oracleText,
    colors,
    colorIdentity,
    manaCost,
    cmc,
    power,
    toughness,
    oracleId,
  ];
}

class _DeckRulesFakeSession implements Session {
  _DeckRulesFakeSession({
    required this.hasIdentityColumns,
    required this.cards,
  });

  final bool hasIdentityColumns;
  final Map<String, List<Object?>> cards;
  var _executeCount = 0;

  @override
  bool get isOpen => true;

  @override
  Future<void> get closed async {}

  @override
  Future<Statement> prepare(Object query) {
    throw UnimplementedError('prepare is not used by this test fake');
  }

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    _executeCount += 1;
    if (_executeCount == 1) {
      return _result([
        [hasIdentityColumns ? 3 : 0],
      ]);
    }

    if (_executeCount == 2) {
      final ids = (parameters as Map?)?['ids'] as List?;
      final rows = <List<Object?>>[
        for (final id in ids ?? const [])
          if (cards[id] case final row?) row,
      ];
      return _result(rows);
    }

    return _result(const []);
  }
}

Result _result(List<List<Object?>> rows) {
  final schema = ResultSchema(const []);
  return Result(
    rows: [
      for (final row in rows) ResultRow(values: row, schema: schema),
    ],
    affectedRows: rows.length,
    schema: schema,
  );
}
