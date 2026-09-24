/// Admissão controlada de contas por convite (BT-AUTH-006).
///
/// Decisões do dono: D-16 (convite de uso único, emitido por ele em lotes de
/// 20 a 30, entregue por e-mail, com expiração e revogável; sem lista de
/// espera; deixa de ser exigido quando o cadastro abrir) e D-56 (aceitar o
/// convite enviado ao e-mail conta como verificação do e-mail).
///
/// Aqui ficam só regras puras: modo de admissão, formato e hash do código,
/// digest e pista do e-mail convidado e as negativas públicas. O acesso ao
/// banco está em `beta_invite_store.dart`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Variável que liga ou desliga a exigência de convite no cadastro.
const registrationAdmissionEnvironment = 'MANALOOM_REGISTRATION_ADMISSION';

/// Modo de admissão do `POST /auth/register`.
enum RegistrationAdmission {
  /// Só com convite válido. Padrão da produção (D-16).
  invite('invite'),

  /// Cadastro aberto: o convite deixa de ser exigido (D-16). Um convite
  /// informado continua valendo e continua verificando o e-mail.
  open('open');

  const RegistrationAdmission(this.wireName);

  final String wireName;

  bool get requiresInvite => this == RegistrationAdmission.invite;

  /// Produção: convite, salvo `open` explícito. Fora da produção: aberto,
  /// salvo `invite` explícito. Qualquer outro valor fecha em convite.
  static RegistrationAdmission fromEnvironment(
    Map<String, String> environment,
  ) {
    final production =
        (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
        'production';
    final raw =
        environment[registrationAdmissionEnvironment]?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) {
      return production
          ? RegistrationAdmission.invite
          : RegistrationAdmission.open;
    }
    return raw == 'open'
        ? RegistrationAdmission.open
        : RegistrationAdmission.invite;
  }
}

/// Alfabeto base32 de Crockford: sem I, L, O e U, para o código ser lido e
/// digitado sem ambiguidade.
const _crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// 16 símbolos de 5 bits: 80 bits aleatórios por convite.
const betaInviteCodeSymbols = 16;

final _normalizedCodePattern = RegExp(r'^[0-9A-HJKMNP-TV-Z]{16}$');

/// Gera um código novo, no formato `XXXX-XXXX-XXXX-XXXX`.
String newBetaInviteCode({Random? random}) {
  final source = random ?? Random.secure();
  final symbols = [
    for (var i = 0; i < betaInviteCodeSymbols; i++)
      _crockfordAlphabet[source.nextInt(_crockfordAlphabet.length)],
  ];
  return [
    for (var i = 0; i < betaInviteCodeSymbols; i += 4)
      symbols.sublist(i, i + 4).join(),
  ].join('-');
}

/// Normaliza o código recebido: maiúsculas, sem espaços nem hífens, `O` vira
/// `0`, `I` e `L` viram `1`. Devolve `null` quando não tem o formato de um
/// código (valor que não é texto, tamanho errado, símbolo fora do alfabeto).
String? normalizeBetaInviteCode(Object? raw) {
  if (raw is! String || raw.length > 64) return null;
  final compact = raw
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll('I', '1')
      .replaceAll('L', '1');
  return _normalizedCodePattern.hasMatch(compact) ? compact : null;
}

/// Hash guardado no banco no lugar do código.
String betaInviteTokenHash(String normalizedCode) =>
    _sha256Hex('brewtact:beta-invite-code:$normalizedCode');

/// Digest do e-mail convidado, comparado com o e-mail do cadastro.
String betaInviteEmailDigest(String email) =>
    _sha256Hex('brewtact:beta-invite-email:${email.trim().toLowerCase()}');

/// Identificador do código no limite de tentativas; nunca o código cru.
String betaInviteRateLimitIdentifier(String normalizedCode) =>
    'invite:${_sha256Hex('brewtact:beta-invite-rate:$normalizedCode')}';

/// Pista mascarada do e-mail, para o dono reconhecer o convite na listagem:
/// `joao.silva@example.com` vira `jo***@example.com`.
String betaInviteEmailHint(String email) {
  final normalized = email.trim().toLowerCase();
  final at = normalized.lastIndexOf('@');
  if (at <= 0 || at == normalized.length - 1) return '***';
  final local = normalized.substring(0, at);
  final domain = normalized.substring(at + 1);
  final visible =
      local.length <= 2 ? local.substring(0, 1) : local.substring(0, 2);
  final hint = '$visible***@$domain';
  return hint.length <= 120 ? hint : '${hint.substring(0, 117)}...';
}

/// E-mail aceito na emissão: um endereço simples, sem espaços nem quebra de
/// linha, com domínio. O cadastro valida o resto.
bool isAcceptableInviteEmail(String email) {
  final candidate = email.trim();
  return candidate.length <= 254 &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(candidate);
}

/// Rótulo do lote: minúsculas, dígitos, ponto, hífen e sublinhado, até 64.
bool isValidBetaInviteBatchLabel(String label) =>
    RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(label);

/// Máximo de convites por emissão (D-16: lotes de 20 a 30).
const betaInviteMaxBatchSize = 30;

/// Validade padrão de um convite emitido.
const betaInviteDefaultValidity = Duration(days: 14);

/// Negativas públicas do cadastro por convite. Código estável em snake_case
/// com a frase em português (D-21).
enum BetaInviteDenial {
  required(
    'invite_required',
    'O cadastro da beta é só por convite. Use o código que você recebeu por '
        'e-mail.',
  ),
  invalid(
    'invite_invalid',
    'Convite inválido para este e-mail. Confira o código e use o mesmo e-mail '
        'que recebeu o convite.',
  ),
  expired('invite_expired', 'Este convite expirou. Peça um novo convite.'),
  revoked(
    'invite_revoked',
    'Este convite foi cancelado. Peça um novo convite.',
  ),
  alreadyUsed(
    'invite_already_used',
    'Este convite já foi usado. Se a conta é sua, entre com seu e-mail e '
        'senha.',
  );

  const BetaInviteDenial(this.code, this.message);

  final String code;
  final String message;

  int get statusCode => HttpStatus.forbidden;

  Map<String, Object?> toJson() => {'error': code, 'message': message};
}

/// Convite recusado. [inviteId] e [auditEvent] existem quando o código é de
/// um convite real: a recusa entra na trilha de auditoria dele.
class BetaInviteDeniedException implements Exception {
  const BetaInviteDeniedException(
    this.denial, {
    this.inviteId,
    this.auditEvent,
  });

  final BetaInviteDenial denial;
  final String? inviteId;
  final String? auditEvent;

  @override
  String toString() => 'BetaInviteDeniedException(${denial.code})';
}

/// Estado de um convite, lido do banco para decidir a admissão.
class BetaInviteStatus {
  const BetaInviteStatus({
    required this.inviteId,
    required this.emailMatches,
    required this.accepted,
    required this.revoked,
    required this.expired,
  });

  final String inviteId;
  final bool emailMatches;
  final bool accepted;
  final bool revoked;
  final bool expired;
}

/// Decide a admissão de um convite. O e-mail vem primeiro: quem não tem o
/// código e o e-mail certos só vê `invite_invalid`, sem saber se o código
/// existe, expirou ou já foi usado.
BetaInviteDeniedException? evaluateBetaInvite(BetaInviteStatus? status) {
  if (status == null) {
    return const BetaInviteDeniedException(BetaInviteDenial.invalid);
  }
  if (!status.emailMatches) {
    return BetaInviteDeniedException(
      BetaInviteDenial.invalid,
      inviteId: status.inviteId,
      auditEvent: 'denied_email_mismatch',
    );
  }
  if (status.accepted) {
    return BetaInviteDeniedException(
      BetaInviteDenial.alreadyUsed,
      inviteId: status.inviteId,
      auditEvent: 'denied_used',
    );
  }
  if (status.revoked) {
    return BetaInviteDeniedException(
      BetaInviteDenial.revoked,
      inviteId: status.inviteId,
      auditEvent: 'denied_revoked',
    );
  }
  if (status.expired) {
    return BetaInviteDeniedException(
      BetaInviteDenial.expired,
      inviteId: status.inviteId,
      auditEvent: 'denied_expired',
    );
  }
  return null;
}

String _sha256Hex(String value) =>
    sha256.convert(utf8.encode(value)).toString();
