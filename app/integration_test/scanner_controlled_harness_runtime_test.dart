import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/scanner/providers/scanner_provider.dart';
import 'package:manaloom/features/scanner/services/scanner_card_search_service.dart';
import 'package:manaloom/features/scanner/services/scanner_ocr_parser.dart';

class _HarnessSearchService extends ScannerCardSearchService {
  final List<String> exactCalls = [];

  @override
  Future<List<DeckCardItem>> fetchPrintingsByExactName(
    String name, {
    int limit = 50,
  }) async {
    exactCalls.add(name);
    if (name != 'Lightning Bolt') return const [];

    return [
      DeckCardItem(
        id: 'blb-nonfoil',
        name: 'Lightning Bolt',
        manaCost: '{R}',
        typeLine: 'Instant',
        oracleText: 'Deal 3 damage to any target.',
        colors: const ['R'],
        colorIdentity: const ['R'],
        setCode: 'blb',
        setName: 'Bloomburrow',
        rarity: 'rare',
        quantity: 1,
        isCommander: false,
        collectorNumber: '157',
        foil: false,
      ),
      DeckCardItem(
        id: 'blb-foil',
        name: 'Lightning Bolt',
        manaCost: '{R}',
        typeLine: 'Instant',
        oracleText: 'Deal 3 damage to any target.',
        colors: const ['R'],
        colorIdentity: const ['R'],
        setCode: 'blb',
        setName: 'Bloomburrow',
        rarity: 'rare',
        quantity: 1,
        isCommander: false,
        collectorNumber: '157',
        foil: true,
      ),
    ];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scanner controlled harness resolves OCR text above camera layer', (
    tester,
  ) async {
    final ocrResult = ScannerOcrParser.parseControlledText('''
Lightning Bolt
Instant
157/274 ★ BLB ★ EN
''');
    final searchService = _HarnessSearchService();
    final provider = ScannerProvider(searchService: searchService);

    await provider.processRecognitionResult(ocrResult);

    expect(ocrResult.success, isTrue);
    expect(ocrResult.collectorInfo?.setCode, 'BLB');
    expect(ocrResult.collectorInfo?.isFoil, isTrue);
    expect(provider.state, ScannerState.found);
    expect(provider.autoSelectedCard?.id, 'blb-foil');
    expect(searchService.exactCalls, ['Lightning Bolt']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text(
            'scanner harness: ${provider.autoSelectedCard?.name} ${provider.autoSelectedCard?.setCode.toUpperCase()} foil=${provider.autoSelectedCard?.foil}',
          ),
        ),
      ),
    );

    expect(
      find.textContaining('scanner harness: Lightning Bolt BLB foil=true'),
      findsOneWidget,
    );
  });
}
