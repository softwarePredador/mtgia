import 'dart:convert';

enum BinderImportCandidateStatus {
  resolving,
  needsPrinting,
  ambiguous,
  unresolved,
  ready,
  failed,
  applied,
}

class BinderImportParseResult {
  const BinderImportParseResult({
    required this.candidates,
    required this.invalidLines,
  });

  final List<BinderImportCandidate> candidates;
  final List<String> invalidLines;
}

class BinderImportCandidate {
  BinderImportCandidate({
    required this.id,
    required this.requestedName,
    required this.quantity,
    required this.sourceLines,
    this.requestedSetCode,
    this.requestedCollectorNumber,
    this.matchedName,
    this.status = BinderImportCandidateStatus.resolving,
    this.suggestedNames = const [],
    this.printings = const [],
    this.selectedPrinting,
    this.condition = 'NM',
    this.isFoil = false,
    this.language = 'en',
    this.listType = 'have',
    this.error,
    this.applicationStatus,
  });

  factory BinderImportCandidate.fromJson(Map<String, dynamic> json) {
    final statusName = json['status']?.toString();
    return BinderImportCandidate(
      id: json['id']?.toString() ?? '',
      requestedName: json['requested_name']?.toString() ?? '',
      quantity: _int(json['quantity'], fallback: 1),
      sourceLines: (json['source_lines'] as List? ?? const [])
          .map((line) => line.toString())
          .toList(),
      requestedSetCode: _text(json['requested_set_code']),
      requestedCollectorNumber: _text(json['requested_collector_number']),
      matchedName: _text(json['matched_name']),
      status: BinderImportCandidateStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => BinderImportCandidateStatus.resolving,
      ),
      suggestedNames: (json['suggested_names'] as List? ?? const [])
          .map((name) => name.toString())
          .toList(growable: false),
      printings: _mapList(json['printings']),
      selectedPrinting: json['selected_printing'] is Map
          ? (json['selected_printing'] as Map).cast<String, dynamic>()
          : null,
      condition: json['condition']?.toString() ?? 'NM',
      isFoil: json['is_foil'] == true,
      language: json['language']?.toString() ?? 'en',
      listType: json['list_type']?.toString() ?? 'have',
      error: _text(json['error']),
      applicationStatus: _text(json['application_status']),
    );
  }

  final String id;
  final String requestedName;
  int quantity;
  final List<String> sourceLines;
  final String? requestedSetCode;
  final String? requestedCollectorNumber;
  String? matchedName;
  BinderImportCandidateStatus status;
  List<String> suggestedNames;
  List<Map<String, dynamic>> printings;
  Map<String, dynamic>? selectedPrinting;
  String condition;
  bool isFoil;
  String language;
  String listType;
  String? error;
  String? applicationStatus;

  bool get hasDuplicateSources => sourceLines.length > 1;
  bool get isReady =>
      status == BinderImportCandidateStatus.ready && selectedPrinting != null;
  String get displayName => matchedName ?? requestedName;
  String? get cardId => _text(selectedPrinting?['id']);

  String get physicalIdentityKey =>
      '${cardId ?? ''}|$condition|$isFoil|$language|$listType';

  Map<String, dynamic> toJson() => {
    'id': id,
    'requested_name': requestedName,
    'quantity': quantity,
    'source_lines': sourceLines,
    if (requestedSetCode != null) 'requested_set_code': requestedSetCode,
    if (requestedCollectorNumber != null)
      'requested_collector_number': requestedCollectorNumber,
    if (matchedName != null) 'matched_name': matchedName,
    'status': status.name,
    'suggested_names': suggestedNames,
    'printings': printings,
    if (selectedPrinting != null) 'selected_printing': selectedPrinting,
    'condition': condition,
    'is_foil': isFoil,
    'language': language,
    'list_type': listType,
    if (error != null) 'error': error,
    if (applicationStatus != null) 'application_status': applicationStatus,
  };
}

class BinderImportPlan {
  BinderImportPlan({
    required this.inputId,
    required this.candidateIds,
    required this.card,
    required this.quantity,
    required this.condition,
    required this.isFoil,
    required this.language,
    required this.listType,
  });

  final String inputId;
  final List<String> candidateIds;
  final Map<String, dynamic> card;
  final int quantity;
  final String condition;
  final bool isFoil;
  final String language;
  final String listType;
  String status = 'pending';
  String? action;
  String? existingId;
  int? baselineQuantity;
  int? targetQuantity;
  BinderImportAvailability? availability;
  String? code;
  String? message;

  String get cardId => card['id']?.toString() ?? '';
  bool get isReady =>
      status == 'ready' && baselineQuantity != null && targetQuantity != null;

  Map<String, dynamic> toPreviewJson() => {
    'input_id': inputId,
    'card_id': cardId,
    'quantity': quantity,
    'condition': condition,
    'is_foil': isFoil,
    'language': language,
    'list_type': listType,
  };

  Map<String, dynamic> toApplyJson() => {
    ...toPreviewJson(),
    'baseline_quantity': baselineQuantity,
    'target_quantity': targetQuantity,
  };

  void applyPreview(Map<String, dynamic> json) {
    status = json['status']?.toString() ?? 'rejected';
    action = _text(json['action']);
    existingId = _text(json['existing_id']);
    baselineQuantity = _nullableInt(json['baseline_quantity']);
    targetQuantity = _nullableInt(json['target_quantity']);
    code = _text(json['code']);
    message = _text(json['message']);
    if (json['card'] is Map) {
      card
        ..clear()
        ..addAll((json['card'] as Map).cast<String, dynamic>());
    }
    if (json['availability'] is Map) {
      availability = BinderImportAvailability.fromJson(
        (json['availability'] as Map).cast<String, dynamic>(),
      );
    }
  }
}

class BinderImportAvailability {
  const BinderImportAvailability({
    required this.ownedQuantity,
    required this.allocatedQuantity,
    required this.committedTradeQuantity,
    required this.freeQuantity,
    required this.missingQuantity,
  });

  factory BinderImportAvailability.fromJson(Map<String, dynamic> json) {
    return BinderImportAvailability(
      ownedQuantity: _int(json['owned_quantity']),
      allocatedQuantity: _int(json['allocated_quantity']),
      committedTradeQuantity: _int(json['committed_trade_quantity']),
      freeQuantity: _int(json['free_quantity']),
      missingQuantity: _int(json['missing_quantity']),
    );
  }

  final int ownedQuantity;
  final int allocatedQuantity;
  final int committedTradeQuantity;
  final int freeQuantity;
  final int missingQuantity;

  Map<String, dynamic> toJson() => {
    'owned_quantity': ownedQuantity,
    'allocated_quantity': allocatedQuantity,
    'committed_trade_quantity': committedTradeQuantity,
    'free_quantity': freeQuantity,
    'missing_quantity': missingQuantity,
  };
}

class BinderImportBatchHistory {
  const BinderImportBatchHistory({
    required this.batchId,
    required this.createdAt,
    required this.totalApplied,
    required this.totalFailed,
    required this.results,
  });

  factory BinderImportBatchHistory.fromJson(Map<String, dynamic> json) {
    return BinderImportBatchHistory(
      batchId: json['batch_id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      totalApplied: _int(json['total_applied']),
      totalFailed: _int(json['total_failed']),
      results: _mapList(json['results']),
    );
  }

  final String batchId;
  final DateTime createdAt;
  final int totalApplied;
  final int totalFailed;
  final List<Map<String, dynamic>> results;

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'total_applied': totalApplied,
    'total_failed': totalFailed,
    'results': results,
  };
}

BinderImportParseResult parseBinderImportText(
  String source, {
  String listType = 'have',
}) {
  final candidatesByHint = <String, BinderImportCandidate>{};
  final invalidLines = <String>[];
  final lines = const LineSplitter().convert(source);
  final quantityPattern = RegExp(r'^(\d+)\s*x?\s+(.+)$', caseSensitive: false);
  final printingHintPattern = RegExp(
    r'^(.*?)\s+(?:\(([A-Za-z0-9]{2,8})\)|\[([A-Za-z0-9]{2,8})\])(?:\s+(\S+))?\s*$',
  );

  for (var index = 0; index < lines.length; index++) {
    final sourceLine = lines[index].trim();
    if (sourceLine.isEmpty || sourceLine.startsWith('#')) continue;
    final quantityMatch = quantityPattern.firstMatch(sourceLine);
    if (quantityMatch == null) {
      invalidLines.add(sourceLine);
      continue;
    }
    final quantity = int.tryParse(quantityMatch.group(1) ?? '');
    if (quantity == null || quantity < 1) {
      invalidLines.add(sourceLine);
      continue;
    }

    var name = quantityMatch.group(2)?.trim() ?? '';
    String? setCode;
    String? collectorNumber;
    final hintMatch = printingHintPattern.firstMatch(name);
    if (hintMatch != null) {
      name = hintMatch.group(1)?.trim() ?? '';
      setCode = (hintMatch.group(2) ?? hintMatch.group(3))?.toUpperCase();
      collectorNumber = _text(hintMatch.group(4));
    }
    if (name.isEmpty) {
      invalidLines.add(sourceLine);
      continue;
    }

    final hintKey = [
      name.toLowerCase(),
      setCode?.toLowerCase() ?? '',
      collectorNumber?.toLowerCase() ?? '',
    ].join('|');
    final existing = candidatesByHint[hintKey];
    if (existing != null) {
      existing.quantity += quantity;
      existing.sourceLines.add(sourceLine);
      continue;
    }
    candidatesByHint[hintKey] = BinderImportCandidate(
      id: 'line-${index + 1}',
      requestedName: name,
      quantity: quantity,
      sourceLines: <String>[sourceLine],
      requestedSetCode: setCode,
      requestedCollectorNumber: collectorNumber,
      listType: listType,
    );
  }

  return BinderImportParseResult(
    candidates: candidatesByHint.values.toList(growable: false),
    invalidLines: List.unmodifiable(invalidLines),
  );
}

List<BinderImportPlan> buildBinderImportPlans(
  Iterable<BinderImportCandidate> candidates,
) {
  final grouped = <String, List<BinderImportCandidate>>{};
  for (final candidate in candidates.where((candidate) => candidate.isReady)) {
    grouped.putIfAbsent(candidate.physicalIdentityKey, () => []).add(candidate);
  }

  var index = 0;
  return grouped.values
      .map((group) {
        index++;
        final first = group.first;
        return BinderImportPlan(
          inputId: 'plan-$index',
          candidateIds: group.map((candidate) => candidate.id).toList(),
          card: Map<String, dynamic>.from(first.selectedPrinting!),
          quantity: group.fold(
            0,
            (total, candidate) => total + candidate.quantity,
          ),
          condition: first.condition,
          isFoil: first.isFoil,
          language: first.language,
          listType: first.listType,
        );
      })
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList(growable: false);
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) => _nullableInt(value) ?? fallback;

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
