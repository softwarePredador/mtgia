import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'deck_revision_support.dart';

/// Lixeira de decks (DCK-P0-06; decisões D-30 e D-19 do dono).
///
/// - Apagar um deck (`DELETE /decks/:id`) marca `decks.deleted_at`, tira o
///   deck da galeria e despublica os relatórios dele, sem apagar cartas nem
///   nada que pende do deck ([deleteDeckAfterBattleGuard], em
///   `lib/battle/interactive_battle_deck_lifecycle.dart`).
/// - O deck na lixeira some de todas as superfícies: as rotas de
///   `/decks/:id` respondem 404 pelo middleware de `routes/decks/[id]`, e as
///   de fora filtram `deleted_at IS NULL`. Não conta em limite nem em
///   aprendizado; entra na exportação e na exclusão da conta.
/// - `GET /decks/trash` lista a lixeira do dono; `POST /decks/:id/restore`
///   devolve o deck íntegro e privado ([restoreDeckFromTrash]). Restaurar não
///   republica relatório.
/// - A purga é a limpeza por prazo (`retention_cleanup_apply_v1`, regras
///   `shared_deck_reports_trashed_deck_30d` e `decks_trash_30d`), que apaga
///   de vez o deck com mais de [deckTrashRetention] na lixeira. Ela segue
///   desligada até a ativação supervisionada (decisão do dono).
const deckTrashRetention = Duration(days: 30);

/// O deck pedido para restaurar não está na lixeira do dono.
const deckNotInTrashCode = 'deck_not_in_trash';

/// A resposta de deck inexistente, igual à das mudanças de deck: deck na
/// lixeira e deck que não existe não se distinguem.
Response deckNotFoundResponse() => Response.json(
  statusCode: HttpStatus.notFound,
  body: const {
    'ok': false,
    'error': 'Deck não encontrado.',
    'error_code': 'deck_not_found',
  },
);

/// Se o deck está na lixeira, de quem quer que seja.
Future<bool> isDeckInTrash(Pool pool, String deckId) async {
  if (!isDeckUuid(deckId)) return false;
  final result = await pool.execute(
    Sql.named('''
      SELECT EXISTS (
        SELECT 1 FROM decks
        WHERE id = CAST(@deckId AS uuid) AND deleted_at IS NOT NULL
      )
    '''),
    parameters: {'deckId': deckId},
  );
  return result.first[0] == true;
}

/// O guarda de `routes/decks/[id]/_middleware.dart`: deck na lixeira some
/// de toda rota de `/decks/:id` (ler, mudar, analisar, exportar, histórico,
/// Battle, relatório, notas), para qualquer pessoa, com a resposta de deck
/// inexistente. Só `POST /decks/:id/restore` passa. Rota nova sob
/// `/decks/:id` nasce protegida.
Middleware deckTrashGuard() =>
    (handler) => (context) async {
      final segments = context.request.uri.pathSegments;
      if (segments.length >= 2 &&
          segments[0] == 'decks' &&
          isDeckUuid(segments[1])) {
        final restoring =
            context.request.method == HttpMethod.post &&
            segments.length == 3 &&
            segments[2] == 'restore';
        if (!restoring &&
            await isDeckInTrash(context.read<Pool>(), segments[1])) {
          return deckNotFoundResponse();
        }
      }
      return handler(context);
    };

/// A lixeira do dono, do deck apagado mais recente para o mais antigo, com
/// a data em que a limpeza por prazo pode apagá-lo de vez.
Future<List<Map<String, Object?>>> listDeckTrash(
  Pool pool, {
  required String userId,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT d.id::text, d.name, d.format, d.revision, d.deleted_at,
             COALESCE(SUM(dc.quantity), 0)::int AS card_count
      FROM decks d
      LEFT JOIN deck_cards dc ON dc.deck_id = d.id
      WHERE d.user_id = CAST(@userId AS uuid)
        AND d.deleted_at IS NOT NULL
      GROUP BY d.id
      ORDER BY d.deleted_at DESC, d.id
    '''),
    parameters: {'userId': userId},
  );
  final decks = <Map<String, Object?>>[];
  for (final row in result) {
    final map = row.toColumnMap();
    final deletedAt = (map['deleted_at'] as DateTime).toUtc();
    decks.add({
      'id': map['id'],
      'name': map['name'],
      'format': map['format'],
      'revision': (map['revision'] as num).toInt(),
      'card_count': map['card_count'],
      'deleted_at': deletedAt.toIso8601String(),
      'purge_after': deletedAt.add(deckTrashRetention).toIso8601String(),
    });
  }
  return decks;
}

enum DeckRestoreResult { restored, notInTrash, staleRevision }

class DeckRestoreOutcome {
  const DeckRestoreOutcome(
    this.result, {
    this.revisionBefore,
    this.revision,
    this.eventId,
  });

  final DeckRestoreResult result;
  final int? revisionBefore;

  /// A revisão atual: a nova quando restaurou, a do deck quando o
  /// `If-Match` pediu outra.
  final int? revision;
  final String? eventId;
}

/// Tira o deck da lixeira, íntegro e privado: as cartas e o resto nunca
/// saíram do banco; `is_public` fica falso (publicar é sempre um pedido
/// explícito, sob a regra da galeria) e os relatórios seguem despublicados
/// (D-30). Sobe a revisão e grava `deck_restore` no ledger.
Future<DeckRestoreOutcome> restoreDeckFromTrash(
  Pool pool, {
  required String userId,
  required String deckId,
  int? expectedRevision,
}) async {
  if (!isDeckUuid(deckId)) {
    return const DeckRestoreOutcome(DeckRestoreResult.notInTrash);
  }
  return pool.runTx((session) async {
    final trashed = await session.execute(
      Sql.named('''
        SELECT revision, is_public
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
          AND deleted_at IS NOT NULL
        FOR UPDATE
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    if (trashed.isEmpty) {
      return const DeckRestoreOutcome(DeckRestoreResult.notInTrash);
    }
    final revision = (trashed.first[0] as num).toInt();
    if (expectedRevision != null && expectedRevision != revision) {
      return DeckRestoreOutcome(
        DeckRestoreResult.staleRevision,
        revision: revision,
      );
    }
    final wasPublic = trashed.first[1] == true;
    await session.execute(
      Sql.named('''
        UPDATE decks
        SET deleted_at = NULL, is_public = FALSE
        WHERE id = CAST(@deckId AS uuid)
      '''),
      parameters: {'deckId': deckId},
    );
    final event = await recordDeckLifecycleEvent(
      session,
      deckId: deckId,
      userId: userId,
      revisionBefore: revision,
      operation: 'deck_restore',
      metadataBefore: wasPublic ? const {'is_public': true} : const {},
      metadataAfter: wasPublic ? const {'is_public': false} : const {},
    );
    return DeckRestoreOutcome(
      DeckRestoreResult.restored,
      revisionBefore: revision,
      revision: event.revision,
      eventId: event.eventId,
    );
  });
}
