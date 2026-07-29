import 'package:postgres/postgres.dart';

class OptimizeFormatLegalityFilterResult {
  const OptimizeFormatLegalityFilterResult({
    required this.allowed,
    required this.blocked,
  });

  final List<String> allowed;
  final List<String> blocked;
}

Future<OptimizeFormatLegalityFilterResult>
filterOptimizeCardNamesByKnownFormatLegality({
  required Pool pool,
  required Iterable<String> names,
  required String deckFormat,
}) async {
  final requested = names
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  if (requested.isEmpty) {
    return const OptimizeFormatLegalityFilterResult(
      allowed: <String>[],
      blocked: <String>[],
    );
  }

  final normalizedFormat = switch (deckFormat.trim().toLowerCase()) {
    '' => 'commander',
    'edh' => 'commander',
    final value => value,
  };
  final requestedLower = requested
      .map((name) => name.toLowerCase())
      .toSet()
      .toList(growable: false);
  final rows = await pool.execute(
    Sql.named('''
      SELECT LOWER(c.name) AS normalized_name
      FROM cards c
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id AND cl.format = @legality_format
      WHERE LOWER(c.name) = ANY(@names)
      GROUP BY LOWER(c.name)
      HAVING COUNT(cl.status) = 0
        OR BOOL_OR(cl.status IN ('legal', 'restricted'))
    '''),
    parameters: {'legality_format': normalizedFormat, 'names': requestedLower},
  );
  final allowedNames = {
    for (final row in rows) row[0].toString().trim().toLowerCase(),
  };
  return partitionOptimizeCardNamesByAllowedSet(
    names: requested,
    allowedNames: allowedNames,
  );
}

OptimizeFormatLegalityFilterResult partitionOptimizeCardNamesByAllowedSet({
  required Iterable<String> names,
  required Iterable<String> allowedNames,
}) {
  final allowedLower =
      allowedNames
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
  final allowed = <String>[];
  final blocked = <String>[];
  for (final rawName in names) {
    final name = rawName.trim();
    if (name.isEmpty) continue;
    if (allowedLower.contains(name.toLowerCase())) {
      allowed.add(name);
    } else {
      blocked.add(name);
    }
  }
  return OptimizeFormatLegalityFilterResult(allowed: allowed, blocked: blocked);
}
