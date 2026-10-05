import 'package:postgres/postgres.dart';

import '../decks/deck_revision_support.dart';

const interactiveBattleDeckLifecycleLockSql =
    "SELECT pg_advisory_xact_lock("
    "hashtext('manaloom:interactive_battle:deck_lifecycle:v1'))";

enum InteractiveBattleDeckDeleteResult {
  /// O deck foi para a lixeira (DCK-P0-06): nada foi apagado ainda.
  deleted,
  notFound,
  activeBattle,

  /// O `If-Match` pediu outra revisão do deck (DCK-P0-01).
  staleRevision,
}

Future<void> acquireInteractiveBattleDeckLifecycleLock(Session session) async {
  await session.execute(interactiveBattleDeckLifecycleLockSql);
}

/// Apaga o deck do dono: manda para a lixeira (DCK-P0-06; decisões D-30 e
/// D-19 do dono). Marca `deleted_at`, tira o deck da galeria e despublica os
/// relatórios dele de vez (restaurar não os republica); as cartas e tudo que
/// pende do deck ficam até a purga por prazo. Sobe a revisão e grava
/// `deck_delete` no ledger. Deck já na lixeira responde como inexistente.
Future<InteractiveBattleDeckDeleteResult> deleteDeckAfterBattleGuard(
  Pool pool, {
  required String userId,
  required String deckId,
  int? expectedRevision,
}) => pool.runTx((transaction) async {
  // Global lifecycle lock first, deck row second, active-session read last.
  // Interactive admission uses the same order, preventing a FK/delete cycle.
  await acquireInteractiveBattleDeckLifecycleLock(transaction);
  final owned = await transaction.execute(
    Sql.named('''
      SELECT id::text, revision, is_public
      FROM decks
      WHERE id = CAST(@deck_id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
        AND deleted_at IS NULL
      LIMIT 1
      FOR UPDATE
    '''),
    parameters: {'deck_id': deckId, 'user_id': userId},
  );
  if (owned.isEmpty) return InteractiveBattleDeckDeleteResult.notFound;
  final revision = (owned.first[1] as num).toInt();
  if (expectedRevision != null && revision != expectedRevision) {
    return InteractiveBattleDeckDeleteResult.staleRevision;
  }

  final active = await transaction.execute(
    Sql.named('''
      SELECT EXISTS (
        SELECT 1
        FROM interactive_battle_sessions
        WHERE (deck_a_id = CAST(@deck_id AS uuid)
               OR deck_b_id = CAST(@deck_id AS uuid))
          AND status IN (
            'starting',
            'running',
            'waiting_for_action',
            'action_pending'
          )
      )
    '''),
    parameters: {'deck_id': deckId},
  );
  if (active.single.single == true) {
    return InteractiveBattleDeckDeleteResult.activeBattle;
  }

  final wasPublic = owned.first[2] == true;
  await transaction.execute(
    Sql.named('''
      UPDATE decks
      SET deleted_at = CURRENT_TIMESTAMP, is_public = FALSE
      WHERE id = CAST(@deck_id AS uuid)
    '''),
    parameters: {'deck_id': deckId},
  );
  // D-19 e D-30: o link público do relatório morre com o deck apagado e não
  // volta com o restaurar.
  await transaction.execute(
    Sql.named('''
      UPDATE shared_deck_reports
      SET is_public = FALSE, updated_at = CURRENT_TIMESTAMP
      WHERE deck_id = CAST(@deck_id AS uuid) AND is_public = TRUE
    '''),
    parameters: {'deck_id': deckId},
  );
  await recordDeckLifecycleEvent(
    transaction,
    deckId: deckId,
    userId: userId,
    revisionBefore: revision,
    operation: 'deck_delete',
    metadataBefore: wasPublic ? const {'is_public': true} : const {},
    metadataAfter: wasPublic ? const {'is_public': false} : const {},
  );
  return InteractiveBattleDeckDeleteResult.deleted;
});
