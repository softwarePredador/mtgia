import 'package:test/test.dart';

import '../lib/ai/deck_learning_event_support.dart';

void main() {
  test(
      'loadUsageHotCards SQL avoids cards join fanout across multiple printings',
      () {
    final sql = loadUsageHotCardsSql.toLowerCase();

    expect(sql, contains('left join lateral'));
    expect(sql, contains('limit 1'));
    expect(sql, contains('coalesce(card_lookup.canonical_name'));
    expect(
      sql,
      isNot(contains(
        "join cards c on lower(split_part(c.name, ' // ', 1)) = ccu.card_name_normalized",
      )),
    );
  });

  test('usageHotCardCanonicalNames caps and prefers canonical names', () {
    final names = usageHotCardCanonicalNames(
      [
        {
          'canonical_name': 'Jeska\'s Will',
          'card_name_normalized': 'jeskas will',
        },
        {
          'canonical_name': '',
          'card_name_normalized': 'unexpected windfall',
        },
        {
          'canonical_name': 'Arcane Signet',
          'card_name_normalized': 'arcane signet',
        },
      ],
      limit: 2,
    );

    expect(names, equals(['Jeska\'s Will', 'unexpected windfall']));
  });

  test('usageHotCardCanonicalNames defaults to generation candidate limit', () {
    final hotCards = [
      for (var index = 0;
          index < usageHotCardsGenerationCandidateLimit + 5;
          index++)
        {
          'canonical_name': 'Usage Card $index',
          'card_name_normalized': 'usage card $index',
        },
    ];

    final names = usageHotCardCanonicalNames(hotCards);

    expect(names, hasLength(usageHotCardsGenerationCandidateLimit));
    expect(names.first, equals('Usage Card 0'));
    expect(
      names.last,
      equals('Usage Card ${usageHotCardsGenerationCandidateLimit - 1}'),
    );
  });
}
