import '../commander_bracket.dart';

class RebuildRouteRequestData {
  const RebuildRouteRequestData({
    required this.deckId,
    required this.theme,
    required this.archetype,
    required this.scope,
    required this.saveMode,
    required this.bracket,
    required this.mustKeep,
    required this.mustAvoid,
    required this.validationError,
  });

  final String? deckId;
  final String? theme;
  final String? archetype;
  final String scope;
  final String saveMode;
  final int? bracket;
  final List<String> mustKeep;
  final List<String> mustAvoid;
  final String? validationError;
}

RebuildRouteRequestData parseRebuildRouteRequest(Map<String, dynamic> body) {
  String? validationError;
  void report(String error) => validationError ??= error;

  final deckId = _readString(
    body['deck_id'],
    key: 'deck_id',
    maxLength: 128,
    report: report,
  );
  final theme = _readString(
    body['theme'],
    key: 'theme',
    maxLength: 240,
    report: report,
  );
  final archetype = _readString(
    body['archetype'],
    key: 'archetype',
    maxLength: 120,
    report: report,
  );
  final scope =
      _readString(
        body['rebuild_scope'],
        key: 'rebuild_scope',
        maxLength: 40,
        report: report,
      )?.toLowerCase() ??
      'auto';
  final saveMode =
      _readString(
        body['save_mode'],
        key: 'save_mode',
        maxLength: 32,
        report: report,
      )?.toLowerCase() ??
      'draft_clone';

  final bracketResult = parseCommanderBracket(body['bracket']);
  final bracket = bracketResult.value;
  if (bracketResult.error != null) report(bracketResult.error!);

  final mustKeep = _readCardNameList(
    body['must_keep'],
    key: 'must_keep',
    report: report,
  );
  final mustAvoid = _readCardNameList(
    body['must_avoid'],
    key: 'must_avoid',
    report: report,
  );

  return RebuildRouteRequestData(
    deckId: deckId,
    theme: theme,
    archetype: archetype,
    scope: scope,
    saveMode: saveMode,
    bracket: bracket,
    mustKeep: mustKeep,
    mustAvoid: mustAvoid,
    validationError: validationError,
  );
}

String? _readString(
  Object? value, {
  required String key,
  required int maxLength,
  required void Function(String error) report,
}) {
  if (value == null) return null;
  if (value is! String) {
    report('$key must be a string');
    return null;
  }
  final normalized = value.trim();
  if (normalized.length > maxLength) {
    report('$key exceeds the allowed size');
    return null;
  }
  return normalized.isEmpty ? null : normalized;
}

List<String> _readCardNameList(
  Object? value, {
  required String key,
  required void Function(String error) report,
}) {
  if (value == null) return const [];
  if (value is! List) {
    report('$key must be a list');
    return const [];
  }
  if (value.length > 100) {
    report('$key exceeds the allowed item count');
    return const [];
  }

  final normalized = <String>[];
  final seen = <String>{};
  for (final item in value) {
    if (item is! String) {
      report('$key must contain only strings');
      return const [];
    }
    final name = item.trim();
    if (name.length > 300) {
      report('$key contains a name that exceeds the allowed size');
      return const [];
    }
    if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
    normalized.add(name);
  }
  return List.unmodifiable(normalized);
}
