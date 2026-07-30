const accountEmailDeliveryProviderEnvironment =
    'MANALOOM_EMAIL_DELIVERY_PROVIDER';
const resendApiKeyEnvironment = 'RESEND_API_KEY';
const resendFromEmailEnvironment = 'RESEND_FROM_EMAIL';
const resendFromNameEnvironment = 'RESEND_FROM_NAME';
const resendVerifiedDomainEnvironment = 'RESEND_VERIFIED_DOMAIN';

const accountEmailDeliveryEnvironmentKeys = <String>{
  accountEmailDeliveryProviderEnvironment,
  resendApiKeyEnvironment,
  resendFromEmailEnvironment,
  resendFromNameEnvironment,
  resendVerifiedDomainEnvironment,
};

enum AccountEmailDeliveryProvider { webhook, resend }

AccountEmailDeliveryProvider accountEmailDeliveryProvider(
  Map<String, String> environment,
) {
  final configured = environment[accountEmailDeliveryProviderEnvironment];
  if (configured == null || configured.isEmpty) {
    return AccountEmailDeliveryProvider.webhook;
  }
  if (configured != configured.trim()) {
    throw StateError(
      '$accountEmailDeliveryProviderEnvironment não pode conter espaços externos.',
    );
  }
  return switch (configured.toLowerCase()) {
    'webhook' => AccountEmailDeliveryProvider.webhook,
    'resend' => AccountEmailDeliveryProvider.resend,
    _ =>
      throw StateError(
        '$accountEmailDeliveryProviderEnvironment deve ser webhook ou resend.',
      ),
  };
}

class ResendEmailConfiguration {
  const ResendEmailConfiguration({
    required this.apiKey,
    required this.fromEmail,
    required this.fromName,
    required this.verifiedDomain,
  });

  factory ResendEmailConfiguration.fromEnvironment(
    Map<String, String> environment,
  ) {
    final apiKey = environment[resendApiKeyEnvironment];
    if (apiKey == null ||
        apiKey != apiKey.trim() ||
        apiKey.length < 16 ||
        !apiKey.startsWith('re_')) {
      throw StateError(
        '$resendApiKeyEnvironment não atende ao contrato do Resend.',
      );
    }

    final fromEmail = environment[resendFromEmailEnvironment]?.trim() ?? '';
    final emailMatch = RegExp(
      r'^[^@\s<>]+@([^@\s<>]+)$',
      caseSensitive: false,
    ).firstMatch(fromEmail);
    if (emailMatch == null || _containsHeaderBreak(fromEmail)) {
      throw StateError('$resendFromEmailEnvironment deve ser um email válido.');
    }

    final verifiedDomain =
        environment[resendVerifiedDomainEnvironment]?.trim().toLowerCase() ??
        '';
    if (!_isDomain(verifiedDomain)) {
      throw StateError(
        '$resendVerifiedDomainEnvironment deve ser um domínio válido.',
      );
    }
    final fromDomain = emailMatch.group(1)!.toLowerCase();
    if (fromDomain != verifiedDomain) {
      throw StateError(
        '$resendFromEmailEnvironment deve usar '
        '$resendVerifiedDomainEnvironment.',
      );
    }

    final configuredName = environment[resendFromNameEnvironment];
    final fromName = configuredName?.trim() ?? 'ManaLoom';
    if (fromName.isEmpty ||
        fromName.length > 100 ||
        fromName.contains('<') ||
        fromName.contains('>') ||
        _containsHeaderBreak(fromName)) {
      throw StateError('$resendFromNameEnvironment é inválido.');
    }

    return ResendEmailConfiguration(
      apiKey: apiKey,
      fromEmail: fromEmail,
      fromName: fromName,
      verifiedDomain: verifiedDomain,
    );
  }

  final String apiKey;
  final String fromEmail;
  final String fromName;
  final String verifiedDomain;

  String get formattedFrom => '$fromName <$fromEmail>';
}

bool _containsHeaderBreak(String value) =>
    value.contains('\r') || value.contains('\n');

bool _isDomain(String value) {
  if (value.isEmpty ||
      value.length > 253 ||
      !value.contains('.') ||
      value.contains('..') ||
      value.startsWith('.') ||
      value.endsWith('.')) {
    return false;
  }
  return value
      .split('.')
      .every(
        (label) =>
            label.isNotEmpty &&
            label.length <= 63 &&
            RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$').hasMatch(label),
      );
}
