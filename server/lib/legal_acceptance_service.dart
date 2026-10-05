/// Aceite versionado de Termos e Privacidade (BT-LEGAL-ACCEPT-001, D-24).
///
/// `users.terms_version` e `users.privacy_version` guardam o aceite vigente,
/// que o reaceite confere. Cada aceite (cadastro ou reaceite) também entra em
/// `user_legal_acceptances`, que só cresce: é o histórico que a D-24 manda
/// guardar como prova de consentimento.
library;

import 'package:postgres/postgres.dart';

import 'legal_policy.dart';

/// Rota em que a conta aceita a versão atual.
const legalAcceptancePath = '/users/me/legal-acceptance';

/// Origem de uma linha do histórico.
enum LegalAcceptanceSource {
  register('register'),
  reaccept('reaccept');

  const LegalAcceptanceSource(this.wireName);

  final String wireName;
}

/// Aceite de uma conta, comparado com as versões atuais. Conta sem aceite
/// (versão nula, de antes da migration 043) nunca está em dia.
class LegalAcceptanceStatus {
  const LegalAcceptanceStatus({
    required this.acceptedTermsVersion,
    required this.acceptedPrivacyVersion,
  });

  final String? acceptedTermsVersion;
  final String? acceptedPrivacyVersion;

  bool get upToDate =>
      acceptedTermsVersion == currentTermsVersion &&
      acceptedPrivacyVersion == currentPrivacyVersion;

  Map<String, Object?> toJson() => {
    'accepted_terms_version': acceptedTermsVersion,
    'accepted_privacy_version': acceptedPrivacyVersion,
    'current_terms_version': currentTermsVersion,
    'current_privacy_version': currentPrivacyVersion,
    'reacceptance_required': !upToDate,
    'accept_path': legalAcceptancePath,
  };
}

class LegalAcceptanceService {
  const LegalAcceptanceService(this._pool);

  final Pool _pool;

  /// Aceite vigente da conta, ou `null` se a conta não existe ou foi
  /// excluída.
  Future<LegalAcceptanceStatus?> status(String userId) async {
    final rows = await _pool.execute(
      Sql.named('''
        SELECT terms_version, privacy_version
        FROM users
        WHERE id = CAST(@userId AS uuid) AND deleted_at IS NULL
      '''),
      parameters: {'userId': userId},
    );
    if (rows.isEmpty) return null;
    return LegalAcceptanceStatus(
      acceptedTermsVersion: rows.first[0] as String?,
      acceptedPrivacyVersion: rows.first[1] as String?,
    );
  }

  /// Grava o aceite das versões atuais: a conta passa a apontar para elas e o
  /// histórico ganha uma linha. A linha da conta fica travada durante a
  /// transação, então aceites simultâneos gravam uma linha só; aceitar de
  /// novo o que já está aceito não duplica o histórico.
  Future<LegalAcceptanceStatus?> accept(
    String userId,
    LegalAcceptance acceptance, {
    String? requestId,
  }) {
    return _pool.runTx((tx) async {
      final current = await tx.execute(
        Sql.named('''
          SELECT terms_version, privacy_version
          FROM users
          WHERE id = CAST(@userId AS uuid) AND deleted_at IS NULL
          FOR UPDATE
        '''),
        parameters: {'userId': userId},
      );
      if (current.isEmpty) return null;
      final alreadyAccepted =
          current.first[0] == acceptance.termsVersion &&
          current.first[1] == acceptance.privacyVersion;
      if (!alreadyAccepted) {
        await tx.execute(
          Sql.named('''
            UPDATE users
            SET terms_version = @termsVersion,
                terms_accepted_at = CURRENT_TIMESTAMP,
                privacy_version = @privacyVersion,
                privacy_accepted_at = CURRENT_TIMESTAMP
            WHERE id = CAST(@userId AS uuid)
          '''),
          parameters: {
            'userId': userId,
            'termsVersion': acceptance.termsVersion,
            'privacyVersion': acceptance.privacyVersion,
          },
        );
        await recordHistory(
          tx,
          userId: userId,
          acceptance: acceptance,
          source: LegalAcceptanceSource.reaccept,
          requestId: requestId,
        );
      }
      return LegalAcceptanceStatus(
        acceptedTermsVersion: acceptance.termsVersion,
        acceptedPrivacyVersion: acceptance.privacyVersion,
      );
    });
  }

  /// Linha do histórico, na transação de quem chama (o cadastro usa a dele).
  static Future<void> recordHistory(
    Session tx, {
    required String userId,
    required LegalAcceptance acceptance,
    required LegalAcceptanceSource source,
    String? requestId,
  }) async {
    await tx.execute(
      Sql.named('''
        INSERT INTO user_legal_acceptances (
          user_id, terms_version, privacy_version, source, request_id
        ) VALUES (
          CAST(@userId AS uuid), @termsVersion, @privacyVersion, @source,
          @requestId
        )
      '''),
      parameters: {
        'userId': userId,
        'termsVersion': acceptance.termsVersion,
        'privacyVersion': acceptance.privacyVersion,
        'source': source.wireName,
        'requestId': requestId,
      },
    );
  }
}
