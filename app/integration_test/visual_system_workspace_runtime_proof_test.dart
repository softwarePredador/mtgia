import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/app_state_panel.dart';
import 'package:manaloom/core/widgets/main_scaffold.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/binder/providers/binder_provider.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_list_screen.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:manaloom/features/profile/profile_screen.dart';
import 'package:manaloom/features/social/providers/social_provider.dart';
import 'package:manaloom/features/social/screens/user_profile_screen.dart';
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
const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);
const _publicUserId = 'visual-public-player';
const _cardImage =
    'https://cards.scryfall.io/normal/front/7/b/'
    '7b7a348a-51f7-4dc5-8fe7-1c70fea5e050.jpg?1761053659';
const _requiredCheckpoints = <String>[
  'visual_system_00_profile_clean',
  'visual_system_01_profile_dirty',
  'visual_system_02_profile_saving',
  'visual_system_03_profile_error',
  'visual_system_04_profile_saved',
  'visual_system_05_public_profile',
  'visual_system_06_decks_first_use',
  'visual_system_07_no_results',
  'visual_system_08_offline',
  'visual_system_09_unavailable',
];

class _MemorySecureTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _RuntimeApiClient extends ApiClient {
  Map<String, dynamic> profile = <String, dynamic>{
    'id': 'visual-profile-user',
    'username': 'mestre_do_fichario',
    'email': 'jogador@manaloom.local',
    'display_name': 'Marina — Arquivista de Comandantes do Litoral',
    'avatar_url': null,
    'location_state': 'SP',
    'location_city': 'São Paulo',
    'trade_notes': 'Trocas presenciais aos sábados; envio com rastreio.',
    'profile_visibility': 'public',
    'binder_visibility': 'public',
    'location_visibility': 'trade_only',
    'message_visibility': 'followers',
    'trade_visibility': 'everyone',
    'trade_notes_visibility': 'trade_only',
    'email_verified': true,
  };

  Completer<ApiResponse>? _heldPatch;

  void holdNextPatch() {
    _heldPatch = Completer<ApiResponse>();
  }

  void completeHeldPatchWithFailure() {
    _heldPatch?.complete(
      ApiResponse(503, const <String, dynamic>{'error': 'temporary_failure'}),
    );
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint == '/users/me') {
      return ApiResponse(200, <String, dynamic>{
        'user': Map<String, dynamic>.from(profile),
      });
    }
    if (endpoint == '/community/users/$_publicUserId') {
      return ApiResponse(200, <String, dynamic>{
        'user': <String, dynamic>{
          'id': _publicUserId,
          'username': 'aurora_control',
          'display_name': 'Aurora — Pilota Azorius e organiza a Liga Paulista',
          'avatar_url': null,
          'follower_count': 284,
          'following_count': 73,
          'public_deck_count': 2,
          'created_at': '2025-04-12T10:00:00Z',
          'is_following': true,
          'is_own_profile': false,
        },
        'public_decks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'aurora-brago',
            'name': 'Brago — Valor sem fim',
            'format': 'commander',
            'description': 'ETBs, controle de mesa e decisões graduais.',
            'synergy_score': 87,
            'card_count': 100,
            'commander_name': 'Brago, King Eternal',
            'commander_image_url': kIsWeb ? _cardImage : null,
            'created_at': '2026-07-18T12:00:00Z',
          },
          <String, dynamic>{
            'id': 'aurora-azorius',
            'name': 'Azorius Tempo',
            'format': 'modern',
            'synergy_score': 81,
            'card_count': 60,
            'commander_name': 'Solitude',
            'commander_image_url': kIsWeb ? _cardImage : null,
            'created_at': '2026-08-01T12:00:00Z',
          },
        ],
      });
    }
    return ApiResponse(404, <String, dynamic>{'error': 'not_found'});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/auth/login') {
      return ApiResponse(200, <String, dynamic>{
        'token': 'visual-profile-token',
        'user': Map<String, dynamic>.from(profile),
      });
    }
    return ApiResponse(404, <String, dynamic>{'error': 'not_found'});
  }

  @override
  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> body) async {
    if (endpoint != '/users/me') {
      return ApiResponse(404, <String, dynamic>{'error': 'not_found'});
    }
    final heldPatch = _heldPatch;
    if (heldPatch != null) {
      final response = await heldPatch.future;
      _heldPatch = null;
      return response;
    }
    profile = <String, dynamic>{...profile, ...body};
    return ApiResponse(200, <String, dynamic>{
      'user': Map<String, dynamic>.from(profile),
    });
  }
}

class _RuntimeDeckProvider extends DeckProvider {
  _RuntimeDeckProvider({required ApiClient apiClient})
    : super(apiClient: apiClient);

  @override
  List<Deck> get decks => const <Deck>[];

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchDecks({bool silent = false}) async {}
}

class _RuntimeCommercialProvider extends CommercialProvider {
  static const _snapshot = AiUsageSnapshot(
    plan: ManaLoomPlan.free,
    periodKey: '2026-08',
    used: 34,
  );

  @override
  bool get isLoaded => true;

  @override
  AiUsageSnapshot get usageSnapshot => _snapshot;

  @override
  Future<void> load() async {}
}

GoRouter _router(_RuntimeApiClient apiClient) {
  Widget placeholder(String label) => Scaffold(
    backgroundColor: AppTheme.backgroundAbyss,
    body: Center(child: Text(label)),
  );

  return GoRouter(
    initialLocation: '/profile',
    routes: [
      ShellRoute(
        builder: (_, _, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/profile',
            pageBuilder: (_, _) => NoTransitionPage<void>(
              child: ProfileScreen(apiClient: apiClient),
            ),
          ),
          GoRoute(
            path: '/community/user/:userId',
            pageBuilder: (_, state) => NoTransitionPage<void>(
              child: UserProfileScreen(userId: state.pathParameters['userId']!),
            ),
          ),
          GoRoute(
            path: '/decks',
            pageBuilder: (_, _) =>
                const NoTransitionPage<void>(child: DeckListScreen()),
          ),
          GoRoute(
            path: '/proof/no-results',
            pageBuilder: (_, _) => const NoTransitionPage<void>(
              child: _StateProofScreen(status: AppStateStatus.noResults),
            ),
          ),
          GoRoute(
            path: '/proof/offline',
            pageBuilder: (_, _) => const NoTransitionPage<void>(
              child: _StateProofScreen(status: AppStateStatus.offline),
            ),
          ),
          GoRoute(
            path: '/proof/unavailable',
            pageBuilder: (_, _) => const NoTransitionPage<void>(
              child: _StateProofScreen(status: AppStateStatus.unavailable),
            ),
          ),
          GoRoute(path: '/plans', builder: (_, _) => placeholder('Planos')),
          GoRoute(path: '/legal', builder: (_, _) => placeholder('Legal')),
          GoRoute(
            path: '/collection',
            builder: (_, _) => placeholder('Coleção'),
          ),
          GoRoute(
            path: '/decks/generate',
            builder: (_, _) => placeholder('Gerar deck'),
          ),
          GoRoute(
            path: '/decks/import',
            builder: (_, _) => placeholder('Importar deck'),
          ),
          GoRoute(
            path: '/community/decks/:deckId',
            builder: (_, _) => placeholder('Deck público'),
          ),
        ],
      ),
    ],
  );
}

Widget _runtimeApp({
  required GoRouter router,
  required _RuntimeApiClient apiClient,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<SocialProvider>(
        create: (_) => SocialProvider(apiClient: apiClient),
      ),
      ChangeNotifierProvider<BinderProvider>(
        create: (_) => BinderProvider(apiClient: apiClient),
      ),
      ChangeNotifierProvider<DeckProvider>(
        create: (_) => _RuntimeDeckProvider(apiClient: apiClient),
      ),
      ChangeNotifierProvider<CommercialProvider>(
        create: (_) => _RuntimeCommercialProvider(),
      ),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: apiClient),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(apiClient: apiClient),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

class _StateProofScreen extends StatelessWidget {
  const _StateProofScreen({required this.status});

  final AppStateStatus status;

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      AppStateStatus.noResults => (
        Icons.search_off_outlined,
        'Nenhum deck combina com esta busca',
        'Retire um filtro ou tente o nome do comandante para ampliar os resultados.',
        AppTheme.frost400,
      ),
      AppStateStatus.offline => (
        Icons.cloud_off_outlined,
        'Sua coleção não pôde ser atualizada',
        'O que já foi carregado continua seguro. Reconecte para buscar a versão mais recente.',
        AppTheme.error,
      ),
      AppStateStatus.unavailable => (
        Icons.hourglass_disabled_outlined,
        'Este recurso ainda não está disponível',
        'Você pode continuar montando e revisando seus decks enquanto essa etapa é preparada.',
        AppTheme.brass400,
      ),
      _ => throw StateError('Unsupported proof state: $status'),
    };
    return Scaffold(
      key: Key('state-proof-${status.name}'),
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(title: const Text('Estado da jornada')),
      body: AppStatePanel(
        key: const Key('state-proof-panel'),
        status: status,
        icon: data.$1,
        title: data.$2,
        message: data.$3,
        accent: data.$4,
        actionLabel: status == AppStateStatus.unavailable
            ? 'Voltar aos decks'
            : 'Tentar novamente',
        onAction: () {},
      ),
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real Web proves player workspace, save states and contextual state language',
    (tester) async {
      _expectRuntimeContract();
      _emitRuntimeContext();
      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));

      final apiClient = _RuntimeApiClient();
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final authProvider = AuthProvider(
        apiClient: apiClient,
        tokenStore: AuthTokenStore(secureBackend: _MemorySecureTokenBackend()),
      );
      expect(
        await authProvider.login('jogador@manaloom.local', 'VisualOnly123!'),
        isTrue,
      );
      final router = _router(apiClient);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _runtimeApp(
          router: router,
          apiClient: apiClient,
          authProvider: authProvider,
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile-identity-rail')),
      );
      await tester.pump(const Duration(milliseconds: 450));
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[0],
        focus: find.byKey(const Key('profile-identity-rail')),
      );

      final displayName = find.byKey(const Key('profile-display-name-field'));
      tester.widget<TextField>(displayName).controller!.text =
          'Mestre do Fichário — Liga Paulista';
      await tester.pump(const Duration(milliseconds: 250));
      await tester.ensureVisible(displayName);
      expect(find.text('Alterações não salvas'), findsOneWidget);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[1],
        focus: displayName,
      );

      apiClient.holdNextPatch();
      final saveButton = find.byKey(const Key('profile-save-button'));
      tester.widget<FilledButton>(saveButton).onPressed!.call();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('Salvando alterações'), findsOneWidget);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[2],
        focus: find.byKey(const Key('profile-save-status')),
      );

      apiClient.completeHeldPatchWithFailure();
      await pumpUntilFound(tester, find.byIcon(Icons.error_outline));
      _clearSnackBars(tester, find.byKey(const Key('profile-content')));
      await tester.pump(const Duration(milliseconds: 200));
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[3],
        focus: find.byKey(const Key('profile-save-status')),
      );

      tester.widget<FilledButton>(saveButton).onPressed!.call();
      await pumpUntilFound(tester, find.text('Alterações salvas'));
      _clearSnackBars(tester, find.byKey(const Key('profile-content')));
      await tester.pump(const Duration(milliseconds: 200));
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[4],
        focus: find.byKey(const Key('profile-save-status')),
      );

      router.go('/community/user/$_publicUserId');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('user-profile-identity-rail')),
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[5],
        focus: find.byKey(const Key('user-profile-content')),
      );

      router.go('/decks');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('deck-list-empty-state')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[6],
        focus: find.byKey(const Key('deck-list-empty-state')),
      );

      for (final routeAndCheckpoint in <(String, String)>[
        ('/proof/no-results', _requiredCheckpoints[7]),
        ('/proof/offline', _requiredCheckpoints[8]),
        ('/proof/unavailable', _requiredCheckpoints[9]),
      ]) {
        router.go(routeAndCheckpoint.$1);
        await pumpUntilFound(
          tester,
          find.byKey(const Key('state-proof-panel')),
        );
        await _capture(
          binding,
          tester,
          routeAndCheckpoint.$2,
          focus: find.byKey(const Key('state-proof-panel')),
        );
      }
    },
  );
}

void _clearSnackBars(WidgetTester tester, Finder finder) {
  final context = tester.element(finder);
  ScaffoldMessenger.of(context).clearSnackBars();
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint, {
  Finder? focus,
}) async {
  if (focus != null) await tester.ensureVisible(focus);
  await tester.pump(const Duration(milliseconds: 450));
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
}

void _emitRuntimeContext() {
  if (!_captureRuntimeProof) return;
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'visual_system_workspace', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
  );
}
