// ignore_for_file: avoid_print

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Adds the covering index used by GET /market/movers.
Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final host = env['DB_HOST'] ?? 'localhost';
  final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
  final database = env['DB_NAME'] ?? 'mtg_builder';
  final username = env['DB_USER'] ?? 'postgres';
  final password = env['DB_PASS'] ?? env['DB_PASSWORD'];

  final connection = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('Adding market movers covering index...');
    await connection.execute('''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_price_history_date_card_price
      ON price_history(price_date DESC, card_id)
      INCLUDE (price_usd)
    ''');
    await connection.execute('ANALYZE price_history');
    print('Market movers performance migration complete.');
  } finally {
    await connection.close();
  }
}
