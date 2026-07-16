import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/database.dart';

void main() {
  group('databasePoolSettings', () {
    test('uses bounded production-safe defaults', () {
      final settings = databasePoolSettings(const {}, sslMode: SslMode.disable);

      expect(settings.maxConnectionCount, 10);
      expect(settings.maxConnectionAge, const Duration(minutes: 5));
      expect(settings.connectTimeout, const Duration(seconds: 8));
      expect(settings.queryTimeout, const Duration(seconds: 60));
      expect(settings.applicationName, 'manaloom-api');
      expect(settings.sslMode, SslMode.disable);
    });

    test('accepts positive environment overrides and rejects invalid ones', () {
      final settings = databasePoolSettings(const {
        'DB_POOL_MAX_CONNECTIONS': '6',
        'DB_POOL_MAX_AGE_SECONDS': '90',
        'DB_CONNECT_TIMEOUT_SECONDS': '0',
        'DB_QUERY_TIMEOUT_SECONDS': 'invalid',
      }, sslMode: SslMode.require);

      expect(settings.maxConnectionCount, 6);
      expect(settings.maxConnectionAge, const Duration(seconds: 90));
      expect(settings.connectTimeout, const Duration(seconds: 8));
      expect(settings.queryTimeout, const Duration(seconds: 60));
      expect(settings.sslMode, SslMode.require);
    });
  });
}
