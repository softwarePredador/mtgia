import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/scanner/models/card_recognition_result.dart';
import 'package:manaloom/features/scanner/providers/scanner_provider.dart';
import 'package:manaloom/features/scanner/services/scanner_card_search_service.dart';

class _FakeScannerCardSearchService extends ScannerCardSearchService {
  _FakeScannerCardSearchService({
    Map<String, List<DeckCardItem>> exactByName = const {},
    Map<String, List<DeckCardItem>> searchByName = const {},
    Map<String, List<DeckCardItem>> resolveByName = const {},
    Map<String, List<DeckCardItem>> resolveTokenByName = const {},
  }) : _exactByName = exactByName,
       _searchByName = searchByName,
       _resolveByName = resolveByName,
       _resolveTokenByName = resolveTokenByName;

  final Map<String, List<DeckCardItem>> _exactByName;
  final Map<String, List<DeckCardItem>> _searchByName;
  final Map<String, List<DeckCardItem>> _resolveByName;
  final Map<String, List<DeckCardItem>> _resolveTokenByName;
  final List<String> exactCalls = [];
  final List<String> searchCalls = [];
  final List<String> resolveCalls = [];
  final List<String> resolveTokenCalls = [];

  @override
  Future<List<DeckCardItem>> fetchPrintingsByExactName(
    String name, {
    int limit = 50,
    bool dedupe = false,
  }) async {
    exactCalls.add(name);
    return _exactByName[name] ?? const [];
  }

  @override
  Future<List<DeckCardItem>> searchByName(
    String name, {
    int limit = 50,
    int page = 1,
    bool dedupe = true,
    bool includeTokens = false,
  }) async {
    searchCalls.add(name);
    return _searchByName[name] ?? const [];
  }

  @override
  Future<List<DeckCardItem>> resolveCard(String name) async {
    resolveCalls.add(name);
    return _resolveByName[name] ?? const [];
  }

  @override
  Future<List<DeckCardItem>> resolveToken(String name) async {
    resolveTokenCalls.add(name);
    return _resolveTokenByName[name] ?? const [];
  }
}

DeckCardItem _card({
  required String id,
  required String name,
  required String setCode,
  String typeLine = 'Instant',
  String? collectorNumber,
  bool? foil,
}) {
  return DeckCardItem(
    id: id,
    name: name,
    typeLine: typeLine,
    colors: const ['R'],
    colorIdentity: const ['R'],
    setCode: setCode,
    rarity: 'rare',
    quantity: 1,
    isCommander: false,
    collectorNumber: collectorNumber,
    foil: foil,
  );
}

void main() {
  group('ScannerProvider controlled OCR harness', () {
    test(
      'auto-selects exact printing by collector number, set code and foil',
      () async {
        final searchService = _FakeScannerCardSearchService(
          exactByName: {
            'Lightning Bolt': [
              _card(
                id: 'blb-nonfoil',
                name: 'Lightning Bolt',
                setCode: 'blb',
                collectorNumber: '157',
                foil: false,
              ),
              _card(
                id: 'blb-foil',
                name: 'Lightning Bolt',
                setCode: 'blb',
                collectorNumber: '157',
                foil: true,
              ),
              _card(
                id: 'cmm-foil',
                name: 'Lightning Bolt',
                setCode: 'cmm',
                collectorNumber: '300',
                foil: true,
              ),
            ],
          },
        );
        final provider = ScannerProvider(searchService: searchService);

        await provider.processRecognitionResult(
          CardRecognitionResult.success(
            primaryName: 'Lightning Bolt',
            setCodeCandidates: const ['BLB'],
            confidence: 93,
            collectorInfo: const CollectorInfo(
              collectorNumber: '157',
              totalInSet: '274',
              setCode: 'BLB',
              isFoil: true,
              language: 'EN',
            ),
          ),
        );

        expect(provider.state, ScannerState.found);
        expect(provider.foundCards, hasLength(3));
        expect(provider.autoSelectedCard?.id, 'blb-foil');
        expect(searchService.exactCalls, ['Lightning Bolt']);
      },
    );

    test(
      'falls back to resolveCard after local exact and fuzzy search miss',
      () async {
        final searchService = _FakeScannerCardSearchService(
          resolveByName: {
            'Lighning Bolt': [
              _card(
                id: 'resolved-1',
                name: 'Lightning Bolt',
                setCode: 'lea',
                collectorNumber: '161',
              ),
            ],
          },
        );
        final provider = ScannerProvider(searchService: searchService);

        await provider.processRecognitionResult(
          CardRecognitionResult.success(
            primaryName: 'Lighning Bolt',
            confidence: 58,
          ),
        );

        expect(provider.state, ScannerState.found);
        expect(provider.lastResult?.primaryName, 'Lightning Bolt');
        expect(provider.foundCards.single.id, 'resolved-1');
        expect(searchService.resolveCalls, ['Lighning Bolt']);
      },
    );

    test('keeps empty OCR result in notFound state without throwing', () async {
      final searchService = _FakeScannerCardSearchService();
      final provider = ScannerProvider(searchService: searchService);

      await provider.processRecognitionResult(
        CardRecognitionResult.failed('Nome nao reconhecido'),
      );

      expect(provider.state, ScannerState.notFound);
      expect(provider.errorMessage, contains('Melhore a iluminação'));
      expect(provider.errorMessage, isNot(contains('Nome nao reconhecido')));
      expect(provider.foundCards, isEmpty);
      expect(searchService.exactCalls, isEmpty);
      expect(searchService.resolveCalls, isEmpty);
    });

    test('prioritizes token cards when OCR bottom indicates token', () async {
      final searchService = _FakeScannerCardSearchService(
        exactByName: {
          'Phyrexian Horror': [
            _card(
              id: 'regular-card',
              name: 'Phyrexian Horror',
              setCode: 'abc',
              typeLine: 'Creature — Phyrexian Horror',
            ),
          ],
        },
        searchByName: {
          'Phyrexian Horror': [
            _card(
              id: 'token-onc',
              name: 'Phyrexian Horror',
              setCode: 'onc',
              typeLine: 'Token Artifact Creature — Phyrexian Horror',
              collectorNumber: '020',
            ),
            _card(
              id: 'regular-card',
              name: 'Phyrexian Horror',
              setCode: 'abc',
              typeLine: 'Creature — Phyrexian Horror',
            ),
          ],
        },
      );
      final provider = ScannerProvider(searchService: searchService);

      await provider.processRecognitionResult(
        CardRecognitionResult.success(
          primaryName: 'Phyrexian Horror',
          confidence: 92,
          collectorInfo: const CollectorInfo(
            collectorNumber: '020',
            setCode: 'ONC',
            language: 'EN',
            isToken: true,
          ),
        ),
      );

      expect(provider.state, ScannerState.found);
      expect(provider.autoSelectedCard?.id, 'token-onc');
      expect(provider.foundCards.single.id, 'token-onc');
      expect(searchService.searchCalls, ['Phyrexian Horror']);
      expect(searchService.exactCalls, isEmpty);
    });

    test('resolves missing token through token-specific fallback', () async {
      final searchService = _FakeScannerCardSearchService(
        resolveTokenByName: {
          'Phyrexian Horror': [
            _card(
              id: 'token-scryfall',
              name: 'Phyrexian Horror',
              setCode: 'tmoc',
              typeLine: 'Token Artifact Creature — Phyrexian Horror',
              collectorNumber: '40',
            ),
          ],
        },
      );
      final provider = ScannerProvider(searchService: searchService);

      await provider.processRecognitionResult(
        CardRecognitionResult.success(
          primaryName: 'Phyrexian Horror',
          confidence: 92,
          collectorInfo: const CollectorInfo(isToken: true),
        ),
      );

      expect(provider.state, ScannerState.found);
      expect(provider.foundCards.single.id, 'token-scryfall');
      expect(searchService.resolveTokenCalls, ['Phyrexian Horror']);
      expect(searchService.exactCalls, isEmpty);
      expect(searchService.resolveCalls, isEmpty);
    });

    test(
      'does not fallback to fuzzy normal card when token lookup misses',
      () async {
        final searchService = _FakeScannerCardSearchService(
          exactByName: {
            'Phyrexian Horror': [
              _card(
                id: 'regular-card',
                name: 'Phyrexian Horror',
                setCode: 'abc',
                typeLine: 'Creature — Phyrexian Horror',
              ),
            ],
          },
          resolveByName: {
            'Phyrexian Horror': [
              _card(
                id: 'wrong-fuzzy',
                name: 'Phyrexian Censor',
                setCode: 'one',
                typeLine: 'Creature — Phyrexian Wizard',
              ),
            ],
          },
        );
        final provider = ScannerProvider(searchService: searchService);

        await provider.processRecognitionResult(
          CardRecognitionResult.success(
            primaryName: 'Phyrexian Horror',
            confidence: 92,
            collectorInfo: const CollectorInfo(isToken: true),
          ),
        );

        expect(provider.state, ScannerState.notFound);
        expect(provider.foundCards, isEmpty);
        expect(searchService.searchCalls, ['Phyrexian Horror']);
        expect(searchService.resolveTokenCalls, ['Phyrexian Horror']);
        expect(searchService.exactCalls, isEmpty);
        expect(searchService.resolveCalls, isEmpty);
      },
    );

    test('groups close OCR variants as the same live detection', () {
      expect(
        ScannerProvider.isSameStableLiveNameForTest(
          'PuYREXIAN HORROR',
          'Phyrexian Horror',
        ),
        isTrue,
      );
      expect(
        ScannerProvider.isSameStableLiveNameForTest(
          'Phyrexian',
          'Phyrexian Horror',
        ),
        isFalse,
      );
      expect(
        ScannerProvider.isSameStableLiveNameForTest(
          'Sedex',
          'Phyrexian Horror',
        ),
        isFalse,
      );
    });
  });
}
