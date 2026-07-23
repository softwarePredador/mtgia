import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/config/launch_features.dart';
import 'core/observability/app_observability.dart';
import 'core/services/image_cache_policy.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/realtime_notification_coordinator.dart';
import 'core/services/performance_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/debug_accessibility_tools.dart';
import 'features/home/home_screen.dart';
import 'features/decks/screens/deck_list_screen.dart';
import 'features/decks/providers/deck_provider.dart';
import 'features/decks/models/deck_card_item.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/auth_redirect.dart';

import 'core/widgets/main_scaffold.dart';

import 'features/decks/screens/deck_details_screen.dart';
import 'features/decks/screens/deck_generate_screen.dart';
import 'features/decks/screens/deck_import_screen.dart';

import 'features/cards/providers/card_provider.dart';
import 'features/cards/screens/card_search_screen.dart';
import 'features/cards/screens/card_detail_screen.dart';
import 'features/battle/screens/battle_replays_screen.dart';
import 'features/market/providers/market_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/scanner/screens/card_scanner_screen.dart';
import 'features/community/providers/community_provider.dart';
import 'features/community/screens/community_screen.dart';
import 'features/community/screens/community_deck_detail_screen.dart';
import 'features/social/providers/social_provider.dart';
import 'features/social/screens/user_profile_screen.dart';
import 'features/social/screens/user_search_screen.dart';
import 'features/binder/providers/binder_provider.dart';
import 'features/trades/providers/trade_provider.dart';
import 'features/trades/screens/trade_inbox_screen.dart';
import 'features/trades/screens/trade_detail_screen.dart';
import 'features/trades/screens/create_trade_screen.dart';
import 'features/collection/screens/collection_screen.dart';
import 'features/collection/screens/latest_set_collection_screen.dart';
import 'features/collection/screens/set_cards_screen.dart';
import 'features/collection/screens/sets_catalog_screen.dart';
import 'features/messages/providers/message_provider.dart';
import 'features/messages/screens/message_inbox_screen.dart';
import 'features/messages/screens/chat_screen.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/notifications/widgets/notification_permission_boundary.dart';
import 'features/home/onboarding_core_flow_screen.dart';
import 'features/home/life_counter_route.dart';
import 'features/home/lotus_life_counter_screen.dart';
import 'features/commercial/providers/commercial_provider.dart';
import 'features/commercial/screens/checkout_screen.dart';
import 'features/commercial/screens/legal_screen.dart';
import 'features/commercial/screens/plan_screen.dart';
import 'features/commercial/screens/upgrade_screen.dart';
import 'features/retention/screens/post_game_notes_screen.dart';

final bool _debugBootIntoLifeCounter =
    kDebugMode &&
    const bool.fromEnvironment(
      'DEBUG_BOOT_INTO_LIFE_COUNTER',
      // Default must be false so QA/dev boot into the normal app flow.
      defaultValue: false,
    );

const bool _disableFirebaseStartup = bool.fromEnvironment(
  'DISABLE_FIREBASE_STARTUP',
  defaultValue: false,
);
const bool _disablePushInit = bool.fromEnvironment(
  'DISABLE_PUSH_INIT',
  defaultValue: false,
);
const bool _disableFirebasePerformanceInit = bool.fromEnvironment(
  'DISABLE_FIREBASE_PERFORMANCE_INIT',
  defaultValue: false,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppObservability.instance.bootstrap(() async {
    runApp(const ManaLoomApp());
    _schedulePostFirstFramePlatformBootstrap();
  });
}

void _schedulePostFirstFramePlatformBootstrap() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePostFirstFramePlatformServices());
  });
}

Future<void> _initializePostFirstFramePlatformServices() async {
  if (_disableFirebaseStartup) {
    debugPrint(
      '[Main] Firebase startup desabilitado por DISABLE_FIREBASE_STARTUP.',
    );
    await AppObservability.instance.captureReleaseStartupProof(
      fcmInitialized: false,
      fcmTokenPresent: false,
    );
    return;
  }

  var fcmTokenPresent = false;
  if (_disablePushInit) {
    debugPrint('[Main] Firebase push desabilitado por DISABLE_PUSH_INIT.');
  } else {
    await _runStartupTask(
      label: 'Firebase push',
      timeout: const Duration(seconds: 8),
      task: () => PushNotificationService().init(),
    );
    if (AppObservability.instance.releaseStartupProofEnabled &&
        PushNotificationService().isFirebaseInitialized) {
      try {
        fcmTokenPresent = await PushNotificationService()
            .probeReleaseFcmTokenAvailability()
            .timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('[Main] Prova FCM da release indisponivel: $error');
      }
    }
  }

  await AppObservability.instance.captureReleaseStartupProof(
    fcmInitialized: PushNotificationService().isFirebaseInitialized,
    fcmTokenPresent: fcmTokenPresent,
  );

  if (_disableFirebasePerformanceInit) {
    debugPrint(
      '[Main] Firebase Performance desabilitado por '
      'DISABLE_FIREBASE_PERFORMANCE_INIT.',
    );
    return;
  }

  await _runStartupTask(
    label: 'Firebase Performance',
    timeout: const Duration(seconds: 5),
    task: () => PerformanceService.instance.init(),
  );
}

Future<void> _runStartupTask({
  required String label,
  required Duration timeout,
  required Future<void> Function() task,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    await task().timeout(timeout);
    debugPrint(
      '[Main] $label inicializado apos primeiro frame '
      '(${stopwatch.elapsedMilliseconds}ms)',
    );
  } on TimeoutException catch (error, stackTrace) {
    debugPrint(
      '[Main] $label excedeu ${timeout.inSeconds}s; app segue renderizado.',
    );
    unawaited(
      AppObservability.instance.captureException(
        error,
        stackTrace: stackTrace,
        tags: const {'source': 'startup_deferred_timeout'},
        extras: {'startup_task': label, 'timeout_ms': timeout.inMilliseconds},
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('[Main] $label indisponivel; app segue renderizado: $error');
    unawaited(
      AppObservability.instance.captureException(
        error,
        stackTrace: stackTrace,
        tags: const {'source': 'startup_deferred_error'},
        extras: {'startup_task': label},
      ),
    );
  }
}

class ManaLoomScrollBehavior extends MaterialScrollBehavior {
  const ManaLoomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class ManaLoomApp extends StatefulWidget {
  const ManaLoomApp({super.key});

  @override
  State<ManaLoomApp> createState() => _ManaLoomAppState();
}

class _ManaLoomAppState extends State<ManaLoomApp> with WidgetsBindingObserver {
  late final AuthProvider _authProvider;
  late final DeckProvider _deckProvider;
  late final CardProvider _cardProvider;
  late final MarketProvider _marketProvider;
  late final CommunityProvider _communityProvider;
  late final SocialProvider _socialProvider;
  late final BinderProvider _binderProvider;
  late final TradeProvider _tradeProvider;
  late final MessageProvider _messageProvider;
  late final NotificationProvider _notificationProvider;
  late final CommercialProvider _commercialProvider;
  late final RealtimeNotificationCoordinator _realtimeCoordinator;
  late final GoRouter _router;
  bool _hadAuthenticatedSession = false;
  Timer? _authenticatedWarmupTimer;

  @override
  void initState() {
    super.initState();
    AppImageCachePolicy.apply();
    WidgetsBinding.instance.addObserver(this);
    // go_router keeps imperative pushes out of the browser URL by default.
    // ManaLoom uses push for drill-down screens, so reflecting those pushes is
    // required for reload, browser back/forward, bookmarks, and shared links.
    GoRouter.optionURLReflectsImperativeAPIs = true;
    _authProvider = AuthProvider();
    ApiClient.setSessionExpiredHandler(_authProvider.expireSession);
    _deckProvider = DeckProvider();
    _cardProvider = CardProvider();
    _marketProvider = MarketProvider();
    _communityProvider = CommunityProvider();
    _socialProvider = SocialProvider();
    _binderProvider = BinderProvider();
    _tradeProvider = TradeProvider();
    _messageProvider = MessageProvider();
    _notificationProvider = NotificationProvider();
    _commercialProvider = CommercialProvider();
    unawaited(_commercialProvider.load());

    // Iniciar/parar polling de notificações quando autenticado
    _authProvider.addListener(_onAuthChanged);
    unawaited(_authProvider.initialize());

    // Log da URL da API no boot
    ApiClient.debugLogBaseUrl();

    _router = GoRouter(
      initialLocation: _debugBootIntoLifeCounter ? lifeCounterRoutePath : '/',
      refreshListenable: _authProvider,
      observers: [
        PerformanceNavigatorObserver(),
        AppObservabilityNavigatorObserver(),
      ],
      redirect: (context, state) {
        final location = state.matchedLocation;
        final status = _authProvider.status;

        debugPrint('[🧭 Router] redirect: status=$status');

        // Sempre permite a Splash (ela decide para onde ir).
        if (location == '/') return null;

        if (_debugBootIntoLifeCounter && location == lifeCounterRoutePath) {
          debugPrint('[🧭 Router] → null (debug life counter direto)');
          return null;
        }

        final isAuthRoute =
            location == '/login' ||
            location == '/register' ||
            location == '/forgot-password' ||
            location == '/reset-password';
        final isProtectedRoute =
            location.startsWith('/home') ||
            location.startsWith('/decks') ||
            location.startsWith('/cards') ||
            location.startsWith('/market') ||
            location.startsWith('/collection') ||
            location.startsWith('/profile') ||
            location.startsWith('/community') ||
            location.startsWith('/trades') ||
            location.startsWith('/messages') ||
            location.startsWith('/notifications') ||
            location.startsWith('/plans') ||
            location.startsWith('/upgrade') ||
            location.startsWith('/checkout') ||
            location.startsWith('/onboarding') ||
            location.startsWith(lifeCounterRoutePath);

        // Enquanto auth inicializa/carrega, mantém o app em splash/auth.
        // Evita abrir telas protegidas e disparar rajadas de 401 no boot.
        if (status == AuthStatus.loading || status == AuthStatus.initial) {
          final isBootSafeRoute =
              location == '/' ||
              location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location == '/reset-password' ||
              location == '/verify-email' ||
              location == '/legal' ||
              (_debugBootIntoLifeCounter && location == lifeCounterRoutePath);
          if (!isBootSafeRoute) {
            final redirectTarget = state.uri.toString();
            final splashUri = Uri(
              path: '/',
              queryParameters: isProtectedRoute
                  ? {'redirect': redirectTarget}
                  : null,
            ).toString();
            debugPrint(
              '[🧭 Router] → splash de autenticação '
              '(status=$status, aguardando auth)',
            );
            return splashUri;
          }

          debugPrint('[🧭 Router] → null (status=$status, aguardando)');
          return null;
        }

        if (isProtectedRoute && !_authProvider.isAuthenticated) {
          final loginLocation = buildAuthLocation(
            '/login',
            state.uri.toString(),
          );
          debugPrint('[🧭 Router] → login (rota protegida sem auth)');
          return loginLocation;
        }

        if (location == '/register' &&
            _authProvider.isAuthenticated &&
            _authProvider.user?.emailVerified == false) {
          final redirectPath = normalizePostAuthRedirect(
            state.uri.queryParameters['redirect'],
          );
          final verifyLocation = Uri(
            path: '/verify-email',
            queryParameters: redirectPath == null
                ? null
                : {'redirect': redirectPath},
          ).toString();
          debugPrint('[🧭 Router] → verificar email após cadastro');
          return verifyLocation;
        }

        if (isAuthRoute && _authProvider.isAuthenticated) {
          final postAuthRedirect = normalizePostAuthRedirect(
            state.uri.queryParameters['redirect'],
          );
          final target = resolveAuthenticatedLocation(
            redirectPath: postAuthRedirect,
            defaultLocation: _authProvider.defaultAuthenticatedLocation,
          );
          debugPrint('[🧭 Router] → rota autenticada resolvida');
          return target;
        }

        final uriPath = state.uri.path;
        if (!LaunchFeatures.scannerEnabled && uriPath.endsWith('/scan')) {
          final fallbackPath = uriPath.replaceFirst(
            RegExp(r'/scan$'),
            '/search',
          );
          debugPrint('[🧭 Router] → busca (scanner deferred neste build)');
          return fallbackPath;
        }

        debugPrint('[🧭 Router] → null (sem redirect)');
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              SplashScreen(redirectPath: state.uri.queryParameters['redirect']),
        ),

        GoRoute(
          path: '/login',
          builder: (context, state) =>
              LoginScreen(redirectPath: state.uri.queryParameters['redirect']),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterScreen(
            redirectPath: state.uri.queryParameters['redirect'],
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: '/legal',
          builder: (context, state) => const CommercialLegalScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => VerifyEmailScreen(
            token: state.uri.queryParameters['token'] ?? '',
            redirectPath: state.uri.queryParameters['redirect'],
          ),
        ),

        GoRoute(
          path: lifeCounterRoutePath,
          builder: (context, state) => LotusLifeCounterScreen(
            deckId: state.uri.queryParameters['deckId'],
            deckName: state.uri.queryParameters['deckName'],
            deckSnapshotHash: state.uri.queryParameters['deckSnapshotHash'],
            deckVersionAtEpochMs: int.tryParse(
              state.uri.queryParameters['deckVersionAt'] ?? '',
            ),
          ),
        ),

        ShellRoute(
          builder: (context, state, child) {
            return MainScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/onboarding/core-flow',
              builder: (context, state) {
                final auth = context.read<AuthProvider>();
                return OnboardingCoreFlowScreen(
                  userId: auth.user?.id ?? '',
                  initialStorageWarning:
                      state.uri.queryParameters['storage'] == 'unavailable',
                  onSettled: auth.markOnboardingSettled,
                );
              },
            ),
            GoRoute(
              path: '/decks',
              builder: (context, state) => const DeckListScreen(),
              routes: [
                GoRoute(
                  path: 'generate',
                  builder: (context, state) {
                    final initialFormat = state.uri.queryParameters['format'];
                    return DeckGenerateScreen(
                      initialFormat: initialFormat,
                      draftOwnerId: context.read<AuthProvider>().user?.id ?? '',
                    );
                  },
                ),
                GoRoute(
                  path: 'import',
                  builder: (context, state) {
                    final initialFormat = state.uri.queryParameters['format'];
                    return DeckImportScreen(
                      initialFormat: initialFormat,
                      draftOwnerId: context.read<AuthProvider>().user?.id ?? '',
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return DeckDetailsScreen(
                      deckId: id,
                      initialOptimizationIntent:
                          state.uri.queryParameters['optimize'],
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        final mode = state.uri.queryParameters['mode'];
                        return CardSearchScreen(deckId: id, mode: mode);
                      },
                    ),
                    if (LaunchFeatures.scannerEnabled)
                      GoRoute(
                        path: 'scan',
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return CardScannerScreen(deckId: id);
                        },
                      ),
                    GoRoute(
                      path: 'post-game',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        final startedAtMs = int.tryParse(
                          state.uri.queryParameters['startedAt'] ?? '',
                        );
                        final endedAtMs = int.tryParse(
                          state.uri.queryParameters['endedAt'] ?? '',
                        );
                        final deckVersionAtMs = int.tryParse(
                          state.uri.queryParameters['deckVersionAt'] ?? '',
                        );
                        return PostGameNotesScreen(
                          deckId: id,
                          playSessionId:
                              state.uri.queryParameters['playSessionId'],
                          sessionStartedAt: startedAtMs == null
                              ? null
                              : DateTime.fromMillisecondsSinceEpoch(
                                  startedAtMs,
                                ),
                          sessionEndedAt: endedAtMs == null
                              ? null
                              : DateTime.fromMillisecondsSinceEpoch(endedAtMs),
                          deckSnapshotHash:
                              state.uri.queryParameters['deckSnapshotHash'],
                          deckVersionAt: deckVersionAtMs == null
                              ? null
                              : DateTime.fromMillisecondsSinceEpoch(
                                  deckVersionAtMs,
                                ),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'battle-replays',
                      builder: (context, state) => BattleReplaysScreen(
                        deckId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/plans',
              builder: (context, state) => const PlanScreen(),
            ),
            GoRoute(
              path: '/cards/:cardId',
              builder: (context, state) => CardDetailRouteScreen(
                cardId: state.pathParameters['cardId']!,
                initialCard: state.extra is DeckCardItem
                    ? state.extra as DeckCardItem
                    : null,
              ),
            ),
            GoRoute(
              path: '/upgrade',
              builder: (context, state) => const UpgradeScreen(),
            ),
            GoRoute(
              path: '/checkout',
              builder: (context, state) => const CheckoutScreen(),
            ),
            GoRoute(
              path: '/collection',
              builder: (context, state) {
                final tabStr = state.uri.queryParameters['tab'];
                final tab = int.tryParse(tabStr ?? '') ?? 0;
                return CollectionScreen(initialTab: tab);
              },
            ),
            GoRoute(
              path: '/collection/latest-set',
              builder: (context, state) => const LatestSetCollectionScreen(),
            ),
            GoRoute(
              path: '/collection/sets',
              builder: (context, state) => const SetsCatalogScreen(),
              routes: [
                GoRoute(
                  path: ':code',
                  builder: (context, state) {
                    final code = state.pathParameters['code']!;
                    return SetCardsScreen(setCode: code);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/market',
              redirect: (context, state) => '/community?tab=3',
            ),
            GoRoute(
              path: '/community',
              builder: (context, state) {
                final tab = int.tryParse(
                  state.uri.queryParameters['tab'] ?? '',
                );
                return CommunityScreen(initialTab: tab ?? 0);
              },
              routes: [
                GoRoute(
                  path: 'search-users',
                  builder: (context, state) => const UserSearchScreen(),
                ),
                GoRoute(
                  path: 'user/:userId',
                  builder: (context, state) {
                    final userId = state.pathParameters['userId']!;
                    return UserProfileScreen(userId: userId);
                  },
                ),
                GoRoute(
                  path: 'decks/:deckId',
                  builder: (context, state) {
                    final deckId = state.pathParameters['deckId']!;
                    return CommunityDeckDetailScreen(deckId: deckId);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/messages',
              builder: (context, state) => const MessageInboxScreen(),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  builder: (context, state) {
                    final conversationId =
                        state.pathParameters['conversationId']!;
                    final otherUser = state.extra is ConversationUser
                        ? state.extra as ConversationUser
                        : null;
                    return ChatScreen(
                      conversationId: conversationId,
                      otherUser: otherUser,
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationPermissionBoundary(
                child: NotificationScreen(),
              ),
            ),
            GoRoute(
              path: '/trades',
              builder: (context, state) => const TradeInboxScreen(),
              routes: [
                GoRoute(
                  path: 'create/:receiverId',
                  builder: (context, state) {
                    final receiverId = state.pathParameters['receiverId']!;
                    final args = state.extra;
                    return CreateTradeScreen(
                      receiverId: receiverId,
                      initialType: args is CreateTradeRouteArgs
                          ? args.initialType
                          : 'trade',
                      preselectedItem: args is CreateTradeRouteArgs
                          ? args.preselectedItem
                          : null,
                    );
                  },
                ),
                GoRoute(
                  path: ':tradeId',
                  builder: (context, state) {
                    final tradeId = state.pathParameters['tradeId']!;
                    return TradeDetailScreen(tradeId: tradeId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
    _configureRealtimePushHandlers();
  }

  void _configureRealtimePushHandlers() {
    _realtimeCoordinator = RealtimeNotificationCoordinator(
      router: _router,
      notificationProvider: _notificationProvider,
      messageProvider: _messageProvider,
      tradeProvider: _tradeProvider,
    );

    final pushService = PushNotificationService();
    pushService.onForegroundMessage = (message) {
      unawaited(_realtimeCoordinator.handleForegroundData(message.data));
    };
    pushService.onMessageTap = (message) {
      _realtimeCoordinator.handleMessageTapData(message.data);
    };
  }

  void _onAuthChanged() {
    final status = _authProvider.status;

    if (_authProvider.isAuthenticated) {
      if (_hadAuthenticatedSession) {
        unawaited(AppObservability.instance.setUserContext(_authProvider.user));
        return;
      }

      _hadAuthenticatedSession = true;
      unawaited(AppObservability.instance.setUserContext(_authProvider.user));
      _scheduleAuthenticatedWarmup();
      return;
    }

    // Ignora estados transitórios para evitar efeitos colaterais (ex.: 401 em loop).
    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return;
    }

    if (status == AuthStatus.unauthenticated) {
      _authenticatedWarmupTimer?.cancel();
      _authenticatedWarmupTimer = null;
      unawaited(AppObservability.instance.clearUserContext());
      // Parar polling e limpar todo o estado dos providers ao deslogar
      _notificationProvider.stopPolling();
      _messageProvider.stopPolling();

      // Remove FCM token do server apenas quando houve sessão autenticada antes.
      // Evita chamadas redundantes no boot/login sem token válido no backend.
      if (_hadAuthenticatedSession) {
        if (!_disableFirebaseStartup && !_disablePushInit) {
          unawaited(PushNotificationService().unregister());
        }
      }
      _hadAuthenticatedSession = false;

      _clearAllProvidersState();
    }
  }

  void _scheduleAuthenticatedWarmup() {
    _authenticatedWarmupTimer?.cancel();
    _authenticatedWarmupTimer = Timer(const Duration(milliseconds: 1200), () {
      _authenticatedWarmupTimer = null;
      if (!_authProvider.isAuthenticated || !_hadAuthenticatedSession) return;

      _notificationProvider.startPolling();
      _messageProvider.startPolling();
      unawaited(_commercialProvider.refreshFromServer());

      if (!_disableFirebaseStartup && !_disablePushInit) {
        unawaited(PushNotificationService().registerIfAuthorized());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_authProvider.isAuthenticated && _hadAuthenticatedSession) {
          _scheduleAuthenticatedWarmup();
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _authenticatedWarmupTimer?.cancel();
        _authenticatedWarmupTimer = null;
        _notificationProvider.stopPolling();
        _messageProvider.stopPolling();
        return;
    }
  }

  /// Limpa o estado de todos os providers ao deslogar, evitando dados stale
  /// entre sessões de diferentes usuários.
  void _clearAllProvidersState() {
    _deckProvider.clearAllState();
    _cardProvider.clearSearch();
    _marketProvider.clearAllState();
    _communityProvider.clearAllState();
    _socialProvider.clearAllState();
    _binderProvider.clearAllState();
    _tradeProvider.clearAllState();
    _messageProvider.clearAllState();
    _notificationProvider.clearAllState();
    unawaited(_commercialProvider.clearRemoteSnapshot());
  }

  @override
  void dispose() {
    _authenticatedWarmupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_onAuthChanged);
    ApiClient.setSessionExpiredHandler(null);
    _notificationProvider.stopPolling();
    _messageProvider.stopPolling();
    final pushService = PushNotificationService();
    pushService.onForegroundMessage = null;
    pushService.onMessageTap = null;
    _router.dispose();
    _deckProvider.dispose();
    _cardProvider.dispose();
    _marketProvider.dispose();
    _communityProvider.dispose();
    _socialProvider.dispose();
    _binderProvider.dispose();
    _tradeProvider.dispose();
    _messageProvider.dispose();
    _notificationProvider.dispose();
    _commercialProvider.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _deckProvider),
        ChangeNotifierProvider.value(value: _cardProvider),
        ChangeNotifierProvider.value(value: _marketProvider),
        ChangeNotifierProvider.value(value: _communityProvider),
        ChangeNotifierProvider.value(value: _socialProvider),
        ChangeNotifierProvider.value(value: _binderProvider),
        ChangeNotifierProvider.value(value: _tradeProvider),
        ChangeNotifierProvider.value(value: _messageProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        ChangeNotifierProvider.value(value: _commercialProvider),
      ],
      child: MaterialApp.router(
        title: 'ManaLoom - Deck Builder',
        theme: AppTheme.darkTheme,
        scrollBehavior: const ManaLoomScrollBehavior(),
        routerConfig: _router,
        builder: buildManaLoomDebugAccessibilityTools,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
