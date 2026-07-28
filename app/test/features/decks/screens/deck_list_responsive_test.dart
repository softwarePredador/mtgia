import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_list_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

class _StaticDeckProvider extends DeckProvider {
  _StaticDeckProvider(this.seededDecks) : super(apiClient: _NoopApiClient());

  final List<Deck> seededDecks;

  @override
  List<Deck> get decks => List.unmodifiable(seededDecks);

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchDecks({bool silent = false}) async {}
}

class _FailingCreateDeckProvider extends _StaticDeckProvider {
  _FailingCreateDeckProvider() : super(const <Deck>[]);

  @override
  String? get errorMessage => 'Não foi possível criar este deck agora.';

  @override
  Future<bool> createDeck({
    required String name,
    required String format,
    String? description,
    String? archetype,
    int? bracket,
    List<Map<String, dynamic>>? cards,
    bool isPublic = false,
  }) async {
    return false;
  }
}

class _SuccessfulCreateDeckProvider extends _StaticDeckProvider {
  _SuccessfulCreateDeckProvider() : super(const <Deck>[]);

  @override
  Future<bool> createDeck({
    required String name,
    required String format,
    String? description,
    String? archetype,
    int? bracket,
    List<Map<String, dynamic>>? cards,
    bool isPublic = false,
  }) async {
    return true;
  }
}

const _commanderNames = <String>[
  'Lorehold, the Historian',
  'Atraxa, Grand Unifier',
  'Jin-Gitaxias',
  'Auntie Ool, Cursewretch',
  'Talrand, Sky Summoner',
  'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki',
];

String? _commanderImageUrl(int index) {
  return switch (index) {
    0 =>
      'https://cards.scryfall.io/normal/front/7/1/71a6701f-40f1-43ef-bff5-a5907fd67cd6.jpg?1783903640',
    1 =>
      'https://api.scryfall.com/cards/4a1f905f-1d55-4d02-9d24-e58070793d3f?format=image&version=normal',
    2 =>
      'https://api.scryfall.com/cards/named?exact=Jin-Gitaxias&format=image&version=art_crop',
    3 => 'https://cdn.example.test/auntie-ool-full-card.jpg',
    4 =>
      'ttps://cards.scryfall.io/large/front/1/2/12345678-0000-0000-0000-000000000000.jpg?1700000000',
    _ => null,
  };
}

List<Deck> _decks() => List.generate(10, (index) {
  return Deck(
    id: 'deck-$index',
    name: 'Deck $index com nome suficientemente longo',
    format: index.isEven ? 'commander' : 'standard',
    isPublic: index.isEven,
    createdAt: DateTime(2026, 7, 1 + index),
    cardCount: index.isEven ? 100 : 60,
    commanderName: index < _commanderNames.length
        ? _commanderNames[index]
        : null,
    commanderImageUrl: _commanderImageUrl(index),
    colorIdentity: index == 0 ? const [] : const ['U'],
    colorIdentityKnown: index != 9,
  );
});

Future<void> _pumpDecks(
  WidgetTester tester,
  Size size, {
  List<Deck>? decks,
  DeckProvider? deckProvider,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DeckProvider>(
          create: (_) => deckProvider ?? _StaticDeckProvider(decks ?? _decks()),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider(apiClient: _NoopApiClient()),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(apiClient: _NoopApiClient()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const DeckListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide gallery is bounded and fits at least five dense columns', (
    tester,
  ) async {
    await _pumpDecks(tester, const Size(1880, 1000));

    final first = find.byKey(const Key('deck-list-row-deck-0'));
    final firstRect = tester.getRect(first);
    final cardRects = List.generate(
      10,
      (index) => tester.getRect(find.byKey(Key('deck-list-row-deck-$index'))),
    );
    final firstRowCount = cardRects
        .where((rect) => (rect.top - firstRect.top).abs() < 1)
        .length;

    expect(firstRowCount, greaterThanOrEqualTo(5));
    // Flutter distributes the remaining grid pixels between columns, so allow
    // the sub-pixel rounding around the 310 px design target.
    expect(firstRect.width, lessThanOrEqualTo(312));
    expect(firstRect.left, greaterThanOrEqualTo(140));
    expect(find.byType(SvgPicture), findsWidgets);

    Rect? referenceFrame;
    for (var index = 0; index < 6; index++) {
      final frame = find.byKey(Key('deck-gallery-art-frame-deck-$index'));
      final image = tester.widget<CachedCardImage>(
        find.byKey(Key('deck-gallery-art-deck-$index')),
      );
      final frameRect = tester.getRect(frame);
      referenceFrame ??= frameRect;

      expect(frameRect.width / frameRect.height, closeTo(488 / 680, 0.002));
      expect(frameRect.width, closeTo(referenceFrame.width, 0.01));
      expect(frameRect.height, closeTo(referenceFrame.height, 0.01));
      expect(image.fit, BoxFit.contain);

      final uri = Uri.parse(image.imageUrl!);
      if (uri.host == 'cards.scryfall.io') {
        expect(uri.pathSegments.first, 'normal');
      } else {
        expect(uri.host, 'api.scryfall.com');
        expect(uri.queryParameters['version'], 'normal');
      }
      expect(image.imageUrl, isNot(contains('art_crop')));
      expect(image.fallbackImageUrl, isNot(contains('art_crop')));
    }

    final doubleFacedImage = tester.widget<CachedCardImage>(
      find.byKey(const Key('deck-gallery-art-deck-5')),
    );
    expect(doubleFacedImage.imageUrl, contains('Fable+of+the+Mirror-Breaker'));
    expect(doubleFacedImage.imageUrl, contains('%2F%2F'));

    final fallbackFrame = tester.getRect(
      find.byKey(const Key('deck-gallery-art-frame-deck-6')),
    );
    expect(
      fallbackFrame.width / fallbackFrame.height,
      closeTo(488 / 680, 0.002),
    );
    expect(fallbackFrame.width, closeTo(referenceFrame!.width, 0.01));
    expect(fallbackFrame.height, closeTo(referenceFrame.height, 0.01));
    expect(find.byKey(const Key('deck-gallery-art-deck-6')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide gallery has a deterministic reviewed visual baseline', (
    tester,
  ) async {
    final placeholderDecks = List.generate(6, (index) {
      return Deck(
        id: 'golden-deck-$index',
        name: 'Deck visual $index',
        format: index.isEven ? 'commander' : 'standard',
        commanderName: null,
        commanderImageUrl: null,
        isPublic: index.isEven,
        createdAt: DateTime(2026, 7, 1 + index),
        cardCount: index.isEven ? 100 : 60,
        colorIdentity: index.isEven ? const ['R', 'W'] : const ['U'],
      );
    });
    await _pumpDecks(tester, const Size(1880, 1000), decks: placeholderDecks);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byKey(const Key('deck-list-row-golden-deck-0')),
      matchesGoldenFile('goldens/deck_gallery_card_1880.png'),
    );
  });

  testWidgets('compact deck list preserves gutters and single-column cards', (
    tester,
  ) async {
    await _pumpDecks(tester, const Size(390, 844));

    final firstRect = tester.getRect(
      find.byKey(const Key('deck-list-row-deck-0')),
    );
    final secondRect = tester.getRect(
      find.byKey(const Key('deck-list-row-deck-1')),
    );

    expect(firstRect.left, greaterThanOrEqualTo(14));
    expect(firstRect.right, lessThanOrEqualTo(376));
    expect(secondRect.top, greaterThan(firstRect.bottom));

    final image = tester.widget<CachedCardImage>(
      find.byKey(const Key('deck-spotlight-art-deck-0')),
    );
    expect(image.fit, BoxFit.contain);
    final uri = Uri.parse(image.imageUrl!);
    if (uri.host == 'cards.scryfall.io') {
      expect(uri.pathSegments.first, 'small');
    } else {
      expect(uri.queryParameters['version'], 'small');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone landscape deck list stays usable and exposes its create actions',
    (tester) async {
      await _pumpDecks(tester, const Size(844, 390));

      final first = find.byKey(const Key('deck-list-row-deck-0'));
      expect(first, findsOneWidget);
      final firstRect = tester.getRect(first);
      expect(firstRect.left, greaterThanOrEqualTo(0));
      expect(firstRect.right, lessThanOrEqualTo(844));

      final menu = find.byKey(const Key('deck-list-fab-menu'));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('deck-list-menu-generate')), findsOneWidget);
      expect(find.byKey(const Key('deck-list-menu-import')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty deck name stays inside modal, receives focus, and clears on edit',
    (tester) async {
      await _pumpDecks(tester, const Size(390, 844), decks: const <Deck>[]);

      final create = find.byKey(const Key('deck-list-empty-create-button'));
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deck-create-submit-button')));
      await tester.pump();

      final dialog = find.byKey(const Key('deck-create-dialog'));
      final error = find.byKey(const Key('deck-create-name-error'));
      expect(dialog, findsOneWidget);
      expect(error, findsOneWidget);
      expect(find.text('Informe o nome do deck.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      final dialogRect = tester.getRect(dialog);
      final errorRect = tester.getRect(error);
      expect(dialogRect.contains(errorRect.topLeft), isTrue);
      expect(dialogRect.contains(errorRect.bottomRight), isTrue);

      final nameField = tester.widget<TextField>(
        find.byKey(const Key('deck-create-name-field')),
      );
      expect(nameField.focusNode?.hasFocus, isTrue);

      await tester.enterText(
        find.byKey(const Key('deck-create-name-field')),
        'Azorius Control',
      );
      await tester.pump();
      expect(error, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'create validation remains scrollable at 320x568 with 200 percent text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpDecks(tester, const Size(320, 568), decks: const <Deck>[]);
      expect(tester.takeException(), isNull);

      final create = find.byKey(const Key('deck-list-empty-create-button'));
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final submit = find.byKey(const Key('deck-create-submit-button'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(submit);
      await tester.pump();
      expect(tester.takeException(), isNull);

      final error = find.byKey(const Key('deck-create-name-error'));
      expect(error, findsOneWidget);
      await tester.ensureVisible(error);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final dialogRect = tester.getRect(
        find.byKey(const Key('deck-create-dialog')),
      );
      final errorRect = tester.getRect(error);
      expect(dialogRect.contains(errorRect.topLeft), isTrue);
      expect(dialogRect.contains(errorRect.bottomRight), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('create failure stays inside modal and preserves form values', (
    tester,
  ) async {
    await _pumpDecks(
      tester,
      const Size(390, 844),
      deckProvider: _FailingCreateDeckProvider(),
    );

    await tester.tap(find.byKey(const Key('deck-list-empty-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deck-create-name-field')),
      'Izzet Spells',
    );
    await tester.enterText(
      find.byKey(const Key('deck-create-description-field')),
      'Mágicas e valor incremental',
    );
    await tester.tap(find.byKey(const Key('deck-create-public-switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('deck-create-submit-button')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('deck-create-dialog'));
    final error = find.byKey(const Key('deck-create-submit-error'));
    expect(dialog, findsOneWidget);
    expect(error, findsOneWidget);
    expect(
      find.text('Não foi possível criar este deck agora.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Izzet Spells'), findsOneWidget);
    expect(find.text('Mágicas e valor incremental'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('deck-create-format-field')),
          )
          .initialValue,
      'commander',
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('deck-create-public-switch')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('deck-create-submit-button')),
          )
          .onPressed,
      isNotNull,
    );

    final dialogRect = tester.getRect(dialog);
    final errorRect = tester.getRect(error);
    expect(dialogRect.contains(errorRect.topLeft), isTrue);
    expect(dialogRect.contains(errorRect.bottomRight), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'successful create closes modal and shows only success feedback',
    (tester) async {
      await _pumpDecks(
        tester,
        const Size(390, 844),
        deckProvider: _SuccessfulCreateDeckProvider(),
      );

      await tester.tap(find.byKey(const Key('deck-list-empty-create-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('deck-create-name-field')),
        'Selesnya Tokens',
      );
      await tester.tap(find.byKey(const Key('deck-create-submit-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deck-create-dialog')), findsNothing);
      expect(find.byKey(const Key('deck-create-name-error')), findsNothing);
      expect(find.byKey(const Key('deck-create-submit-error')), findsNothing);
      expect(find.text('Deck criado com sucesso!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
