import 'package:postgres/postgres.dart';

import 'card_resolution_support.dart';

class DeckCardNameCandidate {
  const DeckCardNameCandidate({
    required this.inputName,
    required this.cardId,
    required this.candidateName,
    required this.resolutionSource,
  });

  final String inputName;
  final String cardId;
  final String candidateName;
  final String resolutionSource;
}

Future<String?> resolveDeckCardIdByName({
  required Session session,
  required String name,
  required String preferredFormat,
}) async {
  final candidatesByInput = await resolveDeckCardNameCandidates(
    session: session,
    names: [name],
    preferredFormat: preferredFormat,
  );
  final candidates = candidatesByInput[name.trim()] ?? const [];
  final decision = resolveCardCandidateNames(
    name,
    candidates.map((candidate) => candidate.candidateName),
  );
  if (!decision.isResolved) return null;

  final matchedName = decision.matchedName!.toLowerCase();
  for (final candidate in candidates) {
    if (candidate.candidateName.toLowerCase() == matchedName) {
      return candidate.cardId;
    }
  }
  return null;
}

Future<Map<String, List<DeckCardNameCandidate>>> resolveDeckCardNameCandidates({
  required Session session,
  required Iterable<String> names,
  String? preferredFormat,
  int limitPerInput = 5,
  bool allowFuzzy = false,
}) async {
  final cleanNames =
      names.map((name) => name.trim()).where((name) => name.isNotEmpty).toSet();
  if (cleanNames.isEmpty) return const {};

  Result result;
  try {
    result = await _queryDeckCardNameCandidatesFromIdentityBridge(
      session: session,
      names: cleanNames,
      preferredFormat: preferredFormat,
      limitPerInput: limitPerInput,
      allowFuzzy: allowFuzzy,
    );
  } catch (error) {
    if (!isUndefinedCardIdentityBridgeError(error)) rethrow;
    result = await _queryDeckCardNameCandidatesFromCards(
      session: session,
      names: cleanNames,
      preferredFormat: preferredFormat,
      limitPerInput: limitPerInput,
      allowFuzzy: allowFuzzy,
    );
  }

  final candidatesByInput = {
    for (final name in cleanNames) name: <DeckCardNameCandidate>[],
  };
  for (final row in result) {
    final inputName = row[0]?.toString().trim() ?? '';
    final cardId = row[1]?.toString().trim() ?? '';
    final candidateName = row[2]?.toString().trim() ?? '';
    final source = row[3]?.toString().trim() ?? '';
    if (inputName.isEmpty || cardId.isEmpty || candidateName.isEmpty) {
      continue;
    }
    candidatesByInput.putIfAbsent(inputName, () => <DeckCardNameCandidate>[]);
    candidatesByInput[inputName]!.add(DeckCardNameCandidate(
      inputName: inputName,
      cardId: cardId,
      candidateName: candidateName,
      resolutionSource: source.isEmpty ? 'unknown' : source,
    ));
  }

  return candidatesByInput;
}

Future<Result> _queryDeckCardNameCandidatesFromIdentityBridge({
  required Session session,
  required Set<String> names,
  required String? preferredFormat,
  required int limitPerInput,
  required bool allowFuzzy,
}) {
  final normalizedPreferredFormat = preferredFormat?.trim().toLowerCase();
  final hasPreferredFormat =
      normalizedPreferredFormat != null && normalizedPreferredFormat.isNotEmpty;
  final matchCondition = allowFuzzy
      ? '''
        cib.normalized_lookup_name = i.normalized_input_name
        OR cib.normalized_canonical_name = i.normalized_input_name
        OR cib.normalized_canonical_name LIKE i.normalized_input_name || ' // %'
        OR cib.normalized_canonical_name LIKE '% // ' || i.normalized_input_name
        OR cib.normalized_lookup_name LIKE i.normalized_input_name || '%'
        OR cib.normalized_canonical_name LIKE i.normalized_input_name || '%'
        OR cib.normalized_lookup_name LIKE '%' || i.normalized_input_name || '%'
        OR cib.normalized_canonical_name LIKE '%' || i.normalized_input_name || '%'
      '''
      : '''
        cib.normalized_lookup_name = i.normalized_input_name
        OR cib.normalized_canonical_name = i.normalized_input_name
        OR cib.normalized_canonical_name LIKE i.normalized_input_name || ' // %'
        OR cib.normalized_canonical_name LIKE '% // ' || i.normalized_input_name
      ''';

  return session.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT DISTINCT
          TRIM(n) AS input_name,
          LOWER(TRIM(n)) AS normalized_input_name
        FROM unnest(@names::text[]) AS n
        WHERE TRIM(n) <> ''
      ),
      matched AS (
        SELECT
          i.input_name,
          cib.card_id::text AS card_id,
          cib.canonical_name AS candidate_name,
          'card_identity_bridge'::text AS resolution_source,
          CASE
            WHEN cib.normalized_lookup_name = i.normalized_input_name THEN 0
            WHEN cib.normalized_canonical_name = i.normalized_input_name THEN 1
            WHEN cib.normalized_canonical_name LIKE i.normalized_input_name || ' // %' THEN 2
            WHEN cib.normalized_canonical_name LIKE '% // ' || i.normalized_input_name THEN 3
            WHEN cib.normalized_lookup_name LIKE i.normalized_input_name || '%' THEN 4
            WHEN cib.normalized_canonical_name LIKE i.normalized_input_name || '%' THEN 5
            WHEN cib.normalized_lookup_name LIKE '%' || i.normalized_input_name || '%' THEN 6
            WHEN cib.normalized_canonical_name LIKE '%' || i.normalized_input_name || '%' THEN 7
            ELSE 8
          END AS match_rank,
          CASE
            WHEN cl.status = 'legal' THEN 0
            WHEN cl.status = 'restricted' THEN 1
            WHEN cl.status IS NULL THEN 2
            ELSE 3
          END AS legality_rank,
          COALESCE(cib.match_priority, 999) AS match_priority
        FROM input_names i
        JOIN card_identity_bridge cib
          ON $matchCondition
        LEFT JOIN card_legalities cl
          ON cl.card_id = cib.card_id
         AND cl.format = @preferredFormat
        WHERE cib.canonical_name IS NOT NULL
          AND TRIM(cib.canonical_name) <> ''
      ),
      deduped AS (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY input_name, candidate_name
            ORDER BY match_rank, match_priority, legality_rank, card_id
          ) AS candidate_rank
        FROM matched
      ),
      limited AS (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY input_name
            ORDER BY match_rank, match_priority, legality_rank, candidate_name, card_id
          ) AS input_rank
        FROM deduped
        WHERE candidate_rank = 1
      )
      SELECT input_name, card_id, candidate_name, resolution_source
      FROM limited
      WHERE input_rank <= @limitPerInput
      ORDER BY input_name, input_rank
    '''),
    parameters: {
      'names': TypedValue(Type.textArray, names.toList()),
      'preferredFormat': hasPreferredFormat ? normalizedPreferredFormat : '',
      'limitPerInput': limitPerInput,
    },
  );
}

Future<Result> _queryDeckCardNameCandidatesFromCards({
  required Session session,
  required Set<String> names,
  required String? preferredFormat,
  required int limitPerInput,
  required bool allowFuzzy,
}) {
  final normalizedPreferredFormat = preferredFormat?.trim().toLowerCase();
  final hasPreferredFormat =
      normalizedPreferredFormat != null && normalizedPreferredFormat.isNotEmpty;
  final matchCondition = allowFuzzy
      ? '''
        LOWER(c.name) = i.normalized_input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 1)) = i.normalized_input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 2)) = i.normalized_input_name
        OR LOWER(REPLACE(c.name, ' // ', '/')) = i.normalized_input_name
        OR LOWER(c.name) LIKE i.normalized_input_name || '%'
        OR LOWER(c.name) LIKE '%' || i.normalized_input_name || '%'
      '''
      : '''
        LOWER(c.name) = i.normalized_input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 1)) = i.normalized_input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 2)) = i.normalized_input_name
        OR LOWER(REPLACE(c.name, ' // ', '/')) = i.normalized_input_name
      ''';

  return session.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT DISTINCT
          TRIM(n) AS input_name,
          LOWER(TRIM(n)) AS normalized_input_name
        FROM unnest(@names::text[]) AS n
        WHERE TRIM(n) <> ''
      ),
      matched AS (
        SELECT
          i.input_name,
          c.id::text AS card_id,
          c.name AS candidate_name,
          'cards_fallback'::text AS resolution_source,
          CASE
            WHEN LOWER(c.name) = i.normalized_input_name THEN 0
            WHEN LOWER(SPLIT_PART(c.name, ' // ', 1)) = i.normalized_input_name THEN 1
            WHEN LOWER(SPLIT_PART(c.name, ' // ', 2)) = i.normalized_input_name THEN 2
            WHEN LOWER(REPLACE(c.name, ' // ', '/')) = i.normalized_input_name THEN 3
            WHEN LOWER(c.name) LIKE i.normalized_input_name || '%' THEN 4
            WHEN LOWER(c.name) LIKE '%' || i.normalized_input_name || '%' THEN 5
            ELSE 6
          END AS match_rank,
          CASE
            WHEN cl.status = 'legal' THEN 0
            WHEN cl.status = 'restricted' THEN 1
            WHEN cl.status IS NULL THEN 2
            ELSE 3
          END AS legality_rank
        FROM input_names i
        JOIN cards c
          ON $matchCondition
        LEFT JOIN card_legalities cl
          ON cl.card_id = c.id
         AND cl.format = @preferredFormat
      ),
      deduped AS (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY input_name, candidate_name
            ORDER BY match_rank, legality_rank, card_id
          ) AS candidate_rank
        FROM matched
      ),
      limited AS (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY input_name
            ORDER BY match_rank, legality_rank, candidate_name, card_id
          ) AS input_rank
        FROM deduped
        WHERE candidate_rank = 1
      )
      SELECT input_name, card_id, candidate_name, resolution_source
      FROM limited
      WHERE input_rank <= @limitPerInput
      ORDER BY input_name, input_rank
    '''),
    parameters: {
      'names': TypedValue(Type.textArray, names.toList()),
      'preferredFormat': hasPreferredFormat ? normalizedPreferredFormat : '',
      'limitPerInput': limitPerInput,
    },
  );
}

bool isUndefinedCardIdentityBridgeError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('card_identity_bridge') &&
      (text.contains('does not exist') ||
          text.contains('undefined_table') ||
          text.contains('42p01'));
}
