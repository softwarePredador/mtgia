import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/config/release_capabilities.dart';
import 'package:manaloom/core/services/activation_funnel_service.dart'
    as activation;
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/main_scaffold.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/home/home_screen.dart';
import 'package:manaloom/features/home/onboarding_core_flow_screen.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';
import 'web_viewport_reset.dart';

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
const _userId = 'visual-onboarding-user';
const _requiredCheckpoints = <String>[
  'onboarding_intent_00_first_run',
  'onboarding_intent_01_build_path',
  'onboarding_intent_02_resumed_plan',
  'onboarding_intent_03_skipped_home',
  'onboarding_intent_04_completed_home',
];

class _NoopApiClient extends ApiClient {}

class _RuntimeDeckProvider extends DeckProvider {
  _RuntimeDeckProvider() : super(apiClient: _NoopApiClient());

  List<Deck> _seededDecks = <Deck>[];

  @override
  List<Deck> get decks => List<Deck>.unmodifiable(_seededDecks);

  @override
  Future<void> fetchDecks({bool silent = false}) async {}

  void replaceDecks(List<Deck> decks) {
    _seededDecks = List<Deck>.of(decks);
    notifyListeners();
  }
}

class _RuntimeOnboardingRepository implements OnboardingStateRepository {
  OnboardingState state = const OnboardingState();

  @override
  Future<OnboardingState> load(String userId) async => state;

  @override
  Future<void> saveProgress(
    String userId, {
    required String selectedFormat,
    OnboardingGoal? selectedGoal,
    OnboardingExperience? experience,
    OnboardingBuildMode? buildMode,
  }) async {
    state = state.copyWith(
      selectedFormat: selectedFormat,
      selectedGoal: selectedGoal,
      experience: experience,
      buildMode: buildMode,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
    OnboardingGoal? selectedGoal,
    OnboardingExperience? experience,
    OnboardingBuildMode? buildMode,
  }) async {
    state = OnboardingState(
      disposition: disposition,
      selectedFormat: selectedFormat,
      selectedGoal: selectedGoal ?? state.selectedGoal,
      experience: experience ?? state.experience,
      buildMode: buildMode ?? state.buildMode,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

class _NoopEventTracker implements activation.ActivationEventTracker {
  @override
  Future<void> track(
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<void> trackOnce(
    String dedupeKey,
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) async {}
}

GoRouter _router(
  _RuntimeOnboardingRepository repository,
  _NoopEventTracker eventTracker,
) {
  return GoRouter(
    initialLocation: '/onboarding/core-flow',
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/onboarding/core-flow',
            pageBuilder: (_, __) => NoTransitionPage<void>(
              child: OnboardingCoreFlowScreen(
                userId: _userId,
                stateRepository: repository,
                eventTracker: eventTracker,
              ),
            ),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => NoTransitionPage<void>(
              child: HomeScreen(
                userId: _userId,
                lifeCounterAvailable: false,
                onboardingStateRepository: repository,
              ),
            ),
          ),
          GoRoute(
            path: '/proof/blank',
            pageBuilder: (_, __) => const NoTransitionPage<void>(
              child: ColoredBox(color: AppTheme.backgroundAbyss),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _runtimeApp({
  required GoRouter router,
  required _RuntimeDeckProvider deckProvider,
}) {
  final api = _NoopApiClient();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ReleaseCapabilitiesProvider>.value(
        value: ReleaseCapabilitiesProvider.seeded(const {
          ReleaseCapability.decksPrivate,
        }),
      ),
      ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
      ChangeNotifierProvider<MessageProvider>(
        create: (_) => MessageProvider(apiClient: api),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(apiClient: api),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real Web proves first run, task choice, resume, skip and contextual return',
    (tester) async {
      _expectRuntimeContract();
      _emitRuntimeContext();
      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));

      final repository = _RuntimeOnboardingRepository();
      final deckProvider = _RuntimeDeckProvider();
      final router = _router(repository, _NoopEventTracker());
      addTearDown(router.dispose);
      await tester.pumpWidget(
        _runtimeApp(router: router, deckProvider: deckProvider),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('onboarding-intent-screen')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[0],
        focus: find.byKey(const Key('onboarding-intent-hero')),
      );

      await _tapWhenVisible(
        tester,
        find.byKey(const Key('onboarding-goal-buildDeck')),
      );
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('onboarding-experience-returning')),
      );
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('onboarding-format-dropdown')),
      );
      dropdown.onChanged?.call('modern');
      await tester.pump(const Duration(milliseconds: 250));
      await _tapWhenVisible(
        tester,
        find.byKey(const Key('onboarding-build-manual')),
      );
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[1],
        focus: find.byKey(const Key('onboarding-primary-action')),
      );

      router.go('/proof/blank');
      await tester.pump(const Duration(milliseconds: 150));
      router.go('/onboarding/core-flow');
      await pumpUntilFound(
        tester,
        find.byKey(const Key('onboarding-intent-screen')),
      );
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.state.selectedGoal, OnboardingGoal.buildDeck);
      expect(repository.state.experience, OnboardingExperience.returning);
      expect(repository.state.selectedFormat, 'modern');
      expect(repository.state.buildMode, OnboardingBuildMode.manual);
      expect(find.text('PLANO RETOMADO'), findsOneWidget);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[2],
        focus: find.byKey(const Key('onboarding-intent-hero')),
      );

      await _tapWhenVisible(
        tester,
        find.byKey(const Key('onboarding-skip-action')),
      );
      await pumpUntilFound(tester, find.byKey(const Key('home-hero-frame')));
      expect(repository.state.disposition, OnboardingDisposition.skipped);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[3],
        focus: find.byKey(const Key('home-hero-frame')),
      );

      repository.state = const OnboardingState(
        disposition: OnboardingDisposition.completed,
        selectedFormat: 'modern',
        selectedGoal: OnboardingGoal.buildDeck,
        experience: OnboardingExperience.returning,
        buildMode: OnboardingBuildMode.manual,
      );
      deckProvider.replaceDecks([
        Deck(
          id: 'completed-onboarding-deck',
          name: 'Izzet Phoenix revisado',
          format: 'modern',
          isPublic: false,
          createdAt: DateTime(2026, 8, 6),
          cardCount: 60,
        ),
      ]);
      router.go('/proof/blank');
      await tester.pump(const Duration(milliseconds: 150));
      router.go('/home');
      await pumpUntilFound(tester, find.byKey(const Key('home-hero-frame')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Continue\nIzzet Phoenix revisado'), findsOneWidget);
      await _capture(
        binding,
        tester,
        _requiredCheckpoints[4],
        focus: find.byKey(const Key('home-hero-frame')),
      );
    },
  );
}

Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 180));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 280));
  expect(tester.takeException(), isNull);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint, {
  Finder? focus,
}) async {
  resetBrowserViewport();
  if (focus != null) await tester.ensureVisible(focus);
  await tester.pump(const Duration(milliseconds: 450));
  expect(tester.takeException(), isNull, reason: 'Before $checkpoint');
  expectNoRawTechnicalErrorText(tester);
  if (_captureRuntimeProof) {
    await captureVisualProof(
      binding,
      tester,
      checkpoint,
      beforeTakeScreenshot: () async {
        // ensureVisible scrolls only the Flutter list. Chrome must stay pinned
        // to the release viewport or a focused CTA can shift the whole canvas.
        resetBrowserViewport();
        await tester.pump();
      },
    );
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
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'onboarding_intent', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
  );
}
