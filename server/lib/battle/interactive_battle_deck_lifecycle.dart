import 'package:postgres/postgres.dart';

const interactiveBattleDeckLifecycleLockSql =
    "SELECT pg_advisory_xact_lock("
    "hashtext('manaloom:interactive_battle:deck_lifecycle:v1'))";

enum InteractiveBattleDeckDeleteResult {
  deleted,
  notFound,
  activeBattle,

  /// O `If-Match` pediu outra revisão do deck (DCK-P0-01).
  staleRevision,
}

Future<void> acquireInteractiveBattleDeckLifecycleLock(Session session) async {
  await session.execute(interactiveBattleDeckLifecycleLockSql);
}

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
      SELECT id::text, revision
      FROM decks
      WHERE id = CAST(@deck_id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
      LIMIT 1
      FOR UPDATE
    '''),
    parameters: {'deck_id': deckId, 'user_id': userId},
  );
  if (owned.isEmpty) return InteractiveBattleDeckDeleteResult.notFound;
  if (expectedRevision != null &&
      (owned.first[1] as num).toInt() != expectedRevision) {
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

  final deleted = await transaction.execute(
    Sql.named('''
      DELETE FROM decks
      WHERE id = CAST(@deck_id AS uuid)
        AND user_id = CAST(@user_id AS uuid)
      RETURNING id::text
    '''),
    parameters: {'deck_id': deckId, 'user_id': userId},
  );
  return deleted.isEmpty
      ? InteractiveBattleDeckDeleteResult.notFound
      : InteractiveBattleDeckDeleteResult.deleted;
});
