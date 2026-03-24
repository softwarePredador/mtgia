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
    if (_selectedDeck == null || _selectedDeck!.id != deckId) {
      await fetchDeckDetails(deckId);
    }
    final deck = _selectedDeck;
    if (deck == null) throw Exception('Deck não encontrado');

    final currentCards = buildCurrentCardsMap(deck);
    currentCards.remove(cardId);

    final response = await _apiClient.put('/decks/$deckId', {
      'cards': currentCards.values.toList(),
    });

    if (response.statusCode != 200) {
      final data = response.data;
      final msg =
          (data is Map && data['error'] != null)
              ? data['error'].toString()
              : 'Falha ao remover carta: ${response.statusCode}';
      throw Exception(msg);
    }

    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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
      final response = await _apiClient.post('/decks/$deckId/cards/set', {
        'card_id': newCardId,
        'quantity': quantity,
        'replace_same_name': true,
        'condition': condition,
      });

      if (response.statusCode != 200) {
        final data = response.data;
        final msg =
            (data is Map && data['error'] != null)
                ? data['error'].toString()
                : 'Falha ao atualizar carta: ${response.statusCode}';
        throw Exception(msg);
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

      final response = await _apiClient.post('/decks/$deckId/cards/set', {
        'card_id': newCardId,
        'quantity': quantity,
        'replace_same_name': false,
        'condition': condition,
      });

      if (response.statusCode != 200) {
        final data = response.data;
        final msg =
            (data is Map && data['error'] != null)
                ? data['error'].toString()
                : 'Falha ao atualizar carta: ${response.statusCode}';
        throw Exception(msg);
      }
    }

    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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
      final response = await _apiClient.get('/decks/$deckId');
      final state = parseDeckDetailsResponse(response);
      _selectedDeck = state.selectedDeck;
      _detailsErrorMessage = state.errorMessage;
      _detailsStatusCode = state.statusCode;

      if (state.selectedDeck != null) {
        storeDeckDetailsInCache(
          cache: _deckDetailsCache,
          cacheTimes: _deckDetailsCacheTime,
          deck: state.selectedDeck!,
        );
        _syncColorIdentityToList(deckId, state.selectedDeck!.colorIdentity);
      }
    } catch (e) {
      _detailsErrorMessage = 'Erro de conexão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Propaga a color identity obtida dos detalhes para o item correspondente
  /// na lista de decks, para que os pips WUBRG apareçam na listagem.
  void _syncColorIdentityToList(String deckId, List<String> colorIdentity) {
    _decks = syncDeckColorIdentityToList(_decks, deckId, colorIdentity);
  }

  /// Aplica color identity do cache de detalhes para todos os decks na lista
  /// que ainda não possuem essa informação.
  void _applyCachedColorIdentities() {
    _decks = applyCachedColorIdentitiesToDeckList(_decks, _deckDetailsCache);
  }

  /// Busca color identity em background para decks que ainda não a possuem.
  /// Carrega os detalhes de cada deck sem color_identity e propaga para a lista.
  Future<void> fetchMissingColorIdentities() async {
    final missing = decksMissingColorIdentity(_decks);
    if (missing.isEmpty) return;

    debugPrint(
      '[DeckProvider] Fetching color identity for ${missing.length} deck(s)...',
    );
    var enriched = 0;

    for (final deck in missing) {
      try {
        final response = await _apiClient.get('/decks/${deck.id}');
        if (response.statusCode == 200) {
          final details = DeckDetails.fromJson(
            response.data as Map<String, dynamic>,
          );
          storeDeckDetailsInCache(
            cache: _deckDetailsCache,
            cacheTimes: _deckDetailsCacheTime,
            deck: details,
          );
          // Sync to list
          if (details.colorIdentity.isNotEmpty) {
            _syncColorIdentityToList(deck.id, details.colorIdentity);
            enriched++;
          }
          debugPrint(
            '[DeckProvider] Deck "${deck.name}" → colors: ${details.colorIdentity}',
          );
        }
      } catch (e) {
        debugPrint(
          '[DeckProvider] Failed to fetch colors for "${deck.name}": $e',
        );
      }
    }
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
      final response = await _apiClient.get('/decks');
      final state = parseDeckListResponse(response);
      if (state.decks != null) {
        _decks = state.decks!;
        _errorMessage = null;
        // Aplica color identity do cache de detalhes para decks que o servidor
        // ainda não retorna color_identity (até deploy da nova rota)
        _applyCachedColorIdentities();

        // Busca color identity em background para decks que ainda não a possuem
        // (não bloqueia a UI — roda em paralelo)
        fetchMissingColorIdentities();
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
      final response = await _apiClient.post('/decks', {
        'name': name,
        'format': format,
        'description': description,
        'is_public': isPublic,
        'cards': normalizedCards,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDecks(); // Recarrega a lista
        await _trackActivationEvent(
          'deck_created',
          format: format,
          source: 'deck_provider.createDeck',
        );
        return true;
      }

      final msg = extractApiError(
        response.data,
        fallback: 'Erro ao criar deck: ${response.statusCode}',
      );
      _errorMessage = msg;
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
      final response = await _apiClient.delete('/decks/$deckId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _decks.removeWhere((deck) => deck.id == deckId);
        notifyListeners();
        return true;
      }
      _errorMessage = 'Erro ao deletar deck: ${response.statusCode}';
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
    if (_selectedDeck == null || _selectedDeck!.id != deckId) {
      await fetchDeckDetails(deckId);
    }
    if (_selectedDeck == null || _selectedDeck!.id != deckId) {
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

        invalidateDeckCache(deckId);
        await fetchDeckDetails(deckId);

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
    try {
      onProgress?.call('Preparando análise do deck...', 0, 5);

      final payload = <String, dynamic>{
        'deck_id': deckId,
        'archetype': archetype,
        if (bracket != null) 'bracket': bracket,
        'keep_theme': keepTheme,
      };

      // Debug snapshot (sem token): útil para você colar o JSON de request/response.
      await saveOptimizeDebugSnapshot(request: payload);
      AppLogger.debug('🧪 [AI Optimize] request=$payload');

      final response = await _apiClient.post('/ai/optimize', payload);

      if (response.statusCode == 200) {
        final data = asDynamicMap(response.data);
        await saveOptimizeDebugSnapshot(response: data);
        AppLogger.debug('🧪 [AI Optimize] response=$data');
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
        return data;
      } else if (response.statusCode == 202) {
        // Async job: servidor processará em background
        final data = asDynamicMap(response.data);
        final jobId = data['job_id'] as String;
        final pollInterval = data['poll_interval_ms'] as int? ?? 2000;
        AppLogger.debug('🧪 [AI Optimize] async job criado: $jobId');
        onProgress?.call(
          'Preparando referências do commander...',
          1,
          data['total_stages'] as int? ?? 6,
        );
        return await _pollOptimizeJob(
          jobId,
          pollInterval: pollInterval,
          onProgress: onProgress,
        );
      } else if (response.statusCode == 422) {
        final data = asDynamicMap(response.data);
        await saveOptimizeDebugSnapshot(
          response: {'statusCode': 422, 'data': data},
        );
        final qualityError = asDynamicMap(data['quality_error']);
        final errorMsg =
            data['error'] as String? ??
            qualityError['message'] as String? ??
            'A otimização não atingiu a qualidade mínima.';
        final code = qualityError['code'] as String? ?? 'QUALITY_ERROR';
        AppLogger.warning('⚠️ [AI Optimize] quality gate: $code — $errorMsg');
        throw buildDeckAiFlowException(
          data,
          fallbackMessage: errorMsg,
          fallbackCode: code,
        );
      } else {
        await saveOptimizeDebugSnapshot(
          response: {'statusCode': response.statusCode, 'data': response.data},
        );
        throw Exception('Falha ao otimizar deck: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
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
    final payload = <String, dynamic>{
      'deck_id': deckId,
      if (archetype != null && archetype.trim().isNotEmpty)
        'archetype': archetype,
      if (theme != null && theme.trim().isNotEmpty) 'theme': theme,
      if (bracket != null) 'bracket': bracket,
      'rebuild_scope': rebuildScope,
      'save_mode': saveMode,
      if (mustKeep.isNotEmpty) 'must_keep': mustKeep,
      if (mustAvoid.isNotEmpty) 'must_avoid': mustAvoid,
    };

    final response = await _apiClient.post(
      '/ai/rebuild',
      payload,
      timeout: const Duration(minutes: 4),
    );

    if (response.statusCode == 200) {
      final data = asDynamicMap(response.data);
      final draftDeckId = data['draft_deck_id']?.toString();
      if (draftDeckId != null && draftDeckId.isNotEmpty) {
        await _trackActivationEvent(
          'deck_rebuild_created',
          deckId: draftDeckId,
          source: 'deck_provider.rebuildDeck',
          metadata: {
            'source_deck_id': deckId,
            'rebuild_scope_selected': data['rebuild_scope_selected'],
            'save_mode': saveMode,
          },
        );
      }
      return data;
    }

    if (response.statusCode == 422) {
      final data = asDynamicMap(response.data);
      throw buildDeckAiFlowException(
        data,
        fallbackMessage:
            data['error']?.toString() ?? 'A reconstrução guiada falhou.',
        fallbackCode: 'REBUILD_FAILED',
      );
    }

    throw Exception('Falha ao reconstruir deck: ${response.statusCode}');
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
      final response = await _apiClient.get('/ai/optimize/jobs/$jobId');
      if (response.statusCode == 200) {
        final data = asDynamicMap(response.data);
        final status = data['status'] as String?;
        if (status == 'completed') {
          final result = data['result'];
          final resultMap = asDynamicMap(result);
          await saveOptimizeDebugSnapshot(response: resultMap);
          AppLogger.debug(
            '🧪 [AI Optimize] job $jobId completed after ${i + 1} polls',
          );
          return resultMap;
        } else if (status == 'failed') {
          final qualityError = asDynamicMap(data['quality_error']);
          final errorMsg =
              data['error'] as String? ??
              qualityError['message'] as String? ??
              'Otimização falhou no servidor.';
          AppLogger.warning('⚠️ [AI Optimize] job $jobId failed: $errorMsg');
          throw buildDeckAiFlowException(
            data,
            fallbackMessage: errorMsg,
            fallbackCode:
                qualityError['code']?.toString() ?? 'OPTIMIZE_JOB_FAILED',
          );
        } else {
          // Still processing — update progress
          onProgress?.call(
            data['stage'] as String? ?? 'Processando...',
            data['stage_number'] as int? ?? 0,
            data['total_stages'] as int? ?? 6,
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Job de otimização expirou ou não foi encontrado.');
      }
    }
    throw Exception('Timeout: a otimização demorou mais de 5 minutos.');
  }

  Future<bool> addCardsBulk({
    required String deckId,
    required List<Map<String, dynamic>> cards,
  }) async {
    final response = await _apiClient.post('/decks/$deckId/cards/bulk', {
      'cards': cards,
    });
    if (response.statusCode == 200) {
      invalidateDeckCache(deckId);
      await fetchDeckDetails(deckId);
      return true;
    }
    if (response.data is Map && (response.data as Map)['error'] != null) {
      throw Exception((response.data as Map)['error'].toString());
    }
    throw Exception('Falha ao adicionar em lote : ${response.statusCode}');
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
    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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
    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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
    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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
  }) async {
    try {
      return await generateDeckFromPrompt(
        _apiClient,
        prompt: prompt,
        format: format,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<DeckDetails> _ensureDeckLoadedForOptimization(String deckId) async {
    if (_selectedDeck == null || _selectedDeck!.id != deckId) {
      AppLogger.debug('📥 [DeckProvider] Buscando detalhes do deck...');
      await fetchDeckDetails(deckId);
    }

    final deck = _selectedDeck;
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
    final stopwatch = Stopwatch()..start();
    final response = await _apiClient.put('/decks/$deckId', {
      'cards': cardsPayload,
    });
    stopwatch.stop();
    AppLogger.debug(
      '⏱️ [DeckProvider] Tempo de resposta do servidor: ${stopwatch.elapsedMilliseconds}ms',
    );

    ensureSuccessfulDeckMutationResponse(
      response,
      fallbackMessage: 'Falha ao atualizar deck',
    );

    AppLogger.debug('✅ [DeckProvider] Deck atualizado com sucesso!');

    try {
      final validation = await validateDeck(deckId);
      final isValid = validation['valid'] as bool? ?? false;
      if (!isValid) {
        final errors = (validation['errors'] as List?)?.join(', ') ?? '';
        AppLogger.warning(
          '[DeckProvider] Deck salvo mas com avisos de validação: $errors',
        );
      }
    } catch (validationError) {
      AppLogger.warning(
        '[DeckProvider] Não foi possível validar deck após salvar: $validationError',
      );
    }

    invalidateDeckCache(deckId);
    await fetchDeckDetails(deckId);
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

      // 1. Buscar o deck atual para pegar a lista de cartas
      await _ensureDeckLoadedForOptimization(deckId);

      // 2. Construir lista atual de cartas em formato de map
      final currentCards = buildCurrentCardsMap(_selectedDeck!);

      // 3. Buscar IDs das cartas a adicionar pelo nome (EM PARALELO)
      final cardsToAddIds = await resolveOptimizationAdditions(
        _apiClient,
        cardsToAdd,
      );

      // 4. Buscar IDs das cartas a remover pelo nome (EM PARALELO)
      final cardsToRemoveIds = await resolveOptimizationRemovals(
        _apiClient,
        cardsToRemove,
      );

      if (cardsToAdd.isNotEmpty && cardsToAddIds.isEmpty) {
        throw Exception(
          'Nenhuma das cartas sugeridas para adicionar foi encontrada no banco. Tente novamente.',
        );
      }
      if (cardsToRemove.isNotEmpty && cardsToRemoveIds.isEmpty) {
        throw Exception(
          'Nenhuma das cartas sugeridas para remover foi encontrada no banco. Tente novamente.',
        );
      }

      // 5. Remover as cartas da lista atual
      AppLogger.debug('✂️ [DeckProvider] Removendo cartas...');

      // 6. Adicionar as novas cartas
      AppLogger.debug(
        '➕ [DeckProvider] Adicionando ${cardsToAddIds.length} cartas...',
      );

      final applyResult = buildNamedOptimizationApplyResult(
        deck: _selectedDeck!,
        cardsToRemoveIds: cardsToRemoveIds,
        cardsToAddIds: cardsToAddIds,
      );
      for (final cardId in applyResult.skippedForIdentity) {
        AppLogger.debug(
          '⛔️ [DeckProvider] Pulando fora da identidade do comandante: $cardId',
        );
      }
      currentCards
        ..clear()
        ..addAll(applyResult.currentCards);

      if (!applyResult.hasStructuralChange) {
        throw Exception(
          'Nenhuma mudança aplicável foi encontrada para este deck.',
        );
      }

      // 7. Atualizar o deck via API
      return _persistDeckCardsPayload(
        deckId: deckId,
        cardsPayload: currentCards.values.toList(),
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

      // 1. Buscar deck atual
      if (_selectedDeck == null || _selectedDeck!.id != deckId) {
        await fetchDeckDetails(deckId);
      }
      if (_selectedDeck == null) throw Exception('Deck não encontrado');

      AppLogger.debug(
        '👑 [DeckProvider] Commanders no deck: ${_selectedDeck!.commander.length}',
      );
      for (final commander in _selectedDeck!.commander) {
        AppLogger.debug(
          '  Commander: ${commander.name} (id=${commander.id}, qty=${commander.quantity})',
        );
      }
      AppLogger.debug(
        '🃏 [DeckProvider] MainBoard entries: ${_selectedDeck!.mainBoard.length}',
      );

      final cardsPayload = buildOptimizedCardPayload(
        deck: _selectedDeck!,
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
  }) async {
    try {
      return await validateImportListRequest(
        _apiClient,
        format: format,
        list: list,
      );
    } catch (e) {
      return buildConnectionFailureResult(e);
    }
  }

  /// Importa uma lista de cartas para um deck EXISTENTE
  /// Se replaceAll=true, substitui todas as cartas; senão, adiciona às existentes
  Future<Map<String, dynamic>> importListToDeck({
    required String deckId,
    required String list,
    bool replaceAll = false,
  }) async {
    try {
      final result = await importListToDeckRequest(
        _apiClient,
        deckId: deckId,
        list: list,
        replaceAll: replaceAll,
      );

      if (result['success'] == true) {
        invalidateDeckCache(deckId);
      }

      return result;
    } catch (e) {
      return buildConnectionFailureResult(e);
    }
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
      return {'error': 'Erro de conexão: $e'};
    }
  }

  /// Copia um deck público para a conta do usuário autenticado
  Future<Map<String, dynamic>> copyPublicDeck(String deckId) async {
    try {
      final result = await copyPublicDeckRequest(_apiClient, deckId);
      if (result['success'] == true) {
        await fetchDecks();
      }
      return result;
    } catch (e) {
      return buildConnectionFailureResult(e);
    }
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
