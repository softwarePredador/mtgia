@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/legal_policy.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  Future<http.Response> register(Map<String, dynamic> payload) => http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  Future<List<List<Object?>>> accountRows(String email) async {
    final pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    try {
      final result = await pool.execute(
        Sql.named('''
          SELECT u.terms_version, u.terms_accepted_at,
                 u.privacy_version, u.privacy_accepted_at,
                 COUNT(p.user_id)::int
          FROM users u
          LEFT JOIN user_plans p ON p.user_id = u.id
          WHERE u.email = @email
          GROUP BY u.id
        '''),
        parameters: {'email': email},
      );
      return result.map((row) => row.toList()).toList();
    } finally {
      await pool.close();
    }
  }

  test(
    'required consent rejects atomically and persists exact accepted versions',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final email = 'legal_$suffix@example.invalid';
      final base = <String, dynamic>{
        'username': 'legal_$suffix',
        'email': email,
        'password': 'BetaQa!2026-Deck',
      };

      final missing = await register(base);
      expect(missing.statusCode, 400, reason: missing.body);
      expect(
        (jsonDecode(missing.body) as Map)['error'],
        'legal_acceptance_required',
      );
      expect(await accountRows(email), isEmpty);

      final stale = await register({
        ...base,
        'legal_accepted': true,
        'terms_version': '2026-01-01',
        'privacy_version': currentPrivacyVersion,
      });
      expect(stale.statusCode, 400, reason: stale.body);
      expect(await accountRows(email), isEmpty);

      final accepted = await register({
        ...base,
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      });
      expect(accepted.statusCode, 201, reason: accepted.body);

      final rows = await accountRows(email);
      expect(rows, hasLength(1));
      expect(rows.single[0], currentTermsVersion);
      expect(rows.single[1], isA<DateTime>());
      expect(rows.single[2], currentPrivacyVersion);
      expect(rows.single[3], isA<DateTime>());
      expect(
        rows.single[4],
        1,
        reason: 'free plan must be in same transaction',
      );
    },
    skip: skipIntegration,
  );
}
