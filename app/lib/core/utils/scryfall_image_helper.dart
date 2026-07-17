/// Centralizes Scryfall image URLs so list rendering can reuse persisted URLs
/// instead of issuing one `/cards/named` request per visible card.
abstract final class ScryfallImageHelper {
  static const _versions = <String>{
    'small',
    'normal',
    'large',
    'png',
    'art_crop',
    'border_crop',
  };

  static String? namedImageUrl(String? name, {String version = 'normal'}) {
    final cardName = name?.trim();
    if (cardName == null || cardName.isEmpty) return null;
    final safeVersion = _versions.contains(version) ? version : 'normal';
    return Uri.https('api.scryfall.com', '/cards/named', {
      'exact': cardName,
      'format': 'image',
      'version': safeVersion,
    }).toString();
  }

  static String? _normalizeUrl(String? imageUrl) {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    if (raw.startsWith('ttps://')) return 'h$raw';
    if (raw.startsWith('//')) return 'https:$raw';
    if (!raw.contains('://')) return 'https://$raw';
    if (raw.startsWith('http://')) {
      return 'https://${raw.substring('http://'.length)}';
    }
    return raw;
  }

  /// Returns the requested rendition of a persisted Scryfall URL.
  ///
  /// `cards.scryfall.io/normal/front/...` URLs can be rewritten without an API
  /// lookup. Named image URLs keep their endpoint and only replace `version`.
  /// Unknown hosts are deliberately left untouched by returning `null`.
  static String? withVersion(String? imageUrl, {required String version}) {
    final raw = _normalizeUrl(imageUrl);
    if (raw == null || raw.isEmpty || !_versions.contains(version)) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    if (uri.host == 'api.scryfall.com') {
      final isNamedImage = uri.path == '/cards/named';
      final segments = uri.pathSegments;
      final isDirectCardImage =
          segments.length >= 2 &&
          segments.first == 'cards' &&
          uri.queryParameters['format'] == 'image' &&
          !const {
            'autocomplete',
            'collection',
            'named',
            'random',
            'search',
          }.contains(segments[1]);
      if (isNamedImage || isDirectCardImage) {
        return uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'format': 'image',
                'version': version,
              },
            )
            .toString();
      }
    }

    if (uri.host != 'cards.scryfall.io') return null;
    final segments = uri.pathSegments.toList();
    if (segments.isEmpty || !_versions.contains(segments.first)) return null;
    segments[0] = version;
    return uri.replace(pathSegments: segments).toString();
  }

  /// Resolves a card image to one canonical Scryfall rendition.
  ///
  /// Persisted URLs can come from the card CDN, `/cards/named`, or the direct
  /// `/cards/{printing-id}` endpoint. Unknown hosts are not allowed to define
  /// deck-card geometry: when a card name is available, the named Scryfall
  /// image is used; otherwise the caller should render its neutral fallback.
  static String? canonicalCardImageUrl({
    required String? explicitUrl,
    required String? cardName,
    String version = 'normal',
  }) {
    if (!_versions.contains(version)) return null;
    return withVersion(explicitUrl, version: version) ??
        namedImageUrl(cardName, version: version);
  }

  /// Prefers the already persisted image and only falls back to a named API
  /// URL when the model has no usable artwork at all.
  static String? preferredImageUrl({
    required String? explicitUrl,
    required String? cardName,
    required String version,
  }) {
    final explicit = explicitUrl?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return withVersion(explicit, version: version) ?? explicit;
    }
    return namedImageUrl(cardName, version: version);
  }
}
