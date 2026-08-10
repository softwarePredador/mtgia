import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/auth/models/user.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/community/providers/community_provider.dart';
import 'package:manaloom/features/community/screens/community_deck_detail_screen.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('keeps a padded single-column composition at 390px', (
    tester,
  ) async {
    await _pumpDetail(tester, const Size(390, 844));

    expect(
      find.byKey(const Key('community-deck-mobile-stack')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('community-deck-desktop-panes')), findsNothing);

    final header = tester.getRect(
      find.byKey(const Key('community-deck-header')),
    );
    final copyButton = tester.getSize(
      find.byKey(const Key('community-deck-copy-button')),
    );
    expect(header.left, greaterThanOrEqualTo(12));
    expect(header.right, lessThanOrEqualTo(378));
    expect(copyButton.width, greaterThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses main content and a 360px inspector at 1280px', (
    tester,
  ) async {
    await _pumpDetail(tester, const Size(1280, 900));

    expect(
      find.byKey(const Key('community-deck-desktop-panes')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('community-deck-mobile-stack')), findsNothing);

    final panes = tester.getRect(
      find.byKey(const Key('community-deck-desktop-panes')),
    );
    final feedback = tester.getRect(
      find.byKey(const Key('community-deck-feedback-panel')),
    );
    final copyButton = tester.getSize(
      find.byKey(const Key('community-deck-copy-button')),
    );
    expect(panes.left, greaterThanOrEqualTo(20));
    expect(panes.right, lessThanOrEqualTo(1260));
    expect(feedback.width, closeTo(AppTheme.inspectorWidth, 0.1));
    expect(copyButton.width, lessThan(AppTheme.inspectorWidth));
    expect(tester.takeException(), isNull);
  });

  testWidgets('comment field validates before posting community feedback', (
    tester,
  ) async {
    final api = _CommunityDetailApiFixture();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => CommunityProvider(apiClient: api),
          ),
          ChangeNotifierProvider(
            create: (_) => DeckProvider(apiClient: _DeckApiFixture()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CommunityDeckDetailScreen(deckId: 'deck-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('community-deck-comment-field')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('community-deck-feedback-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('community-deck-comment-field')),
      findsOneWidget,
    );
    expect(api.commentPosts, isEmpty);

    ElevatedButton submitButton() {
      return tester.widget<ElevatedButton>(
        find.byKey(const Key('community-deck-comment-submit-button')),
      );
    }

    expect(submitButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('community-deck-comment-field')),
      'ok',
    );
    await tester.pumpAndSettle();
    expect(submitButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('community-deck-comment-field')),
      'Boa sugestão para testar na mesa.',
    );
    await tester.pumpAndSettle();
    expect(submitButton().onPressed, isNotNull);

    await tester.tap(
      find.byKey(const Key('community-deck-comment-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(api.commentPosts, ['Boa sugestão para testar na mesa.']);
    expect(find.text('Comentário publicado.'), findsOneWidget);
  });

  testWidgets('comment can anchor its public context to a deck card', (
    tester,
  ) async {
    final api = _CommunityDetailApiFixture();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _FakeAuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => CommunityProvider(apiClient: api),
          ),
          ChangeNotifierProvider(
            create: (_) => DeckProvider(apiClient: _DeckApiFixture()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const CommunityDeckDetailScreen(deckId: 'deck-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final contextField = find.byKey(
      const Key('community-deck-comment-context'),
    );
    await tester.ensureVisible(contextField);
    await tester.tap(contextField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carta · Arcane Signet').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('community-deck-comment-field')),
      'Vale testar esta peça na curva dois.',
    );
    await tester.pumpAndSettle();
    final submit = find.byKey(
      const Key('community-deck-comment-submit-button'),
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(api.commentPosts, [
      '[Contexto: Carta · Arcane Signet] '
          'Vale testar esta peça na curva dois.',
    ]);
  });

  testWidgets('shows exact printing identity for public deck cards', (
    tester,
  ) async {
    await _pumpDetail(tester, const Size(390, 844));

    final card = find.byKey(const Key('community-deck-card-card-1'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();

    expect(card, findsOneWidget);
    expect(find.text('TST #001'), findsOneWidget);
    expect(find.text('Non-foil'), findsNothing);
    expect(find.textContaining('Test Set'), findsOneWidget);
    expect(find.text('Arte de referência'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetail(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => _FakeAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CommunityProvider(apiClient: _CommunityDetailApiFixture()),
        ),
        ChangeNotifierProvider(
          create: (_) => DeckProvider(apiClient: _DeckApiFixture()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CommunityDeckDetailScreen(deckId: 'deck-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CommunityDetailApiFixture extends ApiClient {
  final commentPosts = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/community/decks/deck-1') {
      return ApiResponse(200, {
        'id': 'deck-1',
        'name': 'Deck público',
        'format': 'commander',
        'description': 'Lista compartilhada para teste.',
        'owner_username': 'player_one',
        'stats': {'total_cards': 100},
        'commander': const [],
        'main_board': const <String, dynamic>{
          'Artifact': [
            {
              'id': 'card-1',
              'oracle_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              'name': 'Arcane Signet',
              'quantity': 1,
              'is_commander': false,
              'type_line': 'Artifact',
              'mana_cost': '{2}',
              'image_url':
                  'https://cards.scryfall.io/normal/front/a/a/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg',
              'set_code': 'tst',
              'collector_number': '001',
              'set_name': 'Test Set',
              'set_release_date': '2026-01-02',
              'rarity': 'uncommon',
              'foil': false,
            },
          ],
        },
        'visual_analysis': const <String, dynamic>{},
      });
    }
    if (endpoint == '/community/decks/deck-1/comments') {
      return ApiResponse(200, {'data': const []});
    }
    if (endpoint == '/community/trade-matches') {
      return ApiResponse(200, {'matches': const []});
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/community/decks/deck-1/comments') {
      commentPosts.add(body['body'] as String);
      return ApiResponse(201, {'ok': true});
    }
    throw UnimplementedError('No POST handler for $endpoint');
  }
}

class _DeckApiFixture extends ApiClient {}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(apiClient: _DeckApiFixture());

  @override
  User? get user =>
      User(id: 'viewer-1', username: 'viewer', email: 'viewer@example.com');
}
