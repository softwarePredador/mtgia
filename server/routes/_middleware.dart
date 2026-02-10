import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/database.dart';

// Instancia o banco de dados uma vez.
final _db = Database();
var _connected = false;
var _schemaReady = false;

Handler middleware(Handler handler) {
  // shelf_cors_headers cuida de OPTIONS + headers em todas as respostas,
  // sem substituir os headers originais (faz merge correto).
  return handler
      .use(_dbMiddleware)
      .use(fromShelfMiddleware(corsHeaders()));
}

/// Middleware que conecta ao banco, roda DDL e injeta Pool no contexto.
Middleware _dbMiddleware(Handler handler) {
  return (context) async {
    if (!_connected) {
      await _db.connect();
      _connected = true;
    }

    if (!_schemaReady) {
      await _ensureRuntimeSchema(_db.connection);
      _schemaReady = true;
    }

    return handler.use(provider<Pool>((_) => _db.connection))(context);
  };
}

Future<void> _ensureRuntimeSchema(Pool pool) async {
  // Idempotente: garante compatibilidade com bases antigas após deploy.
  // Importante para validações de Commander (color identity).
  await pool.execute(Sql.named(
      'ALTER TABLE cards ADD COLUMN IF NOT EXISTS color_identity TEXT[]'));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_cards_color_identity ON cards USING GIN (color_identity)'));

  // Social: tabela de follows
  await pool.execute(Sql.named('''
    CREATE TABLE IF NOT EXISTS user_follows (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT uq_follow UNIQUE (follower_id, following_id),
      CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
    )
  '''));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON user_follows (follower_id)'));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_user_follows_following ON user_follows (following_id)'));

  // Épico 4: Mensagens Diretas
  await pool.execute(Sql.named('''
    CREATE TABLE IF NOT EXISTS conversations (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_a_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      user_b_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      last_message_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT uq_conversation UNIQUE (LEAST(user_a_id, user_b_id), GREATEST(user_a_id, user_b_id)),
      CONSTRAINT chk_no_self_chat CHECK (user_a_id != user_b_id)
    )
  '''));
  await pool.execute(Sql.named('''
    CREATE TABLE IF NOT EXISTS direct_messages (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
      sender_id UUID NOT NULL REFERENCES users(id),
      message TEXT NOT NULL,
      read_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  '''));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_dm_conversation ON direct_messages (conversation_id, created_at DESC)'));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_dm_unread ON direct_messages (conversation_id) WHERE read_at IS NULL'));

  // Épico 5: Notificações
  await pool.execute(Sql.named('''
    CREATE TABLE IF NOT EXISTS notifications (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      reference_id UUID,
      title TEXT NOT NULL,
      body TEXT,
      read_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  '''));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, created_at DESC)'));
  await pool.execute(Sql.named(
      'CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (user_id) WHERE read_at IS NULL'));
}
