import 'dart:io';

import 'package:test/test.dart';

final _runtimeDdl = RegExp(
  r'\b(?:create(?:\s+or\s+replace)?|alter|drop)\s+'
  r'(?:unique\s+)?(?:materialized\s+)?'
  r'(?:table|index|view|type|extension|function|trigger|schema)\b',
  caseSensitive: false,
);

void _expectMigrationOnlySchema(String service) {
  expect(_runtimeDdl.hasMatch(service), isFalse);
  expect(service, isNot(contains('ensureSchema')));
}

void main() {
  group('product retention and public report contracts', () {
    test(
      'post-game notes are persisted behind authenticated deck ownership',
      () {
        final migrations = File('bin/migrate.dart').readAsStringSync();
        final service =
            File(
              'lib/retention/post_game_note_service.dart',
            ).readAsStringSync();
        final indexRoute =
            File(
              'routes/decks/[id]/post-game-notes/index.dart',
            ).readAsStringSync();
        final deleteRoute =
            File(
              'routes/decks/[id]/post-game-notes/[noteId].dart',
            ).readAsStringSync();

        expect(migrations, contains("version: '030'"));
        expect(
          migrations,
          contains('CREATE TABLE IF NOT EXISTS post_game_notes'),
        );
        _expectMigrationOnlySchema(service);
        expect(service, contains('WHERE id = CAST(@deckId AS uuid)'));
        expect(service, contains('AND user_id = CAST(@userId AS uuid)'));
        expect(service, contains('@performedWell::jsonb'));
        expect(indexRoute, contains('PostGameNoteService'));
        expect(indexRoute, contains('context.read<String>()'));
        expect(indexRoute, contains('HttpMethod.get'));
        expect(indexRoute, contains('HttpMethod.post'));
        expect(indexRoute, contains('internalServerError'));
        expect(deleteRoute, contains('String deckId'));
        expect(deleteRoute, contains('String noteId'));
        expect(deleteRoute, contains('HttpMethod.delete'));
        expect(deleteRoute, contains('internalServerError'));
        expect(service, contains('buildTimeline'));
        expect(service, contains('diagnostics'));
        expect(service, contains('next_actions'));
      },
    );

    test(
      'shareable reports have authenticated creation and public read route',
      () {
        final migrations = File('bin/migrate.dart').readAsStringSync();
        final service =
            File(
              'lib/reports/shareable_report_service.dart',
            ).readAsStringSync();
        final createRoute =
            File('routes/decks/[id]/reports/index.dart').readAsStringSync();
        final publicRoute = File('routes/reports/[id].dart').readAsStringSync();
        final webPage =
            File(
              '../web-public/src/app/reports/[id]/page.tsx',
            ).readAsStringSync();

        expect(migrations, contains("version: '030'"));
        expect(
          migrations,
          contains('CREATE TABLE IF NOT EXISTS shared_deck_reports'),
        );
        _expectMigrationOnlySchema(service);
        expect(service, contains('is_public = TRUE'));
        expect(service, contains('@payload::jsonb'));
        expect(service, contains('WHERE id = CAST(@deckId AS uuid)'));
        expect(service, contains('AND user_id = CAST(@userId AS uuid)'));
        expect(createRoute, contains('context.read<String>()'));
        expect(createRoute, contains('public_url'));
        expect(createRoute, contains('internalServerError'));
        expect(publicRoute, contains('getPublicReport'));
        expect(publicRoute, contains('internalServerError'));
        expect(webPage, contains('loadPublicReport'));
        expect(webPage, contains('if (!report) notFound();'));
        expect(webPage, contains('Relatorio compartilhavel'));
        expect(webPage, contains('Trocas sugeridas'));
      },
    );

    test('optimization apply events are persisted from deck mutations', () {
      final migrations = File('bin/migrate.dart').readAsStringSync();
      final service =
          File(
            'lib/decks/deck_optimization_history_service.dart',
          ).readAsStringSync();
      final deckRoute = File('routes/decks/[id]/index.dart').readAsStringSync();
      final bulkRoute =
          File('routes/decks/[id]/cards/bulk/index.dart').readAsStringSync();

      expect(migrations, contains("version: '033'"));
      expect(
        migrations,
        contains('CREATE TABLE IF NOT EXISTS deck_optimization_events'),
      );
      _expectMigrationOnlySchema(service);
      expect(service, contains('pending_after_apply'));
      expect(service, contains('normalizeMutationContext'));
      expect(service, contains('optimization_contract'));
      expect(deckRoute, contains('mutation_context'));
      expect(deckRoute, contains('DeckOptimizationHistoryService'));
      expect(deckRoute, contains('Failed to record deck optimization event'));
      expect(bulkRoute, contains('mutation_context'));
      expect(bulkRoute, contains('DeckOptimizationHistoryService'));
      expect(bulkRoute, contains('Failed to record deck optimization event'));
    });
  });
}
