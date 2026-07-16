/// Normaliza nomes para regra de cópia física e comparação de pares.
///
/// Cartas split/MDFC podem chegar como nome completo ("Face A // Face B") ou
/// só pela face frontal ("Face A"). Para limite de cópias e matching de
/// "partner with", ambas representam a mesma carta física.
String normalizePhysicalCardCopyName(String name) {
  final collapsed = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final splitParts = collapsed.split(RegExp(r'\s*//\s*'));
  return splitParts.first.trim();
}

class CommanderPairingCard {
  const CommanderPairingCard({
    required this.name,
    required this.typeLine,
    this.oracleText,
  });

  final String name;
  final String typeLine;
  final String? oracleText;
}

bool isBackgroundCommanderPairCard(CommanderPairingCard card) {
  final typeLine = card.typeLine.toLowerCase();
  return typeLine.contains('legendary') &&
      typeLine.contains('enchantment') &&
      typeLine.contains('background');
}

bool hasChooseBackgroundCommanderPairAbility(CommanderPairingCard card) {
  return (card.oracleText ?? '').toLowerCase().contains('choose a background');
}

bool hasFriendsForeverCommanderPairAbility(CommanderPairingCard card) {
  return partnerTextCommanderPairVariant(card) == 'friends forever';
}

bool hasDoctorsCompanionCommanderPairAbility(CommanderPairingCard card) {
  return _commanderPairKeywordLines(card).contains("doctor's companion");
}

bool isTimeLordDoctorCommander(CommanderPairingCard card) {
  final parts = _normalizedTypeLineParts(card.typeLine);
  if (parts.length != 2 || !_isLegendaryCreatureTypeHeader(parts.first)) {
    return false;
  }
  return parts.last == 'time lord doctor';
}

String? partnerWithCommanderPairTargetName(CommanderPairingCard card) {
  for (final line in _commanderPairKeywordLines(card)) {
    final match = RegExp(r'^partner with\s+(.+)$').firstMatch(line);
    final value = match?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// Returns the exact CR 702.124i `partner—[text]` variant, when present.
///
/// Some Oracle payloads expose the named ability without the `partner—`
/// prefix (for example, `Friends forever`), so both representations normalize
/// to the same variant key.
String? partnerTextCommanderPairVariant(CommanderPairingCard card) {
  for (final line in _commanderPairKeywordLines(card)) {
    final match = RegExp(r'^partner\s*[—–-]\s*(.+)$').firstMatch(line);
    final explicitVariant = match?.group(1)?.trim();
    if (explicitVariant != null && explicitVariant.isNotEmpty) {
      return explicitVariant;
    }
    if (_standalonePartnerTextVariants.contains(line)) return line;
  }
  return null;
}

bool hasGenericPartnerCommanderPairAbility(CommanderPairingCard card) {
  if (partnerWithCommanderPairTargetName(card) != null) return false;
  if (partnerTextCommanderPairVariant(card) != null) return false;
  return _commanderPairKeywordLines(card).contains('partner');
}

bool areCommanderPairingCompatible(
  CommanderPairingCard first,
  CommanderPairingCard second,
) {
  final firstPartnerWith = partnerWithCommanderPairTargetName(first);
  final secondPartnerWith = partnerWithCommanderPairTargetName(second);
  final firstPartnerText = partnerTextCommanderPairVariant(first);
  final secondPartnerText = partnerTextCommanderPairVariant(second);

  if (hasGenericPartnerCommanderPairAbility(first) &&
      hasGenericPartnerCommanderPairAbility(second)) {
    return true;
  }

  if (firstPartnerText != null && firstPartnerText == secondPartnerText) {
    return true;
  }

  final firstName = normalizePhysicalCardCopyName(first.name);
  final secondName = normalizePhysicalCardCopyName(second.name);
  if (firstPartnerWith != null &&
      secondPartnerWith != null &&
      normalizePhysicalCardCopyName(firstPartnerWith) == secondName &&
      normalizePhysicalCardCopyName(secondPartnerWith) == firstName) {
    return true;
  }

  if ((hasChooseBackgroundCommanderPairAbility(first) &&
          isBackgroundCommanderPairCard(second)) ||
      (hasChooseBackgroundCommanderPairAbility(second) &&
          isBackgroundCommanderPairCard(first))) {
    return true;
  }

  if ((hasDoctorsCompanionCommanderPairAbility(first) &&
          _isLegendaryCreatureCard(first) &&
          isTimeLordDoctorCommander(second)) ||
      (hasDoctorsCompanionCommanderPairAbility(second) &&
          _isLegendaryCreatureCard(second) &&
          isTimeLordDoctorCommander(first))) {
    return true;
  }

  return false;
}

const _standalonePartnerTextVariants = <String>{
  'character select',
  'father & son',
  'friends forever',
  'survivors',
};

List<String> _commanderPairKeywordLines(CommanderPairingCard card) {
  final oracle = (card.oracleText ?? '')
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('\r\n', '\n');
  return oracle
      .split('\n')
      .map((rawLine) {
        final beforeReminder = rawLine.split('(').first;
        return beforeReminder
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'[.;:]+$'), '')
            .trim();
      })
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

List<String> _normalizedTypeLineParts(String typeLine) {
  final normalized =
      typeLine.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized.split(RegExp(r'\s+[—–-]\s+'));
}

bool _isLegendaryCreatureTypeHeader(String typeHeader) {
  return RegExp(r'\blegendary\b').hasMatch(typeHeader) &&
      RegExp(r'\bcreature\b').hasMatch(typeHeader);
}

bool _isLegendaryCreatureCard(CommanderPairingCard card) {
  final parts = _normalizedTypeLineParts(card.typeLine);
  return parts.isNotEmpty && _isLegendaryCreatureTypeHeader(parts.first);
}
