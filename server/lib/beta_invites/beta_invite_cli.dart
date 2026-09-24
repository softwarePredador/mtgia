/// Argumentos, guardas e textos do script de convites do dono
/// (`server/bin/beta_invites.dart`, BT-AUTH-006). Separado do `bin` para ser
/// testado sem banco.
library;

import 'beta_invite_delivery_service.dart';
import 'beta_invite_policy.dart';

enum BetaInviteCommand { emitir, reenviar, revogar, listar }

class BetaInviteUsageException implements Exception {
  const BetaInviteUsageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BetaInviteCliOptions {
  const BetaInviteCliOptions({
    required this.command,
    required this.apply,
    this.batchLabel,
    this.emails = const [],
    this.emailFile,
    this.validity = betaInviteDefaultValidity,
    this.issuedBy = 'dono',
    this.reason,
    this.inviteId,
  });

  final BetaInviteCommand command;

  /// Sem `--aplicar` é dry-run: nada é gravado nem enviado.
  final bool apply;
  final String? batchLabel;
  final List<String> emails;
  final String? emailFile;
  final Duration validity;
  final String issuedBy;
  final String? reason;
  final String? inviteId;
}

const betaInviteCliUsage = '''
Convites da beta do BrewTact (BT-AUTH-006, D-16). Sem --aplicar é só simulação.

  emitir   --lote NOME (--emails ARQUIVO | --email E-MAIL ...)
           [--validade-dias N] [--emissor NOME] [--aplicar]
  reenviar --email E-MAIL [--validade-dias N] [--emissor NOME] [--aplicar]
  revogar  (--email E-MAIL | --convite ID) --motivo TEXTO [--emissor NOME]
           [--aplicar]
  listar   [--lote NOME]

ARQUIVO: um e-mail por linha; linhas vazias e as que começam com # são
ignoradas. No máximo 30 e-mails por emissão. Validade de 1 a 60 dias
(padrão 14).

Com --aplicar: MANALOOM_CONFIRM_POSTGRES_WRITES e
MANALOOM_CONFIRM_LIVE_MUTATIONS iguais a I_HAVE_EXPLICIT_APPROVAL; banco
fora do loopback só pelo server/bin/with_new_server_pg.sh --write-approved.''';

BetaInviteCliOptions parseBetaInviteArgs(List<String> args) {
  if (args.isEmpty) {
    throw const BetaInviteUsageException('informe o comando');
  }
  BetaInviteCommand? command;
  for (final value in BetaInviteCommand.values) {
    if (value.name == args.first) command = value;
  }
  if (command == null) {
    throw BetaInviteUsageException('comando desconhecido: ${args.first}');
  }
  const valued = {
    '--lote',
    '--emails',
    '--email',
    '--validade-dias',
    '--emissor',
    '--motivo',
    '--convite',
  };
  final values = <String, String>{};
  final emails = <String>[];
  var apply = false;
  for (var i = 1; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--aplicar') {
      apply = true;
    } else if (valued.contains(arg)) {
      if (i + 1 >= args.length) {
        throw BetaInviteUsageException('$arg precisa de um valor');
      }
      final value = args[++i];
      if (arg == '--email') {
        emails.add(value);
      } else if (values.containsKey(arg)) {
        throw BetaInviteUsageException('$arg repetido');
      } else {
        values[arg] = value;
      }
    } else {
      throw BetaInviteUsageException('argumento desconhecido: $arg');
    }
  }

  final rawDays = values['--validade-dias'];
  final days = rawDays == null ? 14 : int.tryParse(rawDays);
  if (days == null || days < 1 || days > 60) {
    throw const BetaInviteUsageException(
      '--validade-dias deve ser um inteiro de 1 a 60',
    );
  }
  final issuedBy = (values['--emissor'] ?? 'dono').trim();
  if (issuedBy.isEmpty || issuedBy.length > 80) {
    throw const BetaInviteUsageException('--emissor deve ter de 1 a 80 letras');
  }
  final batchLabel = values['--lote'];
  final reason = values['--motivo']?.trim();
  final inviteId = values['--convite']?.trim();

  switch (command) {
    case BetaInviteCommand.emitir:
      if (batchLabel == null || !isValidBetaInviteBatchLabel(batchLabel)) {
        throw const BetaInviteUsageException(
          '--lote é obrigatório: minúsculas, dígitos, ponto, hífen ou '
          'sublinhado, até 64',
        );
      }
      if (emails.isEmpty && values['--emails'] == null) {
        throw const BetaInviteUsageException(
          'informe --emails ARQUIVO ou --email E-MAIL',
        );
      }
    case BetaInviteCommand.reenviar:
      if (emails.length != 1) {
        throw const BetaInviteUsageException('reenviar pede um --email');
      }
    case BetaInviteCommand.revogar:
      if ((emails.length == 1) == (inviteId != null) || emails.length > 1) {
        throw const BetaInviteUsageException(
          'revogar pede um --email ou um --convite, um só',
        );
      }
      if (reason == null || reason.isEmpty || reason.length > 200) {
        throw const BetaInviteUsageException(
          '--motivo é obrigatório (até 200 letras)',
        );
      }
    case BetaInviteCommand.listar:
      if (apply) {
        throw const BetaInviteUsageException('listar só lê; tire --aplicar');
      }
      if (batchLabel != null && !isValidBetaInviteBatchLabel(batchLabel)) {
        throw const BetaInviteUsageException('--lote inválido');
      }
  }

  return BetaInviteCliOptions(
    command: command,
    apply: apply,
    batchLabel: batchLabel,
    emails: emails,
    emailFile: values['--emails'],
    validity: Duration(days: days),
    issuedBy: issuedBy,
    reason: reason,
    inviteId: inviteId,
  );
}

/// E-mails de um arquivo: um por linha, sem vazias nem comentários (`#`).
List<String> readBetaInviteEmails(String contents) => [
  for (final line in contents.split('\n'))
    if (line.trim().isNotEmpty && !line.trim().startsWith('#')) line.trim(),
];

/// Confere o tamanho do lote antes de tocar o banco (D-16: até 30).
void checkBetaInviteBatchSize(Iterable<String> emails) {
  final distinct = {
    for (final email in emails)
      if (isAcceptableInviteEmail(email)) email.trim().toLowerCase(),
  };
  if (distinct.isEmpty) {
    throw const BetaInviteUsageException('nenhum e-mail válido na lista');
  }
  if (distinct.length > betaInviteMaxBatchSize) {
    throw BetaInviteUsageException(
      '${distinct.length} e-mails: o lote tem no máximo '
      '$betaInviteMaxBatchSize (D-16); divida em lotes',
    );
  }
}

const _approvalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';

/// Motivo do bloqueio da escrita, ou `null` quando pode gravar. Dry-run e
/// listagem nunca são bloqueados.
String? betaInviteWriteBlockedReason({
  required bool apply,
  required Map<String, String> environment,
}) {
  if (!apply) return null;
  if (environment['MANALOOM_CONFIRM_POSTGRES_WRITES'] != _approvalPhrase ||
      environment['MANALOOM_CONFIRM_LIVE_MUTATIONS'] != _approvalPhrase) {
    return '--aplicar grava no PostgreSQL e envia e-mail: defina '
        'MANALOOM_CONFIRM_POSTGRES_WRITES e MANALOOM_CONFIRM_LIVE_MUTATIONS '
        'iguais a $_approvalPhrase';
  }
  final host = (environment['DB_HOST'] ?? 'localhost').trim().toLowerCase();
  const loopback = {'localhost', '127.0.0.1', '::1'};
  if (!loopback.contains(host) &&
      environment['MANALOOM_PG_WRAPPER_MODE'] != 'write-approved') {
    return 'banco fora do loopback: rode pelo '
        'server/bin/with_new_server_pg.sh --write-approved';
  }
  return null;
}

/// Prévia do e-mail do convite, com um código de exemplo.
String betaInvitePreview(Map<String, String> environment, Duration validity) {
  const sampleCode = 'XXXX-XXXX-XXXX-XXXX';
  final expires = DateTime.now().toUtc().add(validity).toIso8601String();
  return '''
Assunto: Seu convite para a beta do BrewTact
Você foi convidado para a beta do BrewTact
Use este convite para criar sua conta. Ele vale uma vez e só para este email.
Criar minha conta: ${betaInviteActionUrl(environment, sampleCode)}
Código do convite: $sampleCode
Este link expira em $expires (aproximado).
Se você não esperava este convite, ignore este email.''';
}
