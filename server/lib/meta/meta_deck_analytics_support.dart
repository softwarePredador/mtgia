import 'meta_deck_card_list_support.dart';
import 'meta_deck_commander_shell_support.dart';
import 'meta_deck_format_support.dart';

const metaDeckSourceMtgTop8 = 'mtgtop8';
const metaDeckSourceExternal = 'external';

class MetaDeckAnalyticsContext {
  const MetaDeckAnalyticsContext({
    required this.source,
    required this.sourceUrl,
    required this.format,
    required this.rawArchetype,
    required this.formatDescriptor,
    required this.parsedCardList,
    required this.commanderShell,
  });

  final String source;
  final String sourceUrl;
  final String format;
  final String rawArchetype;
  final MetaDeckFormatDescriptor formatDescriptor;
  final ParsedMetaDeckCardList parsedCardList;
  final CommanderShellMetadata commanderShell;

  String? get commanderSubformat => formatDescriptor.commanderSubformat;

  int get totalCards => parsedCardList.effectiveTotal;
}

String classifyMetaDeckSource(String? sourceUrl) {
  final raw = sourceUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return metaDeckSourceExternal;
  }

  final uri = Uri.tryParse(raw);
  final host = uri?.host.toLowerCase();
  if (host == 'mtgtop8.com' || host == 'www.mtgtop8.com') {
    return metaDeckSourceMtgTop8;
  }

  return metaDeckSourceExternal;
}

MetaDeckAnalyticsContext resolveMetaDeckAnalyticsContext({
  required String format,
  required String cardList,
  String? sourceUrl,
  String? rawArchetype,
  String? commanderName,
  String? partnerCommanderName,
  String? shellLabel,
  String? strategyArchetype,
}) {
  final normalizedFormat = format.trim();
  final normalizedSourceUrl = sourceUrl?.trim() ?? '';
  final normalizedArchetype = rawArchetype?.trim() ?? '';

  final parsedCardList = parseMetaDeckCardList(
    cardList: cardList,
    format: normalizedFormat,
  );
  final commanderShell = resolveCommanderShellMetadata(
    format: normalizedFormat,
    rawArchetype: normalizedArchetype,
    cardList: cardList,
    commanderName: commanderName,
    partnerCommanderName: partnerCommanderName,
    shellLabel: shellLabel,
    strategyArchetype: strategyArchetype,
  );

  return MetaDeckAnalyticsContext(
    source: classifyMetaDeckSource(normalizedSourceUrl),
    sourceUrl: normalizedSourceUrl,
    format: normalizedFormat,
    rawArchetype: normalizedArchetype,
    formatDescriptor: describeMetaDeckFormat(normalizedFormat),
    parsedCardList: parsedCardList,
    commanderShell: commanderShell,
  );
}
