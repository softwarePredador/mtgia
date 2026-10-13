// Convites da beta (BT-AUTH-006, D-16): o caminho do dono para emitir,
// reenviar, revogar e listar convites de uso único.
//
// Comece sempre pela simulação, que é o padrão: sem --aplicar nada é gravado
// nem enviado, e o script mostra o que faria e o e-mail que sairia.
//
//   dart run bin/beta_invites.dart emitir --lote beta-2026-10-a \
//     --emails convidados.txt [--validade-dias 14] [--emissor dono] [--aplicar]
//   dart run bin/beta_invites.dart reenviar --email pessoa@example.com [--aplicar]
//   dart run bin/beta_invites.dart revogar --email pessoa@example.com \
//     --motivo "pedido do dono" [--aplicar]
//   dart run bin/beta_invites.dart listar [--lote beta-2026-10-a]
//
// --aplicar exige MANALOOM_CONFIRM_POSTGRES_WRITES e
// MANALOOM_CONFIRM_LIVE_MUTATIONS iguais a I_HAVE_EXPLICIT_APPROVAL; banco
// fora do loopback só pelo wrapper de escrita aprovada do servidor (o comando
// exato está em betaInviteCliUsage). Este script não chama o wrapper: é o
// wrapper que o chama.
// A entrega usa a configuração de e-mail da API (MANALOOM_EMAIL_DELIVERY_PROVIDER
// e RESEND_*, ou BETA_INVITE_WEBHOOK_URL) e BETA_INVITE_APP_URL para o link.
// Emitir e reenviar fazem antes um ensaio da entrega, pelo mesmo transporte e
// sem sair da máquina: a simulação mostra o resultado, e o --aplicar para antes
// de gravar quando a entrega não está pronta, ou quando o banco é o da produção
// (wrapper) e ENVIRONMENT não é production.
// O banco guarda só o hash do código e o digest do e-mail; o código só existe
// no e-mail enviado.
//
// Saída: uma linha por e-mail (status e pista mascarada) e, no fim, um resumo
// em JSON. Código de saída: 0 ok, 1 alguma entrega falhou, 2 uso inválido,
// 3 bloqueado ou sem banco.

import 'dart:convert';
import 'dart:io';

import '../lib/beta_invites/beta_invite_cli.dart';
import '../lib/beta_invites/beta_invite_delivery_service.dart';
import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/database.dart';
import '../lib/runtime_environment.dart';

Future<void> main(List<String> args) async {
  final BetaInviteCliOptions options;
  final runtime = loadRuntimeEnvironment();
  final environment = <String, String>{
    for (final key in const {
      'DB_HOST',
      'MANALOOM_CONFIRM_POSTGRES_WRITES',
      'MANALOOM_CONFIRM_LIVE_MUTATIONS',
      'MANALOOM_PG_WRAPPER_MODE',
      ...betaInviteDeliveryEnvironmentKeys,
    })
      if (runtime[key] case final String value) key: value,
  };
  try {
    options = parseBetaInviteArgs(args);
  } on BetaInviteUsageException catch (error) {
    stderr
      ..writeln('beta_invites: ${error.message}')
      ..writeln(betaInviteCliUsage);
    exitCode = 2;
    return;
  }

  var emails = <String>[];
  if (options.command == BetaInviteCommand.emitir) {
    try {
      emails = [
        ...options.emails,
        if (options.emailFile case final String path)
          ...readBetaInviteEmails(File(path).readAsStringSync()),
      ];
      checkBetaInviteBatchSize(emails);
    } on BetaInviteUsageException catch (error) {
      stderr.writeln('beta_invites: ${error.message}');
      exitCode = 2;
      return;
    } on FileSystemException catch (error) {
      stderr.writeln('beta_invites: não consegui ler ${error.path}');
      exitCode = 2;
      return;
    }
  } else {
    emails = options.emails;
  }

  final blocked = betaInviteWriteBlockedReason(
    apply: options.apply,
    environment: environment,
  );
  if (blocked != null) {
    stderr.writeln('BLOCKED: $blocked');
    exitCode = 3;
    return;
  }

  final deliveryEnvironment = {
    for (final key in betaInviteDeliveryEnvironmentKeys)
      if (environment[key] case final String value) key: value,
  };
  final deliveryService = BetaInviteDeliveryService(
    environment: deliveryEnvironment,
  );
  // Emitir e reenviar mandam e-mail: o ensaio da entrega roda antes do banco.
  // Na simulação ele só informa; com --aplicar, entrega que não está pronta
  // para tudo antes de gravar (o código só existe no e-mail).
  _DeliveryCheck? deliveryCheck;
  if (options.command == BetaInviteCommand.emitir ||
      options.command == BetaInviteCommand.reenviar) {
    final readiness = await deliveryService.rehearse();
    deliveryCheck = (
      readiness: readiness,
      blockedReason: betaInviteDeliveryBlockedReason(
        readiness: readiness,
        environment: environment,
      ),
    );
    if (options.apply && deliveryCheck.blockedReason != null) {
      stderr.writeln('BLOCKED: ${deliveryCheck.blockedReason}');
      exitCode = 3;
      return;
    }
  }

  final database = Database();
  await database.connect();
  if (!database.isConnected) {
    stderr.writeln('beta_invites: sem conexão com o PostgreSQL');
    exitCode = 3;
    return;
  }
  final issuer = BetaInviteIssuer(
    database.connection,
    deliver: deliveryService.deliver,
  );

  try {
    exitCode = await _run(
      options,
      emails,
      issuer,
      deliveryEnvironment,
      deliveryCheck,
    );
  } finally {
    await database.connection.close();
  }
}

typedef _DeliveryCheck =
    ({BetaInviteDeliveryReadiness readiness, String? blockedReason});

/// Linhas do ensaio da entrega na simulação.
void _printDeliveryCheck(_DeliveryCheck check) {
  final readiness = check.readiness;
  stdout.writeln(
    readiness.ready
        ? 'Entrega (ensaio, nada saiu da máquina): pronta, '
            '${readiness.provider} para ${readiness.target}'
        : 'Entrega (ensaio, nada saiu da máquina): NÃO pronta '
            '(${readiness.errorCode})',
  );
  stdout.writeln(
    check.blockedReason == null
        ? 'Com --aplicar: liberado.'
        : 'Com --aplicar: BLOQUEADO, ${check.blockedReason}.',
  );
}

Map<String, Object?> _deliveryJson(_DeliveryCheck? check) => {
  if (check != null)
    'entrega': {
      ...check.readiness.toJson(),
      'aplicar': check.blockedReason == null ? 'liberado' : 'bloqueado',
    },
};

Future<int> _run(
  BetaInviteCliOptions options,
  List<String> emails,
  BetaInviteIssuer issuer,
  Map<String, String> deliveryEnvironment,
  _DeliveryCheck? deliveryCheck,
) async {
  final mode = options.apply ? 'aplicado' : 'simulacao';
  final delivery = _deliveryJson(deliveryCheck);
  switch (options.command) {
    case BetaInviteCommand.emitir:
      final plan = await issuer.plan(emails);
      if (!options.apply) {
        for (final entry in plan) {
          stdout.writeln(
            '${entry.action.label.padRight(16)} ${entry.emailHint}',
          );
        }
        stdout
          ..writeln()
          ..writeln('Prévia do e-mail:')
          ..writeln(betaInvitePreview(deliveryEnvironment, options.validity))
          ..writeln();
        _printDeliveryCheck(deliveryCheck!);
        stdout.writeln('Simulação: nada foi gravado nem enviado.');
        _summary(options, mode, {
          for (final action in BetaInvitePlanAction.values)
            action.label: plan.where((e) => e.action == action).length,
        }, extra: delivery);
        return 0;
      }
      final outcomes = await issuer.issue(
        plan,
        batchLabel: options.batchLabel!,
        validity: options.validity,
        issuedBy: options.issuedBy,
      );
      return _report(options, mode, outcomes, extra: delivery);
    case BetaInviteCommand.reenviar:
      final email = emails.single;
      if (!options.apply) {
        final plan = await issuer.plan([email]);
        final action = plan.single.action;
        final wouldResend =
            action == BetaInvitePlanAction.alreadyInvited ||
            action == BetaInvitePlanAction.reissue;
        stdout.writeln(
          wouldResend
              ? 'reenviaria      ${plan.single.emailHint} (código novo; o '
                  'anterior deixa de valer)'
              : '${action.label.padRight(16)} ${plan.single.emailHint} '
                  '(nada a reenviar)',
        );
        _printDeliveryCheck(deliveryCheck!);
        stdout.writeln('Simulação: nada foi gravado nem enviado.');
        _summary(options, mode, {
          'reenviaria': wouldResend ? 1 : 0,
        }, extra: delivery);
        return 0;
      }
      final outcome = await issuer.resend(
        email,
        validity: options.validity,
        issuedBy: options.issuedBy,
      );
      return _report(options, mode, [outcome], extra: delivery);
    case BetaInviteCommand.revogar:
      if (!options.apply) {
        String? targetId;
        String? targetHint;
        if (options.inviteId case final String inviteId) {
          for (final row in await issuer.list()) {
            final open =
                row['status'] == 'aberto' || row['status'] == 'expirado';
            if (open && row['convite'] == inviteId) {
              targetId = inviteId;
              targetHint = row['email'] as String?;
            }
          }
        } else {
          final entry = (await issuer.plan(emails)).single;
          targetId = entry.existingInviteId;
          targetHint = entry.emailHint;
        }
        stdout.writeln(
          targetId == null
              ? 'sem convite aberto para revogar'
              : 'revogaria       $targetHint (convite $targetId)',
        );
        stdout.writeln('Simulação: nada foi gravado.');
        _summary(options, mode, {'revogaria': targetId == null ? 0 : 1});
        return 0;
      }
      final outcome = await issuer.revoke(
        email: options.inviteId == null ? emails.single : null,
        inviteId: options.inviteId,
        reason: options.reason!,
        actor: options.issuedBy,
      );
      return _report(options, mode, [outcome]);
    case BetaInviteCommand.listar:
      final rows = await issuer.list(batchLabel: options.batchLabel);
      for (final row in rows) {
        stdout.writeln(
          '${(row['status']! as String).padRight(9)} '
          '${row['email']}  lote=${row['lote']}  expira=${row['expira_em']}'
          '  convite=${row['convite']}',
        );
      }
      final byStatus = <String, int>{};
      for (final row in rows) {
        final status = row['status']! as String;
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }
      _summary(options, 'leitura', byStatus);
      return 0;
  }
}

int _report(
  BetaInviteCliOptions options,
  String mode,
  List<BetaInviteIssueOutcome> outcomes, {
  Map<String, Object?> extra = const {},
}) {
  for (final outcome in outcomes) {
    final delivery =
        outcome.inviteId == null ? '' : '  envio=${outcome.delivery.label}';
    final error =
        outcome.deliveryErrorCode == null
            ? ''
            : ' (${outcome.deliveryErrorCode})';
    stdout.writeln(
      '${outcome.status.padRight(16)} ${outcome.emailHint}$delivery$error',
    );
  }
  final counts = <String, int>{};
  for (final outcome in outcomes) {
    counts[outcome.status] = (counts[outcome.status] ?? 0) + 1;
    if (outcome.inviteId != null &&
        outcome.delivery != BetaInviteDeliveryState.skipped) {
      final key = 'envio_${outcome.delivery.label}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  _summary(options, mode, counts, extra: extra);
  final failed = outcomes.any(
    (outcome) =>
        outcome.delivery == BetaInviteDeliveryState.failed ||
        outcome.delivery == BetaInviteDeliveryState.notConfigured,
  );
  return failed ? 1 : 0;
}

void _summary(
  BetaInviteCliOptions options,
  String mode,
  Map<String, int> counts, {
  Map<String, Object?> extra = const {},
}) {
  stdout.writeln(
    jsonEncode({
      'comando': options.command.name,
      'modo': mode,
      if (options.batchLabel != null) 'lote': options.batchLabel,
      'resumo': counts,
      ...extra,
    }),
  );
}
