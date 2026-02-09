// ignore_for_file: avoid_print

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

/// Migration: Cria tabela user_binder_items para o sistema de fichário.
Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final host = env['DB_HOST'] ?? 'localhost';
  final port = int.parse(env['DB_PORT'] ?? '5432');
  final db = env['DB_NAME'] ?? 'mtg_db';
  final user = env['DB_USER'] ?? 'postgres';
  final pass = env['DB_PASSWORD'] ?? env['DB_PASS'] ?? 'postgres';

  final pool = Pool.withEndpoints([
    Endpoint(host: host, port: port, database: db, username: user, password: pass),
  ], settings: PoolSettings(sslMode: SslMode.disable));

  print('🗄️  Conectando ao banco de dados...');

  try {
    // Tabela principal do binder
    await pool.execute(Sql.named('''
      CREATE TABLE IF NOT EXISTS user_binder_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
        condition TEXT NOT NULL DEFAULT 'NM'
          CHECK (condition IN ('NM', 'LP', 'MP', 'HP', 'DMG')),
        is_foil BOOLEAN DEFAULT FALSE,
        for_trade BOOLEAN DEFAULT FALSE,
        for_sale BOOLEAN DEFAULT FALSE,
        price DECIMAL(10,2),
        currency TEXT DEFAULT 'BRL',
        notes TEXT,
        language TEXT DEFAULT 'en',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, card_id, condition, is_foil)
      )
    '''));
    print('✅ Tabela user_binder_items criada/verificada');

    // Índices
    await pool.execute(Sql.named(
        'CREATE INDEX IF NOT EXISTS idx_binder_user ON user_binder_items (user_id)'));
    await pool.execute(Sql.named(
        'CREATE INDEX IF NOT EXISTS idx_binder_card ON user_binder_items (card_id)'));
    await pool.execute(Sql.named(
        'CREATE INDEX IF NOT EXISTS idx_binder_for_trade ON user_binder_items (for_trade) WHERE for_trade = TRUE'));
    await pool.execute(Sql.named(
        'CREATE INDEX IF NOT EXISTS idx_binder_for_sale ON user_binder_items (for_sale) WHERE for_sale = TRUE'));
    print('✅ Índices criados/verificados');

    print('\n🎉 Migration do binder concluída com sucesso!');
  } catch (e) {
    print('❌ Erro na migration: $e');
  } finally {
    await pool.close();
  }
}
