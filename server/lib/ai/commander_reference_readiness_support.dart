import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../generated_deck_validation_service.dart';
import 'commander_reference_card_stats_support.dart';
import 'commander_reference_deck_corpus_support.dart';
import 'commander_reference_generate_fallback_support.dart';
import 'commander_reference_profile_support.dart';

const commanderReferenceReadinessVersion =
    'commander_reference_readiness_v2_2026-05-13';

class CommanderReferenceReadinessRuntimeProof {
  const CommanderReferenceReadinessRuntimeProof({
    required this.available,
    required this.status,
    this.backendSha,
    this.withCommander,
  });

  final bool available;
  final String status;
  final String? backendSha;
  final Map<String, dynamic>? withCommander;

  bool get gatePassed {
    final mode = withCommander;
    if (!available || mode == null) return false;
    final commanderPreserved = mode.containsKey('commander_preserved')
        ? _intValue(mode['commander_preserved'])
        : _intValue(mode['lorehold_commander']);
    final mainQuantityOk = mode.containsKey('main_quantity_99')
        ? _intValue(mode['main_quantity_99'])
        : 5;
    final fallbackCount = mode.containsKey('fallback_count')
        ? _intValue(mode['fallback_count'])
        : _intValue(mode['fallback']);
    final timeoutFallbackCount = mode.containsKey('timeout_fallback_count')
        ? _intValue(mode['timeout_fallback_count'])
        : _intValue(mode['timeout_fallback']);
    final deterministicReferencePathOk = fallbackCount >= 5 &&
        timeoutFallbackCount == 0 &&
        _intValue(mode['profile_used']) >= 5 &&
        _intValue(mode['stats_used']) >= 5 &&
        _intValue(mode['corpus_used']) >= 5 &&
        _intValue(mode['invalid_cards_total']) == 0 &&
        _intValue(mode['off_identity_total']) == 0 &&
        (_intValue(mode['p95_ms']) == 0 || _intValue(mode['p95_ms']) <= 5000);
    return _intValue(mode['http_200']) >= 5 &&
        _intValue(mode['validation_ok']) >= 5 &&
        commanderPreserved >= 5 &&
        mainQuantityOk >= 5 &&
        _intValue(mode['corpus_used']) >= 5 &&
        timeoutFallbackCount == 0 &&
        (fallbackCount == 0 || deterministicReferencePathOk);
  }

  Map<String, dynamic> toJson() => {
        'available': available,
        'status': status,
        if (backendSha != null) 'backend_sha': backendSha,
        if (withCommander != null) 'with_commander': withCommander,
        'gate_passed': gatePassed,
      };
}

class CommanderReferenceReadinessInputs {
  const CommanderReferenceReadinessInputs({
    required this.commanderName,
    required this.commanderCardResolved,
    required this.profileAvailable,
    required this.profileConfidence,
    required this.profileSourceCount,
    required this.profileThemeCount,
    required this.profileExpectedPackageCount,
    required this.cardStatsCount,
    required this.cardStatsUnresolvedCount,
    required this.cardStatsPackageCount,
    required this.corpusAvailable,
    required this.corpusAcceptedDeckCount,
    required this.corpusCorePackageCount,
    required this.corpusThemePackageCount,
    required this.corpusSupportPackageCount,
    required this.deterministicDeckValid,
    required this.deterministicMainQuantity,
    required this.deterministicWarnings,
    this.runtimeProof,
  });

  final String commanderName;
  final bool commanderCardResolved;
  final bool profileAvailable;
  final String profileConfidence;
  final int profileSourceCount;
  final int profileThemeCount;
  final int profileExpectedPackageCount;
  final int cardStatsCount;
  final int cardStatsUnresolvedCount;
  final int cardStatsPackageCount;
  final bool corpusAvailable;
  final int corpusAcceptedDeckCount;
  final int corpusCorePackageCount;
  final int corpusThemePackageCount;
  final int corpusSupportPackageCount;
  final bool deterministicDeckValid;
  final int deterministicMainQuantity;
  final List<String> deterministicWarnings;
  final CommanderReferenceReadinessRuntimeProof? runtimeProof;

  Map<String, dynamic> toJson() => {
        'commander_name': commanderName,
        'commander_card_resolved': commanderCardResolved,
        'profile_available': profileAvailable,
        'profile_confidence': profileConfidence,
        'profile_source_count': profileSourceCount,
        'profile_theme_count': profileThemeCount,
        'profile_expected_package_count': profileExpectedPackageCount,
        'card_stats_count': cardStatsCount,
        'card_stats_unresolved_count': cardStatsUnresolvedCount,
        'card_stats_package_count': cardStatsPackageCount,
        'corpus_available': corpusAvailable,
        'corpus_accepted_deck_count': corpusAcceptedDeckCount,
        'corpus_core_package_count': corpusCorePackageCount,
        'corpus_theme_package_count': corpusThemePackageCount,
        'corpus_support_package_count': corpusSupportPackageCount,
        'deterministic_deck_valid': deterministicDeckValid,
        'deterministic_main_quantity': deterministicMainQuantity,
        'deterministic_warnings': deterministicWarnings,
        if (runtimeProof != null) 'runtime_proof': runtimeProof!.toJson(),
      };
}

class CommanderReferenceReadinessScorecard {
  const CommanderReferenceReadinessScorecard({
    required this.version,
    required this.commanderName,
    required this.score,
    required this.status,
    required this.gates,
    required this.blockers,
    required this.warnings,
    required this.nextActions,
    required this.inputs,
    required this.cacheKey,
  });

  final String version;
  final String commanderName;
  final int score;
  final String status;
  final Map<String, dynamic> gates;
  final List<String> blockers;
  final List<String> warnings;
  final List<String> nextActions;
  final CommanderReferenceReadinessInputs inputs;
  final String cacheKey;

  bool get expansionReady => status == 'ready_for_mini_batch';

  Map<String, dynamic> toJson() => {
        'version': version,
        'commander_name': commanderName,
        'score': score,
        'status': status,
        'expansion_ready': expansionReady,
        'gates': gates,
        'blockers': blockers,
        'warnings': warnings,
        'next_actions': nextActions,
        'inputs': inputs.toJson(),
        'cache_key': cacheKey,
      };
}

CommanderReferenceReadinessScorecard
    calculateCommanderReferenceReadinessScorecard(
  CommanderReferenceReadinessInputs inputs,
) {
  final gates = <String, dynamic>{
    'commander_card_resolved': inputs.commanderCardResolved,
    'profile_available': inputs.profileAvailable,
    'profile_confidence_usable':
        isReferenceProfileConfidenceUsable(inputs.profileConfidence),
    'profile_has_sources': inputs.profileSourceCount > 0,
    'profile_has_themes': inputs.profileThemeCount > 0,
    'profile_has_expected_packages': inputs.profileExpectedPackageCount > 0,
    'card_stats_available': inputs.cardStatsCount > 0,
    'card_stats_unresolved_zero': inputs.cardStatsUnresolvedCount == 0,
    'card_stats_packages_available': inputs.cardStatsPackageCount > 0,
    'corpus_available': inputs.corpusAvailable,
    'corpus_minimum_accepted_decks': inputs.corpusAcceptedDeckCount >= 3,
    'corpus_core_package_strong': inputs.corpusCorePackageCount >= 20,
    'deterministic_deck_valid': inputs.deterministicDeckValid,
    'deterministic_main_quantity_ok': inputs.deterministicMainQuantity == 99,
    'runtime_public_gate_passed': inputs.runtimeProof?.gatePassed == true,
  };

  final blockers = <String>[];
  final warnings = <String>[];
  final nextActions = <String>[];

  void block(String message, String action) {
    blockers.add(message);
    nextActions.add(action);
  }

  if (!inputs.commanderCardResolved) {
    block(
      'commander_card_not_resolved',
      'Resolver a carta do comandante em cards antes de habilitar runtime.',
    );
  }
  if (!inputs.profileAvailable) {
    block(
      'profile_missing_or_below_confidence',
      'Criar/aplicar Commander Reference Profile com confidence >= medium.',
    );
  }
  if (inputs.profileAvailable &&
      !isReferenceProfileConfidenceUsable(inputs.profileConfidence)) {
    block(
      'profile_confidence_not_usable',
      'Elevar ou revisar confidence do profile antes de usar em generate.',
    );
  }
  if (inputs.cardStatsCount == 0) {
    block(
      'card_stats_missing',
      'Aplicar commander_reference_card_stats resolvidos para o comandante.',
    );
  }
  if (inputs.cardStatsUnresolvedCount > 0) {
    block(
      'card_stats_unresolved_present',
      'Resolver/remover card_stats unresolved antes de runtime.',
    );
  }
  if (!inputs.deterministicDeckValid) {
    block(
      'deterministic_reference_deck_invalid',
      'Corrigir fallback deterministico commander-aware antes de liberar.',
    );
  }
  if (inputs.deterministicMainQuantity != 99) {
    block(
      'deterministic_main_quantity_not_99',
      'Garantir fallback deterministic com 99 cartas no main.',
    );
  }

  if (!inputs.corpusAvailable) {
    warnings.add('corpus_missing');
    nextActions.add(
      'Coletar/aplicar corpus aceito antes de habilitar caminho deterministico forte.',
    );
  } else if (inputs.corpusAcceptedDeckCount < 3) {
    warnings.add('corpus_low_evidence_count');
    nextActions.add('Elevar corpus aceito para pelo menos 3 decks.');
  }
  if (inputs.corpusCorePackageCount < 20) {
    warnings.add('core_package_weak');
    nextActions.add('Revisar corpus/core_package antes de mini-batch.');
  }
  if (inputs.runtimeProof == null || !inputs.runtimeProof!.available) {
    warnings.add('public_runtime_proof_missing');
    nextActions.add('Executar prova publica 5x com commander_name.');
  } else if (!inputs.runtimeProof!.gatePassed) {
    warnings.add('public_runtime_gate_not_passed');
    nextActions
        .add('Repetir proof ate fallback/off-color/commander gates passarem.');
  }
  if (inputs.deterministicWarnings.isNotEmpty) {
    warnings.addAll(
      inputs.deterministicWarnings.map((warning) => 'deterministic:$warning'),
    );
  }

  final score = _scoreReadiness(inputs, gates).clamp(0, 100);
  final status = blockers.isNotEmpty
      ? 'blocked'
      : score >= 85 && warnings.where(_isExpansionBlockingWarning).isEmpty
          ? 'ready_for_mini_batch'
          : score >= 70
              ? 'profile_ready_needs_proof'
              : 'needs_data';

  final cacheKey = sha256
      .convert(utf8.encode(jsonEncode({
        'version': commanderReferenceReadinessVersion,
        'commander': normalizeCommanderReferenceName(inputs.commanderName),
        'inputs': inputs.toJson(),
      })))
      .toString()
      .substring(0, 16);

  return CommanderReferenceReadinessScorecard(
    version: commanderReferenceReadinessVersion,
    commanderName: inputs.commanderName,
    score: score,
    status: status,
    gates: gates,
    blockers: blockers,
    warnings: warnings.toSet().toList(growable: false)..sort(),
    nextActions: nextActions.toSet().toList(growable: false)..sort(),
    inputs: inputs,
    cacheKey: 'commander_reference_readiness:$cacheKey',
  );
}

Future<CommanderReferenceReadinessScorecard>
    buildCommanderReferenceReadinessScorecard({
  required Pool pool,
  required String commanderName,
  CommanderReferenceReadinessRuntimeProof? runtimeProof,
}) async {
  final profile = await loadUsableCommanderReferenceProfile(
    pool: pool,
    commanderName: commanderName,
  );
  final statsLoad = await loadUsableCommanderReferenceCardStats(
    pool: pool,
    commanderName: commanderName,
  );
  final corpus = await loadCommanderReferenceDeckCorpusGuidance(
    pool: pool,
    commanderName: commanderName,
  );

  var commanderResolved = false;
  var deterministicValid = false;
  var deterministicMainQuantity = 0;
  final deterministicWarnings = <String>[];

  if (profile != null) {
    final commanderResolution = await resolveCommanderReferenceCommanderCard(
      pool,
      profile,
    );
    commanderResolved = commanderResolution.resolved;

    try {
      final deck = buildDeterministicReferenceDeck(
        profile: profile,
        referenceCardStats: statsLoad.stats,
        referenceDeckCorpusGuidance: corpus,
      );
      final cards = (deck['cards'] as List?)
              ?.whereType<Map>()
              .map((card) => card.cast<String, dynamic>())
              .toList(growable: false) ??
          const <Map<String, dynamic>>[];
      deterministicMainQuantity = _mainQuantity(cards);
      final commander = deck['commander'];
      final commanderName = commander is Map
          ? commander['name']?.toString()
          : commander?.toString();
      final validation = await GeneratedDeckValidationService(
        PostgresGeneratedDeckRepository(pool, preferredFormat: 'commander'),
      ).validate(
        format: 'commander',
        cards: cards,
        commanderName: commanderName,
      );
      deterministicValid = validation.isValid;
      deterministicWarnings.addAll(validation.warnings);
      deterministicWarnings.addAll(validation.errors);
    } catch (error) {
      deterministicWarnings.add('validation_exception:${error.runtimeType}');
    }
  }

  final profileJson = profile ?? const <String, dynamic>{};
  final themes = profileJson['themes'];
  final expectedPackages = profileJson['expected_packages'];
  final packages = corpus?.packages;
  final inputs = CommanderReferenceReadinessInputs(
    commanderName: commanderName,
    commanderCardResolved: commanderResolved,
    profileAvailable: profile != null,
    profileConfidence: normalizeCommanderReferenceConfidence(
      profileJson['confidence'],
    ),
    profileSourceCount: _intValue(profileJson['source_count']),
    profileThemeCount: themes is Iterable ? themes.length : 0,
    profileExpectedPackageCount:
        expectedPackages is Map ? expectedPackages.length : 0,
    cardStatsCount: statsLoad.stats.length,
    cardStatsUnresolvedCount: statsLoad.unresolvedCardNames.length,
    cardStatsPackageCount:
        statsLoad.stats.map((stat) => stat.packageKey).toSet().length,
    corpusAvailable: corpus != null && corpus.isUsable,
    corpusAcceptedDeckCount: corpus?.acceptedDeckCount ?? 0,
    corpusCorePackageCount: packages?.corePackage.length ?? 0,
    corpusThemePackageCount: packages?.themePackage.length ?? 0,
    corpusSupportPackageCount: packages?.supportPackage.length ?? 0,
    deterministicDeckValid: deterministicValid,
    deterministicMainQuantity: deterministicMainQuantity,
    deterministicWarnings: deterministicWarnings,
    runtimeProof: runtimeProof,
  );
  return calculateCommanderReferenceReadinessScorecard(inputs);
}

CommanderReferenceReadinessRuntimeProof?
    parseCommanderReferenceReadinessRuntimeProof(
        Map<String, dynamic>? payload) {
  if (payload == null || payload.isEmpty) return null;
  final byMode = payload['by_mode'];
  final withCommander = byMode is Map ? byMode['with_commander_corpus'] : null;
  final health = payload['health'];
  if (withCommander is Map) {
    return CommanderReferenceReadinessRuntimeProof(
      available: true,
      status: payload['status']?.toString() ?? 'not_proven',
      backendSha: health is Map ? health['git_sha']?.toString() : null,
      withCommander: withCommander.cast<String, dynamic>(),
    );
  }
  if (payload.containsKey('http_200') &&
      payload.containsKey('validation_ok') &&
      payload.containsKey('commander_preserved')) {
    return CommanderReferenceReadinessRuntimeProof(
      available: true,
      status: payload['status']?.toString() ?? 'not_proven',
      backendSha: payload['backend_git_sha']?.toString(),
      withCommander: payload,
    );
  }
  return CommanderReferenceReadinessRuntimeProof(
    available: false,
    status: payload['status']?.toString() ?? 'not_proven',
    backendSha: health is Map ? health['git_sha']?.toString() : null,
    withCommander: null,
  );
}

int _scoreReadiness(
  CommanderReferenceReadinessInputs inputs,
  Map<String, dynamic> gates,
) {
  var score = 0;
  if (gates['commander_card_resolved'] == true) score += 15;
  if (gates['profile_available'] == true) score += 10;
  if (gates['profile_confidence_usable'] == true) score += 10;
  if (gates['profile_has_sources'] == true) score += 3;
  if (gates['profile_has_themes'] == true) score += 3;
  if (gates['profile_has_expected_packages'] == true) score += 4;
  if (gates['card_stats_available'] == true) score += 10;
  if (gates['card_stats_unresolved_zero'] == true) score += 5;
  if (gates['card_stats_packages_available'] == true) score += 5;
  if (gates['corpus_available'] == true) score += 5;
  if (gates['corpus_minimum_accepted_decks'] == true) score += 7;
  if (gates['corpus_core_package_strong'] == true) score += 8;
  if (gates['deterministic_deck_valid'] == true) score += 10;
  if (gates['deterministic_main_quantity_ok'] == true) score += 3;
  if (gates['runtime_public_gate_passed'] == true) score += 2;
  return score;
}

bool _isExpansionBlockingWarning(String warning) =>
    warning == 'corpus_missing' ||
    warning == 'corpus_low_evidence_count' ||
    warning == 'core_package_weak' ||
    warning == 'public_runtime_proof_missing' ||
    warning == 'public_runtime_gate_not_passed';

int _mainQuantity(List<Map<String, dynamic>> cards) {
  var total = 0;
  for (final card in cards) {
    final quantity = _intValue(card['quantity']);
    total += quantity <= 0 ? 1 : quantity;
  }
  return total;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
