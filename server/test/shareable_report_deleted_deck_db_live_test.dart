@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/battle/interactive_battle_deck_lifecycle.dart';
import '../lib/reports/shareable_report_service.dart';
import '../routes/reports/[id].dart' as report_route;
import 'support/scripted_pool.dart';

/// Buraco 4 da D-19 (parte do DCK-P0-06), em PostgreSQL descartável: o
/// relatório compartilhável continua público, mas deixa de ser servido
/// quando o deck é apagado, pela exclusão de hoje (`DELETE`, que zera
/// `deck_id`) ou pela lixeira (`decks.deleted_at`).
///
/// Requer `RUN_SHAREABLE_REPORT_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_SHAREABLE_REPORT_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;

  setUpAll(() async {
    if (!enabled) return;
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
    if (enabled) await pool.close();
  });

  Future<String> insertUser(String suffix) async {
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@username, @email, 'x')
        RETURNING id::text
      '''),
      parameters: {
        'username': 'report_$suffix',
        'email': 'report_$suffix@example.invalid',
      },
    );
    return result.single.single! as String;
  }

  Future<String> insertDeck(String userId, String name) async {
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, is_public)
        VALUES (CAST(@userId AS uuid), @name, 'commander', TRUE)
        RETURNING id::text
      '''),
      parameters: {'userId': userId, 'name': name},
    );
    return result.single.single! as String;
  }

  Future<Response> getReport(String id) => report_route.onRequest(
    ScriptedRequestContext(
      Request.get(Uri.parse('http://localhost/reports/$id')),
      providers: {Pool: pool},
    ),
    id,
  );

  test(
    'relatório de deck apagado deixa de ser servido; os outros seguem',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final userId = await insertUser(suffix);
      final deletedDeck = await insertDeck(userId, 'Deck apagado $suffix');
      final trashedDeck = await insertDeck(userId, 'Deck na lixeira $suffix');
      final keptDeck = await insertDeck(userId, 'Deck mantido $suffix');
      final service = ShareableReportService(pool);

      Future<String> share(String deckId) async {
        final report = await service.createForDeck(
          userId: userId,
          deckId: deckId,
          body: const {},
        );
        return report!['id'] as String;
      }

      final deletedReport = await share(deletedDeck);
      final trashedReport = await share(trashedDeck);
      final keptReport = await share(keptDeck);
      for (final id in [deletedReport, trashedReport, keptReport]) {
        expect(await service.getPublicReport(id), isNotNull, reason: id);
      }

      final deletion = await deleteDeckAfterBattleGuard(
        pool,
        userId: userId,
        deckId: deletedDeck,
      );
      expect(deletion, InteractiveBattleDeckDeleteResult.deleted);
      await pool.execute(
        Sql.named('''
          UPDATE decks SET deleted_at = NOW()
          WHERE id = CAST(@deckId AS uuid)
        '''),
        parameters: {'deckId': trashedDeck},
      );

      // A linha do relatório continua no banco (deck_id zerado pelo FK),
      // mas não é mais servida.
      final orphan = await pool.execute(
        Sql.named(
          'SELECT deck_id, is_public FROM shared_deck_reports WHERE id = @id',
        ),
        parameters: {'id': deletedReport},
      );
      expect(orphan.single[0], isNull);
      expect(orphan.single[1], isTrue);

      expect(await service.getPublicReport(deletedReport), isNull);
      expect(await service.getPublicReport(trashedReport), isNull);
      expect(await service.getPublicReport(keptReport), isNotNull);

      final gone = await getReport(deletedReport);
      expect(gone.statusCode, HttpStatus.notFound);
      expect(await gone.body(), isNot(contains('deck_snapshot')));
      final trashed = await getReport(trashedReport);
      expect(trashed.statusCode, HttpStatus.notFound);
      final kept = await getReport(keptReport);
      expect(kept.statusCode, HttpStatus.ok);
      final keptBody = jsonDecode(await kept.body()) as Map<String, dynamic>;
      expect(keptBody['deck_id'], keptDeck);
      expect(keptBody['is_public'], isTrue);
    },
    skip: skipReason,
  );
}
