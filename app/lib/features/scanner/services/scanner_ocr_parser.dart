import 'dart:ui';

import '../models/card_recognition_result.dart';

class ScannerOcrParser {
  static const _setCodeStopwords = <String>{
    'THE',
    'AND',
    'FOR',
    'YOU',
    'WITH',
    'FROM',
    'THIS',
    'THAT',
    'NOT',
    'YES',
    'CAN',
    'MAY',
    'ALL',
    'ANY',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
    'TEN',
    'TM',
    'LLC',
    'INC',
    'CO',
    'BY',
    'OF',
  };

  static const _languageCodes = <String>{
    'EN',
    'PT',
    'JP',
    'JA',
    'DE',
    'FR',
    'ES',
    'IT',
    'RU',
    'KO',
    'ZH',
    'PH',
    'CS',
    'CT',
  };

  static const _nonNameKeywords = <String>{
    'creature',
    'instant',
    'sorcery',
    'enchantment',
    'artifact',
    'land',
    'planeswalker',
    'legendary',
    'basic',
    'token',
    'flying',
    'trample',
    'haste',
    'vigilance',
    'lifelink',
    'deathtouch',
    'tap',
    'untap',
    'target',
    'damage',
    'draw',
    'discard',
    'sacrifice',
    'destroy',
    'exile',
    'return',
    'counter',
    'copyright',
    'illustrated',
    'illus',
    'wizards',
    'hasbro',
  };

  static final _typeLinePattern = RegExp(
    r'^(legendary\s+)?(artifact\s+)?(creature|artifact|enchantment|instant|sorcery|land|planeswalker|battle|basic)\b',
    caseSensitive: false,
  );

  static final _collectorSlashPattern = RegExp(r'(\d{1,4})\s*/\s*(\d{1,4})');
  static final _soloNumberPattern = RegExp(r'(?<!\d)(\d{1,4})(?!\d|/\d)');
  static final _setCodePattern = RegExp(r'\b([A-Z][A-Z0-9]{1,4})\b');
  static final _languagePattern = RegExp(
    r'\b(EN|PT|JP|JA|DE|FR|ES|IT|RU|KO|ZH|PH|CS|CT)\b',
  );

  static CardRecognitionResult parseControlledText(String rawText) {
    final lines =
        rawText
            .split(RegExp(r'\r?\n'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    if (lines.isEmpty) {
      return CardRecognitionResult.failed('Texto OCR vazio');
    }

    final candidates = <CardNameCandidate>[];
    for (var i = 0; i < lines.length; i++) {
      final candidate = _buildNameCandidate(lines[i], i);
      if (candidate != null) candidates.add(candidate);
    }

    if (candidates.isEmpty) {
      return CardRecognitionResult.failed('Nenhum nome valido no OCR');
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final collectorLines = lines.where(_looksLikeCollectorLine).toList();
    final bottomText =
        collectorLines.isNotEmpty
            ? collectorLines.join(' ')
            : lines.skip(lines.length > 3 ? lines.length - 3 : 0).join(' ');

    return CardRecognitionResult.success(
      primaryName: candidates.first.text,
      alternatives:
          candidates
              .skip(1)
              .map((candidate) => candidate.text)
              .where((name) => name != candidates.first.text)
              .take(5)
              .toList(),
      setCodeCandidates: extractSetCodeCandidates(rawText),
      confidence: candidates.first.score.clamp(0, 100),
      allCandidates: candidates,
      collectorInfo: extractCollectorInfo(bottomText),
    );
  }

  static List<String> extractSetCodeCandidates(String rawText) {
    final text = rawText.replaceAll('\n', ' ');
    final matches = RegExp(r'\b[A-Za-z0-9]{2,6}\b').allMatches(text);

    final seen = <String>{};
    final candidates = <String>[];

    for (final match in matches) {
      final token = match.group(0);
      if (token == null) continue;

      final upper = token.toUpperCase();
      if (_setCodeStopwords.contains(upper)) continue;
      if (_languageCodes.contains(upper)) continue;

      final hasDigit = upper.contains(RegExp(r'\d'));
      final len = upper.length;
      final looksLikeSetCode = (len >= 3 && len <= 5) || (hasDigit && len <= 6);
      if (!looksLikeSetCode) continue;
      if (RegExp(r'^\d+$').hasMatch(upper)) continue;
      if (_nonNameKeywords.contains(upper.toLowerCase())) continue;

      if (seen.add(upper)) {
        candidates.add(upper);
        if (candidates.length >= 10) break;
      }
    }

    return candidates;
  }

  static CollectorInfo? extractCollectorInfo(String rawBottomText) {
    final rawBottom = rawBottomText.replaceAll('\n', ' ').trim();
    if (rawBottom.isEmpty) return null;

    String? collectorNumber;
    String? totalInSet;
    String? setCode;
    bool? isFoil;
    String? language;

    if (rawBottom.contains('★') ||
        rawBottom.contains('✩') ||
        rawBottom.contains('☆') ||
        rawBottom.contains('*')) {
      isFoil = true;
    } else if (rawBottom.contains('•') || rawBottom.contains('·')) {
      isFoil = false;
    }

    final slashMatch = _collectorSlashPattern.firstMatch(rawBottom);
    if (slashMatch != null) {
      collectorNumber = slashMatch.group(1);
      totalInSet = slashMatch.group(2);
    }

    if (collectorNumber == null) {
      for (final match in _soloNumberPattern.allMatches(rawBottom)) {
        final num = match.group(1)!;
        final numValue = int.tryParse(num);
        if (numValue != null &&
            (numValue < 1993 || numValue > 2030) &&
            numValue <= 999) {
          collectorNumber = num;
          break;
        }
      }
    }

    final upperBottom = rawBottom.toUpperCase();
    final langMatch = _languagePattern.firstMatch(upperBottom);
    if (langMatch != null) {
      language = langMatch.group(1);
    }

    for (final match in _setCodePattern.allMatches(upperBottom)) {
      final candidate = match.group(1)!;
      if (RegExp(r'^\d+$').hasMatch(candidate)) continue;
      if (_setCodeStopwords.contains(candidate)) continue;
      if (_languageCodes.contains(candidate)) continue;
      if (candidate.length < 2 || candidate.length > 5) continue;
      setCode = candidate;
      break;
    }

    if (collectorNumber == null && setCode == null && isFoil == null) {
      return null;
    }

    return CollectorInfo(
      collectorNumber: collectorNumber,
      totalInSet: totalInSet,
      setCode: setCode,
      isFoil: isFoil,
      language: language,
      rawBottomText: rawBottom,
    );
  }

  static CardNameCandidate? _buildNameCandidate(String rawLine, int lineIndex) {
    if (_looksLikeCollectorLine(rawLine)) return null;

    final cleaned = _cleanNameText(rawLine);
    if (cleaned.length < 2 || cleaned.length > 55) return null;

    final lower = cleaned.toLowerCase();
    if (_typeLinePattern.hasMatch(cleaned)) return null;
    if (RegExp(r'^\d+\s*/\s*\d+$').hasMatch(cleaned)) return null;
    if (RegExp(r'^[\d\s\W]+$').hasMatch(cleaned)) return null;
    if (_nonNameKeywords.contains(lower)) return null;
    if (lower.startsWith('illus') || lower.contains('wizards of the coast')) {
      return null;
    }

    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length > 6) return null;

    var score = 55.0;
    if (lineIndex == 0) score += 25;
    if (RegExp(r'^[A-Z]').hasMatch(cleaned)) score += 10;
    if (words.length >= 2) score += 8;
    if (cleaned.contains("'")) score += 6;
    if (cleaned.contains(',')) score += 6;
    if (cleaned.contains('-')) score += 4;

    return CardNameCandidate(
      text: cleaned,
      rawText: rawLine,
      score: score,
      boundingBox: Rect.zero,
    );
  }

  static bool _looksLikeCollectorLine(String line) {
    return _collectorSlashPattern.hasMatch(line) ||
        RegExp(r'[★✩☆•·*]').hasMatch(line);
  }

  static String _cleanNameText(String text) {
    var result = text.replaceAll(RegExp(r'\{[^}]+\}'), '');
    result = result.replaceAll(RegExp(r"['`']"), "'");
    result = result.replaceAll(RegExp(r'[—–]'), '-');
    result = result.replaceAll(RegExp(r"[^a-zA-Z\s'\-,]"), '');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (result == result.toLowerCase() || result == result.toUpperCase()) {
      result = _toTitleCase(result);
    }

    return result;
  }

  static String _toTitleCase(String text) {
    const smallWords = {
      'a',
      'an',
      'the',
      'and',
      'but',
      'or',
      'for',
      'nor',
      'of',
      'to',
      'in',
      'on',
      'at',
      'by',
    };

    return text
        .split(' ')
        .asMap()
        .entries
        .map((entry) {
          final word = entry.value;
          if (word.isEmpty) return word;
          if (entry.key == 0 || !smallWords.contains(word.toLowerCase())) {
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }
          return word.toLowerCase();
        })
        .join(' ');
  }
}
