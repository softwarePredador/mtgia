import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_optimization_event.dart';

void main() {
  test('parses paired changes, source summary and rollback guard', () {
    final event = DeckOptimizationEvent.fromJson({
      'id': 'event-1',
      'event_type': 'optimize_apply',
      'mode': 'optimize',
      'intensity': 'focused',
      'archetype': 'artifacts',
      'bracket': 3,
      'selected_change_count': 4,
      'removals': [
        {'card_id': 'old-1', 'name': 'Old Card'},
        {'card_id': 'old-2', 'name': 'Slow Card'},
      ],
      'additions': [
        {'card_id': 'new-1', 'name': 'New Card'},
        {'card_id': 'new-2', 'name': 'Fast Card'},
      ],
      'validation_status': 'validated',
      'battle_status': 'pending_after_apply',
      'battle_message': 'Teste em mesa pendente.',
      'created_at': '2026-08-05T12:00:00.000Z',
      'can_rollback': true,
      'rollback_reason': '',
      'source_summary': {'has_meta_reference': true, 'reference_count': 2},
    });

    expect(event.isApply, isTrue);
    expect(event.isRollback, isFalse);
    expect(event.pairCount, 2);
    expect(event.canRollback, isTrue);
    expect(event.bracket, 3);
    expect(event.sourceSummary['reference_count'], 2);
    expect(event.createdAt, DateTime.parse('2026-08-05T12:00:00.000Z'));
  });

  test('uses the shortest lane as the number of safe pairs', () {
    final event = DeckOptimizationEvent.fromJson({
      'id': 'event-2',
      'event_type': 'optimize_apply',
      'removals': const [
        {'name': 'One'},
        {'name': 'Two'},
      ],
      'additions': const [
        {'name': 'Replacement'},
      ],
    });

    expect(event.pairCount, 1);
    expect(event.createdAt, isNull);
    expect(event.sourceSummary, isEmpty);
  });
}
