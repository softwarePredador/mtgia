import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../models/binder_import_models.dart';
import '../services/binder_import_draft_store.dart';

class BinderImportProvider extends ChangeNotifier {
  BinderImportProvider({
    ApiClient? apiClient,
    BinderImportDraftStore? draftStore,
  }) : _api = apiClient ?? ApiClient(),
       _draftStore = draftStore ?? BinderImportDraftStore();

  final ApiClient _api;
  final BinderImportDraftStore _draftStore;
  final Map<String, List<Map<String, dynamic>>> _printingCache = {};

  String _ownerId = '';
  String _sourceText = '';
  List<BinderImportCandidate> _candidates = [];
  List<String> _invalidLines = [];
  List<BinderImportPlan> _plans = [];
  List<BinderImportBatchHistory> _history = [];
  BinderImportAvailability? _summary;
  bool _isLoadingDraft = true;
  bool _isResolving = false;
  bool _isPreviewing = false;
  bool _isApplying = false;
  String? _error;

  String get sourceText => _sourceText;
  List<BinderImportCandidate> get candidates => List.unmodifiable(_candidates);
  List<String> get invalidLines => List.unmodifiable(_invalidLines);
  List<BinderImportPlan> get plans => List.unmodifiable(_plans);
  List<BinderImportBatchHistory> get history => List.unmodifiable(_history);
  BinderImportAvailability? get summary => _summary;
  bool get isLoadingDraft => _isLoadingDraft;
  bool get isResolving => _isResolving;
  bool get isPreviewing => _isPreviewing;
  bool get isApplying => _isApplying;
  bool get isBusy => _isResolving || _isPreviewing || _isApplying;
  String? get error => _error;
  int get readyCount =>
      _candidates.where((candidate) => candidate.isReady).length;
  int get pendingDecisionCount => _candidates.where((candidate) {
    return candidate.status == BinderImportCandidateStatus.needsPrinting ||
        candidate.status == BinderImportCandidateStatus.ambiguous ||
        candidate.status == BinderImportCandidateStatus.unresolved ||
        candidate.status == BinderImportCandidateStatus.failed;
  }).length;
  bool get canPreview => readyCount > 0 && !isBusy;
  bool get canApply =>
      _plans.isNotEmpty && _plans.every((plan) => plan.isReady) && !isBusy;

  Future<void> initialize({
    required String ownerId,
    required String listType,
  }) async {
    _ownerId = ownerId;
    _isLoadingDraft = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _draftStore.loadDraft(ownerId),
        _draftStore.loadHistory(ownerId),
      ]);
      final draft = results[0] as BinderImportDraft?;
      _history = results[1] as List<BinderImportBatchHistory>;
      if (draft != null) {
        _sourceText = draft.sourceText;
        _candidates = draft.candidates;
        for (final candidate in _candidates) {
          candidate.listType = listType;
          candidate.applicationStatus = null;
          if (candidate.selectedPrinting != null) {
            candidate.status = BinderImportCandidateStatus.ready;
          } else if (candidate.status ==
                  BinderImportCandidateStatus.resolving ||
              candidate.status == BinderImportCandidateStatus.applied) {
            candidate.status = BinderImportCandidateStatus.unresolved;
          }
        }
      }
    } catch (error) {
      _error = 'O rascunho local não pôde ser carregado.';
      debugPrint('[BinderImportProvider] load draft failed: $error');
    } finally {
      _isLoadingDraft = false;
      notifyListeners();
    }
  }

  Future<void> saveSourceDraft(String sourceText) async {
    _sourceText = sourceText;
    await _saveDraft();
  }

  Future<void> reviewSource(
    String sourceText, {
    required String listType,
  }) async {
    if (_isResolving) return;
    final parsed = parseBinderImportText(sourceText, listType: listType);
    _sourceText = sourceText;
    _candidates = parsed.candidates;
    _invalidLines = parsed.invalidLines;
    _plans = [];
    _summary = null;
    _error = null;
    if (_candidates.isEmpty) {
      _error = parsed.invalidLines.isEmpty
          ? 'Cole ao menos uma linha no formato “quantidade + nome”.'
          : 'Nenhuma linha válida foi encontrada.';
      notifyListeners();
      await _saveDraft();
      return;
    }

    _isResolving = true;
    notifyListeners();
    await _saveDraft();
    try {
      final names = _candidates
          .map((candidate) => candidate.requestedName)
          .toSet()
          .toList(growable: false);
      final response = await _api.post('/cards/resolve/batch', {
        'names': names,
      });
      if (response.statusCode != 200 || response.data is! Map) {
        throw StateError('resolve batch returned ${response.statusCode}');
      }
      final data = (response.data as Map).cast<String, dynamic>();
      final resolved = <String, Map<String, dynamic>>{};
      for (final row in _mapList(data['data'])) {
        resolved[_normalized(row['input_name'])] = row;
      }
      final ambiguous = <String, List<String>>{};
      for (final row in _mapList(data['ambiguous'])) {
        ambiguous[_normalized(
          row['input_name'],
        )] = (row['candidates'] as List? ?? const [])
            .map((name) => name.toString())
            .toList(growable: false);
      }
      final unresolved = (data['unresolved'] as List? ?? const [])
          .map(_normalized)
          .toSet();

      final printingsByName = <String, List<Map<String, dynamic>>>{};
      for (final candidate in _candidates) {
        final key = _normalized(candidate.requestedName);
        final resolution = resolved[key];
        if (resolution != null) {
          candidate.matchedName = resolution['matched_name']?.toString();
          await _loadCandidatePrintings(candidate, printingsByName);
        } else if (ambiguous.containsKey(key)) {
          candidate.status = BinderImportCandidateStatus.ambiguous;
          candidate.suggestedNames = ambiguous[key]!;
          candidate.error = 'Escolha o nome correto antes da impressão.';
        } else if (unresolved.contains(key)) {
          candidate.status = BinderImportCandidateStatus.unresolved;
          candidate.error = 'Carta não encontrada no catálogo local.';
        } else {
          candidate.status = BinderImportCandidateStatus.unresolved;
          candidate.error = 'Não foi possível confirmar esta carta.';
        }
        notifyListeners();
      }
      await _saveDraft();
    } catch (error) {
      for (final candidate in _candidates) {
        if (candidate.status == BinderImportCandidateStatus.resolving) {
          candidate.status = BinderImportCandidateStatus.failed;
          candidate.error = 'Falha de conexão. O rascunho foi preservado.';
        }
      }
      _error = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.binder,
        fallback:
            'Não foi possível revisar o lote agora. O rascunho foi preservado.',
      );
      await _saveDraft();
    } finally {
      _isResolving = false;
      notifyListeners();
    }
  }

  Future<void> chooseSuggestedName(String candidateId, String name) async {
    final candidate = _candidate(candidateId);
    if (candidate == null || isBusy) return;
    candidate.matchedName = name;
    candidate.status = BinderImportCandidateStatus.resolving;
    candidate.error = null;
    _invalidatePreview();
    notifyListeners();
    try {
      await _loadCandidatePrintings(
        candidate,
        <String, List<Map<String, dynamic>>>{},
      );
      await _saveDraft();
    } catch (error) {
      candidate.status = BinderImportCandidateStatus.failed;
      candidate.error = 'Não foi possível carregar as impressões.';
      await _saveDraft();
    }
    notifyListeners();
  }

  Future<void> useManualCard(
    String candidateId,
    Map<String, dynamic> card,
  ) async {
    final candidate = _candidate(candidateId);
    if (candidate == null || isBusy) return;
    candidate.matchedName = card['name']?.toString() ?? candidate.requestedName;
    candidate.status = BinderImportCandidateStatus.resolving;
    candidate.error = null;
    _invalidatePreview();
    notifyListeners();
    try {
      await _loadCandidatePrintings(
        candidate,
        <String, List<Map<String, dynamic>>>{},
      );
      if (candidate.printings.length == 1) {
        candidate.selectedPrinting = Map<String, dynamic>.from(
          candidate.printings.single,
        );
        candidate.status = BinderImportCandidateStatus.ready;
      }
      await _saveDraft();
    } catch (_) {
      candidate.printings = [Map<String, dynamic>.from(card)];
      candidate.selectedPrinting = Map<String, dynamic>.from(card);
      candidate.status = BinderImportCandidateStatus.ready;
      await _saveDraft();
    }
    notifyListeners();
  }

  Future<void> addScannedCard(
    Map<String, dynamic> card, {
    required String listType,
  }) async {
    final cardId = card['id']?.toString().trim() ?? '';
    final cardName = card['name']?.toString().trim() ?? '';
    if (cardId.isEmpty || cardName.isEmpty) {
      _error = 'O scanner não devolveu uma impressão válida.';
      notifyListeners();
      return;
    }
    final existing = _candidates.cast<BinderImportCandidate?>().firstWhere(
      (candidate) =>
          candidate?.cardId == cardId &&
          candidate?.condition == 'NM' &&
          candidate?.isFoil == false &&
          candidate?.language == 'en' &&
          candidate?.listType == listType,
      orElse: () => null,
    );
    final sourceLine = 'Scanner • $cardName';
    if (existing != null) {
      existing.quantity += 1;
      existing.sourceLines.add(sourceLine);
      existing.status = BinderImportCandidateStatus.ready;
      existing.applicationStatus = null;
      existing.error = null;
    } else {
      final printing = Map<String, dynamic>.from(card);
      _candidates.add(
        BinderImportCandidate(
          id: 'scan-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}',
          requestedName: cardName,
          matchedName: cardName,
          quantity: 1,
          sourceLines: [sourceLine],
          printings: [printing],
          selectedPrinting: printing,
          status: BinderImportCandidateStatus.ready,
          listType: listType,
        ),
      );
    }
    _error = null;
    _invalidatePreview();
    notifyListeners();
    await _saveDraft();
  }

  Future<List<Map<String, dynamic>>> fetchPrintings(String cardName) async {
    final key = _normalized(cardName);
    final cached = _printingCache[key];
    if (cached != null) return cached;
    final encoded = Uri.encodeQueryComponent(cardName.trim());
    final response = await _api.get(
      '/cards/printings?name=$encoded&limit=50&dedupe=false',
    );
    if (response.statusCode != 200 || response.data is! Map) {
      throw StateError('printing lookup returned ${response.statusCode}');
    }
    final rows = _mapList(
      (response.data as Map)['data'],
    ).where((row) => _normalized(row['name']) == key).toList(growable: false);
    final seenIds = <String>{};
    final unique = rows
        .where((row) {
          final id = row['id']?.toString() ?? '';
          return id.isNotEmpty && seenIds.add(id);
        })
        .toList(growable: false);
    _printingCache[key] = unique;
    return unique;
  }

  Future<void> selectPrinting(
    String candidateId,
    Map<String, dynamic> printing,
  ) async {
    final candidate = _candidate(candidateId);
    if (candidate == null) return;
    candidate.selectedPrinting = Map<String, dynamic>.from(printing);
    candidate.matchedName =
        printing['name']?.toString() ?? candidate.matchedName;
    candidate.status = BinderImportCandidateStatus.ready;
    candidate.error = null;
    candidate.applicationStatus = null;
    _invalidatePreview();
    notifyListeners();
    await _saveDraft();
  }

  Future<void> updatePhysicalIdentity(
    String candidateId, {
    String? condition,
    bool? isFoil,
    String? language,
  }) async {
    final candidate = _candidate(candidateId);
    if (candidate == null) return;
    if (condition != null) candidate.condition = condition;
    if (isFoil != null) candidate.isFoil = isFoil;
    if (language != null) candidate.language = language;
    candidate.applicationStatus = null;
    if (candidate.selectedPrinting != null) {
      candidate.status = BinderImportCandidateStatus.ready;
    }
    _invalidatePreview();
    notifyListeners();
    await _saveDraft();
  }

  Future<void> changeQuantity(String candidateId, int delta) async {
    final candidate = _candidate(candidateId);
    if (candidate == null) return;
    candidate.quantity = (candidate.quantity + delta).clamp(1, 99999);
    candidate.applicationStatus = null;
    if (candidate.selectedPrinting != null) {
      candidate.status = BinderImportCandidateStatus.ready;
    }
    _invalidatePreview();
    notifyListeners();
    await _saveDraft();
  }

  Future<void> removeCandidate(String candidateId) async {
    _candidates.removeWhere((candidate) => candidate.id == candidateId);
    _invalidatePreview();
    notifyListeners();
    await _saveDraft();
  }

  Future<void> previewBatch() async {
    if (!canPreview) return;
    _isPreviewing = true;
    _error = null;
    _plans = buildBinderImportPlans(_candidates);
    notifyListeners();
    try {
      final response = await _api.post('/binder/import/preview', {
        'items': _plans
            .map((plan) => plan.toPreviewJson())
            .toList(growable: false),
      });
      if (response.statusCode != 200 || response.data is! Map) {
        throw StateError('preview returned ${response.statusCode}');
      }
      final data = (response.data as Map).cast<String, dynamic>();
      final rowsById = {
        for (final row in _mapList(data['data']))
          row['input_id']?.toString() ?? '': row,
      };
      for (final plan in _plans) {
        final row = rowsById[plan.inputId];
        if (row == null) {
          plan.status = 'rejected';
          plan.message = 'O backend não devolveu este item.';
        } else {
          plan.applyPreview(row);
        }
      }
      if (data['summary'] is Map) {
        _summary = BinderImportAvailability.fromJson(
          (data['summary'] as Map).cast<String, dynamic>(),
        );
      }
    } catch (error) {
      _plans = [];
      _error = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.binder,
        fallback:
            'Não foi possível montar o plano. Nenhuma carta foi alterada.',
      );
    } finally {
      _isPreviewing = false;
      notifyListeners();
    }
  }

  Future<void> applyBatch() async {
    if (!canApply) return;
    _isApplying = true;
    _error = null;
    notifyListeners();
    final batchId = _newBatchId();
    try {
      final response = await _api.post('/binder/import/apply', {
        'batch_id': batchId,
        'items': _plans
            .map((plan) => plan.toApplyJson())
            .toList(growable: false),
      });
      if (response.statusCode != 200 || response.data is! Map) {
        throw StateError('apply returned ${response.statusCode}');
      }
      final data = (response.data as Map).cast<String, dynamic>();
      final results = _mapList(data['data']);
      final resultsById = {
        for (final result in results)
          result['input_id']?.toString() ?? '': result,
      };
      const successful = {'created', 'updated', 'unchanged'};
      for (final plan in _plans) {
        final result = resultsById[plan.inputId];
        final status = result?['status']?.toString() ?? 'failed';
        plan.status = status;
        plan.code = result?['code']?.toString();
        plan.message = result?['message']?.toString();
        for (final candidateId in plan.candidateIds) {
          final candidate = _candidate(candidateId);
          if (candidate == null) continue;
          candidate.applicationStatus = status;
          if (successful.contains(status)) {
            candidate.status = BinderImportCandidateStatus.applied;
            candidate.error = null;
          } else {
            candidate.status = BinderImportCandidateStatus.failed;
            candidate.error =
                plan.message ??
                'Este item não foi aplicado e continua no rascunho.';
          }
        }
      }
      if (data['summary'] is Map) {
        _summary = BinderImportAvailability.fromJson(
          (data['summary'] as Map).cast<String, dynamic>(),
        );
      }
      final totalApplied = _int(data['total_applied']);
      final totalFailed = _int(data['total_failed']);
      final history = BinderImportBatchHistory(
        batchId: data['batch_id']?.toString() ?? batchId,
        createdAt: DateTime.now().toUtc(),
        totalApplied: totalApplied,
        totalFailed: totalFailed,
        results: results
            .map((result) {
              final plan = _plans.cast<BinderImportPlan?>().firstWhere(
                (candidatePlan) =>
                    candidatePlan?.inputId == result['input_id']?.toString(),
                orElse: () => null,
              );
              return {
                ...result,
                if (plan != null) 'card_name': plan.card['name'],
                if (plan != null) 'quantity': plan.quantity,
              };
            })
            .toList(growable: false),
      );
      await _draftStore.addHistory(_ownerId, history);
      _history = [
        history,
        ..._history,
      ].take(BinderImportDraftStore.historyLimit).toList(growable: false);
      await _saveDraft(includeApplied: false);
    } catch (error) {
      _error = FriendlyErrorMapper.fromException(
        error,
        context: FriendlyErrorContext.binder,
        fallback:
            'Não foi possível confirmar o resultado. Revise antes de tentar novamente.',
      );
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  Future<void> retryFailed() async {
    for (final candidate in _candidates) {
      if (candidate.status == BinderImportCandidateStatus.failed &&
          candidate.selectedPrinting != null) {
        candidate.status = BinderImportCandidateStatus.ready;
        candidate.applicationStatus = null;
        candidate.error = null;
      }
    }
    _invalidatePreview();
    await _saveDraft();
    notifyListeners();
    await previewBatch();
  }

  Future<void> discardDraft() async {
    _sourceText = '';
    _candidates = [];
    _invalidLines = [];
    _plans = [];
    _summary = null;
    _error = null;
    await _draftStore.clearDraft(_ownerId);
    notifyListeners();
  }

  Future<void> _loadCandidatePrintings(
    BinderImportCandidate candidate,
    Map<String, List<Map<String, dynamic>>> requestCache,
  ) async {
    final matchedName = candidate.matchedName?.trim();
    if (matchedName == null || matchedName.isEmpty) {
      candidate.status = BinderImportCandidateStatus.unresolved;
      candidate.error = 'Escolha um nome antes da impressão.';
      return;
    }
    final key = _normalized(matchedName);
    final printings = requestCache[key] ?? await fetchPrintings(matchedName);
    requestCache[key] = printings;
    candidate.printings = printings;
    candidate.selectedPrinting = null;
    if (printings.isEmpty) {
      candidate.status = BinderImportCandidateStatus.unresolved;
      candidate.error = 'Nenhuma impressão local foi encontrada.';
      return;
    }

    final hinted = printings
        .where((printing) {
          final requestedSet = candidate.requestedSetCode?.toLowerCase();
          final requestedCollector = candidate.requestedCollectorNumber
              ?.toLowerCase();
          final setMatches =
              requestedSet == null ||
              printing['set_code']?.toString().toLowerCase() == requestedSet;
          final collectorMatches =
              requestedCollector == null ||
              printing['collector_number']?.toString().toLowerCase() ==
                  requestedCollector;
          return setMatches && collectorMatches;
        })
        .toList(growable: false);

    if ((candidate.requestedSetCode != null ||
            candidate.requestedCollectorNumber != null) &&
        hinted.length == 1) {
      candidate.selectedPrinting = Map<String, dynamic>.from(hinted.single);
      candidate.status = BinderImportCandidateStatus.ready;
      candidate.error = null;
      return;
    }
    if (candidate.requestedSetCode == null &&
        candidate.requestedCollectorNumber == null &&
        printings.length == 1) {
      candidate.selectedPrinting = Map<String, dynamic>.from(printings.single);
      candidate.status = BinderImportCandidateStatus.ready;
      candidate.error = null;
      return;
    }

    candidate.status = BinderImportCandidateStatus.needsPrinting;
    candidate.error =
        hinted.isEmpty &&
            (candidate.requestedSetCode != null ||
                candidate.requestedCollectorNumber != null)
        ? 'O set/número informado não bateu; escolha uma impressão.'
        : 'Escolha set e número antes de aplicar.';
  }

  BinderImportCandidate? _candidate(String id) {
    for (final candidate in _candidates) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  void _invalidatePreview() {
    _plans = [];
    _summary = null;
  }

  Future<void> _saveDraft({bool includeApplied = true}) {
    final candidates = includeApplied
        ? _candidates
        : _candidates
              .where(
                (candidate) =>
                    candidate.status != BinderImportCandidateStatus.applied,
              )
              .toList(growable: false);
    return _draftStore.saveDraft(
      _ownerId,
      sourceText: _sourceText,
      candidates: candidates,
    );
  }

  String _newBatchId() =>
      'collection-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList(growable: false);
}

String _normalized(Object? value) =>
    value?.toString().trim().toLowerCase() ?? '';

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
