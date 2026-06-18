import 'dart:convert';

import 'card_identity_support.dart';

const scryfallCollectionMaxBatchSize = 75;

class CardIdentityBackfillPayload {
  final String scryfallId;
  final String oracleId;
  final String? layout;
  final String? cardFacesJson;

  const CardIdentityBackfillPayload({
    required this.scryfallId,
    required this.oracleId,
    required this.layout,
    required this.cardFacesJson,
  });
}

int normalizeScryfallCollectionBatchSize(int value) {
  if (value < 1) return 1;
  if (value > scryfallCollectionMaxBatchSize) {
    return scryfallCollectionMaxBatchSize;
  }
  return value;
}

List<List<T>> chunkForScryfallCollection<T>(
  List<T> values, {
  int batchSize = scryfallCollectionMaxBatchSize,
}) {
  final normalizedBatchSize = normalizeScryfallCollectionBatchSize(batchSize);
  final chunks = <List<T>>[];
  for (var i = 0; i < values.length; i += normalizedBatchSize) {
    final end = (i + normalizedBatchSize).clamp(0, values.length);
    chunks.add(values.sublist(i, end));
  }
  return chunks;
}

String buildScryfallCollectionRequestBody(List<String> scryfallIds) {
  final identifiers = scryfallIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .map((id) => {'id': id})
      .toList(growable: false);
  return jsonEncode({'identifiers': identifiers});
}

String buildScryfallCollectionOracleRequestBody(List<String> oracleIds) {
  final identifiers = oracleIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .map((id) => {'oracle_id': id})
      .toList(growable: false);
  return jsonEncode({'identifiers': identifiers});
}

Map<String, CardIdentityBackfillPayload> parseScryfallCollectionIdentities(
  Map<String, dynamic> decoded,
) {
  final data = decoded['data'];
  if (data is! List) return const {};

  final identities = <String, CardIdentityBackfillPayload>{};
  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    final payload = scryfallIdentityPayload(item);
    final scryfallId = payload['scryfall_id'];
    final oracleId = payload['oracle_id'];
    if (scryfallId == null || oracleId == null) continue;
    identities[scryfallId] = CardIdentityBackfillPayload(
      scryfallId: scryfallId,
      oracleId: oracleId,
      layout: payload['layout'],
      cardFacesJson: payload['card_faces_json'],
    );
  }
  return identities;
}

Map<String, CardIdentityBackfillPayload>
    parseScryfallCollectionIdentitiesByOracleId(
  Map<String, dynamic> decoded,
) {
  final identitiesByScryfallId = parseScryfallCollectionIdentities(decoded);
  return {
    for (final payload in identitiesByScryfallId.values)
      payload.oracleId: payload,
  };
}
