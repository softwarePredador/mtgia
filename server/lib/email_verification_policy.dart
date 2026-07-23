import 'runtime_environment.dart';

const requireVerifiedEmailEnvironment = 'MANALOOM_REQUIRE_VERIFIED_EMAIL';
const emailVerificationTestResponseEnvironment =
    'MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE';
const emailVerificationTestResponseApproval =
    'I_UNDERSTAND_VERIFICATION_TOKENS_ARE_TEST_ONLY';

bool isVerifiedEmailRequired([Map<String, String>? values]) {
  final environment = values ?? _environmentValues();
  final production =
      (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
      'production';
  final explicit =
      (environment[requireVerifiedEmailEnvironment] ?? '').trim().toLowerCase();
  return production || explicit == 'true' || explicit == '1';
}

bool mayExposeEmailVerificationTokenForTesting(
  Map<String, String> environment,
) {
  return !isProductionEmailEnvironment(environment) &&
      environment[emailVerificationTestResponseEnvironment] ==
          emailVerificationTestResponseApproval;
}

bool isProductionEmailEnvironment(Map<String, String> environment) =>
    (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
    'production';

Map<String, String> emailVerificationEnvironmentValues() =>
    _environmentValues();

Map<String, String> _environmentValues() {
  final runtime = loadRuntimeEnvironment();
  return {
    for (final key in const [
      'ENVIRONMENT',
      requireVerifiedEmailEnvironment,
      emailVerificationTestResponseEnvironment,
      'EMAIL_VERIFICATION_WEBHOOK_URL',
      'EMAIL_VERIFICATION_WEBHOOK_TOKEN',
      'EMAIL_VERIFICATION_APP_URL',
    ])
      if (runtime[key] case final String value) key: value,
  };
}
