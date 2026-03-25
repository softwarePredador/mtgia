import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/scanner/models/card_recognition_result.dart';
import 'package:manaloom/features/scanner/widgets/scanned_card_preview.dart';

DeckCardItem _sampleCard() {
  return DeckCardItem(
    id: 'card-1',
    name: 'Lightning Bolt',
    manaCost: '{R}',
    typeLine: 'Instant',
    oracleText: 'Deal 3 damage to any target.',
    setCode: 'lea',
    setName: 'Limited Edition Alpha',
    rarity: 'rare',
    quantity: 1,
    isCommander: false,
    foil: true,
    condition: CardCondition.nm,
  );
}

CardRecognitionResult _sampleResult() {
  return CardRecognitionResult.success(
    primaryName: 'Lightning Bolt',
    confidence: 92,
    allCandidates: [
      CardNameCandidate(
        text: 'Lightning Bolt',
        rawText: 'Lightning Bolt',
        score: 0.92,
        boundingBox: Rect.zero,
      ),
    ],
  );
}

void main() {
  testWidgets('scanner preview renders primary card actions and info', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: ScannedCardPreview(
            result: _sampleResult(),
            foundCards: [_sampleCard()],
            onCardSelected: (_) {},
            onAlternativeSelected: (_) {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lightning Bolt'), findsOneWidget);
    expect(find.text('Instant'), findsOneWidget);
    expect(find.text('Foil'), findsOneWidget);
    expect(find.text('NM'), findsOneWidget);
    expect(find.text('LEA'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
  });

  testWidgets('card not found widget keeps manual recovery path visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CardNotFoundWidget(
            detectedName: 'Lighning Bolt',
            errorMessage: 'Carta não encontrada',
            onRetry: () {},
            onManualSearch: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carta não encontrada'), findsOneWidget);
    expect(find.text('Detectado: "Lighning Bolt"'), findsOneWidget);
    expect(find.text('Tentar Novamente'), findsOneWidget);
    expect(find.text('Digite o nome correto'), findsOneWidget);
  });
}
