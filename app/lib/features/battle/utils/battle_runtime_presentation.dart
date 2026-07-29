/// Presentation-only vocabulary for Battle runtime details.
///
/// Wire values and diagnostic provenance stay unchanged. Product surfaces must
/// describe the capability delivered to the player instead of exposing the
/// third-party rules executors used behind the API.
String battleRuntimeUserLabel(String? wireValue) => switch (wireValue) {
  'all' => 'Todos os modos',
  'auto' => 'Seleção automática',
  'xmage' => 'Execução principal',
  'forge' => 'Execução compatível',
  'manaloom_native_reviewed' || 'native' => 'Execução revisada',
  'unknown' || null => 'Modo não informado',
  _ => 'Execução registrada',
};

String sanitizeBattleUserMessage(String message) {
  final technicalTokens = sanitizeBattleTechnicalToken(message);
  return technicalTokens
      .replaceFirst(
        RegExp(r'^XMage\b', caseSensitive: false),
        'motor de regras',
      )
      .replaceFirst(
        RegExp(r'^Forge\b', caseSensitive: false),
        'motor de compatibilidade',
      )
      .replaceFirst(
        RegExp(r'^ManaLoom nativo(?: revisado)?\b', caseSensitive: false),
        'execução revisada',
      );
}

String sanitizeBattleTechnicalToken(String value) {
  final exactLabel = switch (value.toLowerCase()) {
    'xmage' ||
    'forge' ||
    'native' ||
    'manaloom_native_reviewed' => battleRuntimeUserLabel(value),
    _ => null,
  };
  if (exactLabel != null) return exactLabel;

  return value
      .replaceAll(RegExp(r'\bxmage(?=[_:\-])', caseSensitive: false), 'rules')
      .replaceAll(
        RegExp(r'\bforge(?=[_:\-])', caseSensitive: false),
        'compatibility',
      )
      .replaceAll(
        RegExp(r'\bmanaloom_native_reviewed\b', caseSensitive: false),
        'reviewed_simulation',
      );
}

Object? sanitizeBattleDiagnosticPayload(Object? value, {String? parentKey}) {
  if (value is Map) {
    final sanitized = <String, dynamic>{};
    for (final entry in value.entries) {
      final originalKey = entry.key.toString();
      final key = sanitizeBattleTechnicalToken(originalKey);
      sanitized[key] = sanitizeBattleDiagnosticPayload(
        entry.value,
        parentKey: originalKey,
      );
    }
    return sanitized;
  }
  if (value is List) {
    return value
        .map(
          (item) => sanitizeBattleDiagnosticPayload(item, parentKey: parentKey),
        )
        .toList(growable: false);
  }
  if (value is String) {
    if (_engineValueKeys.contains(parentKey)) {
      return battleRuntimeUserLabel(value);
    }
    return sanitizeBattleUserMessage(value);
  }
  return value;
}

const Set<String> _engineValueKeys = {
  'engine',
  'actual_engine',
  'requested_engine',
  'selected_engine',
};
