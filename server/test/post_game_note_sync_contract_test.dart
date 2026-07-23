import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('post-game cross-device sync contract', () {
    final service =
        File('lib/retention/post_game_note_service.dart').readAsStringSync();
    final listRoute =
        File('routes/decks/[id]/post-game-notes/index.dart').readAsStringSync();
    final deleteRoute =
        File(
          'routes/decks/[id]/post-game-notes/[noteId].dart',
        ).readAsStringSync();

    test('persists session and deck snapshot metadata', () {
      for (final field in const [
        'play_session_id',
        'session_started_at',
        'session_ended_at',
        'deck_snapshot_hash',
        'deck_version_at',
        'revision',
      ]) {
        expect(service, contains(field));
      }
      expect(service, contains('buildDeckSnapshotHash'));
      expect(service, contains("note['deck_snapshot_hash']"));
      expect(service, contains("note['deck_version_at']"));
      expect(
        service,
        contains(
          'deck_snapshot_hash e deck_version_at devem ser enviados juntos.',
        ),
      );
      expect(service, contains("currentMap['deck_snapshot_hash']"));
      expect(service, contains("currentMap['deck_version_at']"));
      expect(service, contains('revision = revision + 1'));
      expect(service, contains("note['base_revision']"));
    });

    test('tombstones prevent deleted notes from being resurrected', () {
      expect(service, contains('SET result ='));
      expect(
        service,
        contains('deleted_at = CAST(@mutationAt AS timestamptz)'),
      );
      expect(service, contains("if (currentMap['deleted_at'] != null)"));
      expect(service, contains('throw PostGameConflictException(currentJson)'));
      expect(service, isNot(contains('DELETE FROM post_game_notes')));
      expect(listRoute, contains("params['include_deleted'] == 'true'"));
      expect(listRoute, contains("'sync_cursor':"));
    });

    test('sync watermark serializes readers and concurrent writers', () {
      expect(service, contains('UPDATE post_game_sync_state'));
      expect(service, contains("watermark + INTERVAL '1 microsecond'"));
      expect(service, contains('clock_timestamp()'));
      expect(
        service,
        contains('final syncCursor = await _reserveSyncWatermark'),
      );
      expect(
        service,
        contains('final mutationAt = await _reserveSyncWatermark'),
      );
      expect(service, contains('updated_at <= @syncCursor'));
      expect(
        service,
        contains('updated_at > CAST(@updatedSince AS timestamptz)'),
      );
    });

    test('tombstones retain deck identity for client reconciliation', () {
      expect(service, contains("'deck_id': map['deck_id']?.toString() ?? ''"));
      expect(service, contains('if (deletedAt != null) return common;'));
      expect(
        service,
        contains('id, deck_id, created_at, result, table_level, notes,'),
      );
    });

    test('optimistic concurrency remains optional for legacy clients', () {
      expect(service, contains('if (baseRevision != null'));
      expect(listRoute, contains("'error': 'post_game_conflict'"));
      expect(deleteRoute, contains("'if-match'"));
      expect(deleteRoute, contains('HttpStatus.conflict'));
    });
  });
}
