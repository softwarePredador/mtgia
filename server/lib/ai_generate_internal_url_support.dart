Uri resolveAiGenerateInternalUrl({
  required Map<String, String> headers,
  required Uri requestUri,
  String? configuredBaseUrl,
  String? fallbackPort,
}) {
  final configured = configuredBaseUrl?.trim();
  if (configured != null && configured.isNotEmpty) {
    final base = configured.replaceFirst(RegExp(r'/$'), '');
    return Uri.parse('$base/ai/generate');
  }

  final host = headers['host']?.trim();
  final resolvedHost = host != null && host.isNotEmpty
      ? host
      : '127.0.0.1:${fallbackPort?.isNotEmpty == true ? fallbackPort : '8080'}';

  final forwardedProto =
      headers['x-forwarded-proto'] ?? headers['X-Forwarded-Proto'];
  final forwardedScheme = forwardedProto?.split(',').first.trim().toLowerCase();
  final requestScheme = requestUri.scheme.toLowerCase();
  final scheme = forwardedScheme == 'https' || forwardedScheme == 'http'
      ? forwardedScheme
      : requestScheme == 'https' || requestScheme == 'http'
          ? requestScheme
          : 'http';

  return Uri.parse('$scheme://$resolvedHost/ai/generate');
}
