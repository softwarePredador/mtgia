/// Banco da admissão por convite (BT-AUTH-006): a checagem do cadastro, o
/// aceite dentro da transação que cria a conta e a trilha de auditoria.
library;

import 'package:postgres/postgres.dart';

import '../logger.dart';
import 'beta_invite_policy.dart';

/// Convite apresentado no cadastro: o código já normalizado e o request-id,
/// que vai para a auditoria.
class BetaInviteClaim {
  const BetaInviteClaim({required this.code, this.requestId});

  final String code;
  final String? requestId;
}

/// Ator gravado na auditoria quando o convite é usado no cadastro.
const betaInviteRegistrationActor = 'auth_register';

const _statusSql = '''
  SELECT id::text,
         email_digest = @emailDigest AS email_matches,
         accepted_at IS NOT NULL AS accepted,
         revoked_at IS NOT NULL AS revoked,
         expires_at <= CURRENT_TIMESTAMP AS expired
  FROM beta_invites
  WHERE token_hash = @tokenHash
''';

/// Operações do convite no cadastro.
class BetaInviteAdmission {
  const BetaInviteAdmission._();

  /// Checagem antecipada, só leitura. Roda antes do bcrypt e de qualquer
  /// escrita, para negar convite ruim sem gastar nem gravar nada. A decisão
  /// que vale é a de [lockForAcceptance], dentro da transação.
  static Future<BetaInviteDeniedException?> preflight(
    Session db, {
    required String code,
    required String email,
  }) async {
    final rows = await db.execute(
      Sql.named(_statusSql),
      parameters: _statusParameters(code, email),
    );
    return evaluateBetaInvite(_status(rows));
  }

  /// Dentro da transação do cadastro, antes de criar o usuário: trava a
  /// linha do convite e decide. Um segundo cadastro com o mesmo código espera
  /// o primeiro terminar e então encontra o convite já aceito.
  static Future<String> lockForAcceptance(
    Session tx, {
    required String code,
    required String email,
  }) async {
    final rows = await tx.execute(
      Sql.named('$_statusSql  FOR UPDATE'),
      parameters: _statusParameters(code, email),
    );
    final status = _status(rows);
    final denial = evaluateBetaInvite(status);
    if (denial != null) throw denial;
    return status!.inviteId;
  }

  /// Marca o convite como aceito pela conta nova, na mesma transação.
  static Future<void> markAccepted(
    Session tx, {
    required String inviteId,
    required String userId,
    String? requestId,
  }) async {
    final updated = await tx.execute(
      Sql.named('''
        UPDATE beta_invites
        SET accepted_at = CURRENT_TIMESTAMP,
            accepted_user_id = CAST(@userId AS uuid)
        WHERE id = CAST(@inviteId AS uuid)
          AND accepted_at IS NULL
          AND revoked_at IS NULL
          AND expires_at > CURRENT_TIMESTAMP
        RETURNING id
      '''),
      parameters: {'inviteId': inviteId, 'userId': userId},
    );
    if (updated.isEmpty) {
      throw BetaInviteDeniedException(
        BetaInviteDenial.alreadyUsed,
        inviteId: inviteId,
        auditEvent: 'denied_used',
      );
    }
    await recordEvent(
      tx,
      inviteId: inviteId,
      event: 'accepted',
      actor: betaInviteRegistrationActor,
      requestId: requestId,
    );
  }

  /// Grava um evento da trilha de auditoria.
  static Future<void> recordEvent(
    Session db, {
    required String inviteId,
    required String event,
    required String actor,
    String? requestId,
  }) async {
    await db.execute(
      Sql.named('''
        INSERT INTO beta_invite_events (invite_id, event, actor, request_id)
        VALUES (CAST(@inviteId AS uuid), @event, @actor, @requestId)
      '''),
      parameters: {
        'inviteId': inviteId,
        'event': event,
        'actor': actor,
        'requestId': requestId,
      },
    );
  }

  /// Registra a recusa de um convite real, fora da transação desfeita. Código
  /// desconhecido não vira linha no banco (só log): quem martela códigos
  /// inventados não faz a tabela crescer. Falha na auditoria só vai para o
  /// log e não muda a resposta.
  static Future<void> recordDenial(
    Session db,
    BetaInviteDeniedException denial, {
    String? requestId,
  }) async {
    logDenial(denial.denial, audit: denial.auditEvent, requestId: requestId);
    final inviteId = denial.inviteId;
    final event = denial.auditEvent;
    if (inviteId == null || event == null) return;
    try {
      await recordEvent(
        db,
        inviteId: inviteId,
        event: event,
        actor: betaInviteRegistrationActor,
        requestId: requestId,
      );
    } on Object catch (error) {
      Log.w(
        '[beta_invite] audit_failed event=$event type=${error.runtimeType}',
      );
    }
  }

  /// Log da recusa, sem e-mail nem código.
  static void logDenial(
    BetaInviteDenial denial, {
    String? audit,
    String? requestId,
  }) {
    Log.w(
      '[beta_invite] denied reason=${denial.code} audit=${audit ?? 'none'} '
      'request_id=${requestId ?? 'n/a'}',
    );
  }

  static Map<String, Object?> _statusParameters(String code, String email) => {
    'tokenHash': betaInviteTokenHash(code),
    'emailDigest': betaInviteEmailDigest(email),
  };

  static BetaInviteStatus? _status(Result rows) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    return BetaInviteStatus(
      inviteId: row[0]! as String,
      emailMatches: row[1] == true,
      accepted: row[2] == true,
      revoked: row[3] == true,
      expired: row[4] == true,
    );
  }
}
