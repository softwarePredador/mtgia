import '../basic_land_utils.dart' as basic_lands;
import 'functional_card_tags.dart';

String normalizeOptimizeReasoning(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

Map<String, dynamic> normalizeOptimizePayload(
  Map<String, dynamic> payload, {
  required String defaultMode,
}) {
  final normalized = Map<String, dynamic>.from(payload);
  normalized['mode'] = resolveOptimizeMode(normalized, defaultMode);
  normalized['reasoning'] = normalizeOptimizeReasoning(normalized['reasoning']);
  return normalized;
}

String resolveOptimizeMode(Map<String, dynamic> payload, String defaultMode) {
  final rawCandidates = [
    payload['mode'],
    payload['modde'],
    payload['type'],
    payload['operation_mode'],
    payload['strategy_mode'],
  ];

  for (final raw in rawCandidates) {
    if (raw is! String) continue;
    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('complete')) return 'complete';
    if (normalized.contains('opt')) return 'optimize';
  }

  if (payload['additions_detailed'] is List) {
    final additionsDetailed = payload['additions_detailed'] as List;
    if (additionsDetailed.isNotEmpty) return 'complete';
  }

  return defaultMode;
}

class OptimizeIntensityConfig {
  const OptimizeIntensityConfig({
    required this.selected,
    required this.requested,
    required this.source,
    required this.targetMin,
    required this.targetMax,
    this.valid = true,
  });

  final String selected;
  final String? requested;
  final String source;
  final int targetMin;
  final int targetMax;
  final bool valid;

  bool get isRebuild => selected == 'rebuild';
  bool get wasOmitted => source == 'omitted_default';

  int clampRequestedSwapCount(int count) {
    if (targetMax <= 0) return 0;
    return count.clamp(0, targetMax);
  }

  Map<String, dynamic> toJson({
    int? candidateSwaps,
    int? returnedSwaps,
    int? qualityGateDropped,
  }) {
    final returned = returnedSwaps;
    final dropped = qualityGateDropped ?? 0;
    return {
      'selected': selected,
      'requested': requested,
      'source': source,
      'target_swaps': {
        'min': targetMin,
        'max': targetMax,
      },
      'quality_gate': {
        'can_reduce_scope': true,
        if (dropped > 0) 'dropped_swaps': dropped,
        if (returned != null && returned < targetMin && selected != 'rebuild')
          'reduced_below_target': true,
      },
      if (candidateSwaps != null) 'candidate_swaps': candidateSwaps,
      if (returned != null) 'returned_swaps': returned,
    };
  }
}

bool shouldUseAsyncOptimizeExecutor({
  required OptimizeIntensityConfig intensity,
  required String requestMode,
  required bool forceSync,
  bool? asyncRequested,
}) {
  if (forceSync) return false;
  if (requestMode != 'optimize') return false;
  if (intensity.isRebuild) return false;
  if (asyncRequested == false) return false;
  return asyncRequested == true || intensity.selected == 'aggressive';
}

OptimizeIntensityConfig resolveOptimizeIntensity(dynamic raw) {
  if (raw == null || raw.toString().trim().isEmpty) {
    return const OptimizeIntensityConfig(
      selected: 'focused',
      requested: null,
      source: 'omitted_default',
      targetMin: 6,
      targetMax: 10,
    );
  }

  final requested = raw.toString().trim().toLowerCase();
  final normalized = switch (requested) {
    'conservative' || 'safe' || 'leve' => 'light',
    'default' || 'balanced' || 'balanceado' => 'focused',
    'strong' || 'hard' || 'alta' => 'aggressive',
    'reconstruct' || 'reconstruction' || 'full_rebuild' => 'rebuild',
    _ => requested,
  };

  switch (normalized) {
    case 'light':
      return OptimizeIntensityConfig(
        selected: 'light',
        requested: requested,
        source: 'explicit',
        targetMin: 3,
        targetMax: 5,
      );
    case 'focused':
      return OptimizeIntensityConfig(
        selected: 'focused',
        requested: requested,
        source: 'explicit',
        targetMin: 6,
        targetMax: 10,
      );
    case 'aggressive':
      return OptimizeIntensityConfig(
        selected: 'aggressive',
        requested: requested,
        source: 'explicit',
        targetMin: 10,
        targetMax: 20,
      );
    case 'rebuild':
      return OptimizeIntensityConfig(
        selected: 'rebuild',
        requested: requested,
        source: 'explicit',
        targetMin: 0,
        targetMax: 0,
      );
    default:
      return OptimizeIntensityConfig(
        selected: 'focused',
        requested: requested,
        source: 'invalid',
        targetMin: 6,
        targetMax: 10,
        valid: false,
      );
  }
}

Map<String, dynamic> parseOptimizeSuggestions(Map<String, dynamic> payload) {
  final removals = <String>[];
  final additions = <String>[];
  var recognizedFormat = false;

  final collections = [
    payload['swaps'],
    payload['swap'],
    payload['changes'],
    payload['suggestions'],
    payload['recommendations'],
    payload['replacements'],
  ];

  for (final collection in collections) {
    if (collection is! List) continue;
    recognizedFormat = true;
    for (final entry in collection) {
      if (entry is String) {
        final raw = entry.trim();
        if (raw.isEmpty) continue;
        final arrows = ['->', '=>', '→'];
        String? left;
        String? right;
        for (final arrow in arrows) {
          if (!raw.contains(arrow)) continue;
          final parts = raw.split(arrow);
          if (parts.length >= 2) {
            left = parts.first.trim();
            right = parts.sublist(1).join(arrow).trim();
          }
          break;
        }
        if ((left ?? '').isNotEmpty) removals.add(left!);
        if ((right ?? '').isNotEmpty) additions.add(right!);
        continue;
      }

      if (entry is! Map) continue;
      final map = entry.cast<dynamic, dynamic>();
      final nested = map['swap'] ?? map['change'] ?? map['suggestion'];
      final sourceMap = nested is Map ? nested.cast<dynamic, dynamic>() : map;

      final outRaw = sourceMap['out'] ??
          sourceMap['remove'] ??
          sourceMap['from'] ??
          map['out'] ??
          map['remove'] ??
          map['from'];
      final inRaw = sourceMap['in'] ??
          sourceMap['add'] ??
          sourceMap['to'] ??
          map['in'] ??
          map['add'] ??
          map['to'];

      final out = outRaw?.toString().trim() ?? '';
      final inCard = inRaw?.toString().trim() ?? '';

      if (out.isNotEmpty) removals.add(out);
      if (inCard.isNotEmpty) additions.add(inCard);
    }

    if (removals.isNotEmpty || additions.isNotEmpty) {
      return {
        'removals': removals,
        'additions': additions,
        'recognized_format': true,
      };
    }
  }

  final rawRemovals = payload['removals'];
  final rawAdditions = payload['additions'];

  if (rawRemovals is List) {
    recognizedFormat = true;
    removals.addAll(
        rawRemovals.map((e) => e.toString().trim()).where((e) => e.isNotEmpty));
  } else if (rawRemovals is String && rawRemovals.trim().isNotEmpty) {
    recognizedFormat = true;
    removals.add(rawRemovals.trim());
  } else if (payload.containsKey('removals')) {
    recognizedFormat = true;
  }

  if (rawAdditions is List) {
    recognizedFormat = true;
    additions.addAll(rawAdditions
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty));
  } else if (rawAdditions is String && rawAdditions.trim().isNotEmpty) {
    recognizedFormat = true;
    additions.add(rawAdditions.trim());
  } else if (payload.containsKey('additions')) {
    recognizedFormat = true;
  }

  return {
    'removals': removals,
    'additions': additions,
    'recognized_format': recognizedFormat,
  };
}

Map<String, dynamic> buildDeterministicOptimizeResponse({
  required List<Map<String, dynamic>> deterministicSwapCandidates,
  required String targetArchetype,
  OptimizeIntensityConfig? intensity,
}) {
  final swaps = deterministicSwapCandidates
      .where((candidate) =>
          (candidate['remove']?.toString().trim().isNotEmpty ?? false) &&
          (candidate['add']?.toString().trim().isNotEmpty ?? false))
      .map((candidate) {
    final sources = candidate['candidate_quality_sources'] is List
        ? (candidate['candidate_quality_sources'] as List)
            .map((source) => source.toString())
            .toSet()
        : const <String>{};
    final semanticNote = sources.contains(semanticLayerV2Source)
        ? ' Sinal semântico v2 em shadow mode ajudou o ranking; gates legados continuam valendo.'
        : '';
    return {
      'out': candidate['remove'],
      'in': candidate['add'],
      'reason':
          '${candidate['reason'] ?? 'swap deterministico por funcao'}$semanticNote',
      'role': candidate['remove_role'] ?? candidate['role'] ?? 'utility',
      'function': candidate['remove_role'] ?? candidate['role'] ?? 'utility',
      'priority': intensity?.selected == 'light' ? 'Medium' : 'High',
      'impact': intensity?.selected == 'aggressive'
          ? 'maior escopo de melhoria preservando gates'
          : 'melhoria segura de consistencia',
      'risk': intensity?.selected == 'aggressive' ? 'medium' : 'low',
      if (candidate['candidate_quality_score'] != null)
        'candidate_quality_score': candidate['candidate_quality_score'],
      if (candidate['candidate_quality_signal'] != null)
        'candidate_quality_signal': candidate['candidate_quality_signal'],
      if (candidate['candidate_quality_sources'] != null)
        'candidate_quality_sources': candidate['candidate_quality_sources'],
    };
  }).toList();

  return {
    'mode': 'optimize',
    'strategy_source': 'deterministic_first',
    if (intensity != null) 'intensity': intensity.selected,
    if (intensity != null)
      'optimize_intensity': intensity.toJson(
        candidateSwaps: deterministicSwapCandidates.length,
        returnedSwaps: swaps.length,
      ),
    'reasoning':
        'O backend priorizou swaps determinísticos para $targetArchetype antes da IA, usando função das cartas, prioridade competitiva do comandante e histórico de rejeição.',
    'swaps': swaps,
  };
}

Map<String, dynamic> buildAggressiveOptimizeUtilitySignal({
  required int requestedSwaps,
  required int returnedSwaps,
  required Map<String, int> rejectionBuckets,
  required bool lowCandidateCoverage,
}) {
  final safeRequested = requestedSwaps <= 0 ? 1 : requestedSwaps;
  final returnedRatio = returnedSwaps / safeRequested;

  String status;
  String userMessageKey;
  if (returnedSwaps > 0) {
    status = returnedRatio >= 0.5 ? 'actionable' : 'partial_actionable';
    userMessageKey = 'aggressive_swaps_available';
  } else if (lowCandidateCoverage) {
    status = 'low_coverage';
    userMessageKey = 'aggressive_low_candidate_coverage';
  } else if (rejectionBuckets.isNotEmpty) {
    status = 'quality_rejected';
    userMessageKey = 'aggressive_quality_gate_blocked';
  } else {
    status = 'no_safe_swaps';
    userMessageKey = 'aggressive_no_safe_swaps';
  }

  return {
    'status': status,
    'requested_swaps': safeRequested,
    'returned_swaps': returnedSwaps,
    'returned_ratio': double.parse(returnedRatio.toStringAsFixed(3)),
    'has_actionable_swaps': returnedSwaps > 0,
    'needs_product_explanation': returnedSwaps == 0,
    'user_message_key': userMessageKey,
  };
}

Map<String, dynamic> summarizeAggressiveOptimizeUtilitySamples({
  required List<Map<String, dynamic>> samples,
  int minApplicableRatePercent = 70,
}) {
  final eligible = samples
      .where((sample) => sample['eligible'] != false)
      .toList(growable: false);
  final total = eligible.length;
  final applicable = eligible.where((sample) {
    final swaps = sample['returned_swaps'];
    if (swaps is int) return swaps > 0;
    final diagnostics = sample['aggressive_candidate_quality'];
    if (diagnostics is Map) {
      final returned = diagnostics['returned_swaps'];
      return returned is int && returned > 0;
    }
    final rawSwaps = sample['swaps'];
    return rawSwaps is List && rawSwaps.isNotEmpty;
  }).length;
  final noOp = total - applicable;
  final rate = total == 0 ? 0 : ((applicable * 100) / total).round();

  final latencies = eligible
      .map((sample) => sample['latency_ms'])
      .whereType<int>()
      .toList()
    ..sort();
  final p95 = latencies.isEmpty
      ? null
      : latencies[((latencies.length * 0.95).ceil() - 1)
          .clamp(0, latencies.length - 1)];

  return {
    'eligible_samples': total,
    'applicable_samples': applicable,
    'no_op_samples': noOp,
    'applicable_rate_percent': rate,
    'min_applicable_rate_percent': minApplicableRatePercent,
    'passes_utility_gate': total > 0 && rate >= minApplicableRatePercent,
    if (p95 != null) 'p95_ms': p95,
  };
}

bool shouldRetryOptimizeWithAiFallback({
  required bool deterministicFirstEnabled,
  required bool fallbackAlreadyAttempted,
  required String? strategySource,
  required String? qualityErrorCode,
  required bool isComplete,
}) {
  if (!deterministicFirstEnabled || fallbackAlreadyAttempted || isComplete) {
    return false;
  }

  if (strategySource != 'deterministic_first') return false;

  return qualityErrorCode == 'OPTIMIZE_NO_SAFE_SWAPS' ||
      qualityErrorCode == 'OPTIMIZE_QUALITY_REJECTED';
}

Map<String, dynamic> buildOptimizeRecommendationDetail({
  required String type,
  required String name,
  required String cardId,
  required int quantity,
  required String targetArchetype,
  required String confidenceLevel,
  required double cmcBefore,
  required double cmcAfter,
  required bool keepTheme,
  String? functionalRole,
  String? priority,
  String? risk,
}) {
  final confidenceScore = _confidenceScoreFromLevel(confidenceLevel);
  final action = type == 'add' ? 'entrada' : 'saída';
  final curveDelta = (cmcAfter - cmcBefore).toStringAsFixed(2);
  final isBasicLand = basic_lands.isBasicLandName(name);
  final resolvedRole = (functionalRole == null || functionalRole.trim().isEmpty)
      ? 'utility'
      : functionalRole.trim();

  return {
    'type': type,
    'name': name,
    'card_id': cardId,
    'quantity': quantity,
    'is_basic_land': isBasicLand,
    'role': resolvedRole,
    'function': resolvedRole,
    'priority': priority ?? (type == 'add' ? 'High' : 'Medium'),
    'risk': risk ?? (keepTheme ? 'low' : 'medium'),
    'reason':
        'Sugestão de $action para alinhar o deck ao plano ${targetArchetype.toLowerCase()} e melhorar consistência geral.',
    'confidence': {
      'level': confidenceLevel,
      'score': confidenceScore,
    },
    'impact_estimate': {
      'curve': 'ΔCMC $curveDelta',
      'consistency': keepTheme ? 'alta' : 'média',
      'synergy': type == 'add' ? 'melhora' : 'ajuste',
      'legality': 'mantida',
      'risk': risk ?? (keepTheme ? 'low' : 'medium'),
    },
  };
}

double _confidenceScoreFromLevel(String level) {
  switch (level.toLowerCase()) {
    case 'alta':
    case 'high':
      return 0.9;
    case 'média':
    case 'media':
    case 'medium':
      return 0.7;
    default:
      return 0.5;
  }
}
