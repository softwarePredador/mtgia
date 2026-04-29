import 'dart:io';
import 'dart:ui' show Rect;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../models/card_recognition_result.dart';
import '../services/card_recognition_service.dart';
import '../services/image_preprocessor.dart';
import '../services/fuzzy_card_matcher.dart';
import '../services/scanner_card_search_service.dart';
import '../../decks/models/deck_card_item.dart';

enum ScannerState {
  idle,
  capturing,
  processing,
  searching,
  found,
  notFound,
  error,
}

/// Provider para gerenciar estado do scanner de cartas
class ScannerProvider extends ChangeNotifier {
  final CardRecognitionService _recognitionService = CardRecognitionService();
  late final FuzzyCardMatcher _fuzzyMatcher;
  final ScannerCardSearchService _searchService;

  ScannerState _state = ScannerState.idle;
  CardRecognitionResult? _lastResult;
  List<DeckCardItem> _foundCards = [];
  DeckCardItem? _autoSelectedCard;
  String? _errorMessage;
  bool _useFoilMode = false;
  String? _liveDetectedName;
  int _liveConfirmCount = 0;
  static const _liveConfirmThreshold = 2; // frames consecutivos para confirmar

  ScannerState get state => _state;
  CardRecognitionResult? get lastResult => _lastResult;
  List<DeckCardItem> get foundCards => _foundCards;
  DeckCardItem? get autoSelectedCard => _autoSelectedCard;
  String? get errorMessage => _errorMessage;
  bool get useFoilMode => _useFoilMode;
  String? get liveDetectedName => _liveDetectedName;

  ScannerProvider({ScannerCardSearchService? searchService})
    : _searchService = searchService ?? ScannerCardSearchService() {
    _fuzzyMatcher = FuzzyCardMatcher(_searchService);
  }

  /// Alterna modo foil (processamento mais agressivo)
  void toggleFoilMode() {
    _useFoilMode = !_useFoilMode;
    notifyListeners();
  }

  /// Processa um frame da câmera em tempo real (leve)
  /// Retorna true se detectou e já está buscando.
  ///
  /// [cardGuideRect] é a região do guia de carta em coordenadas da câmera.
  /// Blocos de texto fora dessa região serão ignorados.
  Future<bool> processLiveFrame(
    CameraImage image,
    CameraDescription camera, {
    Rect? cardGuideRect,
  }) async {
    if (_state != ScannerState.idle) return false;

    final result = await _recognitionService.recognizeFromCameraImage(
      image,
      camera,
      cardGuideRect: cardGuideRect,
    );

    if (result == null || !result.success || result.primaryName == null) {
      // Reset contagem se perdeu detecção
      if (_liveDetectedName != null) {
        _liveConfirmCount = 0;
        _liveDetectedName = null;
        notifyListeners();
      }
      return false;
    }

    final detected = result.primaryName!.trim();
    if (detected.isEmpty) return false;

    // Mesmo nome detectado novamente → incrementa contagem
    if (detected == _liveDetectedName) {
      _liveConfirmCount++;
    } else {
      _liveDetectedName = detected;
      _liveConfirmCount = 1;
      notifyListeners();
    }

    // Confirmado por N frames consecutivos → busca automática
    if (_liveConfirmCount >= _liveConfirmThreshold) {
      debugPrint(
        '[📸 Live] Confirmado: "$detected" (${result.confidence}%)'
        '${result.collectorInfo?.hasData == true ? ' | Collector: ${result.collectorInfo}' : ''}',
      );
      _liveDetectedName = null;
      _liveConfirmCount = 0;

      // Usa o resultado para buscar
      await processRecognitionResult(result);
      return true;
    }

    return false;
  }

  /// Processa uma imagem capturada (botão manual - processamento completo)
  Future<void> processImage(File imageFile) async {
    _setState(ScannerState.processing);
    _errorMessage = null;
    _foundCards = [];
    _lastResult = null;
    _autoSelectedCard = null;

    try {
      // Pré-processa a imagem
      File processedFile;
      if (_useFoilMode) {
        processedFile = await ImagePreprocessor.preprocessFoil(imageFile);
      } else {
        processedFile = await ImagePreprocessor.preprocess(imageFile);
      }

      // Reconhece o texto
      final result = await _recognitionService.recognizeCard(processedFile);
      // Limpa arquivo processado
      if (processedFile.path != imageFile.path) {
        try {
          await processedFile.delete();
        } catch (_) {}
      }

      await processRecognitionResult(result);
    } catch (e) {
      _errorMessage = 'Erro ao processar: $e';
      _setState(ScannerState.error);
    }
  }

  /// Processes a controlled OCR result without requiring camera or ML Kit.
  Future<void> processRecognitionResult(CardRecognitionResult result) async {
    _lastResult = result;
    _errorMessage = null;
    _foundCards = [];
    _autoSelectedCard = null;

    if (!result.success || result.primaryName == null) {
      _errorMessage = result.error ?? 'Nome não reconhecido';
      _setState(ScannerState.notFound);
      return;
    }

    _setState(ScannerState.searching);

    try {
      final resolved = await _resolveBestPrintings(result);
      if (resolved.isNotEmpty) {
        _foundCards = resolved;
        _autoSelectedCard = _tryAutoSelectEdition(
          printings: resolved,
          setCodeCandidates: result.setCodeCandidates,
          collectorInfo: result.collectorInfo,
        );
        _setState(ScannerState.found);
        return;
      }

      _errorMessage = 'Carta "${result.primaryName}" não encontrada no banco';
      _setState(ScannerState.notFound);
    } catch (e) {
      _errorMessage = 'Erro ao buscar: $e';
      _setState(ScannerState.error);
    }
  }

  Future<List<DeckCardItem>> _resolveBestPrintings(
    CardRecognitionResult result,
  ) async {
    final primary = result.primaryName?.trim();
    if (primary == null || primary.isEmpty) return const [];

    // 1) Tenta printings por nome exato (melhor para selecionar edição).
    final exact = await _searchService.fetchPrintingsByExactName(primary);
    if (exact.isNotEmpty) return exact;

    for (final alt in result.alternatives) {
      final a = alt.trim();
      if (a.isEmpty) continue;
      final altExact = await _searchService.fetchPrintingsByExactName(a);
      if (altExact.isNotEmpty) {
        _lastResult = CardRecognitionResult.success(
          primaryName: a,
          alternatives: [
            if (primary != a) primary,
            ...result.alternatives.where((x) => x != a),
          ],
          setCodeCandidates: result.setCodeCandidates,
          confidence: result.confidence * 0.9,
          allCandidates: result.allCandidates,
          collectorInfo: result.collectorInfo,
        );
        return altExact;
      }
    }

    // 2) Fallback: fuzzy search para achar o nome "correto", depois busca printings exatos.
    final fuzzy = await _fuzzyMatcher.searchWithFuzzy(primary);
    if (fuzzy.isNotEmpty) {
      final bestName = fuzzy.first.name.trim();
      if (bestName.isNotEmpty) {
        final bestExact = await _searchService.fetchPrintingsByExactName(
          bestName,
        );
        if (bestExact.isNotEmpty) {
          _lastResult = CardRecognitionResult.success(
            primaryName: bestName,
            alternatives:
                [
                  primary,
                  ...result.alternatives,
                ].where((x) => x.trim().isNotEmpty && x != bestName).toList(),
            setCodeCandidates: result.setCodeCandidates,
            confidence: result.confidence * 0.8,
            allCandidates: result.allCandidates,
            collectorInfo: result.collectorInfo,
          );
          return bestExact;
        }
      }
      return fuzzy;
    }

    // 3) Último recurso: resolve via Scryfall (server busca na API externa,
    //    insere no DB, e retorna). Isso torna o sistema "self-healing" —
    //    qualquer carta real que não esteja no banco será importada na hora.
    debugPrint('[🔍 Resolve] Tentando resolver "$primary" via Scryfall...');
    final resolved = await _searchService.resolveCard(primary);
    if (resolved.isNotEmpty) {
      final resolvedName = resolved.first.name.trim();
      _lastResult = CardRecognitionResult.success(
        primaryName: resolvedName,
        alternatives:
            [
              if (resolvedName != primary) primary,
              ...result.alternatives,
            ].where((x) => x.trim().isNotEmpty && x != resolvedName).toList(),
        setCodeCandidates: result.setCodeCandidates,
        confidence: result.confidence * 0.7,
        allCandidates: result.allCandidates,
        collectorInfo: result.collectorInfo,
      );
      debugPrint(
        '[🔍 Resolve] Encontrou "$resolvedName" via Scryfall '
        '(${resolved.length} printings)',
      );
      return resolved;
    }

    return const [];
  }

  DeckCardItem? _tryAutoSelectEdition({
    required List<DeckCardItem> printings,
    required List<String> setCodeCandidates,
    CollectorInfo? collectorInfo,
  }) {
    if (printings.isEmpty) return null;

    if (printings.length == 1) return printings.first;

    // ═══════════════════════════════════════════════════════════════════════
    // PRIORIDADE 1: Set code extraído da parte inferior da carta (mais preciso)
    // O set code do bottom é o que realmente está impresso na carta física
    // ═══════════════════════════════════════════════════════════════════════
    if (collectorInfo?.setCode != null) {
      final bottomSet = collectorInfo!.setCode!.toUpperCase();
      final matches =
          printings
              .where((p) => p.setCode.trim().isNotEmpty)
              .where((p) => p.setCode.toUpperCase() == bottomSet)
              .toList();

      if (matches.isNotEmpty) {
        // Se temos collector number, tenta match mais preciso ainda
        if (collectorInfo.collectorNumber != null && matches.length > 1) {
          final cn = collectorInfo.collectorNumber!;
          final exact = matches.where((p) => p.collectorNumber == cn).toList();
          if (exact.isNotEmpty) {
            final foilMatched = _firstFoilMatch(exact, collectorInfo.isFoil);
            debugPrint(
              '[📌 AutoSelect] Match exato: $bottomSet #$cn'
              '${collectorInfo.isFoil == true ? " ★FOIL" : ""}',
            );
            return foilMatched ?? exact.first;
          }
        }

        debugPrint(
          '[📌 AutoSelect] Match pelo set code do bottom: $bottomSet'
          '${collectorInfo.collectorNumber != null ? " #${collectorInfo.collectorNumber}" : ""}'
          '${collectorInfo.isFoil == true ? " ★FOIL" : ""}',
        );
        return _firstFoilMatch(matches, collectorInfo.isFoil) ?? matches.first;
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIORIDADE 2: Set codes do OCR geral (menos preciso, pode ter ruído)
    // ═══════════════════════════════════════════════════════════════════════
    for (final code in setCodeCandidates) {
      final matches =
          printings
              .where((p) => p.setCode.trim().isNotEmpty)
              .where((p) => p.setCode.toUpperCase() == code.toUpperCase())
              .toList();
      if (matches.length == 1) return matches.first;
    }

    // Se não achou set code exato, auto-seleciona a primeira printing
    // (geralmente a mais recente). Não mostra modal — o usuário quer
    // adicionar a carta, não escolher edição manualmente.
    return printings.first;
  }

  DeckCardItem? _firstFoilMatch(List<DeckCardItem> cards, bool? isFoil) {
    if (isFoil == null) return null;
    for (final card in cards) {
      if (card.foil == isFoil) return card;
    }
    return null;
  }

  /// Busca manual por um nome alternativo
  Future<void> searchAlternative(String name) async {
    _setState(ScannerState.searching);
    _errorMessage = null;
    _autoSelectedCard = null;

    try {
      final exact = await _searchService.fetchPrintingsByExactName(name);
      var cards =
          exact.isNotEmpty ? exact : await _fuzzyMatcher.searchWithFuzzy(name);

      // Se fuzzy também falhou, tenta resolver via Scryfall
      if (cards.isEmpty) {
        cards = await _searchService.resolveCard(name);
      }

      if (cards.isNotEmpty) {
        _foundCards = cards;
        _autoSelectedCard = _tryAutoSelectEdition(
          printings: cards,
          setCodeCandidates: _lastResult?.setCodeCandidates ?? const [],
          collectorInfo: _lastResult?.collectorInfo,
        );
        _setState(ScannerState.found);
      } else {
        _errorMessage = 'Carta "$name" não encontrada';
        _setState(ScannerState.notFound);
      }
    } catch (e) {
      _errorMessage = 'Erro na busca: $e';
      _setState(ScannerState.error);
    }
  }

  /// Reseta o estado para nova captura
  void reset() {
    _state = ScannerState.idle;
    _lastResult = null;
    _foundCards = [];
    _autoSelectedCard = null;
    _errorMessage = null;
    _liveDetectedName = null;
    _liveConfirmCount = 0;
    notifyListeners();
  }

  void _setState(ScannerState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    super.dispose();
  }
}
