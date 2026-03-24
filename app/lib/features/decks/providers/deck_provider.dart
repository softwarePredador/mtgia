import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/activation_funnel_service.dart';
import '../../../core/utils/logger.dart';
import '../models/deck.dart';
import '../models/deck_details.dart';
import '../models/deck_card_item.dart';
import 'deck_provider_support.dart';

export 'deck_provider_support.dart' show DeckAiFlowException;

typedef ActivationEventTracker =
    Future<void> Function(
      String eventName, {
      String? format,
      String? deckId,
      String source,
      Map<String, dynamic>? metadata,
    });

/// Provider para gerenciar estado da listagem de decks
class DeckProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final ActivationEventTracker _trackActivationEvent;

  List<Deck> _decks = [];
  DeckDetails? _selectedDeck;
  bool _isLoading = false;
  String? _errorMessage; // Erro geral ou de lista
  String? _detailsErrorMessage; // Erro específico de detalhes
  int? _detailsStatusCode;

  // Cache de detalhes do deck (evita recarregar se já temos os dados)
  final Map<String, DeckDetails> _deckDetailsCache = {};
  final Map<String, DateTime> _deckDetailsCacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  List<Deck> get decks => List.unmodifiable(_decks);
  DeckDetails? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get detailsErrorMessage => _detailsErrorMessage;
  int? get detailsStatusCode => _detailsStatusCode;
  bool get hasError => _errorMessage != null;

  DeckProvider({
    ApiClient? apiClient,
    ActivationEventTracker? trackActivationEvent,
  }) : _apiClient = apiClient ?? ApiClient(),
       _trackActivationEvent =
           trackActivationEvent ?? ActivationFunnelService.instance.track;

  Future<void> removeCardFromDeck({
    required String deckId,
    required String cardId,
  }) async {
    final deck = await _ensureDeckLoadedForMutation(deckId);
    if (deck == null) throw Exception('Deck não encontrado');

    final currentCards = buildCurrentCardsMap(deck);
    currentCards.remove(cardId);

    final result = await removeCardFromDeckRequest(
      _apiClient,
      deckId: deckId,
      cardsPayload: currentCards.values.toList(),
    );

    if (!result.isSuccess) {
      throw Exception(result.errorMessage);
    }

    await _refreshDeckDetailsAfterMutation(deckId);
  }

  Future<void> updateDeckCardEntry({
    required String deckId,
    required String oldCardId,
    required String newCardId,
    required int quantity,
    String? cardName,
    bool consolidateSameName = false,
    String condition = 'NM',
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantidade deve ser > 0');
    }

    // Commander/Brawl (ou quando explicitamente pedido): resolve duplicatas por NOME no backend.
    // Isso garante que, se o deck já estiver com 2 edições da mesma carta, o usuário consegue corrigir.
    if (consolidateSameName) {
      final result = await setDeckCardQuantityRequest(
        _apiClient,
        deckId: deckId,
        cardId: newCardId,
        quantity: quantity,
        replaceSameName: true,
        condition: condition,
      );

      if (!result.isSuccess) {
        throw Exception(result.errorMessage);
      }
    } else {
      // Outros formatos: se trocou a edição, troca primeiro; depois faz SET absoluto.
      if (oldCardId != newCardId) {
        await replaceCardEdition(
          deckId: deckId,
          oldCardId: oldCardId,
          newCardId: newCardId,
        );
      }

      final result = await setDeckCardQuantityRequest(
        _apiClient,
        deckId: deckId,
        cardId: newCardId,
        quantity: quantity,
        replaceSameName: false,
        condition: condition,
      );

      if (!result.isSuccess) {
        throw Exception(result.errorMessage);
      }
    }

    await _refreshDeckDetailsAfterMutation(deckId);
  }

  /// Busca detalhes de um deck específico (com cache)
  Future<void> fetchDeckDetails(
    String deckId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedDeck = readFreshDeckDetailsFromCache(
        cache: _deckDetailsCache,
        cacheTimes: _deckDetailsCacheTime,
        deckId: deckId,
        cacheDuration: _cacheDuration,
      );
      if (cachedDeck != null) {
        final shouldNotify =
            _selectedDeck != cachedDeck ||
            _detailsErrorMessage != null ||
            _detailsStatusCode != 200;
        _selectedDeck = cachedDeck;
        _detailsErrorMessage = null;
        _detailsStatusCode = 200;
        if (shouldNotify) {
          notifyListeners();
        }
        return;
      }
    }

    _isLoading = true;
    _detailsErrorMessage = null;
    _detailsStatusCode = null;
    notifyListeners();

    try {
      final state = await fetchDeckDetailsRequest(_apiClient, deckId);
      _selectedDeck = state.selectedDeck;
      _detailsErrorMessage = state.errorMessage;
      _detailsStatusCode = state.statusCode;

      if (state.selectedDeck != null) {
        storeDeckDetailsInCache(
          cache: _deckDetailsCache,
          cacheTimes: _deckDetailsCacheTime,
          deck: state.selectedDeck!,
        );
        _decks = syncDeckColorIdentityToList(
          _decks,
          deckId,
          state.selectedDeck!.colorIdentity,
        );
      }
    } catch (e) {
      _detailsErrorMessage = 'Erro de conexão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca color identity em background para decks que ainda não a possuem.
  /// Carrega os detalhes de cada deck sem color_identity e propaga para a lista.
  Future<void> fetchMissingColorIdentities([List<Deck>? targetDecks]) async {
    final missing = targetDecks ?? decksMissingColorIdentity(_decks);
    if (missing.isEmpty) return;

    debugPrint(
      '[DeckProvider] Fetching color identity for ${missing.length} deck(s)...',
    );
    final result = await fetchMissingDeckColorIdentities(_apiClient, missing);
    for (final deck in missing.where(
      (deck) => result.failedDeckIds.contains(deck.id),
    )) {
      debugPrint('[DeckProvider] Failed to fetch colors for "${deck.name}".');
    }

    final applyResult = applyDeckColorIdentityEnrichment(_decks, result);
    for (final details in applyResult.cachedDetails) {
      storeDeckDetailsInCache(
        cache: _deckDetailsCache,
        cacheTimes: _deckDetailsCacheTime,
        deck: details,
      );
      debugPrint('[DeckProvider] Deck "${details.name}" → colors: ${details.colorIdentity}');
    }

    final enriched = applyResult.enrichedCount;
    _decks = applyResult.decks;
    debugPrint(
      '[DeckProvider] Color enrichment done: $enriched/${missing.length} decks.',
    );
    if (enriched > 0) {
      // Cria nova referência de lista para que context.select detecte a mudança
      _decks = List<Deck>.from(_decks);
      notifyListeners();
    }
  }

  /// Busca todos os decks do usuário
  Future<void> fetchDecks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final state = await fetchDeckListRequest(_apiClient);
      if (state.decks != null) {
        final hydration = buildDeckListHydrationResult(
          state.decks!,
          _deckDetailsCache,
        );
        _decks = hydration.decks;
        _errorMessage = null;
        // Busca color identity em background para decks que ainda não a possuem.
        fetchMissingColorIdentities(hydration.missingColorIdentityDecks);
      } else {
        _errorMessage = state.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Erro de conexão: $e';
      // Não limpa _decks para permitir cache visual em caso de erro
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria um novo deck
  Future<bool> createDeck({
    required String name,
    required String format,
    String? description,
    List<Map<String, dynamic>>? cards,
    bool isPublic = false,
  }) async {
    try {
      final normalizedCards = await normalizeCreateDeckCards(
        _apiClient,
        cards ?? [],
      );
      final result = await createDeckRequest(
        _apiClient,
        name: name,
        format: format,
        description: description,
        isPublic: isPublic,
        cards: normalizedCards,
      );

      if (result.isSuccess) {
        await fetchDecks(); // Recarrega a lista
        await _trackActivationEvent(
          'deck_created',
          format: format,
          source: 'deck_provider.createDeck',
        );
        return true;
      }

      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao criar deck: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deleta um deck
  Future<bool> deleteDeck(String deckId) async {
    try {
      final result = await deleteDeckRequest(_apiClient, deckId);
      if (result.isSuccess) {
        final nextState = applyDeckDeletionToState(
          _decks,
          _selectedDeck,
          deckId,
        );
        _decks = nextState.decks;
        _selectedDeck = nextState.selectedDeck;
        invalidateDeckCache(deckId);
        notifyListeners();
        return true;
      }
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao deletar deck: $e';
      notifyListeners();
      return false;
    }
  }

  /// Adiciona uma carta ao deck
  Future<bool> addCardToDeck(
    String deckId,
    DeckCardItem card,
    int quantity, {
    bool isCommander = false,
    String condition = 'NM',
  }) async {
    final deck = await _ensureDeckLoadedForMutation(deckId);
    if (deck == null) {
      _errorMessage =
          'Deck não carregado. Abra os detalhes do deck e tente novamente.';
      notifyListeners();
      return false;
    }

    try {
      final result = await addCardToDeckRequest(
        _apiClient,
        deckId: deckId,
        cardId: card.id,
        quantity: quantity,
        isCommander: isCommander,
        condition: condition,
      );
      if (result.isSuccess) {
        _decks = incrementDeckCardCount(
          _decks,
          deckId,
          delta: isCommander ? 1 : quantity,
        );

        await _refreshDeckDetailsAfterMutation(deckId);

        return true;
      }

      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao adicionar carta: $e';
      notifyListeners();
      return false;
    }
  }

  /// Busca opções de otimização (arquétipos) para o deck
  Future<List<Map<String, dynamic>>> fetchOptimizationOptions(
    String deckId,
  ) => fetchOptimizationOptionsRequest(_apiClient, deckId);

  /// Solicita sugestões de otimização para um arquétipo específico
  Future<Map<String, dynamic>> optimizeDeck(
    String deckId,
    String archetype, {
    int? bracket,
    bool keepTheme = true,
    void Function(String stage, int stageNumber, int totalStages)? onProgress,
  }) async {
    onProgress?.call('Preparando análise do deck...', 0, 5);

    final requestResult = await requestOptimizeDeck(
      _apiClient,
      deckId: deckId,
      archetype: archetype,
      bracket: bracket,
      keepTheme: keepTheme,
    );

    if (requestResult.isAsync) {
      onProgress?.call(
        'Preparando referências do commander...',
        1,
        requestResult.totalStages ?? 6,
      );
      return _pollOptimizeJob(
        requestResult.jobId!,
        pollInterval: requestResult.pollIntervalMs ?? 2000,
        onProgress: onProgress,
      );
    }

    await _trackActivationEvent(
      'deck_optimized',
      deckId: deckId,
      source: 'deck_provider.optimizeDeck',
      metadata: {
        'archetype': archetype,
        if (bracket != null) 'bracket': bracket,
        'keep_theme': keepTheme,
      },
    );
    return requestResult.result!;
  }

  Future<Map<String, dynamic>> rebuildDeck(
    String deckId, {
    String? archetype,
    String? theme,
    int? bracket,
    String rebuildScope = 'auto',
    String saveMode = 'draft_clone',
    List<String> mustKeep = const <String>[],
    List<String> mustAvoid = const <String>[],
  }) async {
    final result = await requestRebuildDeck(
      _apiClient,
      deckId: deckId,
      archetype: archetype,
      theme: theme,
      bracket: bracket,
      rebuildScope: rebuildScope,
      saveMode: saveMode,
      mustKeep: mustKeep,
      mustAvoid: mustAvoid,
    );

    final draftDeckId = result.draftDeckId;
    if (draftDeckId != null && draftDeckId.isNotEmpty) {
      await _trackActivationEvent(
        'deck_rebuild_created',
        deckId: draftDeckId,
        source: 'deck_provider.rebuildDeck',
        metadata: {
          'source_deck_id': deckId,
          'rebuild_scope_selected': result.payload['rebuild_scope_selected'],
          'save_mode': saveMode,
        },
      );
    }
    return result.payload;
  }

  /// Faz polling no job de otimização até completar ou falhar.
  /// Polling interval de 5s para evitar rate limiting (429).
  Future<Map<String, dynamic>> _pollOptimizeJob(
    String jobId, {
    int pollInterval = 5000,
    void Function(String stage, int stageNumber, int totalStages)? onProgress,
  }) async {
    const maxPolls = 60; // 60 × 5s = 5 min timeout
    for (var i = 0; i < maxPolls; i++) {
      await Future.delayed(Duration(milliseconds: pollInterval));
      final result = await pollOptimizeJobRequest(_apiClient, jobId);
      if (result.isCompleted) {
        AppLogger.debug(
          '🧪 [AI Optimize] job $jobId completed after ${i + 1} polls',
        );
        return result.result!;
      }
      onProgress?.call(
        result.stage ?? 'Processando...',
        result.stageNumber ?? 0,
        result.totalStages ?? 6,
      );
    }
    throw Exception('Timeout: a otimização demorou mais de 5 minutos.');
  }

  Future<bool> addCardsBulk({
    required String deckId,
    required List<Map<String, dynamic>> cards,
  }) async {
    final result = await addCardsBulkRequest(
      _apiClient,
      deckId: deckId,
      cards: cards,
    );
    if (result.isSuccess) {
      await _refreshDeckDetailsAfterMutation(deckId);
      return true;
    }
    throw Exception(result.errorMessage);
  }

  /// Atualiza apenas a descrição do deck via PUT
  Future<bool> updateDeckDescription({
    required String deckId,
    required String description,
  }) async {
    await updateDeckDescriptionRequest(
      _apiClient,
      deckId: deckId,
      description: description,
    );
    await _refreshDeckDetailsAfterMutation(deckId);
    return true;
  }

  Future<void> updateDeckStrategy({
    required String deckId,
    required String archetype,
    required int bracket,
  }) async {
    await updateDeckStrategyRequest(
      _apiClient,
      deckId: deckId,
      archetype: archetype,
      bracket: bracket,
    );
    await _refreshDeckDetailsAfterMutation(deckId);
  }

  /// Valida o deck no servidor (modo estrito: Commander=100 e com comandante).
  Future<Map<String, dynamic>> validateDeck(String deckId) =>
      validateDeckRequest(_apiClient, deckId);

  Future<bool> replaceCardEdition({
    required String deckId,
    required String oldCardId,
    required String newCardId,
  }) async {
    await replaceCardEditionRequest(
      _apiClient,
      deckId: deckId,
      oldCardId: oldCardId,
      newCardId: newCardId,
    );
    await _refreshDeckDetailsAfterMutation(deckId);
    return true;
  }

  Future<Map<String, dynamic>> fetchDeckPricing(
    String deckId, {
    bool force = false,
  }) => fetchDeckPricingRequest(_apiClient, deckId, force: force);

  /// Atualiza/gera análise de sinergia (IA) e persiste no deck.
  /// Endpoint: POST /decks/:id/ai-analysis
  Future<Map<String, dynamic>> refreshAiAnalysis(
    String deckId, {
    bool force = false,
  }) async {
    final payload = await refreshAiAnalysisRequest(
      _apiClient,
      deckId,
      force: force,
    );
    final nextSelectedDeck = applyAiAnalysisToSelectedDeck(
      _selectedDeck,
      deckId,
      synergyScore: payload.synergyScore,
      strengths: payload.strengths,
      weaknesses: payload.weaknesses,
    );
    final nextDecks = applyAiAnalysisToDeckList(
      _decks,
      deckId,
      synergyScore: payload.synergyScore,
      strengths: payload.strengths,
      weaknesses: payload.weaknesses,
    );

    final didUpdate = nextSelectedDeck != _selectedDeck || nextDecks != _decks;
    _selectedDeck = nextSelectedDeck;
    _decks = nextDecks;

    if (didUpdate) {
      notifyListeners();
    }

    return payload.raw;
  }

  /// Gera um deck do zero usando IA baseado em um prompt de texto
  Future<Map<String, dynamic>> generateDeck({
    required String prompt,
    required String format,
  }) => generateDeckFromPrompt(_apiClient, prompt: prompt, format: format);

  Future<DeckDetails> _ensureDeckLoadedForOptimization(String deckId) async {
    final deck = await _ensureDeckLoadedForMutation(deckId);
    if (deck == null) {
      throw Exception('Deck não encontrado');
    }

    return deck;
  }

  Future<bool> _persistDeckCardsPayload({
    required String deckId,
    required List<Map<String, dynamic>> cardsPayload,
  }) async {
    AppLogger.debug('💾 [DeckProvider] Salvando alterações no servidor...');
    final result = await persistDeckCardsPayloadWithValidation(
      _apiClient,
      deckId: deckId,
      cardsPayload: cardsPayload,
    );
    AppLogger.debug(
      '⏱️ [DeckProvider] Tempo de resposta do servidor: ${result.elapsedMilliseconds}ms',
    );

    AppLogger.debug('✅ [DeckProvider] Deck atualizado com sucesso!');

    try {
      final isValid = result.validation['valid'] as bool? ?? false;
      if (!isValid) {
        final errors = (result.validation['errors'] as List?)?.join(', ') ?? '';
        AppLogger.warning(
          '[DeckProvider] Deck salvo mas com avisos de validação: $errors',
        );
      }
    } catch (validationError) {
      AppLogger.warning(
        '[DeckProvider] Não foi possível validar deck após salvar: $validationError',
      );
    }

    await _refreshDeckDetailsAfterMutation(deckId);
    return true;
  }

  /// Aplica as sugestões de otimização ao deck
  /// Recebe uma lista de cartas para remover e adicionar (por nome)
  /// Busca os IDs das cartas e atualiza o deck
  Future<bool> applyOptimization({
    required String deckId,
    required List<String> cardsToRemove,
    required List<String> cardsToAdd,
  }) async {
    try {
      AppLogger.debug('🔄 [DeckProvider] Iniciando otimização do deck $deckId');
      AppLogger.debug(
        '📋 [DeckProvider] Remover: ${cardsToRemove.length} cartas | Adicionar: ${cardsToAdd.length} cartas',
      );

      final deck = await _ensureDeckLoadedForOptimization(deckId);
      final payloadResult = await buildNamedOptimizationPayload(
        _apiClient,
        deck: deck,
        cardsToRemove: cardsToRemove,
        cardsToAdd: cardsToAdd,
      );
      for (final cardId in payloadResult.skippedForIdentity) {
        AppLogger.debug(
          '⛔️ [DeckProvider] Pulando fora da identidade do comandante: $cardId',
        );
      }
      return _persistDeckCardsPayload(
        deckId: deckId,
        cardsPayload: payloadResult.cardsPayload,
      );
    } catch (e) {
      AppLogger.error('[DeckProvider] Erro fatal na otimização', e);
      rethrow;
    }
  }

  /// Aplica otimização usando IDs diretamente (versão rápida)
  /// Evita N chamadas HTTP para buscar cartas por nome
  Future<bool> applyOptimizationWithIds({
    required String deckId,
    required List<Map<String, dynamic>> removalsDetailed,
    required List<Map<String, dynamic>> additionsDetailed,
  }) async {
    try {
      AppLogger.debug('🚀 [DeckProvider] Otimização rápida com IDs diretos');

      final deck = await _ensureDeckLoadedForOptimization(deckId);

      AppLogger.debug(
        '👑 [DeckProvider] Commanders no deck: ${deck.commander.length}',
      );
      for (final commander in deck.commander) {
        AppLogger.debug(
          '  Commander: ${commander.name} (id=${commander.id}, qty=${commander.quantity})',
        );
      }
      AppLogger.debug(
        '🃏 [DeckProvider] MainBoard entries: ${deck.mainBoard.length}',
      );

      final cardsPayload = buildOptimizedCardPayload(
        deck: deck,
        removalsDetailed: removalsDetailed,
        additionsDetailed: additionsDetailed,
      );

      // 5. Salvar no servidor
      AppLogger.debug('💾 [DeckProvider] Salvando...');

      // DEBUG: Log todas as cartas que serão enviadas
      AppLogger.debug(
        '📦 [DeckProvider] Total de cartas a enviar: ${cardsPayload.length}',
      );
      for (final v in cardsPayload) {
        AppLogger.debug(
          '  📌 ${v['card_id']}: qty=${v['quantity']}, is_commander=${v['is_commander']}',
        );
      }

      return await _persistDeckCardsPayload(
        deckId: deckId,
        cardsPayload: cardsPayload,
      );
    } catch (e) {
      AppLogger.error('[DeckProvider] Erro na otimização rápida', e);
      rethrow;
    }
  }

  /// Limpa o erro
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Invalida o cache de um deck específico (chamar após updates)
  void invalidateDeckCache(String deckId) {
    _deckDetailsCache.remove(deckId);
    _deckDetailsCacheTime.remove(deckId);
  }

  /// Limpa todo o cache de detalhes
  void clearAllCache() {
    _deckDetailsCache.clear();
    _deckDetailsCacheTime.clear();
  }

  /// Importa um deck a partir de uma lista de texto (ex: "1 Sol Ring")
  /// Retorna um Map com:
  /// - 'success': bool
  /// - 'deck': dados do deck criado (se sucesso)
  /// - 'cards_imported': quantidade de cartas importadas
  /// - 'not_found_lines': lista de linhas não encontradas
  /// - 'warnings': lista de avisos
  /// - 'error': mensagem de erro (se falhou)
  Future<Map<String, dynamic>> importDeckFromList({
    required String name,
    required String format,
    required String list,
    String? description,
    String? commander,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await importDeckFromListRequest(
        _apiClient,
        name: name,
        format: format,
        list: list,
        description: description,
        commander: commander,
      );

      if (result['success'] == true) {
        await fetchDecks();
      }

      _errorMessage = result['error']?.toString();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro de conexão: $e';
      notifyListeners();
      return buildConnectionFailureResult(e);
    }
  }

  /// Valida uma lista de cartas sem criar o deck (preview)
  /// Útil para mostrar ao usuário quais cartas foram encontradas e quais não
  Future<Map<String, dynamic>> validateImportList({
    required String format,
    required String list,
  }) => runConnectionSafeMapRequest(
    () => validateImportListRequest(_apiClient, format: format, list: list),
  );

  /// Importa uma lista de cartas para um deck EXISTENTE
  /// Se replaceAll=true, substitui todas as cartas; senão, adiciona às existentes
  Future<Map<String, dynamic>> importListToDeck({
    required String deckId,
    required String list,
    bool replaceAll = false,
  }) async {
    final result = await runConnectionSafeMapRequest(
      () => importListToDeckRequest(
        _apiClient,
        deckId: deckId,
        list: list,
        replaceAll: replaceAll,
      ),
    );

    if (result['success'] == true) {
      invalidateDeckCache(deckId);
    }
    return result;
  }

  Future<DeckDetails?> _ensureDeckLoadedForMutation(String deckId) async {
    if (_selectedDeck == null || _selectedDeck!.id != deckId) {
      AppLogger.debug('📥 [DeckProvider] Buscando detalhes do deck...');
      await fetchDeckDetails(deckId);
    }
    return _selectedDeck;
  }

  Future<void> _refreshDeckDetailsAfterMutation(String deckId) async {
    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
  }

  // ───── Social / Sharing ─────

  /// Alterna visibilidade pública/privada do deck via PUT /decks/:id
  Future<bool> togglePublic(String deckId, {required bool isPublic}) async {
    try {
      final isSuccess = await togglePublicRequest(
        _apiClient,
        deckId: deckId,
        isPublic: isPublic,
      );
      if (isSuccess) {
        _selectedDeck = applyDeckVisibilityToSelectedDeck(
          _selectedDeck,
          deckId,
          isPublic: isPublic,
        );
        _decks = applyDeckVisibilityToDeckList(
          _decks,
          deckId,
          isPublic: isPublic,
        );
        invalidateDeckCache(deckId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('[DeckProvider] togglePublic error: $e');
      return false;
    }
  }

  /// Exporta deck como texto (lista de cartas)
  Future<Map<String, dynamic>> exportDeckAsText(String deckId) async {
    try {
      return await exportDeckAsTextRequest(_apiClient, deckId);
    } catch (e) {
      return buildExportConnectionFailureResult(e);
    }
  }

  /// Copia um deck público para a conta do usuário autenticado
  Future<Map<String, dynamic>> copyPublicDeck(String deckId) async {
    final result = await runConnectionSafeMapRequest(
      () => copyPublicDeckRequest(_apiClient, deckId),
    );
    if (result['success'] == true) {
      await fetchDecks();
    }
    return result;
  }

  /// Limpa todo o estado do provider (chamado no logout)
  void clearAllState() {
    _decks = [];
    _selectedDeck = null;
    _isLoading = false;
    _errorMessage = null;
    _detailsErrorMessage = null;
    _detailsStatusCode = null;
    _deckDetailsCache.clear();
    _deckDetailsCacheTime.clear();
    notifyListeners();
  }
}
