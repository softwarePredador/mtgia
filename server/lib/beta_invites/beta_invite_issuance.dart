/// Emissão, reenvio, revogação e listagem dos convites da beta (BT-AUTH-006).
///
/// É o caminho do dono (D-16): `server/bin/beta_invites.dart` chama esta
/// classe. Tudo é idempotente: emitir de novo o mesmo lote não duplica
/// convite nem e-mail, porque cada e-mail tem no máximo um convite aberto
/// (índice parcial `uq_beta_invites_open_email`).
library;

import 'dart:math';

import 'package:postgres/postgres.dart';

import '../account_email_delivery_transport.dart';
import 'beta_invite_policy.dart';
import 'beta_invite_store.dart';

/// Função que entrega o e-mail do convite; `true` quando entregou.
typedef BetaInviteDeliver =
    Future<bool> Function({
      required String email,
      required String code,
      required DateTime expiresAt,
    });

/// O que a emissão faria (ou fez) com cada e-mail da lista.
enum BetaInvitePlanAction {
  /// Convite novo.
  issue('novo'),

  /// O convite aberto expirou: é revogado como substituído e sai um novo.
  reissue('reemitir'),

  /// Já tem convite aberto e válido: nada muda (use `reenviar`).
  alreadyInvited('ja_convidado'),

  /// O e-mail já tem conta ativa: não precisa de convite.
  hasAccount('ja_tem_conta'),

  /// Endereço inválido.
  invalidEmail('email_invalido'),

  /// Repetido na mesma lista.
  duplicate('repetido');

  const BetaInvitePlanAction(this.label);

  final String label;

  bool get createsInvite =>
      this == BetaInvitePlanAction.issue ||
      this == BetaInvitePlanAction.reissue;
}

class BetaInvitePlanEntry {
  const BetaInvitePlanEntry({
    required this.email,
    required this.emailHint,
    required this.action,
    this.existingInviteId,
  });

  final String email;
  final String emailHint;
  final BetaInvitePlanAction action;
  final String? existingInviteId;
}

/// Resultado de um convite emitido ou reenviado.
enum BetaInviteDeliveryState {
  delivered('enviado'),
  notConfigured('entrega_nao_configurada'),
  failed('falha_envio'),
  skipped('sem_envio');

  const BetaInviteDeliveryState(this.label);

  final String label;
}

class BetaInviteIssueOutcome {
  const BetaInviteIssueOutcome({
    required this.emailHint,
    required this.status,
    this.inviteId,
    this.expiresAt,
    this.delivery = BetaInviteDeliveryState.skipped,
    this.deliveryErrorCode,
  });

  final String emailHint;

  /// Rótulo em português do que aconteceu (`novo`, `reemitir`, ...).
  final String status;
  final String? inviteId;
  final DateTime? expiresAt;
  final BetaInviteDeliveryState delivery;
  final String? deliveryErrorCode;

  Map<String, Object?> toJson() => {
    'email': emailHint,
    'status': status,
    if (inviteId != null) 'convite': inviteId,
    if (expiresAt != null) 'expira_em': expiresAt!.toUtc().toIso8601String(),
    'envio': delivery.label,
    if (deliveryErrorCode != null) 'erro_envio': deliveryErrorCode,
  };
}

class BetaInviteIssuer {
  BetaInviteIssuer(
    this._pool, {
    required BetaInviteDeliver deliver,
    Random? random,
  }) : _deliver = deliver,
       _random = random ?? Random.secure();

  final Pool _pool;
  final BetaInviteDeliver _deliver;
  final Random _random;

  /// Classifica a lista sem gravar nada (é o dry-run).
  Future<List<BetaInvitePlanEntry>> plan(Iterable<String> emails) async {
    final entries = <BetaInvitePlanEntry>[];
    final seen = <String>{};
    for (final raw in emails) {
      final email = raw.trim().toLowerCase();
      final hint = betaInviteEmailHint(email);
      if (!isAcceptableInviteEmail(email)) {
        entries.add(
          BetaInvitePlanEntry(
            email: email,
            emailHint: hint,
            action: BetaInvitePlanAction.invalidEmail,
          ),
        );
        continue;
      }
      if (!seen.add(email)) {
        entries.add(
          BetaInvitePlanEntry(
            email: email,
            emailHint: hint,
            action: BetaInvitePlanAction.duplicate,
          ),
        );
        continue;
      }
      if (await _hasActiveAccount(_pool, email)) {
        entries.add(
          BetaInvitePlanEntry(
            email: email,
            emailHint: hint,
            action: BetaInvitePlanAction.hasAccount,
          ),
        );
        continue;
      }
      final open = await _pool.execute(
        Sql.named('''
          SELECT id::text, expires_at <= CURRENT_TIMESTAMP AS expired
          FROM beta_invites
          WHERE email_digest = @emailDigest
            AND accepted_at IS NULL
            AND revoked_at IS NULL
        '''),
        parameters: {'emailDigest': betaInviteEmailDigest(email)},
      );
      if (open.isEmpty) {
        entries.add(
          BetaInvitePlanEntry(
            email: email,
            emailHint: hint,
            action: BetaInvitePlanAction.issue,
          ),
        );
      } else {
        final expired = open.first[1] == true;
        entries.add(
          BetaInvitePlanEntry(
            email: email,
            emailHint: hint,
            action:
                expired
                    ? BetaInvitePlanAction.reissue
                    : BetaInvitePlanAction.alreadyInvited,
            existingInviteId: open.first[0]! as String,
          ),
        );
      }
    }
    return entries;
  }

  /// Emite os convites do plano e envia os e-mails. Cada convite é gravado
  /// numa transação própria, antes do envio; a entrega fica registrada na
  /// auditoria (`delivered` ou `delivery_failed`).
  Future<List<BetaInviteIssueOutcome>> issue(
    List<BetaInvitePlanEntry> plan, {
    required String batchLabel,
    required Duration validity,
    required String issuedBy,
  }) async {
    _checkBatch(batchLabel, validity, issuedBy);
    final outcomes = <BetaInviteIssueOutcome>[];
    for (final entry in plan) {
      if (!entry.action.createsInvite) {
        outcomes.add(
          BetaInviteIssueOutcome(
            emailHint: entry.emailHint,
            status: entry.action.label,
            inviteId: entry.existingInviteId,
          ),
        );
        continue;
      }
      final code = newBetaInviteCode(random: _random);
      final created = await _pool.runTx((tx) async {
        if (entry.action == BetaInvitePlanAction.reissue) {
          final superseded = await tx.execute(
            Sql.named('''
              UPDATE beta_invites
              SET revoked_at = CURRENT_TIMESTAMP,
                  revoked_reason = 'substituido por novo convite'
              WHERE id = CAST(@inviteId AS uuid)
                AND accepted_at IS NULL
                AND revoked_at IS NULL
              RETURNING id::text
            '''),
            parameters: {'inviteId': entry.existingInviteId},
          );
          if (superseded.isNotEmpty) {
            await BetaInviteAdmission.recordEvent(
              tx,
              inviteId: superseded.first[0]! as String,
              event: 'revoked',
              actor: issuedBy,
            );
          }
        }
        final inserted = await tx.execute(
          Sql.named('''
            INSERT INTO beta_invites (
              batch_label, email_digest, email_hint, token_hash,
              issued_by, expires_at
            ) VALUES (
              @batchLabel, @emailDigest, @emailHint, @tokenHash,
              @issuedBy,
              CURRENT_TIMESTAMP
                + CAST(@validitySeconds AS int) * INTERVAL '1 second'
            )
            ON CONFLICT (email_digest)
              WHERE accepted_at IS NULL AND revoked_at IS NULL
            DO NOTHING
            RETURNING id::text, expires_at
          '''),
          parameters: {
            'batchLabel': batchLabel,
            'emailDigest': betaInviteEmailDigest(entry.email),
            'emailHint': entry.emailHint,
            'tokenHash': betaInviteTokenHash(normalizeBetaInviteCode(code)!),
            'issuedBy': issuedBy,
            'validitySeconds': validity.inSeconds,
          },
        );
        if (inserted.isEmpty) return null;
        final inviteId = inserted.first[0]! as String;
        await BetaInviteAdmission.recordEvent(
          tx,
          inviteId: inviteId,
          event: 'issued',
          actor: issuedBy,
        );
        return (inviteId: inviteId, expiresAt: inserted.first[1]! as DateTime);
      });
      if (created == null) {
        // Outra emissão abriu um convite para o mesmo e-mail no meio tempo.
        outcomes.add(
          BetaInviteIssueOutcome(
            emailHint: entry.emailHint,
            status: BetaInvitePlanAction.alreadyInvited.label,
          ),
        );
        continue;
      }
      outcomes.add(
        await _deliverAndRecord(
          email: entry.email,
          emailHint: entry.emailHint,
          status: entry.action.label,
          inviteId: created.inviteId,
          code: code,
          expiresAt: created.expiresAt,
          actor: issuedBy,
        ),
      );
    }
    return outcomes;
  }

  /// Troca o código do convite aberto do e-mail, renova a validade e envia de
  /// novo. O código anterior deixa de valer.
  Future<BetaInviteIssueOutcome> resend(
    String rawEmail, {
    required Duration validity,
    required String issuedBy,
  }) async {
    final email = rawEmail.trim().toLowerCase();
    final hint = betaInviteEmailHint(email);
    _checkValidity(validity);
    _checkActor(issuedBy);
    if (!isAcceptableInviteEmail(email)) {
      return BetaInviteIssueOutcome(
        emailHint: hint,
        status: BetaInvitePlanAction.invalidEmail.label,
      );
    }
    if (await _hasActiveAccount(_pool, email)) {
      return BetaInviteIssueOutcome(
        emailHint: hint,
        status: BetaInvitePlanAction.hasAccount.label,
      );
    }
    final code = newBetaInviteCode(random: _random);
    final rotated = await _pool.runTx((tx) async {
      final updated = await tx.execute(
        Sql.named('''
          UPDATE beta_invites
          SET token_hash = @tokenHash,
              expires_at = GREATEST(
                CURRENT_TIMESTAMP
                  + CAST(@validitySeconds AS int) * INTERVAL '1 second',
                issued_at + INTERVAL '1 second'
              ),
              delivered_at = NULL
          WHERE email_digest = @emailDigest
            AND accepted_at IS NULL
            AND revoked_at IS NULL
          RETURNING id::text, expires_at
        '''),
        parameters: {
          'tokenHash': betaInviteTokenHash(normalizeBetaInviteCode(code)!),
          'validitySeconds': validity.inSeconds,
          'emailDigest': betaInviteEmailDigest(email),
        },
      );
      if (updated.isEmpty) return null;
      final inviteId = updated.first[0]! as String;
      await BetaInviteAdmission.recordEvent(
        tx,
        inviteId: inviteId,
        event: 'resent',
        actor: issuedBy,
      );
      return (inviteId: inviteId, expiresAt: updated.first[1]! as DateTime);
    });
    if (rotated == null) {
      return BetaInviteIssueOutcome(
        emailHint: hint,
        status: 'sem_convite_aberto',
      );
    }
    return _deliverAndRecord(
      email: email,
      emailHint: hint,
      status: 'reenviado',
      inviteId: rotated.inviteId,
      code: code,
      expiresAt: rotated.expiresAt,
      actor: issuedBy,
    );
  }

  /// Revoga o convite aberto de um e-mail ou de um id. Idempotente: revogar
  /// de novo devolve `sem_convite_aberto` e não muda nada.
  Future<BetaInviteIssueOutcome> revoke({
    String? email,
    String? inviteId,
    required String reason,
    required String actor,
  }) async {
    _checkActor(actor);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty || trimmedReason.length > 200) {
      throw ArgumentError.value(reason, 'reason', 'deve ter de 1 a 200 letras');
    }
    if ((email == null) == (inviteId == null)) {
      throw ArgumentError('informe o e-mail ou o id do convite, um só');
    }
    final hint = email == null ? inviteId! : betaInviteEmailHint(email);
    final revoked = await _pool.runTx((tx) async {
      final updated = await tx.execute(
        Sql.named('''
          UPDATE beta_invites
          SET revoked_at = CURRENT_TIMESTAMP,
              revoked_reason = @reason
          WHERE accepted_at IS NULL
            AND revoked_at IS NULL
            AND (
              (CAST(@inviteId AS text) IS NOT NULL
                AND id::text = CAST(@inviteId AS text))
              OR (CAST(@emailDigest AS text) IS NOT NULL
                AND email_digest = CAST(@emailDigest AS text))
            )
          RETURNING id::text
        '''),
        parameters: {
          'reason': trimmedReason,
          'inviteId': inviteId,
          'emailDigest': email == null ? null : betaInviteEmailDigest(email),
        },
      );
      if (updated.isEmpty) return null;
      final id = updated.first[0]! as String;
      await BetaInviteAdmission.recordEvent(
        tx,
        inviteId: id,
        event: 'revoked',
        actor: actor,
      );
      return id;
    });
    return BetaInviteIssueOutcome(
      emailHint: hint,
      status: revoked == null ? 'sem_convite_aberto' : 'revogado',
      inviteId: revoked,
    );
  }

  /// Lista os convites, sem e-mail em claro.
  Future<List<Map<String, Object?>>> list({String? batchLabel}) async {
    final rows = await _pool.execute(
      Sql.named('''
        SELECT id::text, batch_label, email_hint, issued_by, issued_at,
               expires_at, delivered_at, revoked_at, revoked_reason,
               accepted_at,
               CASE
                 WHEN accepted_at IS NOT NULL THEN 'aceito'
                 WHEN revoked_at IS NOT NULL THEN 'revogado'
                 WHEN expires_at <= CURRENT_TIMESTAMP THEN 'expirado'
                 ELSE 'aberto'
               END AS status
        FROM beta_invites
        WHERE CAST(@batchLabel AS text) IS NULL
           OR batch_label = CAST(@batchLabel AS text)
        ORDER BY issued_at, id
      '''),
      parameters: {'batchLabel': batchLabel},
    );
    String? iso(Object? value) =>
        value is DateTime ? value.toUtc().toIso8601String() : null;
    return [
      for (final row in rows)
        {
          'convite': row[0],
          'lote': row[1],
          'email': row[2],
          'emitido_por': row[3],
          'emitido_em': iso(row[4]),
          'expira_em': iso(row[5]),
          'entregue_em': iso(row[6]),
          'revogado_em': iso(row[7]),
          'motivo_revogacao': row[8],
          'aceito_em': iso(row[9]),
          'status': row[10],
        },
    ];
  }

  Future<BetaInviteIssueOutcome> _deliverAndRecord({
    required String email,
    required String emailHint,
    required String status,
    required String inviteId,
    required String code,
    required DateTime expiresAt,
    required String actor,
  }) async {
    var delivery = BetaInviteDeliveryState.failed;
    String? errorCode;
    try {
      final delivered = await _deliver(
        email: email,
        code: code,
        expiresAt: expiresAt,
      );
      delivery =
          delivered
              ? BetaInviteDeliveryState.delivered
              : BetaInviteDeliveryState.notConfigured;
    } on AccountEmailDeliveryException catch (error) {
      errorCode = error.code;
    } on Object catch (error) {
      errorCode = 'email_delivery_error_${error.runtimeType}';
    }
    if (delivery == BetaInviteDeliveryState.delivered) {
      await _pool.execute(
        Sql.named('''
          UPDATE beta_invites SET delivered_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@inviteId AS uuid)
        '''),
        parameters: {'inviteId': inviteId},
      );
    }
    await BetaInviteAdmission.recordEvent(
      _pool,
      inviteId: inviteId,
      event:
          delivery == BetaInviteDeliveryState.delivered
              ? 'delivered'
              : 'delivery_failed',
      actor: actor,
    );
    return BetaInviteIssueOutcome(
      emailHint: emailHint,
      status: status,
      inviteId: inviteId,
      expiresAt: expiresAt,
      delivery: delivery,
      deliveryErrorCode: errorCode,
    );
  }

  static Future<bool> _hasActiveAccount(Session db, String email) async {
    final rows = await db.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE LOWER(email) = @email AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'email': email},
    );
    return rows.isNotEmpty;
  }

  static void _checkBatch(String batchLabel, Duration validity, String actor) {
    if (!isValidBetaInviteBatchLabel(batchLabel)) {
      throw ArgumentError.value(
        batchLabel,
        'batchLabel',
        'use minúsculas, dígitos, ponto, hífen ou sublinhado (até 64)',
      );
    }
    _checkValidity(validity);
    _checkActor(actor);
  }

  static void _checkValidity(Duration validity) {
    if (validity < const Duration(days: 1) ||
        validity > const Duration(days: 60)) {
      throw ArgumentError.value(validity, 'validity', 'de 1 a 60 dias');
    }
  }

  static void _checkActor(String actor) {
    if (actor.trim().isEmpty || actor.length > 80) {
      throw ArgumentError.value(actor, 'actor', 'de 1 a 80 letras');
    }
  }
}
