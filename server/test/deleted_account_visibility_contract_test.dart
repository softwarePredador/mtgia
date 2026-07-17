import 'dart:io';

import 'package:test/test.dart';

String source(String path) => File(path).readAsStringSync();

void main() {
  group('deleted-account visibility and interaction contract', () {
    test('public discovery excludes deleted accounts and their inventory', () {
      for (final path in const [
        'routes/community/users/index.dart',
        'routes/community/users/[id].dart',
        'routes/community/decks/index.dart',
        'routes/community/decks/[id]/index.dart',
        'routes/community/binders/[userId].dart',
        'routes/community/marketplace/index.dart',
        'lib/community_engagement_service.dart',
      ]) {
        expect(
          source(path),
          contains('deleted_at IS NULL'),
          reason: '$path must hide deleted accounts',
        );
      }
    });

    test('new social writes lock and require active participants', () {
      for (final path in const [
        'routes/users/[id]/follow/index.dart',
        'routes/conversations/index.dart',
        'routes/conversations/[id]/messages.dart',
        'routes/trades/index.dart',
        'routes/trades/[id]/messages.dart',
        'routes/trades/[id]/respond.dart',
        'routes/trades/[id]/status.dart',
      ]) {
        final content = source(path);
        expect(content, contains('deleted_at IS NULL'), reason: path);
        expect(content, contains('FOR UPDATE'), reason: path);
      }
      expect(
        source('lib/community_request_auth.dart'),
        contains('getUserFromToken(token)'),
      );
    });

    test('database guards serialize every user-linked write with deletion', () {
      final migration = source('bin/migrate.dart');

      expect(
        migration,
        contains('CREATE OR REPLACE FUNCTION manaloom_require_active_user'),
      );
      expect(migration, contains("MESSAGE = 'inactive_user_reference'"));
      expect(
        migration,
        contains("constraint_row.confrelid = 'users'::regclass"),
      );
      expect(migration, contains('FOR UPDATE'));
      expect(
        migration,
        contains('CREATE OR REPLACE FUNCTION manaloom_guard_battle_simulation'),
      );
      expect(
        migration,
        contains(
          'CREATE OR REPLACE FUNCTION manaloom_guard_deck_learning_event',
        ),
      );
    });

    test('notifications and push require active targets and actors', () {
      final notifications = source('lib/notification_service.dart');
      final push = source('lib/push_notification_service.dart');
      final privacy = source('lib/user_data_privacy_service.dart');

      expect(notifications, contains('_createFromActiveActor'));
      expect(notifications, contains('deleted_at IS NULL'));
      expect(push, contains('recipient.deleted_at IS NULL'));
      expect(push, contains('actor.deleted_at IS NULL'));
      expect(privacy, contains('USING trade_offers t'));
      expect(privacy, contains('USING conversations c'));
    });

    test('historical records remain readable only as pseudonymous history', () {
      final privacy = source('lib/user_data_privacy_service.dart');

      expect(privacy, contains("display_name = 'Usuário excluído'"));
      expect(privacy, contains("message = '[mensagem removida pelo titular]'"));
      expect(privacy, contains('attachment_url = NULL'));
      expect(privacy, contains('tracking_code = NULL'));
    });
  });
}
