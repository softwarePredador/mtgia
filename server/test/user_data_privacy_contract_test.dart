import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('user data privacy contract', () {
    final service =
        File('lib/user_data_privacy_service.dart').readAsStringSync();
    final route = File('routes/users/me/index.dart').readAsStringSync();
    final exportRoute =
        File('routes/users/me/export/index.dart').readAsStringSync();
    final auth = File('lib/auth_service.dart').readAsStringSync();
    final authMiddleware = File('lib/auth_middleware.dart').readAsStringSync();

    test('portable export omits credentials and is never cacheable', () {
      expect(exportRoute, contains("'Cache-Control': 'no-store, max-age=0'"));
      expect(exportRoute, contains("'Content-Disposition':"));
      expect(service, contains("'schema_version': 1"));
      expect(service, contains("'decks': decks"));
      expect(service, contains("'deck_learning_events': deckLearningEvents"));
      expect(service, contains("'battle_simulations': battleSimulations"));
      expect(service, contains("'binder_items': binderItems"));
      expect(service, contains("'post_game_notes': postGameNotes"));
      expect(service, contains("'direct_messages_sent': directMessagesSent"));
      expect(service, contains("'conversations': conversations"));
      expect(service, contains("'feedback': aiFeedback"));
      expect(service, contains("'fallback_telemetry': aiFallbackTelemetry"));
      expect(service, contains("'optimize_cache': aiOptimizeCache"));
      expect(service, contains('IsolationLevel.repeatableRead'));
      expect(service, contains('AccessMode.readOnly'));
      expect(service, contains("'messages_authored_by_other_users'"));
      expect(service, isNot(contains("'password_hash':")));
      expect(service, isNot(contains("'fcm_token':")));
      expect(service, contains("WHEN t.sender_id = CAST(@userId AS uuid)"));
      expect(service, isNot(contains('SELECT to_jsonb(t) FROM trade_offers')));
      expect(service, contains("'notification_message_bodies'"));
    });

    test(
      'account deletion requires exact confirmation and current password',
      () {
        expect(route, contains('accountDeletionConfirmation'));
        expect(route, contains("body['password']"));
        expect(route, contains('InvalidAccountPasswordException'));
        expect(service, contains('verifyPassword(password, passwordHash)'));
        expect(service, contains('pool.runTx'));
        expect(service, contains('FOR UPDATE'));
        expect(service, contains("'deletion_mode': 'anonymized'"));
      },
    );

    test('personal content is removed before account pseudonymization', () {
      expect(service, contains('DELETE FROM post_game_notes'));
      expect(service, contains('DELETE FROM user_binder_items'));
      expect(service, contains('DELETE FROM decks'));
      expect(
        service,
        contains('DELETE FROM deck_learning_events learning_event'),
      );
      expect(service, contains('DELETE FROM battle_simulations simulation'));
      expect(service, contains('INSERT INTO privacy_deleted_deck_tombstones'));
      expect(service, contains('FROM privacy_keyring'));
      expect(service, contains('hmac('));
      expect(service, contains('deck_token'));
      expect(service, isNot(contains('(deck_id, deleted_at)')));
      expect(service, contains('DELETE FROM ai_logs'));
      expect(service, contains('DELETE FROM notifications'));
      expect(service, contains('USING trade_offers t'));
      expect(service, contains('USING conversations c'));
      expect(service, contains("message = '[mensagem removida pelo titular]'"));
      expect(service, contains('attachment_url = NULL'));
      expect(service, contains('tracking_code = NULL'));
      expect(service, contains('INSERT INTO account_deletion_receipts'));
      expect(service, isNot(contains('subject_hash')));
    });

    test('deleted accounts cannot authenticate with old JWTs', () {
      expect(auth, contains('AND deleted_at IS NULL'));
      expect(authMiddleware, contains('getUserFromToken(token)'));
      expect(
        authMiddleware,
        isNot(contains('final payload = authService.verifyToken(token)')),
      );
    });
  });
}
