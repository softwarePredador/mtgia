import 'dart:io';

import 'package:test/test.dart';

void main() {
  final source =
      File('routes/decks/[id]/optimizations/index.dart').readAsStringSync();

  test('history is read-only and owner scoped', () {
    expect(source, contains('HttpMethod.get'));
    expect(source, isNot(contains('HttpMethod.post')));
    expect(source, contains('deck_id = @deckId'));
    expect(source, contains('user_id = @userId'));
    expect(source, contains('LIMIT 20'));
    expect(source, isNot(contains('INSERT INTO')));
    expect(source, isNot(contains('UPDATE decks')));
    expect(source, isNot(contains('DELETE FROM')));
  });

  test('rollback availability follows the exact persisted snapshot guard', () {
    expect(
      source,
      contains('DeckOptimizationHistoryService.buildDeckSignature'),
    );
    expect(source, contains("eventType == 'optimize_apply'"));
    expect(source, contains('alreadyRolledBack'));
    expect(source, contains('currentSignature == expectedSignature'));
    expect(source, contains("'deck_changed_after_apply'"));
    expect(source, contains("'snapshot_unavailable'"));
  });

  test('public history exposes summaries and never returns raw snapshots', () {
    expect(source, contains("'source_summary': _sourceSummary"));
    expect(source, contains("'removals': _publicChanges"));
    expect(source, contains("'additions': _publicChanges"));
    expect(source, isNot(contains("'before_snapshot':")));
    expect(source, isNot(contains("'after_snapshot':")));
    expect(source, isNot(contains("'recommendation_context':")));
    expect(source, isNot(contains("'report_payload':")));
  });
}
