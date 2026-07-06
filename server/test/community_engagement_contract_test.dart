import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('community engagement contracts', () {
    test('migration and routes persist comments reports and trade matching',
        () {
      final migrations = File('bin/migrate.dart').readAsStringSync();
      final engagement =
          File('lib/community_engagement_service.dart').readAsStringSync();
      final commentsRoute =
          File('routes/community/decks/[id]/comments/index.dart')
              .readAsStringSync();
      final reportsRoute =
          File('routes/community/decks/[id]/reports/index.dart')
              .readAsStringSync();
      final matchesRoute =
          File('routes/community/trade-matches/index.dart').readAsStringSync();

      expect(migrations, contains("version: '031'"));
      expect(migrations, contains('create_community_engagement_tables'));
      expect(migrations, contains('CREATE TABLE IF NOT EXISTS deck_comments'));
      expect(
          migrations, contains('CREATE TABLE IF NOT EXISTS content_reports'));
      expect(engagement, contains('findTradeMatches'));
      expect(engagement, contains("bi.list_type = 'want'"));
      expect(engagement, contains("bi.list_type = 'have'"));
      expect(commentsRoute, contains('HttpMethod.get'));
      expect(commentsRoute, contains('HttpMethod.post'));
      expect(reportsRoute, contains('reportContent'));
      expect(matchesRoute, contains('findTradeMatches'));
      expect(matchesRoute, contains('readAuthenticatedUserId'));
    });

    test('public deck detail exposes visual analysis and comment count', () {
      final route = File('routes/community/decks/[id].dart').readAsStringSync();

      expect(route, contains('comment_count'));
      expect(route, contains('comments_summary'));
      expect(route, contains('visual_analysis'));
      expect(route, contains('_buildVisualAnalysis'));
      expect(route, contains('type_distribution'));
    });

    test('post-game timeline endpoint exposes diagnostics and next actions',
        () {
      final service =
          File('lib/retention/post_game_note_service.dart').readAsStringSync();
      final route = File('routes/decks/[id]/post-game-timeline/index.dart')
          .readAsStringSync();

      expect(service, contains('buildTimeline'));
      expect(service, contains('dominant_issues'));
      expect(service, contains('next_actions'));
      expect(service, contains('weekly_activity'));
      expect(route, contains('buildTimeline'));
      expect(route, contains('context.read<String>()'));
    });
  });
}
