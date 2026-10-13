class CorsPolicy {
  CorsPolicy._({
    required Set<String> allowedOrigins,
    required this.allowDevelopmentLoopback,
    required this.isProduction,
  }) : allowedOrigins = Set<String>.unmodifiable(allowedOrigins);

  factory CorsPolicy.fromEnvironment(Map<String, String> environment) {
    final runtime =
        (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase();
    final isProduction = runtime == 'production' || runtime == 'prod';
    final configured =
        (environment['MANALOOM_ALLOWED_ORIGINS'] ?? '')
            .split(',')
            .map(_normalizeOrigin)
            .whereType<String>()
            .where(
              (origin) => !isProduction || _isSecureProductionOrigin(origin),
            )
            .toSet();
    final allowDevelopmentLoopback =
        !isProduction && _isTrue(environment['MANALOOM_ALLOW_DEV_ORIGINS']);

    return CorsPolicy._(
      allowedOrigins: configured,
      allowDevelopmentLoopback: allowDevelopmentLoopback,
      isProduction: isProduction,
    );
  }

  static const allowedMethods = <String>{
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
  };

  /// A lista única dos cabeçalhos que o navegador pode mandar: o preflight é
  /// validado com ela e o `Access-Control-Allow-Headers` sai dela
  /// ([responseHeaders]). Um cabeçalho fora daqui recusa o preflight (403
  /// `cors_preflight_rejected`) e a chamada do app Web nem sai.
  static const allowedHeaders = <String>{
    'content-type',
    'authorization',
    'x-request-id',
    'x-manaloom-ops-key',
    // DCK-P0-01 (D-29): toda escrita num deck leva a revisão conhecida e uma
    // chave de idempotência (`server/lib/decks/deck_revision_support.dart`).
    'if-match',
    'idempotency-key',
  };

  /// Cabeçalhos de resposta que o app Web pode ler além dos simples do CORS:
  /// o `ETag` com a revisão do deck (DCK-P0-01) e o `x-request-id` que o app
  /// guarda na observabilidade.
  static const exposedHeaders = <String>{'etag', 'x-request-id'};

  /// Os cabeçalhos de CORS fixos de toda resposta, tirados das mesmas listas
  /// que validam o preflight. O middleware raiz não guarda lista própria.
  static final Map<String, String> responseHeaders = Map.unmodifiable({
    'Access-Control-Allow-Methods': allowedMethods.join(', '),
    'Access-Control-Allow-Headers': allowedHeaders.join(', '),
    'Access-Control-Expose-Headers': exposedHeaders.join(', '),
    'Access-Control-Max-Age': '86400',
  });

  final Set<String> allowedOrigins;
  final bool allowDevelopmentLoopback;
  final bool isProduction;

  bool isAllowed(String? rawOrigin) {
    if (rawOrigin == null || rawOrigin.trim().isEmpty) return true;
    final origin = _normalizeOrigin(rawOrigin);
    if (origin == null) return false;
    if (allowedOrigins.contains(origin)) return true;
    if (!allowDevelopmentLoopback) return false;

    final uri = Uri.parse(origin);
    return _isLoopbackHost(uri.host);
  }

  bool isValidPreflight({
    required String? requestedMethod,
    required String? requestedHeaders,
  }) {
    final method = requestedMethod?.trim().toUpperCase();
    if (method == null || !allowedMethods.contains(method)) return false;

    final headers = (requestedHeaders ?? '')
        .split(',')
        .map((header) => header.trim().toLowerCase())
        .where((header) => header.isNotEmpty);
    return headers.every(allowedHeaders.contains);
  }

  Map<String, Object> headersFor(String? rawOrigin) {
    final origin = _normalizeOrigin(rawOrigin ?? '');
    if (origin == null || !isAllowed(origin)) return const <String, Object>{};
    return <String, Object>{
      'Access-Control-Allow-Origin': origin,
      'Vary': 'Origin',
    };
  }

  static String? _normalizeOrigin(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }
    return uri.origin;
  }

  static bool _isTrue(String? raw) {
    final value = raw?.trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }

  static bool _isSecureProductionOrigin(String origin) {
    final uri = Uri.parse(origin);
    return uri.scheme == 'https' && !_isLoopbackHost(uri.host);
  }

  static bool _isLoopbackHost(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
