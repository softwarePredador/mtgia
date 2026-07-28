import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
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

  String? createdName;
  String? createdFormat;
  String? createdDescription;
  List<Map<String, dynamic>>? createdCards;
  bool? createdIsPublic;

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
    createdName = name;
    createdFormat = format;
    createdDescription = description;
    createdCards = cards;
    createdIsPublic = isPublic;
    return true;
  }
}

class _CommanderCardProvider extends CardProvider {
  _CommanderCardProvider(this.seededCards, {this.shouldFail = false})
    : super(apiClient: _NoopApiClient());

  final List<DeckCardItem> seededCards;
  final bool shouldFail;
  List<DeckCardItem> _results = const [];
  bool _loading = false;
  String? _error;
  String? lastQuery;
  String? lastFormat;
  int searchCount = 0;

  @override
  List<DeckCardItem> get searchResults => List.unmodifiable(_results);

  @override
  bool get isLoading => _loading;

  @override
  String? get errorMessage => _error;

  @override
  Future<void> searchCommanderCandidates(
    String query, {
    required String format,
  }) async {
    lastQuery = query;
    lastFormat = format;
    searchCount += 1;
    _loading = true;
    _error = null;
    _results = const [];
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    _loading = false;
    if (shouldFail) {
      _error = 'Não foi possível buscar cartas agora.';
    } else {
      _results = List.of(seededCards);
    }
    notifyListeners();
  }

  @override
  void clearSearch() {
    _results = const [];
    _loading = false;
    _error = null;
    lastQuery = null;
    lastFormat = null;
    notifyListeners();
  }
}

final _atraxa = DeckCardItem(
  id: 'card-atraxa',
  name: 'Atraxa, Grand Unifier',
  manaCost: '{3}{G}{W}{U}{B}',
  typeLine: 'Legendary Creature — Phyrexian Angel',
  oracleText: 'Flying, vigilance, deathtouch, lifelink',
  colors: const ['W', 'U', 'B', 'G'],
  colorIdentity: const ['W', 'U', 'B', 'G'],
  setCode: 'one',
  rarity: 'mythic',
  quantity: 1,
  isCommander: false,
);

final _solRing = DeckCardItem(
  id: 'card-sol-ring',
  name: 'Sol Ring',
  manaCost: '{1}',
  typeLine: 'Artifact',
  oracleText: '{T}: Add {C}{C}.',
  colorIdentity: const [],
  setCode: 'cmm',
  rarity: 'uncommon',
  quantity: 1,
  isCommander: false,
);

final _brawlPlaneswalker = DeckCardItem(
  id: 'card-teferi',
  name: 'Teferi, Hero of Dominaria',
  manaCost: '{3}{W}{U}',
  typeLine: 'Legendary Planeswalker — Teferi',
  colorIdentity: const ['W', 'U'],
  setCode: 'dom',
  rarity: 'mythic',
  quantity: 1,
  isCommander: false,
);

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
  CardProvider? cardProvider,
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
        ChangeNotifierProvider<CardProvider>(
          create: (_) => cardProvider ?? _CommanderCardProvider(const []),
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

Future<void> _openCreateDialog(WidgetTester tester) async {
  final create = find.byKey(const Key('deck-list-empty-create-button'));
  await tester.ensureVisible(create);
  await tester.tap(create);
  await tester.pumpAndSettle();
}

Future<void> _selectCommander(WidgetTester tester, DeckCardItem card) async {
  await tester.tap(find.byKey(const Key('deck-create-commander-select')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('deck-create-commander-search-field')),
    card.name.substring(0, 3),
  );
  await tester.pump(const Duration(milliseconds: 321));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('deck-create-commander-result-${card.id}')));
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
    'Commander and Brawl expose commander selection while regular formats hide it',
    (tester) async {
      await _pumpDecks(tester, const Size(390, 844), decks: const <Deck>[]);
      await _openCreateDialog(tester);

      expect(
        find.byKey(const Key('deck-create-commander-section')),
        findsOneWidget,
      );

      final format = find.byKey(const Key('deck-create-format-field'));
      await tester.tap(format);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standard').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deck-create-commander-section')),
        findsNothing,
      );

      await tester.tap(format);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brawl').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deck-create-commander-section')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('commander picker shows only eligible cards and keeps focus', (
    tester,
  ) async {
    final cards = _CommanderCardProvider([_solRing, _atraxa]);
    await _pumpDecks(
      tester,
      const Size(390, 844),
      decks: const <Deck>[],
      cardProvider: cards,
    );
    await _openCreateDialog(tester);

    await tester.tap(find.byKey(const Key('deck-create-commander-select')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('commander-picker-dialog')), findsOneWidget);
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('deck-create-commander-search-field')),
    );
    expect(searchField.focusNode?.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const Key('deck-create-commander-search-field')),
      'At',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(cards.searchCount, 0);

    await tester.enterText(
      find.byKey(const Key('deck-create-commander-search-field')),
      'Atr',
    );
    await tester.pump(const Duration(milliseconds: 321));
    await tester.pumpAndSettle();
    expect(cards.searchCount, 1);
    expect(
      find.byKey(const Key('deck-create-commander-results')),
      findsOneWidget,
    );
    final resultWidgets = tester.widgetList<InkWell>(
      find.descendant(
        of: find.byKey(const Key('deck-create-commander-results')),
        matching: find.byType(InkWell),
      ),
    );
    expect(
      resultWidgets.first.key,
      const Key('deck-create-commander-result-card-atraxa'),
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('deck-create-commander-result-card-atraxa')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      find.byKey(const Key('deck-create-commander-result-card-sol-ring')),
      findsNothing,
    );
    expect(find.text('Não elegível como comandante'), findsNothing);
    expect(cards.lastFormat, 'commander');

    final result = find.byKey(
      const Key('deck-create-commander-result-card-atraxa'),
    );
    await tester.ensureVisible(result);
    await tester.pumpAndSettle();
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('deck-create-commander-selected')),
      findsOneWidget,
    );
    expect(find.text('Atraxa, Grand Unifier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('commander picker keeps search failures and retry inside modal', (
    tester,
  ) async {
    final cards = _CommanderCardProvider(const [], shouldFail: true);
    await _pumpDecks(
      tester,
      const Size(390, 844),
      decks: const <Deck>[],
      cardProvider: cards,
    );
    await _openCreateDialog(tester);
    await tester.tap(find.byKey(const Key('deck-create-commander-select')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deck-create-commander-search-field')),
      'Atr',
    );
    await tester.pump(const Duration(milliseconds: 321));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('deck-create-commander-error')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(cards.searchCount, 1);

    await tester.tap(find.byKey(const Key('commander-picker-retry')));
    await tester.pumpAndSettle();
    expect(cards.searchCount, 2);
    expect(find.byKey(const Key('commander-picker-dialog')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Brawl accepts a legendary planeswalker candidate', (
    tester,
  ) async {
    final cards = _CommanderCardProvider([_brawlPlaneswalker]);
    await _pumpDecks(
      tester,
      const Size(390, 844),
      decks: const <Deck>[],
      cardProvider: cards,
    );
    await _openCreateDialog(tester);
    final format = find.byKey(const Key('deck-create-format-field'));
    await tester.tap(format);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brawl').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deck-create-commander-select')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('deck-create-commander-search-field')),
      'Tef',
    );
    await tester.pump(const Duration(milliseconds: 321));
    await tester.pumpAndSettle();
    expect(cards.lastFormat, 'brawl');
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('deck-create-commander-result-card-teferi')),
          )
          .onTap,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected commander is sent atomically with deck creation', (
    tester,
  ) async {
    final decks = _SuccessfulCreateDeckProvider();
    await _pumpDecks(
      tester,
      const Size(390, 844),
      deckProvider: decks,
      cardProvider: _CommanderCardProvider([_atraxa]),
    );
    await _openCreateDialog(tester);
    await _selectCommander(tester, _atraxa);
    await tester.enterText(
      find.byKey(const Key('deck-create-name-field')),
      'Atraxa Value',
    );
    final submit = find.byKey(const Key('deck-create-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(decks.createdName, 'Atraxa Value');
    expect(decks.createdFormat, 'commander');
    expect(decks.createdCards, [
      {'card_id': 'card-atraxa', 'quantity': 1, 'is_commander': true},
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing format clears commander and omits it from payload', (
    tester,
  ) async {
    final decks = _SuccessfulCreateDeckProvider();
    await _pumpDecks(
      tester,
      const Size(390, 844),
      deckProvider: decks,
      cardProvider: _CommanderCardProvider([_atraxa]),
    );
    await _openCreateDialog(tester);
    await _selectCommander(tester, _atraxa);
    final format = find.byKey(const Key('deck-create-format-field'));
    await tester.ensureVisible(format);
    await tester.tap(format);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('deck-create-commander-selected')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('deck-create-name-field')),
      'Standard Midrange',
    );
    final submit = find.byKey(const Key('deck-create-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(decks.createdFormat, 'standard');
    expect(decks.createdCards, isNull);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'commander picker and selected state fit 320x568 at 200 percent text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpDecks(
        tester,
        const Size(320, 568),
        decks: const <Deck>[],
        cardProvider: _CommanderCardProvider([_atraxa]),
      );
      await _openCreateDialog(tester);

      final commanderSelector = find.byKey(
        const Key('deck-create-commander-select'),
      );
      await Scrollable.ensureVisible(
        tester.element(commanderSelector),
        alignment: 0.45,
      );
      await tester.pumpAndSettle();
      await tester.tap(commanderSelector);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const Key('deck-create-commander-search-field')),
        'Atr',
      );
      await tester.pump(const Duration(milliseconds: 321));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final compactResult = find.byKey(
        const Key('deck-create-commander-result-card-atraxa'),
      );
      await tester.drag(
        find.byKey(const Key('deck-create-commander-results')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.tap(compactResult);
      await tester.pumpAndSettle();

      final selected = find.byKey(const Key('deck-create-commander-selected'));
      expect(selected, findsOneWidget);
      await tester.ensureVisible(selected);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deck-create-commander-clear')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('deck-create-commander-change')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('create failure stays inside modal and preserves form values', (
    tester,
  ) async {
    await _pumpDecks(
      tester,
      const Size(390, 844),
      deckProvider: _FailingCreateDeckProvider(),
      cardProvider: _CommanderCardProvider([_atraxa]),
    );

    await _openCreateDialog(tester);
    await _selectCommander(tester, _atraxa);
    await tester.enterText(
      find.byKey(const Key('deck-create-name-field')),
      'Izzet Spells',
    );
    await tester.enterText(
      find.byKey(const Key('deck-create-description-field')),
      'Mágicas e valor incremental',
    );
    final publicSwitch = find.byKey(const Key('deck-create-public-switch'));
    await Scrollable.ensureVisible(
      tester.element(publicSwitch),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(publicSwitch);
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
      find.byKey(const Key('deck-create-commander-selected')),
      findsOneWidget,
    );
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
