import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('product retention and public report contracts', () {
    test('post-game notes are persisted behind authenticated deck ownership',
        () {
      final service =
          File('lib/retention/post_game_note_service.dart').readAsStringSync();
      final indexRoute = File('routes/decks/[id]/post-game-notes/index.dart')
          .readAsStringSync();
      final deleteRoute =
          File('routes/decks/[id]/post-game-notes/[noteId].dart')
              .readAsStringSync();

      expect(service, contains('CREATE TABLE IF NOT EXISTS post_game_notes'));
      expect(service, contains('WHERE id = CAST(@deckId AS uuid)'));
      expect(service, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(service, contains('performed_well JSONB'));
      expect(indexRoute, contains('PostGameNoteService'));
      expect(indexRoute, contains('context.read<String>()'));
      expect(indexRoute, contains('HttpMethod.get'));
      expect(indexRoute, contains('HttpMethod.post'));
      expect(deleteRoute, contains('String deckId'));
      expect(deleteRoute, contains('String noteId'));
      expect(deleteRoute, contains('HttpMethod.delete'));
    });

    test('shareable reports have authenticated creation and public read route',
        () {
      final service =
          File('lib/reports/shareable_report_service.dart').readAsStringSync();
      final createRoute =
          File('routes/decks/[id]/reports/index.dart').readAsStringSync();
      final publicRoute = File('routes/reports/[id].dart').readAsStringSync();
      final webPage = File('../web-public/src/app/reports/[id]/page.tsx')
          .readAsStringSync();

      expect(
          service, contains('CREATE TABLE IF NOT EXISTS shared_deck_reports'));
      expect(service, contains('is_public = TRUE'));
      expect(service, contains('payload JSONB NOT NULL'));
      expect(service, contains('WHERE id = CAST(@deckId AS uuid)'));
      expect(service, contains('AND user_id = CAST(@userId AS uuid)'));
      expect(createRoute, contains('context.read<String>()'));
      expect(createRoute, contains('public_url'));
      expect(publicRoute, contains('getPublicReport'));
      expect(webPage, contains('loadPublicReport'));
      expect(webPage, contains('if (!report) notFound();'));
      expect(webPage, contains('Relatorio compartilhavel'));
      expect(webPage, contains('Trocas sugeridas'));
    });
  });
}
