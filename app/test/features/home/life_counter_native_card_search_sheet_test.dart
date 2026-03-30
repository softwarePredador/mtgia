import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_card_search_sheet.dart';

class _FakeCardProvider extends CardProvider {
  _FakeCardProvider();

  String? lastQuery;
  int clearCount = 0;

  @override
  Future<void> searchCards(String query) async {
    lastQuery = query.trim();
    _searchResultsProxy = [
      DeckCardItem(
        id: 'sol-ring',
        name: 'Sol Ring',
        manaCost: '{1}',
        typeLine: 'Artifact',
        oracleText: 'Tap: Add {C}{C}.',
        setCode: 'cmm',
        rarity: 'uncommon',
        quantity: 1,
        isCommander: false,
      ),
    ];
    _isLoadingProxy = false;
    _errorMessageProxy = null;
    notifyListeners();
  }

  @override
  void clearSearch() {
    clearCount += 1;
    _searchResultsProxy = [];
    _isLoadingProxy = false;
    _errorMessageProxy = null;
    notifyListeners();
  }

  List<DeckCardItem> _searchResultsProxy = [];
  bool _isLoadingProxy = false;
  String? _errorMessageProxy;

  @override
  List<DeckCardItem> get searchResults => _searchResultsProxy;

  @override
  bool get isLoading => _isLoadingProxy;

  @override
  String? get errorMessage => _errorMessageProxy;
}

void main() {
  testWidgets('runs search from suggestion and shows results', (tester) async {
    final fakeProvider = _FakeCardProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLifeCounterNativeCardSearchSheet(
                      context,
                      providerFactory: () => fakeProvider,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SOL RING'));
    await tester.pumpAndSettle();

    expect(fakeProvider.lastQuery, 'Sol Ring');
    expect(
      find.byKey(const Key('life-counter-native-card-search-results')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('life-counter-native-card-search-results')),
        matching: find.text('Sol Ring'),
      ),
      findsOneWidget,
    );
    expect(find.text('Artifact  •  CMM'), findsOneWidget);
  });

  testWidgets('clears results when query becomes too short', (tester) async {
    final fakeProvider = _FakeCardProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLifeCounterNativeCardSearchSheet(
                      context,
                      providerFactory: () => fakeProvider,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('life-counter-native-card-search-input')),
      'Sol',
    );
    await tester.pumpAndSettle();
    expect(fakeProvider.lastQuery, 'Sol');

    await tester.enterText(
      find.byKey(const Key('life-counter-native-card-search-input')),
      'So',
    );
    await tester.pumpAndSettle();

    expect(fakeProvider.clearCount, greaterThan(0));
    expect(
      find.byKey(const Key('life-counter-native-card-search-results')),
      findsNothing,
    );
  });
}
