import 'package:meta/meta.dart' show visibleForTesting;
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

/// Classe para gerenciar a conexão com o banco de dados PostgreSQL.
///
/// Utiliza o padrão Singleton para garantir uma única instância do Pool de conexões.
class Database {
  late Pool _pool;
  bool _connected = false;

  // Singleton pattern
  static Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  @visibleForTesting
  static void resetForTesting() {
    _instance = Database._internal();
  }

  /// Verifica se o banco está conectado.
  bool get isConnected => _connected;

  /// Retorna a instância do Pool.
  ///
  /// Se a conexão não estiver ativa, lança uma exceção.
  Pool get connection {
    if (!_connected) {
      throw Exception('A conexão com o banco de dados não foi inicializada. Chame connect() primeiro.');
    }
    return _pool;
  }

  /// Carrega as variáveis de ambiente e estabelece o Pool de conexões.
  ///
  /// Testa a conexão real com um `SELECT 1` após criar o Pool.
  /// Se `DB_SSL_MODE` não estiver definido, tenta primeiro com SSL e faz
  /// fallback para conexão sem SSL (comum em VPS/Docker sem cert).
  Future<void> connect() async {
    if (_connected) return;

    // Carrega as variáveis de ambiente do arquivo .env
    final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();

    final host = env['DB_HOST'];
    final port = int.tryParse(env['DB_PORT'] ?? '');
    final database = env['DB_NAME'];
    final username = env['DB_USER'];
    final password = env['DB_PASS'];
    final environment = (env['ENVIRONMENT'] ?? 'development').toLowerCase();

    if (host == null || port == null || database == null || username == null || password == null) {
      print('❌ Erro: Variáveis de ambiente do banco não configuradas.');
      print('   Necessárias: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS');
      return;
    }

    print('🔌 Conectando ao banco: $host:$port/$database (env: $environment)');

    final endpoint = Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    );

    // Se o usuário definiu DB_SSL_MODE, respeita. Senão, tenta smart fallback.
    final explicitSsl = _parseSslMode(env['DB_SSL_MODE']);

    if (explicitSsl != null) {
      // Modo SSL explícito — usa direto sem fallback.
      final ok = await _tryConnect(endpoint, explicitSsl);
      if (!ok) {
        print('❌ Falha ao conectar com SSL: ${explicitSsl.name}');
      }
      return;
    }

    // Smart fallback: tenta disable primeiro (mais comum em Docker/VPS),
    // depois require se falhar.
    final modes = [SslMode.disable, SslMode.require];
    for (final mode in modes) {
      final ok = await _tryConnect(endpoint, mode);
      if (ok) return;
      print('⚠️  SSL ${mode.name} falhou, tentando próximo...');
    }

    print('❌ Não foi possível conectar ao banco com nenhum modo SSL.');
  }

  /// Tenta criar o pool e validar com `SELECT 1`.
  Future<bool> _tryConnect(Endpoint endpoint, SslMode sslMode) async {
    Pool? pool;
    try {
      pool = Pool.withEndpoints(
        [endpoint],
        settings: PoolSettings(
          maxConnectionCount: 10,
          sslMode: sslMode,
        ),
      );

      // Testa a conexão real (o Pool é lazy, sem isso não sabemos se funciona).
      await pool.execute(Sql.named('SELECT 1'));

      _pool = pool;
      _connected = true;
      print('✅ Pool de conexões inicializado (SSL: ${sslMode.name}).');
      return true;
    } catch (e) {
      print('⚠️  Erro ao conectar (SSL: ${sslMode.name}): $e');
      try { await pool?.close(); } catch (_) {}
      return false;
    }
  }

  /// Fecha a conexão com o banco de dados.
  Future<void> close() async {
    if (!_connected) return;
    await _pool.close();
    _connected = false;
    print('Conexão com o PostgreSQL fechada.');
  }
}

SslMode? _parseSslMode(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  return switch (value) {
    'disable' || 'off' || 'false' || '0' => SslMode.disable,
    'require' || 'on' || 'true' || '1' => SslMode.require,
    'verifyfull' || 'verify_full' || 'verify-full' => SslMode.verifyFull,
    _ => null,
  };
}
