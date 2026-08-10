import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('community engagement contracts', () {
    test(
      'migration and routes persist comments reports and trade matching',
      () {
        final migrations = File('bin/migrate.dart').readAsStringSync();
        final engagement =
            File('lib/community_engagement_service.dart').readAsStringSync();
        final commentsRoute =
            File(
              'routes/community/decks/[id]/comments/index.dart',
            ).readAsStringSync();
        final reportsRoute =
            File(
              'routes/community/decks/[id]/reports/index.dart',
            ).readAsStringSync();
        final matchesRoute =
            File(
              'routes/community/trade-matches/index.dart',
            ).readAsStringSync();

        expect(migrations, contains("version: '031'"));
        expect(migrations, contains('create_community_engagement_tables'));
        expect(
          migrations,
          contains('CREATE TABLE IF NOT EXISTS deck_comments'),
        );
        expect(
          migrations,
          contains('CREATE TABLE IF NOT EXISTS content_reports'),
        );
        expect(engagement, isNot(contains('ensureSchema')));
        expect(engagement, isNot(contains('CREATE TABLE')));
        expect(engagement, isNot(contains('CREATE INDEX')));
        expect(engagement, contains('findTradeMatches'));
        expect(engagement, contains('collection_availability_snapshot'));
        expect(engagement, contains('wanted_missing_quantity'));
        expect(engagement, contains('COALESCE(c.oracle_id, c.id)'));
        expect(engagement, contains('binder_item_availability'));
        expect(
          engagement,
          contains('item_availability.available_quantity > 0'),
        );
        expect(engagement, contains('bi.id AS binder_item_id'));
        expect(engagement, contains("bi.list_type = 'have'"));
        expect(commentsRoute, contains('HttpMethod.get'));
        expect(commentsRoute, contains('HttpMethod.post'));
        expect(reportsRoute, contains('reportContent'));
        expect(matchesRoute, contains('findTradeMatches'));
        expect(matchesRoute, contains('readAuthenticatedUserId'));
      },
    );

    test('public deck detail exposes visual analysis and comment count', () {
      final route =
          File('routes/community/decks/[id]/index.dart').readAsStringSync();

      expect(route, contains('comment_count'));
      expect(route, contains('comments_summary'));
      expect(route, contains('visual_analysis'));
      expect(route, contains('_buildVisualAnalysis'));
      expect(route, contains('type_distribution'));
      expect(route, contains('c.collector_number'));
      expect(route, contains('c.foil'));
      expect(route, contains('s.name AS set_name'));
      expect(route, contains('s.release_date AS set_release_date'));
      expect(route, contains('SELECT DISTINCT ON (LOWER(code))'));
      expect(route, contains('printingId:'));
      expect(route, contains('oracleId:'));
      expect(route, isNot(contains('user_binder_items')));
      expect(route, isNot(contains('card_localized_names')));
    });

    test(
      'post-game timeline endpoint exposes diagnostics and next actions',
      () {
        final service =
            File(
              'lib/retention/post_game_note_service.dart',
            ).readAsStringSync();
        final route =
            File(
              'routes/decks/[id]/post-game-timeline/index.dart',
            ).readAsStringSync();

        expect(service, contains('buildTimeline'));
        expect(service, contains('dominant_issues'));
        expect(service, contains('next_actions'));
        expect(service, contains('weekly_activity'));
        expect(route, contains('buildTimeline'));
        expect(route, contains('context.read<String>()'));
      },
    );
  });
}
