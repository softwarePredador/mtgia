import 'deck_section_support.dart';

class ImportListParseResult {
  final List<Map<String, dynamic>> parsedItems;
  final List<String> invalidLines;
  final List<String> unsupportedSectionLines;

  const ImportListParseResult({
    required this.parsedItems,
    required this.invalidLines,
    this.unsupportedSectionLines = const [],
  });
}

List<String> normalizeImportLines(dynamic rawList) {
  final lines = <String>[];

  if (rawList is String) {
    lines.addAll(rawList.split('\n'));
    return lines;
  }

  if (rawList is List) {
    for (final item in rawList) {
      if (item is String) {
        lines.add(item);
        continue;
      }

      if (item is Map) {
        final q = item['quantity'] ?? item['amount'] ?? item['qtd'] ?? 1;
        final n = item['name'] ?? item['card_name'] ?? item['card'] ?? '';
        if (n.toString().trim().isNotEmpty) {
          lines.add('$q $n');
        }
      }
    }
    return lines;
  }

  throw const FormatException('Field list must be a String or a List.');
}

ImportListParseResult parseImportLines(List<String> lines) {
  final parsedItems = <Map<String, dynamic>>[];
  final invalidLines = <String>[];
  final unsupportedSectionLines = <String>[];
  final lineRegex = RegExp(r'^(\d+)x?\s+([^(]+)\s*(?:\(([\w\d]+)\))?.*$');
  var inUnsupportedSection = false;
  var inCommanderSection = false;

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    final supportedSection = _supportedImportSection(line);
    if (supportedSection != null) {
      inUnsupportedSection = false;
      inCommanderSection = supportedSection == _ImportSection.commander;
      continue;
    }

    final sectionLabel = _unsupportedImportSectionLabel(line);
    if (sectionLabel != null) {
      inUnsupportedSection = true;
      inCommanderSection = false;
      invalidLines.add(line);
      unsupportedSectionLines.add(line);
      continue;
    }

    if (inUnsupportedSection) {
      unsupportedSectionLines.add(line);
      invalidLines.add(line);
      continue;
    }

    final match = lineRegex.firstMatch(line);
    if (match == null) {
      invalidLines.add(line);
      continue;
    }

    final quantity = int.parse(match.group(1)!);
    final cardName = _stripCommanderMarkers(match.group(2)!.trim());
    final lineLower = line.toLowerCase();
    final isCommanderTag =
        inCommanderSection ||
        lineLower.contains('[commander') ||
        lineLower.contains('*cmdr*') ||
        lineLower.contains('!commander');

    parsedItems.add({
      'line': line,
      'name': cardName,
      'quantity': quantity,
      'isCommanderTag': isCommanderTag,
    });
  }

  return ImportListParseResult(
    parsedItems: parsedItems,
    invalidLines: invalidLines,
    unsupportedSectionLines: unsupportedSectionLines,
  );
}

enum _ImportSection { commander, mainboard }

_ImportSection? _supportedImportSection(String line) {
  switch (normalizeDeckSectionValue(line)) {
    case 'commander':
    case 'commanders':
    case 'commandzone':
      return _ImportSection.commander;
    case 'deck':
    case 'main':
    case 'maindeck':
    case 'mainboard':
      return _ImportSection.mainboard;
  }
  return null;
}

String? _unsupportedImportSectionLabel(String line) {
  return isUnsupportedDeckSectionValue(line) ? line.trim() : null;
}

String _stripCommanderMarkers(String value) {
  return value
      .replaceAll(
        RegExp(r'\s*\[(?:commander|cmdr)\]\s*$', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'\s*\*cmdr\*\s*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*!commander\s*$', caseSensitive: false), '')
      .trim();
}
