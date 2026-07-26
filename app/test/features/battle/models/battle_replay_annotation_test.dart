import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_replay_annotation.dart';

void main() {
  group('BattleReplayAnnotation', () {
    test('parses a version-bound immutable annotation', () {
      final annotation = BattleReplayAnnotation.fromJson(const {
        'schema_version': 'battle_replay_annotation_v1',
        'id': 'annotation-1',
        'replay_id': 'replay-1',
        'subject_deck_id': 'deck-1',
        'subject_deck_revision': 'deck_snapshot_sha256_v1:abc',
        'event_ref': 'event:4',
        'kind': 'would_do_differently',
        'payload': {
          'stance': 'would_change',
          'reason': 'Eu protegeria o comandante.',
        },
        'created_at': '2026-07-26T12:00:00Z',
      });

      expect(annotation.kind, BattleReplayAnnotationKind.wouldDoDifferently);
      expect(annotation.eventRef, 'event:4');
      expect(annotation.title, 'Eu faria diferente');
      expect(annotation.detail, contains('Eu protegeria o comandante.'));
      expect(annotation.createdAt.isUtc, isTrue);
    });

    test('rejects unknown schemas and kinds', () {
      Map<String, dynamic> payload({
        String schema = 'battle_replay_annotation_v1',
        String kind = 'note',
      }) => {
        'schema_version': schema,
        'id': 'annotation-1',
        'replay_id': 'replay-1',
        'subject_deck_id': 'deck-1',
        'subject_deck_revision': 'v1:abc',
        'kind': kind,
        'payload': const {'text': 'Nota'},
        'created_at': '2026-07-26T12:00:00Z',
      };

      expect(
        () => BattleReplayAnnotation.fromJson(
          payload(schema: 'battle_replay_annotation_v2'),
        ),
        throwsFormatException,
      );
      expect(
        () => BattleReplayAnnotation.fromJson(payload(kind: 'guess')),
        throwsFormatException,
      );
    });

    test('serializes only the server annotation contract', () {
      const draft = BattleReplayAnnotationDraft(
        kind: BattleReplayAnnotationKind.note,
        eventRef: 'event:2',
        payload: {'title': 'Linha', 'text': 'Rever esta sequência.'},
      );

      expect(draft.toJson(idempotencyKey: 'annotation:test-1'), {
        'kind': 'note',
        'payload': {'title': 'Linha', 'text': 'Rever esta sequência.'},
        'event_ref': 'event:2',
        'idempotency_key': 'annotation:test-1',
      });
    });
  });
}
