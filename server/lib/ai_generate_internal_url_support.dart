Uri resolveInternalAiRouteUrl({
  required Map<String, String> headers,
  required Uri requestUri,
  required String routePath,
  String? configuredBaseUrl,
  String? fallbackPort,
}) {
  // `headers` and `requestUri` are intentionally not used to select the
  // destination. Host/proxy headers are client-controlled at this boundary;
  // reusing them would allow async requests (including their authorization
  // header) to be redirected outside this process.
  final configured = configuredBaseUrl?.trim();
  if (configured != null && configured.isNotEmpty) {
    final configuredUri = Uri.tryParse(configured);
    if (_isSafeConfiguredInternalBase(configuredUri)) {
      return configuredUri!.replace(
        path: routePath,
        query: null,
        fragment: null,
      );
    }
  }

  final parsedPort = int.tryParse(fallbackPort?.trim() ?? '');
  final port =
      parsedPort != null && parsedPort >= 1 && parsedPort <= 65535
          ? parsedPort
          : 8080;
  return Uri(scheme: 'http', host: '127.0.0.1', port: port, path: routePath);
}

bool _isSafeConfiguredInternalBase(Uri? uri) {
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return false;
  return uri.path.isEmpty || uri.path == '/';
}

Uri resolveAiGenerateInternalUrl({
  required Map<String, String> headers,
  required Uri requestUri,
  String? configuredBaseUrl,
  String? fallbackPort,
}) {
  return resolveInternalAiRouteUrl(
    headers: headers,
    requestUri: requestUri,
    routePath: '/ai/generate',
    configuredBaseUrl: configuredBaseUrl,
    fallbackPort: fallbackPort,
  );
}
