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
  }) : _exactByName = exactByName,
       _searchByName = searchByName,
       _resolveByName = resolveByName;

  final Map<String, List<DeckCardItem>> _exactByName;
  final Map<String, List<DeckCardItem>> _searchByName;
  final Map<String, List<DeckCardItem>> _resolveByName;
  final List<String> exactCalls = [];
  final List<String> searchCalls = [];
  final List<String> resolveCalls = [];

  @override
  Future<List<DeckCardItem>> fetchPrintingsByExactName(
    String name, {
    int limit = 50,
  }) async {
    exactCalls.add(name);
    return _exactByName[name] ?? const [];
  }

  @override
  Future<List<DeckCardItem>> searchByName(
    String name, {
    int limit = 50,
    int page = 1,
  }) async {
    searchCalls.add(name);
    return _searchByName[name] ?? const [];
  }

  @override
  Future<List<DeckCardItem>> resolveCard(String name) async {
    resolveCalls.add(name);
    return _resolveByName[name] ?? const [];
  }
}

DeckCardItem _card({
  required String id,
  required String name,
  required String setCode,
  String? collectorNumber,
  bool? foil,
}) {
  return DeckCardItem(
    id: id,
    name: name,
    typeLine: 'Instant',
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
      expect(provider.errorMessage, 'Nome nao reconhecido');
      expect(provider.foundCards, isEmpty);
      expect(searchService.exactCalls, isEmpty);
      expect(searchService.resolveCalls, isEmpty);
    });
  });
}
