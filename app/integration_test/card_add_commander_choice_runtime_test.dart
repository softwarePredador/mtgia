import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/cards/screens/card_search_screen.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

class _FixedCardProvider extends CardProvider {
  _FixedCardProvider(this._results);

  final List<DeckCardItem> _results;

  @override
  List<DeckCardItem> get searchResults => _results;

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => false;
}

class _RuntimeDeckApiClient extends ApiClient {
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/decks/runtime-commander-choice') {
      return ApiResponse(200, _deckDetailsJson());
    }
    return ApiResponse(404, {'error': 'not found'});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/decks/runtime-commander-choice/cards') {
      postBodies.add(body);
      return ApiResponse(200, {'ok': true});
    }
    return ApiResponse(404, {'error': 'not found'});
  }
}

DeckCardItem _loreholdCard() {
  return DeckCardItem(
    id: 'lorehold-runtime-card',
    name: 'Lorehold, the Historian',
    manaCost: '{3}{R}{W}',
    typeLine: 'Legendary Creature — Elder Dragon',
    oracleText: 'Flying, haste. Can be your commander.',
    setCode: 'psos',
    setName: 'Secrets of Strixhaven Promos',
    setReleaseDate: '2026-04-24',
    rarity: 'mythic',
    collectorNumber: '201p',
    foil: false,
    quantity: 1,
    isCommander: false,
    colors: const ['R', 'W'],
    colorIdentity: const ['R', 'W'],
  );
}

Map<String, dynamic> _deckDetailsJson() {
  return {
    'id': 'runtime-commander-choice',
    'name': 'Runtime Commander Choice',
    'format': 'commander',
    'description': null,
    'is_public': false,
    'created_at': '2026-05-21T10:00:00.000Z',
    'color_identity': <String>[],
    'stats': {'total_cards': 0},
    'commander': <Map<String, dynamic>>[],
    'main_board': <String, List<Map<String, dynamic>>>{},
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('add-card modal exposes commander choice for eligible card', (
    tester,
  ) async {
    final card = _loreholdCard();
    final apiClient = _RuntimeDeckApiClient();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CardProvider>(
            create: (_) => _FixedCardProvider([card]),
          ),
          ChangeNotifierProvider<DeckProvider>(
            create: (_) => DeckProvider(apiClient: apiClient),
          ),
        ],
        child: MaterialApp(
          title: 'ManaLoom Commander Choice Runtime',
          theme: AppTheme.darkTheme,
          home: const CardSearchScreen(deckId: 'runtime-commander-choice'),
        ),
      ),
    );

    await pumpUntilFound(tester, find.text('Lorehold, the Historian'));
    await tester.tap(find.byTooltip('Adicionar'));
    await tester.pumpAndSettle();
    await pumpUntilFound(
      tester,
      find.byKey(const Key('card-search-commander-choice-card')),
    );

    expect(find.text('Definir como comandante'), findsOneWidget);
    expect(find.text('Adicionar como carta comum'), findsOneWidget);
    expect(
      find.byKey(const Key('card-search-add-quantity-stepper')),
      findsOneWidget,
    );
    await captureVisualProof(
      binding,
      tester,
      'card_add_commander_choice_modal',
    );

    await tester.tap(find.text('Adicionar como carta comum'));
    await tester.pumpAndSettle();
    final confirmButton = find.byKey(
      const Key('card-search-add-confirm-lorehold-runtime-card'),
    );
    await tester.ensureVisible(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(apiClient.postBodies, isNotEmpty);
    expect(apiClient.postBodies.single['is_commander'], isFalse);
    expectNoRawTechnicalErrorText(tester);
  });
}
