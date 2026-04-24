import 'mtgtop8_meta_support.dart';

const legacyDuelCommanderFormatCode = 'EDH';
const legacyCompetitiveCommanderFormatCode = 'cEDH';

class MetaDeckFormatDescriptor {
  const MetaDeckFormatDescriptor({
    required this.storedFormatCode,
    required this.formatFamily,
    required this.label,
    this.commanderSubformat,
  });

  final String storedFormatCode;
  final String formatFamily;
  final String label;
  final String? commanderSubformat;

  bool get isCommanderFamily => formatFamily == 'commander';
}

MetaDeckFormatDescriptor describeMetaDeckFormat(String? rawFormat) {
  final storedFormat = (rawFormat ?? '').trim();

  switch (storedFormat) {
    case legacyDuelCommanderFormatCode:
      return const MetaDeckFormatDescriptor(
        storedFormatCode: legacyDuelCommanderFormatCode,
        formatFamily: 'commander',
        label: 'Duel Commander (MTGTop8 EDH)',
        commanderSubformat: 'duel_commander',
      );
    case legacyCompetitiveCommanderFormatCode:
      return const MetaDeckFormatDescriptor(
        storedFormatCode: legacyCompetitiveCommanderFormatCode,
        formatFamily: 'commander',
        label: 'Competitive Commander (MTGTop8 cEDH)',
        commanderSubformat: 'competitive_commander',
      );
    default:
      final fallback = storedFormat.isEmpty ? 'unknown' : storedFormat;
      return MetaDeckFormatDescriptor(
        storedFormatCode: fallback,
        formatFamily: fallback.toLowerCase(),
        label: mtgTop8SupportedFormats[storedFormat] ?? fallback,
      );
  }
}

String normalizeCommanderMetaScope(
  String? rawScope, {
  String fallback = 'commander',
}) {
  final normalized = rawScope?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }

  return switch (normalized) {
    'commander' ||
    'edh' ||
    'multiplayer commander' ||
    'casual commander' =>
      'commander',
    'duel_commander' || 'duel commander' || 'mtgtop8 edh' => 'duel_commander',
    'competitive_commander' ||
    'competitive commander' ||
    'cedh' ||
    'competitive edh' =>
      'competitive_commander',
    _ => fallback,
  };
}

String commanderMetaScopeLabel(String? rawScope) {
  return switch (normalizeCommanderMetaScope(rawScope)) {
    'duel_commander' => 'Duel Commander',
    'competitive_commander' => 'Competitive Commander',
    _ => 'Commander (broad scope)',
  };
}

List<String> metaDeckFormatCodesForCommanderScope(String? rawScope) {
  return switch (normalizeCommanderMetaScope(rawScope)) {
    'duel_commander' => const <String>[legacyDuelCommanderFormatCode],
    'competitive_commander' =>
      const <String>[legacyCompetitiveCommanderFormatCode],
    _ => const <String>[
        legacyDuelCommanderFormatCode,
        legacyCompetitiveCommanderFormatCode,
      ],
  };
}

List<String> commanderSubformatsForScope(String? rawScope) {
  return switch (normalizeCommanderMetaScope(rawScope)) {
    'duel_commander' => const <String>['duel_commander'],
    'competitive_commander' => const <String>['competitive_commander'],
    _ => const <String>['duel_commander', 'competitive_commander'],
  };
}

String? legacyMetaDeckFormatCodeForCommanderSubformat(String? rawScope) {
  return switch (normalizeCommanderMetaScope(rawScope)) {
    'duel_commander' => legacyDuelCommanderFormatCode,
    'competitive_commander' => legacyCompetitiveCommanderFormatCode,
    _ => null,
  };
}

List<String> metaDeckFormatCodesForDeckFormat(
  String rawDeckFormat, {
  String commanderScope = 'commander',
}) {
  final trimmed = rawDeckFormat.trim();
  if (trimmed.isEmpty) return const <String>[];

  if (mtgTop8SupportedFormats.containsKey(trimmed)) {
    return <String>[trimmed];
  }

  final normalized = trimmed.toLowerCase();
  switch (normalized) {
    case 'commander':
    case 'edh':
      return metaDeckFormatCodesForCommanderScope(commanderScope);
    case 'cedh':
    case 'competitive commander':
    case 'competitive edh':
    case 'competitive_commander':
      return const <String>[legacyCompetitiveCommanderFormatCode];
    case 'duel commander':
    case 'duel_commander':
      return const <String>[legacyDuelCommanderFormatCode];
    case 'standard':
      return const <String>['ST'];
    case 'pioneer':
      return const <String>['PI'];
    case 'modern':
      return const <String>['MO'];
    case 'legacy':
      return const <String>['LE'];
    case 'vintage':
      return const <String>['VI'];
    case 'pauper':
      return const <String>['PAU'];
    case 'premodern':
      return const <String>['PREM'];
  }

  final upper = trimmed.toUpperCase();
  if (mtgTop8SupportedFormats.containsKey(upper)) {
    return <String>[upper];
  }

  return const <String>[];
}

String metaDeckAnalyticsFormatKey(String? rawFormat) {
  final descriptor = describeMetaDeckFormat(rawFormat);
  return descriptor.commanderSubformat ?? descriptor.storedFormatCode;
}
