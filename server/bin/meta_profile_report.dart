import 'dart:convert';

import '../lib/database.dart';
import '../lib/meta/meta_deck_card_list_support.dart';
import '../lib/meta/meta_deck_commander_shell_support.dart';
import '../lib/meta/meta_deck_format_support.dart';

class CardInfo {
  CardInfo({required this.typeLine, required this.colorIdentity});

  final String typeLine;
  final List<String> colorIdentity;
}

class MutableProfile {
  int deckCount = 0;
  int totalCards = 0;
  int lands = 0;
  int basicLands = 0;
  int creatures = 0;
  int instants = 0;
  int sorceries = 0;
  int enchantments = 0;
  int artifacts = 0;
  int planeswalkers = 0;
}

class CommanderShellSummary {
  int deckCount = 0;
  int withCommanderName = 0;
  int withPartnerCommanderName = 0;
  int withShellLabel = 0;
  int withStrategyArchetype = 0;
  final Set<String> shellLabels = <String>{};
  final Set<String> strategyArchetypes = <String>{};
}

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  final cardRows = await conn.execute('''
    SELECT LOWER(name) AS name, type_line, color_identity
    FROM cards
  ''');

  final cardMap = <String, CardInfo>{};
  for (final row in cardRows) {
    final name = (row[0] as String?) ?? '';
    if (name.isEmpty) continue;
    final typeLine = (row[1] as String?) ?? '';
    final ci = (row[2] as List?)?.cast<String>() ?? const <String>[];
    cardMap[name] = CardInfo(typeLine: typeLine, colorIdentity: ci);
  }

  final deckRows = await conn.execute('''
    SELECT
      id::text,
      format,
      archetype,
      commander_name,
      partner_commander_name,
      shell_label,
      strategy_archetype,
      card_list
    FROM meta_decks
    WHERE source_url ILIKE 'https://www.mtgtop8.com/%'
  ''');

  final byFormat = <String, MutableProfile>{};
  final byFormatColorShell = <String, MutableProfile>{};
  final byFormatColorStrategy = <String, MutableProfile>{};
  final commanderSummaryByFormat = <String, CommanderShellSummary>{};

  for (final row in deckRows) {
    final format = ((row[1] as String?) ?? 'unknown').trim();
    final rawArchetype = ((row[2] as String?) ?? 'unknown').trim();
    final cardList = (row[7] as String?) ?? '';
    final descriptor = describeMetaDeckFormat(format);
    final commanderShell = resolveCommanderShellMetadata(
      format: format,
      rawArchetype: rawArchetype,
      cardList: cardList,
      commanderName: row[3] as String?,
      partnerCommanderName: row[4] as String?,
      shellLabel: row[5] as String?,
      strategyArchetype: row[6] as String?,
    );

    final parsed = _parseDeck(
      cardList: cardList,
      format: format,
      cardMap: cardMap,
    );
    if (parsed.totalCards == 0) continue;

    final formatKey = format.isEmpty ? 'unknown' : format;
    final colorsList = parsed.colors.toList()..sort(_compareManaColors);
    final colorsJoined = colorsList.isEmpty ? 'C' : colorsList.join('');
    final shellTheme = descriptor.isCommanderFamily
        ? _normalizeTheme(commanderShell.shellLabel ?? rawArchetype)
        : _normalizeTheme(rawArchetype);
    final strategyTheme = descriptor.isCommanderFamily
        ? _normalizeTheme(commanderShell.strategyArchetype ?? 'unknown')
        : _normalizeTheme(rawArchetype);

    _accumulate(
      byFormat.putIfAbsent(formatKey, () => MutableProfile()),
      parsed,
    );
    _accumulate(
      byFormatColorShell.putIfAbsent(
        '$formatKey|$colorsJoined|$shellTheme',
        () => MutableProfile(),
      ),
      parsed,
    );
    _accumulate(
      byFormatColorStrategy.putIfAbsent(
        '$formatKey|$colorsJoined|$strategyTheme',
        () => MutableProfile(),
      ),
      parsed,
    );

    if (descriptor.isCommanderFamily) {
      final summary = commanderSummaryByFormat.putIfAbsent(
        formatKey,
        () => CommanderShellSummary(),
      );
      summary.deckCount += 1;
      if (commanderShell.commanderName?.trim().isNotEmpty == true) {
        summary.withCommanderName += 1;
      }
      if (commanderShell.partnerCommanderName?.trim().isNotEmpty == true) {
        summary.withPartnerCommanderName += 1;
      }
      if (commanderShell.shellLabel?.trim().isNotEmpty == true) {
        summary.withShellLabel += 1;
        summary.shellLabels.add(commanderShell.shellLabel!.trim());
      }
      if (commanderShell.strategyArchetype?.trim().isNotEmpty == true) {
        summary.withStrategyArchetype += 1;
        summary.strategyArchetypes.add(
          commanderShell.strategyArchetype!.trim(),
        );
      }
    }
  }

  final formatReport = byFormat.entries.map((entry) {
    final profile = entry.value;
    final descriptor = describeMetaDeckFormat(entry.key);
    return {
      'format': descriptor.storedFormatCode,
      'format_family': descriptor.formatFamily,
      'format_label': descriptor.label,
      'subformat': descriptor.commanderSubformat,
      'deck_count': profile.deckCount,
      'avg_total_cards': _avg(profile.totalCards, profile.deckCount),
      'avg_lands': _avg(profile.lands, profile.deckCount),
      'avg_basic_lands': _avg(profile.basicLands, profile.deckCount),
      'avg_creatures': _avg(profile.creatures, profile.deckCount),
      'avg_instants': _avg(profile.instants, profile.deckCount),
      'avg_sorceries': _avg(profile.sorceries, profile.deckCount),
      'avg_enchantments': _avg(profile.enchantments, profile.deckCount),
      'avg_artifacts': _avg(profile.artifacts, profile.deckCount),
      'avg_planeswalkers': _avg(profile.planeswalkers, profile.deckCount),
    };
  }).toList()
    ..sort(
      (a, b) => (b['deck_count'] as int).compareTo(a['deck_count'] as int),
    );

  final commanderShellStrategySummary = commanderSummaryByFormat.entries
      .map((entry) {
        final descriptor = describeMetaDeckFormat(entry.key);
        final summary = entry.value;
        return {
          'format': descriptor.storedFormatCode,
          'format_label': descriptor.label,
          'subformat': descriptor.commanderSubformat,
          'deck_count': summary.deckCount,
          'with_commander_name': summary.withCommanderName,
          'with_partner_commander_name': summary.withPartnerCommanderName,
          'with_shell_label': summary.withShellLabel,
          'with_strategy_archetype': summary.withStrategyArchetype,
          'distinct_shell_labels': summary.shellLabels.length,
          'distinct_strategy_archetypes': summary.strategyArchetypes.length,
        };
      })
      .toList()
    ..sort(
      (a, b) => (b['deck_count'] as int).compareTo(a['deck_count'] as int),
    );

  final shellReport = _buildGroupedReport(byFormatColorShell, fieldName: 'shell');
  final strategyReport = _buildGroupedReport(
    byFormatColorStrategy,
    fieldName: 'strategy',
  );

  final payload = {
    'total_competitive_decks': deckRows.length,
    'formats': formatReport,
    'commander_shell_strategy_summary': commanderShellStrategySummary,
    'top_groups_format_color_theme': strategyReport.take(40).toList(),
    'top_groups_format_color_shell': shellReport.take(40).toList(),
    'top_groups_format_color_strategy': strategyReport.take(40).toList(),
  };

  print(const JsonEncoder.withIndent('  ').convert(payload));
  await db.close();
}

class ParsedDeck {
  ParsedDeck({
    required this.totalCards,
    required this.lands,
    required this.basicLands,
    required this.creatures,
    required this.instants,
    required this.sorceries,
    required this.enchantments,
    required this.artifacts,
    required this.planeswalkers,
    required this.colors,
  });

  final int totalCards;
  final int lands;
  final int basicLands;
  final int creatures;
  final int instants;
  final int sorceries;
  final int enchantments;
  final int artifacts;
  final int planeswalkers;
  final Set<String> colors;
}

ParsedDeck _parseDeck({
  required String cardList,
  required String format,
  required Map<String, CardInfo> cardMap,
}) {
  final basicNames = {
    'plains',
    'island',
    'swamp',
    'mountain',
    'forest',
    'wastes',
  };
  final colors = <String>{};

  var totalCards = 0;
  var lands = 0;
  var basicLands = 0;
  var creatures = 0;
  var instants = 0;
  var sorceries = 0;
  var enchantments = 0;
  var artifacts = 0;
  var planeswalkers = 0;

  final parsedCardList = parseMetaDeckCardList(
    cardList: cardList,
    format: format,
  );

  for (final entry in parsedCardList.effectiveCards.entries) {
    final qty = entry.value;
    final name = entry.key.toLowerCase();
    totalCards += qty;

    if (basicNames.contains(name)) {
      basicLands += qty;
      lands += qty;
      continue;
    }

    final info = cardMap[name];
    if (info == null) continue;

    for (final color in info.colorIdentity) {
      final upper = color.toUpperCase().trim();
      if (upper.isNotEmpty && 'WUBRGC'.contains(upper)) {
        colors.add(upper);
      }
    }

    final type = info.typeLine.toLowerCase();
    if (type.contains('land')) lands += qty;
    if (type.contains('creature')) creatures += qty;
    if (type.contains('instant')) instants += qty;
    if (type.contains('sorcery')) sorceries += qty;
    if (type.contains('enchantment')) enchantments += qty;
    if (type.contains('artifact')) artifacts += qty;
    if (type.contains('planeswalker')) planeswalkers += qty;
  }

  return ParsedDeck(
    totalCards: totalCards,
    lands: lands,
    basicLands: basicLands,
    creatures: creatures,
    instants: instants,
    sorceries: sorceries,
    enchantments: enchantments,
    artifacts: artifacts,
    planeswalkers: planeswalkers,
    colors: colors,
  );
}

void _accumulate(MutableProfile target, ParsedDeck source) {
  target.deckCount += 1;
  target.totalCards += source.totalCards;
  target.lands += source.lands;
  target.basicLands += source.basicLands;
  target.creatures += source.creatures;
  target.instants += source.instants;
  target.sorceries += source.sorceries;
  target.enchantments += source.enchantments;
  target.artifacts += source.artifacts;
  target.planeswalkers += source.planeswalkers;
}

List<Map<String, dynamic>> _buildGroupedReport(
  Map<String, MutableProfile> source, {
  required String fieldName,
}) {
  return source.entries
      .map((entry) {
        final profile = entry.value;
        final parts = entry.key.split('|');
        final descriptor = describeMetaDeckFormat(parts[0]);
        return {
          'format': descriptor.storedFormatCode,
          'format_family': descriptor.formatFamily,
          'format_label': descriptor.label,
          'subformat': descriptor.commanderSubformat,
          'colors': parts[1],
          fieldName: parts[2],
          'deck_count': profile.deckCount,
          'avg_lands': _avg(profile.lands, profile.deckCount),
          'avg_basic_lands': _avg(profile.basicLands, profile.deckCount),
          'avg_creatures': _avg(profile.creatures, profile.deckCount),
          'avg_instants': _avg(profile.instants, profile.deckCount),
          'avg_sorceries': _avg(profile.sorceries, profile.deckCount),
          'avg_enchantments': _avg(profile.enchantments, profile.deckCount),
          'avg_artifacts': _avg(profile.artifacts, profile.deckCount),
          'avg_planeswalkers': _avg(profile.planeswalkers, profile.deckCount),
        };
      })
      .where((entry) => (entry['deck_count'] as int) >= 2)
      .toList()
    ..sort(
      (a, b) => (b['deck_count'] as int).compareTo(a['deck_count'] as int),
    );
}

double _avg(int total, int count) {
  if (count <= 0) return 0;
  return double.parse((total / count).toStringAsFixed(2));
}

int _compareManaColors(String a, String b) {
  const order = 'WUBRGC';
  return order.indexOf(a).compareTo(order.indexOf(b));
}

String _normalizeTheme(String archetype) {
  final value = archetype.toLowerCase().trim();
  if (value.isEmpty) return 'unknown';

  final cleaned = value
      .replaceAll(RegExp(r'[^a-z0-9\s\-+]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return 'unknown';

  final tokens = cleaned.split(' ');
  final stop = {
    'the',
    'and',
    'of',
    'deck',
    'commander',
    'cedh',
    'edh',
    'duel',
    'mono',
    'with',
    'for',
    'to',
    'a',
    'an',
  };
  for (final token in tokens) {
    if (token.length < 3) continue;
    if (stop.contains(token)) continue;
    return token;
  }
  return tokens.first;
}
