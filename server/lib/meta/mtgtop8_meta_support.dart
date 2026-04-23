import 'package:html/dom.dart';

const mtgTop8BaseUrl = 'https://www.mtgtop8.com';

const mtgTop8SupportedFormats = <String, String>{
  'ST': 'Standard',
  'PI': 'Pioneer',
  'MO': 'Modern',
  'LE': 'Legacy',
  'VI': 'Vintage',
  'EDH': 'Duel Commander',
  'cEDH': 'Competitive EDH',
  'PAU': 'Pauper',
  'PREM': 'Premodern',
};

class MtgTop8EventDeckRow {
  MtgTop8EventDeckRow({
    required this.deckUrl,
    required this.archetype,
    required this.placement,
    required this.formatCode,
    required this.deckId,
  });

  final String deckUrl;
  final String archetype;
  final String placement;
  final String formatCode;
  final String deckId;
}

List<String> extractRecentMtgTop8EventPaths(
  Document document, {
  int limit = 6,
}) {
  return document
      .querySelectorAll('a[href*="event?e="]')
      .map((anchor) => anchor.attributes['href'])
      .whereType<String>()
      .map(_normalizeEventPath)
      .whereType<String>()
      .toSet()
      .take(limit)
      .toList(growable: false);
}

MtgTop8EventDeckRow? parseMtgTop8EventDeckRow(
  Element row, {
  String baseUrl = mtgTop8BaseUrl,
  String? defaultFormatCode,
}) {
  final deckAnchors = row.querySelectorAll('a[href*="&d="]');
  if (deckAnchors.isEmpty) return null;

  final deckAnchor = deckAnchors.firstWhere(
    (anchor) => anchor.text.trim().isNotEmpty,
    orElse: () => deckAnchors.first,
  );

  final href = deckAnchor.attributes['href'];
  if (href == null || href.trim().isEmpty) return null;

  final resolvedUrl = resolveMtgTop8Url(href, baseUrl: baseUrl);
  final deckUri = Uri.parse(resolvedUrl);
  final deckId = deckUri.queryParameters['d'];
  if (deckId == null || deckId.trim().isEmpty) return null;

  final archetype = deckAnchor.text.trim();
  if (archetype.isEmpty) return null;

  return MtgTop8EventDeckRow(
    deckUrl: resolvedUrl,
    archetype: archetype,
    placement: extractMtgTop8Placement(row),
    formatCode: deckUri.queryParameters['f']?.trim().isNotEmpty == true
        ? deckUri.queryParameters['f']!.trim()
        : (defaultFormatCode ?? 'Unknown'),
    deckId: deckId.trim(),
  );
}

String extractMtgTop8Placement(Element row) {
  final directRank = row
      .querySelectorAll('div')
      .map((div) => _normalizeText(div.text))
      .firstWhere(_looksLikePlacement, orElse: () => '');
  if (directRank.isNotEmpty) {
    return directRank;
  }

  final rowText = _normalizeText(row.text);
  final match = RegExp(
    r'^(top\s+\d+|\d+(?:st|nd|rd|th)?|\d+/\d+)',
    caseSensitive: false,
  ).firstMatch(rowText);
  if (match != null) {
    return _normalizeText(match.group(0) ?? '');
  }

  return '?';
}

String resolveMtgTop8Url(String href, {String baseUrl = mtgTop8BaseUrl}) {
  final baseUri = Uri.parse('$baseUrl/');
  return baseUri.resolve(href).toString();
}

String? _normalizeEventPath(String href) {
  final resolved = resolveMtgTop8Url(href);
  final uri = Uri.parse(resolved);
  final eventId = uri.queryParameters['e'];
  if (eventId == null || eventId.trim().isEmpty) return null;
  return 'event?e=${eventId.trim()}';
}

String _normalizeText(String raw) {
  return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _looksLikePlacement(String text) {
  if (text.isEmpty) return false;
  final normalized = text.toLowerCase();
  return RegExp(r'^\d+$').hasMatch(normalized) ||
      RegExp(r'^\d+(st|nd|rd|th)$').hasMatch(normalized) ||
      RegExp(r'^top\s+\d+$').hasMatch(normalized) ||
      RegExp(r'^\d+/\d+$').hasMatch(normalized);
}
