class DeckAnalysisData {
  const DeckAnalysisData({
    required this.deckId,
    required this.format,
    required this.composition,
    this.functionalTags,
    this.readiness,
    this.battleReadiness,
    this.cardBattleReadiness = const <DeckCardBattleReadiness>[],
    this.understandingSummary,
    this.commanderContract,
    this.launchCapabilities,
  });

  final String deckId;
  final String? format;
  final Map<String, int> composition;
  final DeckFunctionalTags? functionalTags;
  final DeckReadinessSummary? readiness;
  final DeckBattleReadinessSummary? battleReadiness;
  final List<DeckCardBattleReadiness> cardBattleReadiness;
  final DeckUnderstandingSummary? understandingSummary;
  final DeckCommanderContractSummary? commanderContract;
  final DeckLaunchCapabilities? launchCapabilities;

  factory DeckAnalysisData.fromJson(Map<String, dynamic> json) {
    final stats = _asStringMap(json['stats']);
    final composition = _parseIntMap(_asStringMap(stats['composition']));
    final functionalTagsPayload = _asStringMap(json['functional_tags']);
    final functionalTags = functionalTagsPayload.isEmpty
        ? null
        : DeckFunctionalTags.fromJson(functionalTagsPayload);
    final readinessPayload = _asStringMap(json['readiness']);
    final battleReadinessPayload = _asStringMap(json['battle_readiness']);
    final cardBattleReadiness = _parseMapList(
      json['card_battle_readiness'],
    ).map(DeckCardBattleReadiness.fromJson).toList(growable: false);
    final understandingPayload = _asStringMap(json['understanding_summary']);
    final commanderContractPayload = _asStringMap(json['commander_contract']);
    final launchCapabilitiesPayload = _asStringMap(json['launch_capabilities']);

    return DeckAnalysisData(
      deckId: json['deck_id']?.toString() ?? '',
      format: json['format']?.toString(),
      composition: composition,
      functionalTags: functionalTags,
      readiness: readinessPayload.isEmpty
          ? null
          : DeckReadinessSummary.fromJson(readinessPayload),
      battleReadiness: battleReadinessPayload.isEmpty
          ? null
          : DeckBattleReadinessSummary.fromJson(battleReadinessPayload),
      cardBattleReadiness: cardBattleReadiness,
      understandingSummary: understandingPayload.isEmpty
          ? null
          : DeckUnderstandingSummary.fromJson(understandingPayload),
      commanderContract: commanderContractPayload.isEmpty
          ? null
          : DeckCommanderContractSummary.fromJson(commanderContractPayload),
      launchCapabilities: launchCapabilitiesPayload.isEmpty
          ? null
          : DeckLaunchCapabilities.fromJson(launchCapabilitiesPayload),
    );
  }

  bool get hasFunctionalTags => functionalTags != null;

  bool get hasLaunchSignals =>
      readiness != null ||
      battleReadiness != null ||
      cardBattleReadiness.isNotEmpty ||
      understandingSummary != null ||
      (commanderContract?.shouldDisplay ?? false);

  bool get hasAnyCounts {
    if (composition.values.any((value) => value > 0)) return true;
    return functionalTags?.counts.values.any((value) => value > 0) ?? false;
  }

  int countFor({required String tagKey, required String compositionKey}) {
    final tags = functionalTags;
    if (tags != null && tags.counts.containsKey(tagKey)) {
      return tags.counts[tagKey] ?? 0;
    }
    return composition[compositionKey] ?? 0;
  }

  List<DeckFunctionalTagSample> samplesFor(String tagKey) {
    return functionalTags?.samples[tagKey] ?? const <DeckFunctionalTagSample>[];
  }

  String get sourceLabel {
    final tags = functionalTags;
    if (tags == null) {
      return 'stats.composition legado';
    }
    final version = tags.schemaVersion.trim();
    if (version.isEmpty) {
      return 'functional_tags do backend';
    }
    return 'functional_tags ($version)';
  }
}

class DeckLaunchCapabilities {
  const DeckLaunchCapabilities({
    required this.schemaVersion,
    required this.releaseChannel,
    required this.flags,
    required this.surfaces,
    this.disclaimer,
  });

  final String schemaVersion;
  final String releaseChannel;
  final Map<String, dynamic> flags;
  final List<DeckLaunchSurfaceCapability> surfaces;
  final String? disclaimer;

  factory DeckLaunchCapabilities.fromJson(Map<String, dynamic> json) {
    return DeckLaunchCapabilities(
      schemaVersion: json['schema_version']?.toString() ?? '',
      releaseChannel: json['release_channel']?.toString() ?? '',
      flags: _asStringMap(json['flags']),
      surfaces: _parseMapList(
        json['surfaces'],
      ).map(DeckLaunchSurfaceCapability.fromJson).toList(growable: false),
      disclaimer: _optionalTrimmedString(json['disclaimer']),
    );
  }

  Iterable<DeckLaunchSurfaceCapability> get visibleBetaSurfaces {
    return surfaces.where(
      (surface) =>
          surface.enabled &&
          surface.requiresReview &&
          (surface.stage == 'beta' || surface.stage == 'advisory'),
    );
  }
}

class DeckLaunchSurfaceCapability {
  const DeckLaunchSurfaceCapability({
    required this.key,
    required this.label,
    required this.enabled,
    required this.stage,
    required this.requiresReview,
  });

  final String key;
  final String label;
  final bool enabled;
  final String stage;
  final bool requiresReview;

  factory DeckLaunchSurfaceCapability.fromJson(Map<String, dynamic> json) {
    return DeckLaunchSurfaceCapability(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      enabled: _parseBool(json['enabled']),
      stage: json['stage']?.toString() ?? '',
      requiresReview: _parseBool(json['requires_review']),
    );
  }

  String get safeLabel {
    final text = label.trim();
    if (text.isNotEmpty) return text;
    return key.trim().isEmpty ? 'Capability' : key;
  }
}

class DeckCardBattleReadiness {
  const DeckCardBattleReadiness({
    required this.schemaVersion,
    required this.cardId,
    required this.name,
    required this.quantity,
    required this.isCommander,
    required this.status,
    required this.statusLabel,
    required this.battleRuleCount,
    required this.verifiedBattleRuleCount,
    required this.sourceCoverage,
    required this.detail,
    this.disclaimer,
  });

  final String schemaVersion;
  final String cardId;
  final String name;
  final int quantity;
  final bool isCommander;
  final String status;
  final String statusLabel;
  final int battleRuleCount;
  final int verifiedBattleRuleCount;
  final Map<String, dynamic> sourceCoverage;
  final String detail;
  final String? disclaimer;

  factory DeckCardBattleReadiness.fromJson(Map<String, dynamic> json) {
    return DeckCardBattleReadiness(
      schemaVersion: json['schema_version']?.toString() ?? '',
      cardId: json['card_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: _parseInt(json['quantity']),
      isCommander: _parseBool(json['is_commander']),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      battleRuleCount: _parseInt(json['battle_rule_count']),
      verifiedBattleRuleCount: _parseInt(json['verified_battle_rule_count']),
      sourceCoverage: _asStringMap(json['source_coverage']),
      detail: json['detail']?.toString() ?? '',
      disclaimer: _optionalTrimmedString(json['disclaimer']),
    );
  }

  String get safeStatusLabel {
    final label = statusLabel.trim();
    if (label.isNotEmpty) return label;
    return status.trim().isEmpty ? 'Sem leitura' : status;
  }
}

class DeckCommanderContractSummary {
  const DeckCommanderContractSummary({
    required this.schemaVersion,
    required this.sourceVersion,
    required this.status,
    required this.statusLabel,
    required this.isCommanderApplicable,
    required this.commanderName,
    required this.totalCards,
    required this.commanderCount,
    required this.summary,
    required this.battleGate,
    this.baselinePolicy,
    required this.gates,
    required this.sourceLanes,
    required this.provenanceLanes,
    required this.planningCoverage,
    required this.planningFlow,
    required this.overviewFields,
    required this.blockers,
    required this.warnings,
    required this.nextActions,
    this.disclaimer,
  });

  final String schemaVersion;
  final String sourceVersion;
  final String status;
  final String statusLabel;
  final bool isCommanderApplicable;
  final String commanderName;
  final int totalCards;
  final int commanderCount;
  final String summary;
  final DeckCommanderBattleGate battleGate;
  final DeckCommanderBaselinePolicy? baselinePolicy;
  final DeckCommanderGateFlags gates;
  final List<DeckCommanderSourceLane> sourceLanes;
  final List<DeckCommanderProvenanceLane> provenanceLanes;
  final DeckCommanderPlanningCoverage planningCoverage;
  final List<DeckCommanderLabelItem> planningFlow;
  final List<DeckCommanderLabelItem> overviewFields;
  final List<String> blockers;
  final List<String> warnings;
  final List<String> nextActions;
  final String? disclaimer;

  factory DeckCommanderContractSummary.fromJson(Map<String, dynamic> json) {
    return DeckCommanderContractSummary(
      schemaVersion: json['schema_version']?.toString() ?? '',
      sourceVersion: json['source_version']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      isCommanderApplicable: _parseBool(json['is_commander_applicable']),
      commanderName: json['commander_name']?.toString() ?? '',
      totalCards: _parseInt(json['total_cards']),
      commanderCount: _parseInt(json['commander_count']),
      summary: json['summary']?.toString() ?? '',
      battleGate: DeckCommanderBattleGate.fromJson(
        _asStringMap(json['battle_gate']),
      ),
      baselinePolicy: _asStringMap(json['baseline_policy']).isEmpty
          ? null
          : DeckCommanderBaselinePolicy.fromJson(
              _asStringMap(json['baseline_policy']),
            ),
      gates: DeckCommanderGateFlags.fromJson(_asStringMap(json['gates'])),
      sourceLanes: _parseMapList(
        json['source_lanes'],
      ).map(DeckCommanderSourceLane.fromJson).toList(growable: false),
      provenanceLanes: _parseMapList(
        _asStringMap(json['provenance'])['lanes'],
      ).map(DeckCommanderProvenanceLane.fromJson).toList(growable: false),
      planningCoverage: DeckCommanderPlanningCoverage.fromJson(
        _asStringMap(json['planning_coverage']),
      ),
      planningFlow: _parseMapList(
        json['planning_flow'],
      ).map(DeckCommanderLabelItem.fromJson).toList(growable: false),
      overviewFields: _parseMapList(
        json['overview_fields'],
      ).map(DeckCommanderLabelItem.fromJson).toList(growable: false),
      blockers: _parseStringList(json['blockers']),
      warnings: _parseStringList(json['warnings']),
      nextActions: _parseStringList(json['next_actions']),
      disclaimer: _optionalTrimmedString(json['disclaimer']),
    );
  }

  bool get shouldDisplay => isCommanderApplicable;

  bool get hasBlockers =>
      status == 'blocked' ||
      blockers.isNotEmpty ||
      baselinePolicy?.status == 'experimental_blocked';

  String get safeStatusLabel {
    final baselineLabel = baselinePolicy?.label.trim() ?? '';
    if (baselineLabel.isNotEmpty) return baselineLabel;
    final label = statusLabel.trim();
    if (label.isNotEmpty) return label;
    return status.trim().isEmpty ? 'Sem leitura' : status;
  }

  String get primaryDetail {
    final baselineDetail = baselinePolicy?.detail.trim() ?? '';
    if (baselineDetail.isNotEmpty) return baselineDetail;
    final text = summary.trim();
    if (text.isNotEmpty) return text;
    if (nextActions.isNotEmpty) return nextActions.first;
    return 'Contrato Commander sem detalhes adicionais.';
  }

  String? get footerLabel {
    final gate = battleGate.label.trim();
    if (gate.isNotEmpty && gate != 'Sem leitura') return 'Battle gate: $gate';
    if (sourceLanes.isEmpty) return null;
    final available = sourceLanes.where((lane) => lane.available).length;
    return '$available/${sourceLanes.length} fontes ativas';
  }
}

class DeckCommanderBaselinePolicy {
  const DeckCommanderBaselinePolicy({
    required this.applies,
    required this.baselineDeckId,
    required this.status,
    required this.label,
    required this.detail,
    required this.candidateDecision,
    required this.seedPairingClaim,
    required this.definitiveClaimAllowed,
    required this.automaticCandidateApplyAllowed,
    required this.nextGate,
  });

  final bool applies;
  final String baselineDeckId;
  final String status;
  final String label;
  final String detail;
  final String candidateDecision;
  final bool seedPairingClaim;
  final bool definitiveClaimAllowed;
  final bool automaticCandidateApplyAllowed;
  final String nextGate;

  factory DeckCommanderBaselinePolicy.fromJson(Map<String, dynamic> json) {
    return DeckCommanderBaselinePolicy(
      applies: _parseBool(json['applies']),
      baselineDeckId: json['baseline_deck_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      candidateDecision: json['candidate_decision']?.toString() ?? '',
      seedPairingClaim: _parseBool(json['seed_pairing_claim']),
      definitiveClaimAllowed: _parseBool(json['definitive_claim_allowed']),
      automaticCandidateApplyAllowed: _parseBool(
        json['automatic_candidate_apply_allowed'],
      ),
      nextGate: json['next_gate']?.toString() ?? '',
    );
  }
}

class DeckCommanderBattleGate {
  const DeckCommanderBattleGate({
    required this.required,
    required this.status,
    required this.label,
  });

  final bool required;
  final String status;
  final String label;

  factory DeckCommanderBattleGate.fromJson(Map<String, dynamic> json) {
    return DeckCommanderBattleGate(
      required: _parseBool(json['required']),
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class DeckCommanderGateFlags {
  const DeckCommanderGateFlags({
    required this.commanderPresent,
    required this.validationValid,
    required this.unresolvedCardsZero,
    required this.hasReferenceLane,
    required this.deterministicReferenceReady,
  });

  final bool commanderPresent;
  final bool validationValid;
  final bool unresolvedCardsZero;
  final bool hasReferenceLane;
  final bool deterministicReferenceReady;

  factory DeckCommanderGateFlags.fromJson(Map<String, dynamic> json) {
    return DeckCommanderGateFlags(
      commanderPresent: _parseBool(json['commander_present']),
      validationValid: _parseBool(json['validation_valid']),
      unresolvedCardsZero: _parseBool(json['unresolved_cards_zero']),
      hasReferenceLane: _parseBool(json['has_reference_lane']),
      deterministicReferenceReady: _parseBool(
        json['deterministic_reference_ready'],
      ),
    );
  }
}

class DeckCommanderSourceLane {
  const DeckCommanderSourceLane({
    required this.key,
    required this.label,
    required this.available,
    required this.count,
    this.detail,
  });

  final String key;
  final String label;
  final bool available;
  final int count;
  final String? detail;

  factory DeckCommanderSourceLane.fromJson(Map<String, dynamic> json) {
    return DeckCommanderSourceLane(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      available: _parseBool(json['available']),
      count: _parseInt(json['count']),
      detail: _optionalTrimmedString(json['detail']),
    );
  }
}

class DeckCommanderProvenanceLane {
  const DeckCommanderProvenanceLane({
    required this.key,
    required this.label,
    required this.available,
    required this.confidence,
  });

  final String key;
  final String label;
  final bool available;
  final String confidence;

  factory DeckCommanderProvenanceLane.fromJson(Map<String, dynamic> json) {
    return DeckCommanderProvenanceLane(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      available: _parseBool(json['available']),
      confidence: json['confidence']?.toString() ?? '',
    );
  }

  String get safeLabel {
    final text = label.trim();
    return text.isEmpty ? 'Fonte da decisão' : text;
  }

  String get confidenceLabel {
    if (!available) return 'Não disponível';
    return switch (confidence.trim().toLowerCase()) {
      'source_backed' => 'Fonte verificada',
      'aggregate_only' => 'Dado agregado',
      'advisory_aggregate' => 'Referência agregada',
      'observed_usage' => 'Uso observado',
      'reviewed_snapshot' => 'Lista revisada',
      'advisory_only' => 'Sugestão consultiva',
      'natural_exposure_only' => 'Exposição natural',
      'comparison_input_only' => 'Entrada de comparação',
      _ => 'Disponível',
    };
  }
}

class DeckCommanderPlanningCoverage {
  const DeckCommanderPlanningCoverage({
    required this.requiredCount,
    required this.readyCount,
    required this.partialCount,
    required this.pendingCount,
    required this.items,
  });

  final int requiredCount;
  final int readyCount;
  final int partialCount;
  final int pendingCount;
  final List<DeckCommanderPlanningCoverageItem> items;

  factory DeckCommanderPlanningCoverage.fromJson(Map<String, dynamic> json) {
    return DeckCommanderPlanningCoverage(
      requiredCount: _parseInt(json['required_count']),
      readyCount: _parseInt(json['ready_count']),
      partialCount: _parseInt(json['partial_count']),
      pendingCount: _parseInt(json['pending_count']),
      items: _parseMapList(
        json['items'],
      ).map(DeckCommanderPlanningCoverageItem.fromJson).toList(growable: false),
    );
  }
}

class DeckCommanderPlanningCoverageItem {
  const DeckCommanderPlanningCoverageItem({
    required this.key,
    required this.label,
    required this.status,
  });

  final String key;
  final String label;
  final String status;

  factory DeckCommanderPlanningCoverageItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeckCommanderPlanningCoverageItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class DeckCommanderLabelItem {
  const DeckCommanderLabelItem({required this.key, required this.label});

  final String key;
  final String label;

  factory DeckCommanderLabelItem.fromJson(Map<String, dynamic> json) {
    return DeckCommanderLabelItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class DeckReadinessSummary {
  const DeckReadinessSummary({
    required this.schemaVersion,
    required this.status,
    required this.isCommander,
    required this.commanderCount,
    required this.totalCards,
    required this.errorCount,
    required this.warningCount,
    required this.blockers,
    required this.nextActions,
    required this.advancedIntelligenceEnabled,
  });

  final String schemaVersion;
  final String status;
  final bool isCommander;
  final int commanderCount;
  final int totalCards;
  final int errorCount;
  final int warningCount;
  final List<String> blockers;
  final List<String> nextActions;
  final bool advancedIntelligenceEnabled;

  factory DeckReadinessSummary.fromJson(Map<String, dynamic> json) {
    return DeckReadinessSummary(
      schemaVersion: json['schema_version']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isCommander: _parseBool(json['is_commander']),
      commanderCount: _parseInt(json['commander_count']),
      totalCards: _parseInt(json['total_cards']),
      errorCount: _parseInt(json['error_count']),
      warningCount: _parseInt(json['warning_count']),
      blockers: _parseStringList(json['blockers']),
      nextActions: _parseStringList(json['next_actions']),
      advancedIntelligenceEnabled: _parseBool(
        json['advanced_intelligence_enabled'],
      ),
    );
  }

  bool get hasBlockers => blockers.isNotEmpty || errorCount > 0;

  String get statusLabel {
    switch (status) {
      case 'needs_commander':
        return 'Comandante pendente';
      case 'incomplete_deck':
        return 'Lista incompleta';
      case 'too_many_cards':
        return 'Cartas demais';
      case 'legality_or_structure_errors':
        return 'Corrigir lista';
      case 'ready_with_warnings':
        return 'Pronto com avisos';
      case 'valid_commander_deck':
        return 'Commander válido';
      case 'valid_deck':
        return 'Deck válido';
      default:
        return status.trim().isEmpty ? 'Sem leitura' : status;
    }
  }

  String get primaryAction {
    if (nextActions.isNotEmpty) return nextActions.first;
    if (hasBlockers) return 'Resolver bloqueios antes de avançar.';
    if (warningCount > 0) return 'Revisar avisos antes da simulação.';
    return 'Inteligência avançada liberada.';
  }
}

class DeckBattleReadinessSummary {
  const DeckBattleReadinessSummary({
    required this.schemaVersion,
    required this.status,
    required this.totalCopies,
    required this.verifiedSimulationCopies,
    required this.partialSimulationCopies,
    required this.pendingAdapterCopies,
    required this.rulesTextOnlyCopies,
    required this.verifiedRatio,
    required this.samples,
    this.disclaimer,
  });

  final String schemaVersion;
  final String status;
  final int totalCopies;
  final int verifiedSimulationCopies;
  final int partialSimulationCopies;
  final int pendingAdapterCopies;
  final int rulesTextOnlyCopies;
  final double verifiedRatio;
  final Map<String, List<String>> samples;
  final String? disclaimer;

  factory DeckBattleReadinessSummary.fromJson(Map<String, dynamic> json) {
    return DeckBattleReadinessSummary(
      schemaVersion: json['schema_version']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalCopies: _parseInt(json['total_copies']),
      verifiedSimulationCopies: _parseInt(json['verified_simulation_copies']),
      partialSimulationCopies: _parseInt(json['partial_simulation_copies']),
      pendingAdapterCopies: _parseInt(json['pending_adapter_copies']),
      rulesTextOnlyCopies: _parseInt(json['rules_text_only_copies']),
      verifiedRatio: _parseDouble(json['verified_ratio']),
      samples: _parseStringListMap(_asStringMap(json['samples'])),
      disclaimer: _optionalTrimmedString(json['disclaimer']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'verified_simulation':
        return 'Simulação verificada';
      case 'partial_simulation':
        return 'Simulação parcial';
      case 'pending_adapter':
        return 'Adaptador pendente';
      case 'rules_text_only':
        return 'Texto de regra';
      case 'not_available':
        return 'Sem leitura';
      default:
        return status.trim().isEmpty ? 'Sem leitura' : status;
    }
  }

  String get verifiedPercentLabel {
    final percent = (verifiedRatio * 100).clamp(0, 100).round();
    return '$percent% verificado';
  }
}

class DeckUnderstandingSummary {
  const DeckUnderstandingSummary({
    required this.schemaVersion,
    required this.source,
    required this.totalCopies,
    required this.functionalTaggedCopies,
    required this.semanticTaggedCopies,
    required this.verifiedBattleRuleCopies,
    required this.functionalCoverageRatio,
    required this.verifiedBattleRatio,
  });

  final String schemaVersion;
  final String source;
  final int totalCopies;
  final int functionalTaggedCopies;
  final int semanticTaggedCopies;
  final int verifiedBattleRuleCopies;
  final double functionalCoverageRatio;
  final double verifiedBattleRatio;

  factory DeckUnderstandingSummary.fromJson(Map<String, dynamic> json) {
    return DeckUnderstandingSummary(
      schemaVersion: json['schema_version']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      totalCopies: _parseInt(json['total_copies']),
      functionalTaggedCopies: _parseInt(json['functional_tagged_copies']),
      semanticTaggedCopies: _parseInt(json['semantic_tagged_copies']),
      verifiedBattleRuleCopies: _parseInt(json['verified_battle_rule_copies']),
      functionalCoverageRatio: _parseDouble(json['functional_coverage_ratio']),
      verifiedBattleRatio: _parseDouble(json['verified_battle_ratio']),
    );
  }

  String get functionalCoverageLabel {
    final percent = (functionalCoverageRatio * 100).clamp(0, 100).round();
    return '$percent% classificado';
  }

  String get verifiedBattleLabel {
    final percent = (verifiedBattleRatio * 100).clamp(0, 100).round();
    return '$percent% simulado';
  }
}

class DeckFunctionalTags {
  const DeckFunctionalTags({
    required this.schemaVersion,
    this.semanticSchemaVersion,
    this.source,
    required this.counts,
    required this.samples,
    required this.coverage,
  });

  final String schemaVersion;
  final String? semanticSchemaVersion;
  final DeckFunctionalTagsSource? source;
  final Map<String, int> counts;
  final Map<String, List<DeckFunctionalTagSample>> samples;
  final DeckFunctionalTagsCoverage coverage;

  factory DeckFunctionalTags.fromJson(Map<String, dynamic> json) {
    final rawSamples = _asStringMap(json['samples']);
    final rawSampleDetails = _asStringMap(json['sample_details']);
    final parsedSamples = <String, List<DeckFunctionalTagSample>>{};
    for (final entry in rawSamples.entries) {
      final rawList = entry.value;
      if (rawList is! List) continue;
      final samples = rawList
          .map(DeckFunctionalTagSample.fromDynamic)
          .whereType<DeckFunctionalTagSample>()
          .toList(growable: false);
      parsedSamples[entry.key] = samples;
    }
    for (final entry in rawSampleDetails.entries) {
      final rawList = entry.value;
      if (rawList is! List) continue;
      final samples = rawList
          .map(DeckFunctionalTagSample.fromDynamic)
          .whereType<DeckFunctionalTagSample>()
          .toList(growable: false);
      if (samples.isEmpty) continue;
      parsedSamples[entry.key] = samples;
    }

    return DeckFunctionalTags(
      schemaVersion: json['schema_version']?.toString() ?? '',
      semanticSchemaVersion: _optionalTrimmedString(
        json['semantic_schema_version'],
      ),
      source: DeckFunctionalTagsSource.fromJson(_asStringMap(json['source'])),
      counts: _parseIntMap(_asStringMap(json['counts'])),
      samples: Map.unmodifiable(parsedSamples),
      coverage: DeckFunctionalTagsCoverage.fromJson(
        _asStringMap(json['coverage']),
      ),
    );
  }
}

class DeckFunctionalTagsSource {
  const DeckFunctionalTagsSource({
    required this.priority,
    required this.persistedRows,
    required this.persistedCopies,
    required this.heuristicRows,
    required this.heuristicCopies,
  });

  final String? priority;
  final int persistedRows;
  final int persistedCopies;
  final int heuristicRows;
  final int heuristicCopies;

  factory DeckFunctionalTagsSource.fromJson(Map<String, dynamic> json) {
    return DeckFunctionalTagsSource(
      priority: _optionalTrimmedString(json['priority']),
      persistedRows: _parseInt(json['persisted_rows']),
      persistedCopies: _parseInt(json['persisted_copies']),
      heuristicRows: _parseInt(json['heuristic_rows']),
      heuristicCopies: _parseInt(json['heuristic_copies']),
    );
  }

  bool get hasAnySignal =>
      persistedRows > 0 ||
      persistedCopies > 0 ||
      heuristicRows > 0 ||
      heuristicCopies > 0 ||
      (priority ?? '').isNotEmpty;

  String get summary {
    if (!hasAnySignal) return 'Origem não informada';
    final parts = <String>[
      if ((priority ?? '').isNotEmpty) 'prioridade $priority',
      if (persistedCopies > 0) '$persistedCopies persistidas',
      if (heuristicCopies > 0) '$heuristicCopies heurísticas',
    ];
    if (parts.isEmpty && persistedRows > 0) {
      parts.add('$persistedRows linhas persistidas');
    }
    if (parts.isEmpty && heuristicRows > 0) {
      parts.add('$heuristicRows linhas heurísticas');
    }
    return parts.join(' • ');
  }
}

class DeckFunctionalTagSample {
  const DeckFunctionalTagSample({
    required this.name,
    this.tag,
    this.reason,
    this.evidence,
    this.role,
    this.confidence,
    this.semanticSchemaVersion,
    this.speed,
    this.manaEfficiency,
    this.cardAdvantageType,
    this.interactionScope,
    this.protectionType,
    this.recursionType,
  });

  final String name;
  final String? tag;
  final String? reason;
  final String? evidence;
  final String? role;
  final double? confidence;
  final String? semanticSchemaVersion;
  final String? speed;
  final String? manaEfficiency;
  final String? cardAdvantageType;
  final String? interactionScope;
  final String? protectionType;
  final String? recursionType;

  static DeckFunctionalTagSample? fromDynamic(dynamic value) {
    if (value is String) {
      final name = value.trim();
      if (name.isEmpty) return null;
      return DeckFunctionalTagSample(name: name);
    }

    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      final rawName =
          map['name'] ??
          map['card_name'] ??
          map['card'] ??
          map['title'] ??
          map['label'];
      final name = rawName?.toString().trim();
      if (name == null || name.isEmpty) return null;
      return DeckFunctionalTagSample(
        name: name,
        tag: _optionalTrimmedString(map['tag']),
        reason: _optionalTrimmedString(map['reason'] ?? map['evidence']),
        evidence: _optionalTrimmedString(map['evidence']),
        role: _optionalTrimmedString(map['role'] ?? map['function']),
        confidence: _optionalDouble(map['confidence']),
        semanticSchemaVersion: _optionalTrimmedString(
          map['semantic_schema_version'],
        ),
        speed: _optionalTrimmedString(map['speed']),
        manaEfficiency: _optionalTrimmedString(map['mana_efficiency']),
        cardAdvantageType: _optionalTrimmedString(map['card_advantage_type']),
        interactionScope: _optionalTrimmedString(map['interaction_scope']),
        protectionType: _optionalTrimmedString(map['protection_type']),
        recursionType: _optionalTrimmedString(map['recursion_type']),
      );
    }

    return null;
  }
}

class DeckFunctionalTagsCoverage {
  const DeckFunctionalTagsCoverage({
    required this.cardRows,
    required this.cardCopies,
    required this.taggedRows,
    required this.taggedCopies,
    required this.otherRows,
    required this.otherCopies,
  });

  final int cardRows;
  final int cardCopies;
  final int taggedRows;
  final int taggedCopies;
  final int otherRows;
  final int otherCopies;

  factory DeckFunctionalTagsCoverage.fromJson(Map<String, dynamic> json) {
    return DeckFunctionalTagsCoverage(
      cardRows: _parseInt(json['card_rows']),
      cardCopies: _parseInt(json['card_copies']),
      taggedRows: _parseInt(json['tagged_rows']),
      taggedCopies: _parseInt(json['tagged_copies']),
      otherRows: _parseInt(json['other_rows']),
      otherCopies: _parseInt(json['other_copies']),
    );
  }

  bool get hasCards => cardRows > 0 || cardCopies > 0;

  double? get taggedCopyRatio {
    if (cardCopies <= 0) return null;
    return taggedCopies / cardCopies;
  }

  String get summary {
    if (cardCopies > 0) {
      return '$taggedCopies/$cardCopies cópias classificadas';
    }
    if (cardRows > 0) {
      return '$taggedRows/$cardRows cartas classificadas';
    }
    return 'Cobertura não informada';
  }
}

Map<String, dynamic> _asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

Map<String, int> _parseIntMap(Map<String, dynamic> map) {
  final parsed = <String, int>{};
  for (final entry in map.entries) {
    parsed[entry.key] = _parseInt(entry.value);
  }
  return Map.unmodifiable(parsed);
}

Map<String, List<String>> _parseStringListMap(Map<String, dynamic> map) {
  final parsed = <String, List<String>>{};
  for (final entry in map.entries) {
    parsed[entry.key] = _parseStringList(entry.value);
  }
  return Map.unmodifiable(parsed);
}

List<Map<String, dynamic>> _parseMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim())
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

String? _optionalTrimmedString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

double? _optionalDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
