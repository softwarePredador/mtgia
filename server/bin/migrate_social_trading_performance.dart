// ignore_for_file: avoid_print

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Adds non-destructive indexes for Binder/Marketplace/Trades/Messages runtime.
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

  final statements = [
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_offers_sender_updated
      ON trade_offers(sender_id, updated_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_offers_receiver_updated
      ON trade_offers(receiver_id, updated_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_offers_sender_status_updated
      ON trade_offers(sender_id, status, updated_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_offers_receiver_status_updated
      ON trade_offers(receiver_id, status, updated_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_items_offer_direction
      ON trade_items(trade_offer_id, direction)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_messages_offer_created
      ON trade_messages(trade_offer_id, created_at)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_trade_history_offer_created
      ON trade_status_history(trade_offer_id, created_at)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_binder_marketplace_available_created
      ON user_binder_items(created_at DESC)
      WHERE for_trade = TRUE OR for_sale = TRUE
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_binder_user_list_name_filters
      ON user_binder_items(user_id, list_type, condition, for_trade, for_sale)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_created
      ON notifications(user_id, created_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_unread_created
      ON notifications(user_id, created_at DESC)
      WHERE read_at IS NULL
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_direct_messages_conversation_created
      ON direct_messages(conversation_id, created_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_direct_messages_unread_by_conversation
      ON direct_messages(conversation_id, sender_id)
      WHERE read_at IS NULL
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversations_user_a_last
      ON conversations(user_a_id, last_message_at DESC, created_at DESC)
    ''',
    '''
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_conversations_user_b_last
      ON conversations(user_b_id, last_message_at DESC, created_at DESC)
    ''',
  ];

  try {
    print('Adding social trading performance indexes...');
    for (final statement in statements) {
      await connection.execute(statement);
    }
    for (final table in [
      'trade_offers',
      'trade_items',
      'trade_messages',
      'trade_status_history',
      'user_binder_items',
      'notifications',
      'conversations',
      'direct_messages',
    ]) {
      await connection.execute('ANALYZE $table');
    }
    print('Social trading performance migration complete.');
  } finally {
    await connection.close();
  }
}
