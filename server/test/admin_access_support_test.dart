import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/admin_access_support.dart';

void main() {
  test('admin ids accept the canonical and legacy environment keys', () {
    final canonical =
        DotEnv()..addAll({'MANALOOM_ADMIN_USER_IDS': 'user-a, User-B '});
    final legacy =
        DotEnv()..addAll({'TELEMETRY_ADMIN_USER_IDS': 'legacy-user'});

    expect(isConfiguredAdminUserId(userId: 'user-b', env: canonical), isTrue);
    expect(isConfiguredAdminUserId(userId: 'legacy-user', env: legacy), isTrue);
    expect(isConfiguredAdminUserId(userId: 'unknown', env: canonical), isFalse);
  });

  test('operational key is configured, case-insensitive and exact', () {
    final env =
        DotEnv()..addAll({
          'MANALOOM_OPS_API_KEY': '0123456789abcdef0123456789abcdef',
        });

    expect(
      isConfiguredOpsRequestKey(
        headers: const {
          'X-ManaLoom-Ops-Key': '0123456789abcdef0123456789abcdef',
        },
        env: env,
      ),
      isTrue,
    );
    expect(
      isConfiguredOpsRequestKey(
        headers: const {
          'x-manaloom-ops-key': '0123456789abcdef0123456789abcdee',
        },
        env: env,
      ),
      isFalse,
    );
    expect(
      isConfiguredOpsRequestKey(
        headers: const {'x-manaloom-ops-key': 'short'},
        env: DotEnv()..addAll({'MANALOOM_OPS_API_KEY': 'also-short'}),
      ),
      isFalse,
    );
  });

  test('only liveness and readiness health paths remain public', () {
    expect(isPublicHealthPath('/health'), isTrue);
    expect(isPublicHealthPath('/health/live'), isTrue);
    expect(isPublicHealthPath('/health/ready'), isTrue);
    expect(isPublicHealthPath('/health/metrics'), isFalse);
    expect(isPublicHealthPath('/health/dashboard'), isFalse);
    expect(isPublicHealthPath('/health/commercial'), isFalse);
    expect(isPublicHealthPath('/health/ai-history'), isFalse);
    expect(isPublicHealthPath('/health/future-endpoint'), isFalse);
  });

  test('external Commander refresh is guarded before collection starts', () {
    final source =
        File('routes/ai/commander-reference/index.dart').readAsStringSync();
    final guardIndex = source.indexOf('if (shouldRefresh)');
    final refreshIndex = source.indexOf(
      'refreshSummary = await _refreshCommanderFromMtgTop8',
    );

    expect(guardIndex, isNonNegative);
    expect(source, contains('await isConfiguredAdminUser('));
    expect(source, contains('HttpStatus.forbidden'));
    expect(refreshIndex, greaterThan(guardIndex));
  });

  test('ML status is admin-only and uses the request-scoped pool', () {
    final source = File('routes/ai/ml-status/index.dart').readAsStringSync();

    expect(source, contains('context.read<Pool>()'));
    expect(source, contains('context.read<String>()'));
    expect(source, contains('await isConfiguredAdminUser('));
    expect(source, contains('HttpStatus.forbidden'));
    expect(source, isNot(contains('Database()')));
  });
}
