const currentPublicSiteFallbackUrl =
    'https://evolution-manaloom-web-public.2ta7qx.easypanel.host';

String resolvePublicSiteBaseUrl(Map<String, String> environment) {
  final production =
      (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
      'production';
  final candidates = <String?>[
    environment['MANALOOM_PUBLIC_SITE_URL'],
    environment['NEXT_PUBLIC_SITE_URL'],
  ];

  for (final rawCandidate in candidates) {
    final candidate = rawCandidate?.trim();
    if (candidate == null || candidate.isEmpty) continue;
    final normalized = _normalizePublicSiteOrigin(
      candidate,
      production: production,
    );
    if (normalized != null) return normalized;
  }

  return currentPublicSiteFallbackUrl;
}

String buildPublicReportUrl(Map<String, String> environment, String reportId) {
  final encodedReportId = Uri.encodeComponent(reportId.trim());
  return '${resolvePublicSiteBaseUrl(environment)}/reports/$encodedReportId';
}

String? _normalizePublicSiteOrigin(
  String candidate, {
  required bool production,
}) {
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    return null;
  }

  final scheme = uri.scheme.toLowerCase();
  final secure = scheme == 'https';
  final developmentLoopback =
      !production && scheme == 'http' && _isLoopbackHost(uri.host);
  if (!secure && !developmentLoopback) return null;

  return uri.replace(path: '', query: null, fragment: null).toString();
}

bool _isLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}
