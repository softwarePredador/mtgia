import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('migration 053 and fresh schema share the annotation contract', () {
    final migration = File('bin/migrate.dart').readAsStringSync();
    final baseline = File('database_setup.sql').readAsStringSync();

    for (final source in [migration, baseline]) {
      expect(
        source,
        contains('CREATE TABLE IF NOT EXISTS battle_replay_annotations'),
      );
      for (final column in const [
        'user_id UUID NOT NULL',
        'replay_id UUID NOT NULL',
        'attempt_id UUID NOT NULL',
        'subject_deck_id UUID NOT NULL',
        'subject_deck_key TEXT NOT NULL',
        'deck_hash_schema TEXT NOT NULL',
        'subject_deck_hash TEXT NOT NULL',
        'subject_deck_revision TEXT NOT NULL',
        'event_ref TEXT',
        'snapshot_ref TEXT',
        'kind TEXT NOT NULL',
        'payload JSONB NOT NULL',
        'idempotency_key TEXT NOT NULL',
        'request_fingerprint TEXT NOT NULL',
        'created_at TIMESTAMP WITH TIME ZONE NOT NULL',
        'updated_at TIMESTAMP WITH TIME ZONE NOT NULL',
      ]) {
        expect(source, contains(column), reason: column);
      }
      expect(source, contains('REFERENCES users(id) ON DELETE CASCADE'));
      expect(
        source,
        contains('REFERENCES battle_simulations(id) ON DELETE CASCADE'),
      );
      expect(source, contains('fk_battle_annotation_attempt_replay'));
      expect(source, contains('chk_battle_annotation_kind'));
      expect(source, contains('chk_battle_annotation_payload'));
      expect(source, contains('chk_battle_annotation_kind_refs'));
      expect(source, contains('chk_battle_annotation_payload_shape'));
      expect(source, contains('UNIQUE (user_id, idempotency_key)'));
      expect(source, contains('uq_battle_annotation_reflection'));
      expect(source, contains('uq_battle_annotation_mulligan'));
      expect(source, contains('uq_battle_annotation_helpful'));
      expect(
        source,
        contains('user_id,\n        replay_id,\n        subject_deck_id,'),
      );
    }

    expect(migration, contains("version: '053'"));
    expect(migration, contains("name: 'create_battle_replay_annotations'"));
    expect(
      migration,
      contains('DROP TABLE IF EXISTS battle_replay_annotations CASCADE'),
    );
  });
}
