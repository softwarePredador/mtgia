import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../logger.dart';

class ThemeContextualRule {
  final String theme;
  final String function;
  final int minCount;
  final int maxCount;
  final int idealCount;
  final String priority;
  final String description;

  const ThemeContextualRule({
    required this.theme,
    required this.function,
    required this.minCount,
    required this.maxCount,
    required this.idealCount,
    required this.priority,
    required this.description,
  });

  factory ThemeContextualRule.fromRow(List<dynamic> row) {
    return ThemeContextualRule(
      theme: row[0] as String,
      function: row[1] as String,
      minCount: (row[2] as num?)?.toInt() ?? 0,
      maxCount: (row[3] as num?)?.toInt() ?? 999,
      idealCount: (row[4] as num?)?.toInt() ?? 0,
      priority: row[5] as String? ?? 'medium',
      description: row[6] as String? ?? '',
    );
  }

  bool get isEssential => priority == 'essential';
  bool get isHigh => priority == 'high';
}

class ThemeValidationResult {
  final String theme;
  final List<ThemeCheck> checks;
  final bool hasCriticalViolation;
  const ThemeValidationResult({
    required this.theme,
    required this.checks,
    required this.hasCriticalViolation,
  });

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'checks': checks.map((check) => check.toJson()).toList(),
    'has_critical_violation': hasCriticalViolation,
  };
}

class ThemeCheck {
  final String function;
  final int current;
  final int min;
  final int max;
  final String priority;
  final String status;
  final String description;

  const ThemeCheck({
    required this.function,
    required this.current,
    required this.min,
    required this.max,
    required this.priority,
    required this.status,
    required this.description,
  });

  bool get isOk => status == 'ok';

  Map<String, dynamic> toJson() => {
    'function': function,
    'current': current,
    'min': min,
    'max': max,
    'priority': priority,
    'status': status,
    'description': description,
  };
}

/// Counts persisted functional roles for theme validation.
///
/// PostgreSQL card rows expose the reviewed payload as `functional_tags`
/// (plural). Each role is counted at most once per card and respects quantity.
/// The legacy singular field is only used as a compatibility fallback.
Map<String, int> countThemeFunctionsFromCards(
  List<Map<String, dynamic>> cards,
) {
  final counts = <String, int>{};
  for (final card in cards) {
    final functions = <String>{};
    _collectThemeFunctions(card['functional_tags'], functions);
    if (functions.isEmpty) {
      _collectThemeFunctions(card['functional_tag'], functions);
    }

    final rawQuantity = card['quantity'];
    final parsedQuantity =
        rawQuantity is num
            ? rawQuantity.toInt()
            : int.tryParse(rawQuantity?.toString() ?? '');
    final quantity =
        parsedQuantity != null && parsedQuantity > 0 ? parsedQuantity : 1;
    for (final function in functions) {
      counts[function] = (counts[function] ?? 0) + quantity;
    }
  }
  return counts;
}

void _collectThemeFunctions(Object? value, Set<String> output) {
  if (value == null) return;

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        _collectThemeFunctions(jsonDecode(trimmed), output);
        return;
      } catch (_) {
        // A malformed legacy value is treated as a plain tag below.
      }
    }
    final normalized = _normalizeThemeFunction(trimmed);
    if (normalized.isNotEmpty) output.add(normalized);
    return;
  }

  if (value is Iterable) {
    for (final entry in value) {
      _collectThemeFunctions(entry, output);
    }
    return;
  }

  if (value is Map) {
    final confidence = _themeTagConfidence(value);
    final directTag =
        value['tag'] ?? value['function'] ?? value['role'] ?? value['name'];
    if (directTag != null && confidence >= 0.65) {
      final normalized = _normalizeThemeFunction(directTag.toString());
      if (normalized.isNotEmpty) output.add(normalized);
    }

    final nestedTags = value['tags'] ?? value['functional_tags'];
    if (nestedTags != null && confidence >= 0.65) {
      _collectThemeFunctions(nestedTags, output);
    }
  }
}

double _themeTagConfidence(Map value) {
  final raw =
      value['confidence'] ?? value['role_confidence'] ?? value['score'] ?? 1.0;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString()) ?? 1.0;
}

String _normalizeThemeFunction(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

class ThemeContextualRulesService {
  final Pool pool;
  ThemeContextualRulesService(this.pool);

  static String archetypeToTheme(String archetype) {
    final a = archetype.trim().toLowerCase();
    if (a.contains('spellslinger') || a.contains('spells'))
      return 'spellslinger';
    if (a.contains('goblin')) return 'tribal_goblins';
    if (a.contains('elf')) return 'elfball';
    if (a.contains('vampire')) return 'vampires';
    if (a.contains('dragon')) return 'dragons';
    if (a.contains('landfall')) return 'landfall';
    if (a.contains('graveyard')) return 'graveyard';
    if (a.contains('token')) return 'tokens';
    if (a.contains('voltron')) return 'voltron';
    if (a.contains('aristocrat')) return 'aristocrats';
    if (a.contains('combo') || a.contains('cedh')) return 'cedh_combo';
    return a.replaceAll(' ', '_');
  }

  Future<List<ThemeContextualRule>> getRulesForArchetype(
    String archetype,
  ) async {
    final theme = archetypeToTheme(archetype);
    if (theme.isEmpty) return [];
    try {
      final result = await pool.execute(
        Sql.named('''
        SELECT theme, function, min_count, max_count, ideal_count, priority, description
        FROM theme_contextual_rules WHERE theme = @theme ORDER BY priority DESC, function
      '''),
        parameters: {'theme': theme},
      );
      return result.map((row) => ThemeContextualRule.fromRow(row)).toList();
    } catch (e) {
      Log.w('ThemeContextualRules unavailable type=${e.runtimeType}');
      return [];
    }
  }

  Map<String, int> countCardsByFunction(List<Map<String, dynamic>> cards) {
    return countThemeFunctionsFromCards(cards);
  }

  Future<ThemeValidationResult> validateDeck({
    required String archetype,
    required List<Map<String, dynamic>> cards,
  }) async {
    final rules = await getRulesForArchetype(archetype);
    if (rules.isEmpty)
      return ThemeValidationResult(
        theme: archetypeToTheme(archetype),
        checks: [],
        hasCriticalViolation: false,
      );
    final counts = countCardsByFunction(cards);
    final checks = <ThemeCheck>[];
    bool hasCritical = false;
    for (final rule in rules) {
      final current = counts[_normalizeThemeFunction(rule.function)] ?? 0;
      final status =
          current < rule.minCount
              ? 'below_min'
              : current > rule.maxCount
              ? 'above_max'
              : 'ok';
      if ((rule.isEssential || rule.isHigh) && status != 'ok')
        hasCritical = true;
      checks.add(
        ThemeCheck(
          function: rule.function,
          current: current,
          min: rule.minCount,
          max: rule.maxCount,
          priority: rule.priority,
          status: status,
          description: rule.description,
        ),
      );
    }
    return ThemeValidationResult(
      theme: archetypeToTheme(archetype),
      checks: checks,
      hasCriticalViolation: hasCritical,
    );
  }
}
