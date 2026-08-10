import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/app_state_panel.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/binder/widgets/binder_item_editor.dart';
import 'package:manaloom/features/cards/providers/card_provider.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_list_screen.dart';
import 'package:manaloom/features/decks/widgets/deck_commander_selector.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/profile/profile_screen.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/trades/providers/trade_provider.dart';
import 'package:manaloom/features/trades/screens/create_trade_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _assetBaseUrl = String.fromEnvironment(
  'MANALOOM_UI_PROOF_ASSET_BASE_URL',
);
const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

const _checkpoints = <String>[
  'ux_pack08_00_profile_security_below_fold',
  'ux_pack08_01_profile_avatar_dialog',
  'ux_pack08_02_profile_blocked_loading',
  'ux_pack08_03_profile_blocked_error_retry',
  'ux_pack08_04_profile_blocked_recovered',
  'ux_pack08_05_profile_password_validation',
  'ux_pack08_06_profile_revoke_validation',
  'ux_pack08_07_profile_delete_validation',
  'ux_pack08_08_deck_seeded_action_context',
  'ux_pack08_09_deck_delete_action_menu',
  'ux_pack08_10_deck_delete_confirmation',
  'ux_pack08_11_deck_delete_cancelled',
  'ux_pack08_12_commander_selection_recovered',
  'ux_pack08_13_binder_printings_error_retry',
  'ux_pack08_14_binder_printings_recovered',
  'ux_pack08_15_binder_delete_confirmation',
  'ux_pack08_16_binder_save_error',
  'ux_pack08_17_trade_item_picker',
  'ux_pack08_18_trade_review_exact_identity',
  'ux_pack08_19_trade_submit_error_retry',
  'ux_pack08_20_session_expired',
  'ux_pack08_21_permission_denied',
];

class _FlutterTesterCacheManager implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.error(
    StateError('Network artwork is disabled in flutter-tester.'),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _assetUrl(String fileName) {
  final base = _assetBaseUrl.trim();
  if (base.isEmpty) {
    return 'https://cards.scryfall.io/normal/front/7/b/'
        '7b7a348a-51f7-4dc5-8fe7-1c70fea5e050.jpg?1761053659';
  }
  return '${base.replaceFirst(RegExp(r'/+$'), '')}/$fileName';
}

class _MemorySecureTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _CriticalApiClient extends ApiClient {
  final profile = <String, dynamic>{
    'id': 'pack08-profile-user',
    'username': 'guardiao_do_fichario',
    'email': 'guardiao@manaloom.local',
    'display_name': 'Guardião do Fichário',
    'avatar_url': null,
    'location_state': 'SP',
    'location_city': 'Campinas',
    'trade_notes': 'Trocas presenciais e envio com rastreio.',
    'profile_visibility': 'public',
    'binder_visibility': 'public',
    'location_visibility': 'trade_only',
    'message_visibility': 'followers',
    'trade_visibility': 'everyone',
    'trade_notes_visibility': 'trade_only',
    'email_verified': true,
  };

  Completer<ApiResponse>? _blockedRequest;
  var _blockedRetrySucceeds = false;

  void holdBlockedUsers() {
    _blockedRequest = Completer<ApiResponse>();
  }

  void failHeldBlockedUsers() {
    _blockedRequest?.complete(
      ApiResponse(503, const <String, dynamic>{'error': 'temporary_failure'}),
    );
    _blockedRequest = null;
    _blockedRetrySucceeds = true;
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/users/me') {
      return ApiResponse(200, <String, dynamic>{
        'user': Map<String, dynamic>.from(profile),
      });
    }
    if (endpoint == '/users/me/blocks') {
      final held = _blockedRequest;
      if (held != null) return held.future;
      if (_blockedRetrySucceeds) {
        return ApiResponse(200, <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'blocked-pack08-player',
              'username': 'ofertas_inseguras',
              'display_name': 'Ofertas inseguras',
              'blocked_at': '2026-08-01T10:00:00Z',
            },
          ],
        });
      }
      return ApiResponse(503, const <String, dynamic>{});
    }
    return ApiResponse(404, const <String, dynamic>{'error': 'not_found'});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/auth/login') {
      return ApiResponse(200, <String, dynamic>{
        'token': 'pack08-profile-token',
        'user': Map<String, dynamic>.from(profile),
      });
    }
    return ApiResponse(404, const <String, dynamic>{'error': 'not_found'});
  }
}

class _CriticalCommercialProvider extends CommercialProvider {
  static const _snapshot = AiUsageSnapshot(
    plan: ManaLoomPlan.free,
    periodKey: '2026-08',
    used: 31,
  );

  @override
  bool get isLoaded => true;

  @override
  AiUsageSnapshot get usageSnapshot => _snapshot;

  @override
  Future<void> load() async {}
}

class _CriticalDeckProvider extends DeckProvider {
  _CriticalDeckProvider(this.seededDecks) : super(apiClient: ApiClient());

  final List<Deck> seededDecks;

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(seededDecks);

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchDecks({bool silent = false}) async {}
}

class _CriticalCommanderProvider extends CardProvider {
  _CriticalCommanderProvider() : super(apiClient: ApiClient());

  List<DeckCardItem> _results = const <DeckCardItem>[];
  var _loading = false;

  @override
  List<DeckCardItem> get searchResults => List.unmodifiable(_results);

  @override
  bool get isLoading => _loading;

  @override
  String? get errorMessage => null;

  @override
  Future<void> searchCommanderCandidates(
    String query, {
    required String format,
  }) async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _results = <DeckCardItem>[
      DeckCardItem(
        id: 'pack08-atraxa',
        name: 'Atraxa, Grand Unifier',
        manaCost: '{3}{G}{W}{U}{B}',
        typeLine: 'Legendary Creature — Phyrexian Angel',
        colorIdentity: const <String>['W', 'U', 'B', 'G'],
        imageUrl: _assetUrl('visual_fixture_arcane_artificer.webp'),
        setCode: 'ONE',
        setName: 'Phyrexia: All Will Be One',
        setReleaseDate: '2023-02-10',
        rarity: 'mythic',
        collectorNumber: '196',
        foil: false,
        quantity: 1,
        isCommander: false,
      ),
    ];
    _loading = false;
    notifyListeners();
  }

  @override
  void clearSearch() {
    _results = const <DeckCardItem>[];
    _loading = false;
    notifyListeners();
  }
}

class _CriticalPrintingProvider extends CardProvider {
  _CriticalPrintingProvider() : super(apiClient: ApiClient());

  var calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchPrintingsByName(String name) async {
    calls += 1;
    if (calls == 1) throw TimeoutException('visual proof printing timeout');
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pack08-ring-cmm',
        'name': 'Sol Ring',
        'image_url': _assetUrl('visual_fixture_arcane_ring.webp'),
        'set_code': 'CMM',
        'collector_number': '396',
        'set_name': 'Commander Masters',
        'set_release_date': '2023-08-04',
        'rarity': 'uncommon',
        'foil': false,
        'price': 4.75,
      },
      <String, dynamic>{
        'id': 'pack08-ring-ltc',
        'name': 'Sol Ring',
        'image_url': _assetUrl('visual_fixture_blue_spell.webp'),
        'set_code': 'LTC',
        'collector_number': '284',
        'set_name': 'Tales of Middle-earth Commander',
        'set_release_date': '2023-06-23',
        'rarity': 'uncommon',
        'foil': true,
        'price': 7.20,
      },
    ];
  }
}

class _CriticalTradeBinderProvider extends BinderProvider {
  _CriticalTradeBinderProvider(this.seededItems);

  final List<BinderItem> seededItems;

  @override
  Future<List<BinderItem>?> fetchBinderDirect({
    required String listType,
    int page = 1,
    int limit = 20,
    String? condition,
    String? search,
    bool? forTrade,
    bool? forSale,
    String? setCode,
    String? rarity,
    String? language,
    bool? foil,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async => seededItems;
}

class _CriticalTradeProvider extends TradeProvider {
  var createCalls = 0;

  @override
  String? get errorMessage =>
      'A proposta não foi enviada. Revise e tente novamente.';

  @override
  Future<bool> createTrade({
    required String receiverId,
    String type = 'trade',
    String? message,
    List<Map<String, dynamic>> myItems = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> requestedItems = const <Map<String, dynamic>>[],
    double? paymentAmount,
    String? paymentMethod,
    String? counterToTradeId,
  }) async {
    createCalls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return false;
  }
}

Deck get _seededDeck => Deck(
  id: 'pack08-deck',
  name: 'Atraxa — Valor e permanentes',
  format: 'commander',
  commanderName: 'Atraxa, Grand Unifier',
  commanderImageUrl: _assetUrl('visual_fixture_arcane_artificer.webp'),
  description: 'Lista revisada para a liga local.',
  isPublic: false,
  createdAt: DateTime.utc(2026, 8, 2),
  cardCount: 100,
  colorIdentity: const <String>['W', 'U', 'B', 'G'],
  validationState: Deck.validationStateValidated,
  reviewReasons: const <String>[],
);

BinderItem _binderItem({
  required String id,
  required String cardId,
  required String name,
  required String image,
  required String setCode,
  required String collector,
  bool foil = false,
  double price = 12.5,
}) => BinderItem(
  id: id,
  cardId: cardId,
  cardName: name,
  cardImageUrl: image,
  cardSetCode: setCode,
  cardCollectorNumber: collector,
  cardSetName: setCode == 'CMM'
      ? 'Commander Masters'
      : 'Tales of Middle-earth Commander',
  cardSetReleaseDate: setCode == 'CMM' ? '2023-08-04' : '2023-06-23',
  cardRarity: 'uncommon',
  quantity: 2,
  availableQuantity: 2,
  condition: 'NM',
  isFoil: foil,
  forTrade: true,
  price: price,
  language: 'pt-br',
  listType: 'have',
);

Widget _profileApp({
  required _CriticalApiClient api,
  required AuthProvider auth,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<SocialProvider>(
        create: (_) => SocialProvider(apiClient: api),
      ),
      ChangeNotifierProvider<CommercialProvider>(
        create: (_) => _CriticalCommercialProvider(),
      ),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: api),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(apiClient: api),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: ProfileScreen(apiClient: api),
    ),
  );
}

Widget _deckApp({
  required DeckProvider deckProvider,
  required CardProvider cardProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: ApiClient()),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(apiClient: ApiClient()),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: const DeckListScreen(),
    ),
  );
}

Widget _binderApp({
  required CardProvider cardProvider,
  required BinderItem item,
}) {
  return ChangeNotifierProvider<CardProvider>.value(
    value: cardProvider,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        backgroundColor: AppTheme.backgroundAbyss,
        body: BinderItemEditor(
          item: item,
          onSave: (_) async => false,
          onDelete: () async => false,
        ),
      ),
    ),
  );
}

Widget _commanderApp({
  required CardProvider cardProvider,
  required DeckCardItem selectedCard,
}) {
  return ChangeNotifierProvider<CardProvider>.value(
    value: cardProvider,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: Scaffold(
        backgroundColor: AppTheme.backgroundAbyss,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: DeckCommanderSelector(
                  format: 'commander',
                  selectedCard: selectedCard,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _tradeApp({
  required BinderProvider binderProvider,
  required TradeProvider tradeProvider,
  required BinderItem requestedItem,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BinderProvider>.value(value: binderProvider),
      ChangeNotifierProvider<TradeProvider>.value(value: tradeProvider),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      home: CreateTradeScreen(
        receiverId: 'pack08-partner',
        initialType: 'trade',
        preselectedItem: requestedItem,
      ),
    ),
  );
}

class _ContractStateScreen extends StatelessWidget {
  const _ContractStateScreen({required this.permissionDenied});

  final bool permissionDenied;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key(
        permissionDenied
            ? 'critical-permission-denied'
            : 'critical-session-expired',
      ),
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: Text(permissionDenied ? 'Perfil público' : 'Sessão'),
      ),
      body: Center(
        child: AppStatePanel(
          key: const Key('critical-contract-state-panel'),
          icon: permissionDenied
              ? Icons.lock_person_outlined
              : Icons.lock_clock_outlined,
          title: permissionDenied
              ? 'Este perfil não está disponível para você'
              : 'Sua sessão expirou',
          message: permissionDenied
              ? 'As preferências de privacidade ou segurança impedem a abertura deste conteúdo. Volte à Comunidade para continuar.'
              : 'Entre novamente para proteger sua conta. Depois da autenticação, o ManaLoom pode retomar o destino solicitado.',
          accent: permissionDenied ? AppTheme.warning : AppTheme.error,
          status: permissionDenied
              ? AppStateStatus.unavailable
              : AppStateStatus.error,
          actionLabel: permissionDenied
              ? 'Voltar à Comunidade'
              : 'Entrar novamente',
          actionKey: Key(
            permissionDenied
                ? 'critical-permission-back'
                : 'critical-session-login',
          ),
          onAction: () {},
        ),
      ),
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'critical overlays expose action-open-final states without external writes',
    (tester) async {
      if (!_captureRuntimeProof) {
        CachedNetworkImageProvider.defaultCacheManager =
            _FlutterTesterCacheManager();
      }
      _expectRuntimeContract();
      _emitRuntimeContext();
      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      final api = _CriticalApiClient()..holdBlockedUsers();
      final auth = AuthProvider(
        apiClient: api,
        tokenStore: AuthTokenStore(secureBackend: _MemorySecureTokenBackend()),
      );
      expect(
        await auth.login('guardiao@manaloom.local', 'VisualOnly123!'),
        isTrue,
      );
      await tester.pumpWidget(_profileApp(api: api, auth: auth));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile-identity-rail')),
      );

      final changePassword = find.byKey(
        const Key('profile-change-password-button'),
      );
      await tester.scrollUntilVisible(
        changePassword,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await _capture(binding, tester, _checkpoints[0], focus: changePassword);

      final avatar = find.byKey(const Key('profile-avatar-edit-button'));
      await tester.scrollUntilVisible(
        avatar,
        -260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(avatar);
      await tester.pumpAndSettle();
      await _capture(
        binding,
        tester,
        _checkpoints[1],
        focus: find.byKey(const Key('profile-avatar-dialog')),
      );
      await tester.tap(find.byKey(const Key('profile-avatar-cancel-button')));
      await tester.pumpAndSettle();

      final blocked = find.byKey(const Key('profile-blocked-users-button'));
      await tester.scrollUntilVisible(
        blocked,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(blocked);
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const Key('profile-blocked-users-loading')),
        findsOneWidget,
      );
      await _capture(binding, tester, _checkpoints[2]);

      api.failHeldBlockedUsers();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile-blocked-users-error')),
      );
      await _capture(binding, tester, _checkpoints[3]);

      await tester.tap(find.byKey(const Key('profile-blocked-users-retry')));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile-blocked-users-list')),
      );
      await _capture(binding, tester, _checkpoints[4]);
      await tester.tap(find.byKey(const Key('profile-blocked-users-close')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(changePassword);
      await tester.tap(changePassword);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('profile-change-password-confirm-button')),
      );
      await tester.pump();
      await _capture(binding, tester, _checkpoints[5]);
      await tester.tap(
        find.byKey(const Key('profile-change-password-cancel-button')),
      );
      await tester.pumpAndSettle();

      final revoke = find.byKey(const Key('profile-revoke-sessions-button'));
      await tester.ensureVisible(revoke);
      await tester.tap(revoke);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('profile-revoke-sessions-confirm-button')),
      );
      await tester.pump();
      await _capture(binding, tester, _checkpoints[6]);
      await tester.tap(
        find.byKey(const Key('profile-revoke-sessions-cancel-button')),
      );
      await tester.pumpAndSettle();

      final deleteAccount = find.byKey(
        const Key('profile-delete-account-button'),
      );
      await tester.scrollUntilVisible(
        deleteAccount,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(deleteAccount);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-delete-confirm-button')));
      await tester.pump();
      await _capture(binding, tester, _checkpoints[7]);
      await tester.tap(find.byKey(const Key('profile-delete-cancel-button')));
      await tester.pumpAndSettle();

      final seededDeckProvider = _CriticalDeckProvider(<Deck>[_seededDeck]);
      final seededCommanderProvider = _CriticalCommanderProvider();
      addTearDown(seededDeckProvider.dispose);
      addTearDown(seededCommanderProvider.dispose);
      await tester.pumpWidget(
        _deckApp(
          deckProvider: seededDeckProvider,
          cardProvider: seededCommanderProvider,
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-list-row-pack08-deck')),
      );
      await _capture(
        binding,
        tester,
        _checkpoints[8],
        focus: find.byKey(const Key('deck-list-row-pack08-deck')),
      );

      await tester.tap(find.byKey(const Key('deck-options-pack08-deck')));
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[9]);
      await tester.tap(find.byKey(const Key('deck-delete-menu-pack08-deck')));
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[10]);
      await tester.tap(find.byKey(const Key('deck-delete-cancel-pack08-deck')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('deck-list-row-pack08-deck')),
        findsOneWidget,
      );
      await _capture(binding, tester, _checkpoints[11]);

      final commanderProvider = _CriticalCommanderProvider();
      addTearDown(commanderProvider.dispose);
      final selectedCommander = DeckCardItem(
        id: 'pack08-atraxa',
        name: 'Atraxa, Grand Unifier',
        manaCost: '{3}{G}{W}{U}{B}',
        typeLine: 'Legendary Creature — Phyrexian Angel',
        colorIdentity: const <String>['W', 'U', 'B', 'G'],
        imageUrl: _assetUrl('visual_fixture_arcane_artificer.webp'),
        setCode: 'ONE',
        setName: 'Phyrexia: All Will Be One',
        setReleaseDate: '2023-02-10',
        rarity: 'mythic',
        collectorNumber: '196',
        foil: false,
        quantity: 1,
        isCommander: true,
      );
      await tester.pumpWidget(
        _commanderApp(
          cardProvider: commanderProvider,
          selectedCard: selectedCommander,
        ),
      );
      await tester.pump(const Duration(milliseconds: 420));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-create-commander-selected')),
      );
      await _capture(binding, tester, _checkpoints[12]);

      final printingProvider = _CriticalPrintingProvider();
      addTearDown(printingProvider.dispose);
      final collectionItem = _binderItem(
        id: 'pack08-binder-ring',
        cardId: 'pack08-ring-cmm',
        name: 'Sol Ring',
        image: _assetUrl('visual_fixture_arcane_ring.webp'),
        setCode: 'CMM',
        collector: '396',
      );
      await tester.pumpWidget(
        _binderApp(cardProvider: printingProvider, item: collectionItem),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('binder-editor-printings-error')),
      );
      await _capture(binding, tester, _checkpoints[13]);
      printingProvider.calls = 1;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        _binderApp(cardProvider: printingProvider, item: collectionItem),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('binder-editor-printings-list')),
      );
      await _capture(binding, tester, _checkpoints[14]);

      final remove = find.byKey(const Key('binder-editor-remove-button'));
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[15]);
      await tester.tap(find.byKey(const Key('binder-editor-delete-cancel')));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('binder-editor-save-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('binder-editor-save-error')),
      );
      await _capture(binding, tester, _checkpoints[16]);

      final requestedItem = _binderItem(
        id: 'pack08-requested-ring',
        cardId: 'pack08-requested-card',
        name: 'Sol Ring',
        image: _assetUrl('visual_fixture_arcane_ring.webp'),
        setCode: 'CMM',
        collector: '396',
        price: 22,
      );
      final offeredItem = _binderItem(
        id: 'pack08-offered-spell',
        cardId: 'pack08-offered-card',
        name: 'Counterspell',
        image: _assetUrl('visual_fixture_blue_spell.webp'),
        setCode: 'LTC',
        collector: '84',
        foil: true,
        price: 18,
      );
      final tradeBinderProvider = _CriticalTradeBinderProvider(<BinderItem>[
        offeredItem,
      ]);
      final tradeProvider = _CriticalTradeProvider();
      addTearDown(tradeBinderProvider.dispose);
      addTearDown(tradeProvider.dispose);
      await tester.pumpWidget(
        _tradeApp(
          binderProvider: tradeBinderProvider,
          tradeProvider: tradeProvider,
          requestedItem: requestedItem,
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-add-item-offered')),
      );
      final addOffered = find.byKey(const Key('create-trade-add-item-offered'));
      await tester.ensureVisible(addOffered);
      await tester.tap(addOffered);
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[17]);
      await tester.tap(
        find.byKey(
          const Key('create-trade-picker-item-offered-pack08-offered-spell'),
        ),
      );
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('create-trade-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-review-dialog')),
      );
      await _capture(binding, tester, _checkpoints[18]);
      await tester.tap(
        find.byKey(const ValueKey('create-trade-review-confirm-button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('create-trade-submit-error')),
      );
      await _capture(
        binding,
        tester,
        _checkpoints[19],
        focus: find.byKey(const Key('create-trade-submit-error')),
      );
      expect(tradeProvider.createCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _ContractStateScreen(permissionDenied: false),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[20]);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const _ContractStateScreen(permissionDenied: true),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(binding, tester, _checkpoints[21]);
    },
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint, {
  Finder? focus,
}) async {
  if (focus != null) await tester.ensureVisible(focus);
  await tester.pump(const Duration(milliseconds: 420));
  expect(tester.takeException(), isNull, reason: 'Before $checkpoint');
  expectNoRawTechnicalErrorText(tester);
  if (_captureRuntimeProof) {
    await captureVisualProof(binding, tester, checkpoint);
  }
  expect(tester.takeException(), isNull, reason: 'After $checkpoint');
}

void _expectRuntimeContract() {
  if (!_captureRuntimeProof) return;
  expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
  expect(_uiProofProfile, isNotEmpty);
  expect(_uiProofTarget, 'web_real_build');
  expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
  expect(_assetBaseUrl, startsWith('http://127.0.0.1:'));
}

void _emitRuntimeContext() {
  if (!_captureRuntimeProof) return;
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'critical_overlays_states', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _checkpoints})}',
  );
}
