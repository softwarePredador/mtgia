import 'package:postgres/postgres.dart';
import '../logger.dart';

/// Serviço para ler theme_contextual_rules do PostgreSQL.
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

String _archetypeToTheme(String archetype) {
  final a = archetype.trim().toLowerCase();
  if (a.contains('spellslinger') || a.contains('spells')) return 'spellslinger';
  if (a.contains('goblin')) return 'tribal_goblins';
  if (a.contains('elf')) return 'elfball';
  if (a.contains('vampire')) return 'vampires';
  if (a.contains('dragon')) return 'dragons';
  if (a.contains('zombie')) return 'zombies';
  if (a.contains('landfall') || a.contains('land_matter')) return 'landfall';
  if (a.contains('graveyard') || a.contains('reanimator')) return 'graveyard';
  if (a.contains('token')) return 'tokens';
  if (a.contains('counter')) return 'counters_plus_one';
  if (a.contains('voltron')) return 'voltron';
  if (a.contains('aristocrat')) return 'aristocrats';
  if (a.contains('enchantress')) return 'enchantress';
  if (a.contains('artifact')) return 'artifacts';
  if (a.contains('blink') || a.contains('flicker')) return 'blink_flicker';
  if (a.contains('combo') || a.contains('cedh')) return 'cedh_combo';
  if (a.contains('aggro')) return 'aggro';
  if (a.contains('control')) return 'control';
  if (a.contains('midrange')) return 'midrange';
  return a.replaceAll(' ', '_');
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
  bool get isViolation => status != 'ok';
}

class ThemeContextualRulesService {
  final Pool pool;

  ThemeContextualRulesService(this.pool);

  Future<List<ThemeContextualRule>> getRulesForArchetype(String archetype) async {
    final theme = _archetypeToTheme(archetype);
    if (theme.isEmpty) return [];

    try {
      final result = await pool.execute(
        Sql.named('''
          SELECT theme, function, min_count, max_count, ideal_count, priority, description
          FROM theme_contextual_rules
          WHERE theme = @theme
          ORDER BY priority DESC, function
        '''),
        parameters: {'theme': theme},
      );

      return result.map((row) => ThemeContextualRule.fromRow(row)).toList();
    } catch (e) {
      Log.w('ThemeContextualRules: erro ao buscar regras para $theme: $e');
      return [];
    }
  }

  Map<String, int> countCardsByFunction(List<Map<String, dynamic>> cards) {
    final counts = <String, int>{};
    for (final card in cards) {
      final functionalTag = card['functional_tag'] as String?;
      if (functionalTag != null && functionalTag.isNotEmpty) {
        counts[functionalTag] = (counts[functionalTag] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<ThemeValidationResult> validateDeck({
    required String archetype,
    required List<Map<String, dynamic>> cards,
  }) async {
    final rules = await getRulesForArchetype(archetype);
    if (rules.isEmpty) {
      return ThemeValidationResult(
        theme: _archetypeToTheme(archetype),
        checks: [],
        hasCriticalViolation: false,
      );
    }

    final theme = _archetypeToTheme(archetype);
    final counts = countCardsByFunction(cards);
    final checks = <ThemeCheck>[];
    bool hasCritical = false;

    for (final rule in rules) {
      final current = counts[rule.function] ?? 0;
      String status;
      if (current < rule.minCount) {
        status = 'below_min';
      } else if (current > rule.maxCount) {
        status = 'above_max';
      } else {
        status = 'ok';
      }

      if ((rule.isEssential || rule.isHigh) && status != 'ok') {
        hasCritical = true;
      }

      checks.add(ThemeCheck(
        function: rule.function,
        current: current,
        min: rule.minCount,
        max: rule.maxCount,
        priority: rule.priority,
        status: status,
        description: rule.description,
      ));
    }

    return ThemeValidationResult(
      theme: theme,
      checks: checks,
      hasCriticalViolation: hasCritical,
    );
  }
}
