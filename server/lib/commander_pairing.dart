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
  return (card.oracleText ?? '').toLowerCase().contains('friends forever');
}

bool hasDoctorsCompanionCommanderPairAbility(CommanderPairingCard card) {
  return (card.oracleText ?? '').toLowerCase().contains("doctor's companion");
}

bool isTimeLordDoctorCommander(CommanderPairingCard card) {
  final typeLine = card.typeLine.toLowerCase();
  return typeLine.contains('time lord') && typeLine.contains('doctor');
}

String? partnerWithCommanderPairTargetName(CommanderPairingCard card) {
  final oracle = (card.oracleText ?? '').toLowerCase();
  final match = RegExp(r'\bpartner with\s+([^\n(]+)').firstMatch(oracle);
  final value = match?.group(1)?.trim();
  if (value == null || value.isEmpty) return null;
  return value.replaceAll(RegExp(r'[.;:]+$'), '').trim();
}

bool hasGenericPartnerCommanderPairAbility(CommanderPairingCard card) {
  final oracle = (card.oracleText ?? '').toLowerCase();
  if (partnerWithCommanderPairTargetName(card) != null) return false;
  return RegExp(r'\bpartner\b').hasMatch(oracle);
}

bool areCommanderPairingCompatible(
  CommanderPairingCard first,
  CommanderPairingCard second,
) {
  final firstPartnerWith = partnerWithCommanderPairTargetName(first);
  final secondPartnerWith = partnerWithCommanderPairTargetName(second);

  if (hasGenericPartnerCommanderPairAbility(first) &&
      hasGenericPartnerCommanderPairAbility(second)) {
    return true;
  }

  final firstName = normalizePhysicalCardCopyName(first.name);
  final secondName = normalizePhysicalCardCopyName(second.name);
  if (firstPartnerWith != null &&
      normalizePhysicalCardCopyName(firstPartnerWith) == secondName) {
    return true;
  }
  if (secondPartnerWith != null &&
      normalizePhysicalCardCopyName(secondPartnerWith) == firstName) {
    return true;
  }

  if ((hasChooseBackgroundCommanderPairAbility(first) &&
          isBackgroundCommanderPairCard(second)) ||
      (hasChooseBackgroundCommanderPairAbility(second) &&
          isBackgroundCommanderPairCard(first))) {
    return true;
  }

  if (hasFriendsForeverCommanderPairAbility(first) &&
      hasFriendsForeverCommanderPairAbility(second)) {
    return true;
  }

  if ((hasDoctorsCompanionCommanderPairAbility(first) &&
          isTimeLordDoctorCommander(second)) ||
      (hasDoctorsCompanionCommanderPairAbility(second) &&
          isTimeLordDoctorCommander(first))) {
    return true;
  }

  return false;
}
