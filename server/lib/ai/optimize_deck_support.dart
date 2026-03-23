bool commanderSignalsSpellslinger(String commanderText) {
  return commanderText.contains('instant or sorcery') ||
      commanderText.contains('instant or sorcery spell') ||
      commanderText.contains('whenever you cast an instant') ||
      commanderText.contains('whenever you cast a sorcery');
}

bool commanderSignalsArtifacts(String commanderText) {
  return commanderText.contains('artifact');
}

bool commanderSignalsEnchantments(String commanderText) {
  return commanderText.contains('enchantment');
}

Map<String, dynamic> buildDeckRepairPlan({
  required String deckFormat,
  required int landCount,
  required int nonLandCount,
  required int instantSorceryCount,
  required int artifactCount,
  required int enchantmentCount,
  required Set<String> commanderColorIdentity,
  required String commanderText,
  required String manaAssessment,
}) {
  final targetLandCount = deckFormat == 'brawl' ? 25 : 36;
  final priorityRepairs = <String>[];
  final roleTargets = <String, int>{};

  if (landCount > targetLandCount) {
    priorityRepairs.add(
      'Cortar aproximadamente ${landCount - targetLandCount} terrenos excedentes antes de avaliar upgrades finos.',
    );
  }

  if (commanderColorIdentity.isNotEmpty &&
      manaAssessment.toLowerCase().contains('falta mana')) {
    priorityRepairs.add(
      'Trocar terrenos incolores por fontes ${commanderColorIdentity.join('/')} até estabilizar a base.',
    );
  }

  if (commanderSignalsSpellslinger(commanderText) && instantSorceryCount < 24) {
    roleTargets['instants_or_sorceries_to_add'] = 24 - instantSorceryCount;
    priorityRepairs.add(
      'Reconstruir o core de spells para alinhar o deck ao plano spellslinger do comandante.',
    );
  }

  if (commanderSignalsArtifacts(commanderText) && artifactCount < 12) {
    roleTargets['artifacts_to_add'] = 12 - artifactCount;
  }

  if (commanderSignalsEnchantments(commanderText) && enchantmentCount < 10) {
    roleTargets['enchantments_to_add'] = 10 - enchantmentCount;
  }

  if (nonLandCount < 30) {
    priorityRepairs.add(
      'Aumentar a densidade de mágicas úteis antes de tentar micro-otimizações.',
    );
  }

  return {
    'summary':
        'O deck precisa de reconstrução estrutural antes de trocas pontuais.',
    'target_land_count': targetLandCount,
    'priority_repairs': priorityRepairs,
    'role_targets': roleTargets,
    'preserve': const ['commander', 'cartas core realmente sinérgicas'],
  };
}

List<Map<String, dynamic>> buildOptimizeAdditionEntries({
  required List<String> requestedAdditions,
  required List<Map<String, dynamic>> additionsData,
}) {
  final requestedCountsByName = <String, int>{};
  for (final addition in requestedAdditions) {
    final normalized = addition.trim().toLowerCase();
    if (normalized.isEmpty) continue;
    requestedCountsByName[normalized] =
        (requestedCountsByName[normalized] ?? 0) + 1;
  }

  final canonicalByName = <String, Map<String, dynamic>>{};
  for (final card in additionsData) {
    final name = ((card['name'] as String?) ?? '').trim();
    if (name.isEmpty) continue;
    canonicalByName.putIfAbsent(
      name.toLowerCase(),
      () => Map<String, dynamic>.from(card),
    );
  }

  final entries = <Map<String, dynamic>>[];
  for (final entry in requestedCountsByName.entries) {
    final card = canonicalByName[entry.key];
    if (card == null) continue;
    entries.add({
      ...card,
      'quantity': entry.value,
    });
  }

  return entries;
}

List<Map<String, dynamic>> buildVirtualDeckForAnalysis({
  required List<Map<String, dynamic>> originalDeck,
  List<String> removals = const [],
  List<Map<String, dynamic>> additions = const [],
}) {
  final virtualDeck =
      originalDeck.map((card) => Map<String, dynamic>.from(card)).toList();

  final removalCountsByName = <String, int>{};
  for (final removal in removals) {
    final normalized = removal.trim().toLowerCase();
    if (normalized.isEmpty) continue;
    removalCountsByName[normalized] =
        (removalCountsByName[normalized] ?? 0) + 1;
  }

  for (final entry in removalCountsByName.entries) {
    final nameLower = entry.key;
    var toRemove = entry.value;

    for (var i = virtualDeck.length - 1; i >= 0 && toRemove > 0; i--) {
      final currentName =
          ((virtualDeck[i]['name'] as String?) ?? '').trim().toLowerCase();
      if (currentName != nameLower) continue;

      final quantity = (virtualDeck[i]['quantity'] as int?) ?? 1;
      if (quantity <= toRemove) {
        virtualDeck.removeAt(i);
        toRemove -= quantity;
      } else {
        virtualDeck[i] = {
          ...virtualDeck[i],
          'quantity': quantity - toRemove,
        };
        toRemove = 0;
      }
    }
  }

  for (final addition in additions) {
    final normalized =
        ((addition['name'] as String?) ?? '').trim().toLowerCase();
    if (normalized.isEmpty) continue;

    final incoming = Map<String, dynamic>.from(addition);
    final incomingQty = (incoming['quantity'] as int?) ?? 1;
    final existingIndex = virtualDeck.indexWhere(
      (card) =>
          ((card['name'] as String?) ?? '').trim().toLowerCase() == normalized,
    );

    if (existingIndex == -1) {
      virtualDeck.add({
        ...incoming,
        'quantity': incomingQty,
      });
      continue;
    }

    final existing = virtualDeck[existingIndex];
    final existingQty = (existing['quantity'] as int?) ?? 1;
    virtualDeck[existingIndex] = {
      ...existing,
      ...incoming,
      'quantity': existingQty + incomingQty,
    };
  }

  return virtualDeck;
}
