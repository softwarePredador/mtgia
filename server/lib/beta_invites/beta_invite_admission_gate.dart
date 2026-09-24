/// Portão do cadastro por convite (BT-AUTH-006): decide, sem banco, se a
/// requisição segue. Roda antes de qualquer consulta, escrita ou e-mail.
library;

import 'package:meta/meta.dart' show visibleForTesting;

import '../runtime_environment.dart';
import 'beta_invite_policy.dart';

class BetaInviteAdmissionGate {
  const BetaInviteAdmissionGate._({this.denial, this.inviteCode});

  /// Negativa já decidida (sem convite no modo `invite`, ou código que nem
  /// tem o formato de convite).
  final BetaInviteDenial? denial;

  /// Código normalizado, quando a requisição trouxe um.
  final String? inviteCode;

  static BetaInviteAdmissionGate evaluate({
    required RegistrationAdmission admission,
    required Object? rawInviteCode,
  }) {
    final missing =
        rawInviteCode == null ||
        (rawInviteCode is String && rawInviteCode.trim().isEmpty);
    if (missing) {
      return admission.requiresInvite
          ? const BetaInviteAdmissionGate._(denial: BetaInviteDenial.required)
          : const BetaInviteAdmissionGate._();
    }
    final code = normalizeBetaInviteCode(rawInviteCode);
    if (code == null) {
      return const BetaInviteAdmissionGate._(denial: BetaInviteDenial.invalid);
    }
    return BetaInviteAdmissionGate._(inviteCode: code);
  }
}

RegistrationAdmission? _registrationAdmissionOverride;

@visibleForTesting
void overrideRegistrationAdmissionForTesting(RegistrationAdmission? value) {
  _registrationAdmissionOverride = value;
}

/// Modo de admissão em vigor, lido do ambiente a cada cadastro.
RegistrationAdmission registrationAdmission() {
  final override = _registrationAdmissionOverride;
  if (override != null) return override;
  final runtime = loadRuntimeEnvironment();
  return RegistrationAdmission.fromEnvironment({
    if (runtime['ENVIRONMENT'] case final String value) 'ENVIRONMENT': value,
    if (runtime[registrationAdmissionEnvironment] case final String value)
      registrationAdmissionEnvironment: value,
  });
}
