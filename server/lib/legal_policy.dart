const currentTermsVersion = '2026-07-21';
const currentPrivacyVersion = '2026-07-21';
const requireLegalAcceptanceEnvironment = 'MANALOOM_REQUIRE_LEGAL_ACCEPTANCE';

class LegalAcceptancePolicy {
  const LegalAcceptancePolicy._();

  static bool isRequired(Map<String, String> environment) {
    final production =
        (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
        'production';
    final explicit =
        (environment[requireLegalAcceptanceEnvironment] ?? '')
            .trim()
            .toLowerCase();
    return production || explicit == 'true' || explicit == '1';
  }

  static LegalAcceptance? parse(
    Map<String, dynamic> body, {
    required bool required,
  }) {
    final accepted = body['legal_accepted'];
    final rawTermsVersion = body['terms_version'];
    final rawPrivacyVersion = body['privacy_version'];
    final termsVersion =
        rawTermsVersion is String ? rawTermsVersion.trim() : null;
    final privacyVersion =
        rawPrivacyVersion is String ? rawPrivacyVersion.trim() : null;
    final omitted =
        accepted == null && termsVersion == null && privacyVersion == null;
    if (omitted && !required) return null;
    if ((rawTermsVersion != null && rawTermsVersion is! String) ||
        (rawPrivacyVersion != null && rawPrivacyVersion is! String) ||
        accepted != true ||
        termsVersion != currentTermsVersion ||
        privacyVersion != currentPrivacyVersion) {
      throw const LegalAcceptanceException(
        'legal_acceptance_required',
        'Leia e aceite os Termos de uso e a Política de privacidade atuais.',
      );
    }
    return const LegalAcceptance(
      termsVersion: currentTermsVersion,
      privacyVersion: currentPrivacyVersion,
    );
  }
}

class LegalAcceptance {
  const LegalAcceptance({
    required this.termsVersion,
    required this.privacyVersion,
  });

  final String termsVersion;
  final String privacyVersion;
}

class LegalAcceptanceException implements Exception {
  const LegalAcceptanceException(this.code, this.message);

  final String code;
  final String message;
}
