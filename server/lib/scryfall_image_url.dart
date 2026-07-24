final RegExp _scryfallPrintingIdPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Returns the concrete Scryfall printing id carried by an upstream payload.
///
/// Scryfall card objects use `id`; MTGJSON uses
/// `identifiers.scryfallId`. `oracle_id`/`scryfallOracleId` are deliberately
/// not accepted because they identify a playable card, not an image printing.
String? scryfallPrintingIdFromPayload(Map<String, dynamic> payload) {
  final identifiers = payload['identifiers'];
  final candidate =
      identifiers is Map ? identifiers['scryfallId'] : payload['id'];
  final value = candidate?.toString().trim().toLowerCase();
  if (value == null || !_scryfallPrintingIdPattern.hasMatch(value)) {
    return null;
  }
  return value;
}

/// Builds the normal/front CDN URL for a concrete Scryfall printing.
///
/// This helper must only receive a printing id validated by
/// [scryfallPrintingIdFromPayload]. It never derives an image from an
/// `oracle_id`.
String? scryfallNormalCdnUrlForPrinting(String? printingId) {
  final normalized = printingId?.trim().toLowerCase();
  if (normalized == null || !_scryfallPrintingIdPattern.hasMatch(normalized)) {
    return null;
  }
  return 'https://cards.scryfall.io/normal/front/'
      '${normalized[0]}/${normalized[1]}/$normalized.jpg';
}

/// Resolves the direct normal image URL from a Scryfall/MTGJSON card payload.
///
/// A payload-provided `image_uris.normal` (or first-face equivalent) wins when
/// it points to the same concrete printing. MTGJSON does not currently expose
/// `image_uris`, so a URL with the same CDN key is derived from its validated
/// `identifiers.scryfallId`. No oracle identity is ever used as an image key.
String? scryfallNormalImageUrlFromPayload(Map<String, dynamic> payload) {
  final printingId = scryfallPrintingIdFromPayload(payload);
  if (printingId == null) return null;

  final candidates = <Object?>[
    if (payload['image_uris'] is Map) (payload['image_uris'] as Map)['normal'],
    if (payload['card_faces'] is List)
      for (final face in payload['card_faces'] as List)
        if (face is Map && face['image_uris'] is Map)
          (face['image_uris'] as Map)['normal'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (_isDirectNormalImageForPrinting(value, printingId)) {
      return value;
    }
  }

  return scryfallNormalCdnUrlForPrinting(printingId);
}

/// Last-resort compatibility URL for payloads without a concrete printing id.
///
/// The endpoint can be rate-limited, so new sync data should prefer
/// [scryfallNormalImageUrlFromPayload]. Split cards use the front-face lookup,
/// matching the historical response normalizer.
String scryfallNamedImageFallback(String name, {String? setCode}) {
  final exact = name.split('//').first.trim();
  final query = <String, String>{
    'exact': exact.isEmpty ? name.trim() : exact,
    if (setCode != null && setCode.trim().isNotEmpty)
      'set': setCode.trim().toLowerCase(),
    'format': 'image',
    'version': 'normal',
  };
  return Uri.https(
    'api.scryfall.com',
    '/cards/named',
    query,
  ).toString().replaceAll('+', '%20');
}

/// Normalizes persisted image URLs while keeping old records readable.
///
/// When both ids prove that [printingId] is not an oracle identity, legacy
/// Scryfall image endpoints can be upgraded at read time to the direct CDN.
/// Without that evidence the original lookup URL is retained.
String? normalizeScryfallImageUrl(
  String? url, {
  String? printingId,
  String? oracleId,
}) {
  final provenPrintingUrl = _provenPrintingCdnUrl(
    printingId: printingId,
    oracleId: oracleId,
  );

  if (url == null) return provenPrintingUrl;
  var normalized = url.trim();
  if (normalized.isEmpty) return provenPrintingUrl;

  if (normalized.startsWith('ttps://')) {
    normalized = 'h$normalized';
  } else if (normalized.startsWith('//api.scryfall.com/') ||
      normalized.startsWith('//cards.scryfall.io/')) {
    normalized = 'https:$normalized';
  } else if (normalized.startsWith('api.scryfall.com/') ||
      normalized.startsWith('cards.scryfall.io/')) {
    normalized = 'https://$normalized';
  } else if (normalized.startsWith('http://api.scryfall.com/')) {
    normalized = normalized.replaceFirst(
      'http://api.scryfall.com/',
      'https://api.scryfall.com/',
    );
  } else if (normalized.startsWith('http://cards.scryfall.io/')) {
    normalized = normalized.replaceFirst(
      'http://cards.scryfall.io/',
      'https://cards.scryfall.io/',
    );
  }

  final parsed = Uri.tryParse(normalized);
  final host = parsed?.host.toLowerCase();
  if (host == 'cards.scryfall.io') return normalized;
  if (host != 'api.scryfall.com') return normalized;

  try {
    final uri = Uri.parse(normalized);
    final qp = Map<String, String>.from(uri.queryParameters);
    final isLegacyImageEndpoint =
        qp['format'] == 'image' &&
        (uri.path == '/cards/named' ||
            RegExp(
              r'^/cards/[0-9a-f-]+$',
              caseSensitive: false,
            ).hasMatch(uri.path));
    if (provenPrintingUrl != null && isLegacyImageEndpoint) {
      return provenPrintingUrl;
    }

    if (qp['set'] != null) qp['set'] = qp['set']!.toLowerCase();

    final exact = qp['exact'];
    if (uri.path == '/cards/named' && exact != null && exact.contains('//')) {
      final left = exact.split('//').first.trim();
      if (left.isNotEmpty) qp['exact'] = left;
    }

    return uri.replace(queryParameters: qp).toString().replaceAll('+', '%20');
  } catch (_) {
    return normalized.replaceAllMapped(
      RegExp(r'([?&]set=)([^&]+)', caseSensitive: false),
      (m) => '${m.group(1)}${(m.group(2) ?? '').toLowerCase()}',
    );
  }
}

bool _isDirectNormalImageForPrinting(String? value, String printingId) {
  if (value == null || value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      uri.host.toLowerCase() != 'cards.scryfall.io') {
    return false;
  }
  final expectedSuffix = '/$printingId.jpg';
  return uri.path.startsWith('/normal/') &&
      uri.path.toLowerCase().endsWith(expectedSuffix);
}

String? _provenPrintingCdnUrl({
  required String? printingId,
  required String? oracleId,
}) {
  final normalizedPrinting = printingId?.trim().toLowerCase();
  final normalizedOracle = oracleId?.trim().toLowerCase();
  if (normalizedPrinting == null ||
      normalizedOracle == null ||
      normalizedPrinting == normalizedOracle ||
      !_scryfallPrintingIdPattern.hasMatch(normalizedPrinting) ||
      !_scryfallPrintingIdPattern.hasMatch(normalizedOracle)) {
    return null;
  }
  return scryfallNormalCdnUrlForPrinting(normalizedPrinting);
}
