@Tags(['live', 'live_db_write'])
library;

import 'dart:io' show Platform;

import 'package:postgres/postgres.dart';
import 'package:server/push_notification_service.dart';
import 'package:test/test.dart';

void main() {
  final liveRequested = Platform.environment['RUN_INTEGRATION_TESTS'] == '1';
  final liveMutationApproved =
      Platform.environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] ==
      'I_HAVE_EXPLICIT_APPROVAL';
  final skipIntegration =
      !liveRequested
          ? 'Teste live requer RUN_INTEGRATION_TESTS=1.'
          : !liveMutationApproved
          ? 'Teste mutante requer aprovação explícita.'
          : null;
  late Pool pool;

  setUpAll(() {
    if (skipIntegration != null) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  });

  tearDownAll(() async {
    if (skipIntegration != null) return;
    await pool.close();
  });

  Future<String> createUser(String label, String token) async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash, fcm_token)
        VALUES (@username, @email, 'not-used', @token)
        RETURNING id::text AS id
      '''),
      parameters: {
        'username': 'fcm_${label}_$suffix',
        'email': 'fcm_${label}_$suffix@example.invalid',
        'token': token,
      },
    );
    return rows.first.toColumnMap()['id'] as String;
  }

  Future<String?> readToken(String userId) async {
    final rows = await pool.execute(
      Sql.named('SELECT fcm_token FROM users WHERE id = CAST(@id AS uuid)'),
      parameters: {'id': userId},
    );
    return rows.first.toColumnMap()['fcm_token'] as String?;
  }

  Future<void> deleteUser(String userId) => pool.execute(
    Sql.named('DELETE FROM users WHERE id = CAST(@id AS uuid)'),
    parameters: {'id': userId},
  );

  test(
    'invalid provider response clears only the token that was sent',
    () async {
      const oldToken = 'old-registration-token';
      const rotatedToken = 'rotated-registration-token';
      final invalidUserId = await createUser('invalid', oldToken);
      final rotatedUserId = await createUser('rotated', oldToken);

      try {
        await PushNotificationService.sendToUserForTesting(
          pool: pool,
          userId: invalidUserId,
          title: 'test',
          sender: ({
            required projectId,
            required token,
            required title,
            body,
            data,
          }) async {
            expect(token, oldToken);
            return FcmDeliveryOutcome.invalidRegistration;
          },
        );
        expect(await readToken(invalidUserId), isNull);

        await PushNotificationService.sendToUserForTesting(
          pool: pool,
          userId: rotatedUserId,
          title: 'test',
          sender: ({
            required projectId,
            required token,
            required title,
            body,
            data,
          }) async {
            await pool.execute(
              Sql.named('''
                UPDATE users
                SET fcm_token = @token
                WHERE id = CAST(@id AS uuid)
              '''),
              parameters: {'id': rotatedUserId, 'token': rotatedToken},
            );
            return FcmDeliveryOutcome.invalidRegistration;
          },
        );
        expect(await readToken(rotatedUserId), rotatedToken);
      } finally {
        await deleteUser(invalidUserId);
        await deleteUser(rotatedUserId);
      }
    },
    skip: skipIntegration,
  );
}
