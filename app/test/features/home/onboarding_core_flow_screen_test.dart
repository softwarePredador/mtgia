import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/services/activation_funnel_service.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/home/onboarding_core_flow_screen.dart';
import 'package:manaloom/features/home/services/onboarding_state_store.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class _FakeOnboardingRepository implements OnboardingStateRepository {
  _FakeOnboardingRepository({this.state = const OnboardingState()});

  OnboardingState state;
  bool failLoad = false;
  bool failWrites = false;
  int loadCalls = 0;
  final List<String> savedFormats = <String>[];
  final List<OnboardingDisposition> settlements = <OnboardingDisposition>[];

  @override
  Future<OnboardingState> load(String userId) async {
    loadCalls += 1;
    if (failLoad) {
      throw const OnboardingPersistenceException('load failed');
    }
    return state;
  }

  @override
  Future<void> saveProgress(
    String userId, {
    required String selectedFormat,
  }) async {
    if (failWrites) {
      throw const OnboardingPersistenceException('write failed');
    }
    savedFormats.add(selectedFormat);
    state = state.copyWith(selectedFormat: selectedFormat);
  }

  @override
  Future<void> settle(
    String userId, {
    required String selectedFormat,
    required OnboardingDisposition disposition,
  }) async {
    if (failWrites) {
      throw const OnboardingPersistenceException('write failed');
    }
    settlements.add(disposition);
    state = OnboardingState(
      disposition: disposition,
      selectedFormat: selectedFormat,
    );
  }
}

class _FakeEventTracker implements ActivationEventTracker {
  final List<String> events = <String>[];
  final List<String> onceKeys = <String>[];

  @override
  Future<void> track(
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) async {
    events.add(eventName);
  }

  @override
  Future<void> trackOnce(
    String dedupeKey,
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) async {
    onceKeys.add(dedupeKey);
    events.add(eventName);
  }
}

Widget _subject({
  required _FakeOnboardingRepository repository,
  required _FakeEventTracker tracker,
  required ValueChanged<GoRouter> onRouter,
  VoidCallback? onSettled,
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding/core-flow',
    routes: [
      GoRoute(
        path: '/onboarding/core-flow',
        builder: (_, _) => OnboardingCoreFlowScreen(
          userId: 'user-widget',
          stateRepository: repository,
          eventTracker: tracker,
          onSettled: onSettled,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(key: Key('home-destination')),
      ),
      GoRoute(
        path: '/decks',
        builder: (_, _) => const Scaffold(key: Key('decks-destination')),
      ),
      GoRoute(
        path: '/decks/generate',
        builder: (_, _) => const Scaffold(key: Key('generate-destination')),
      ),
      GoRoute(
        path: '/decks/import',
        builder: (_, _) => const Scaffold(key: Key('import-destination')),
      ),
    ],
  );
  onRouter(router);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MessageProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('resumes format and remains scrollable at 320x568 text 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeOnboardingRepository(
      state: const OnboardingState(selectedFormat: 'pioneer'),
    );
    final tracker = _FakeEventTracker();
    late GoRouter router;
    await tester.pumpWidget(
      _subject(
        repository: repository,
        tracker: tracker,
        textScale: 2,
        onRouter: (value) => router = value,
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'overflow before scrolling the onboarding',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('onboarding-format-dropdown')),
      180,
      scrollable: find.descendant(
        of: find.byKey(const Key('onboarding-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('onboarding-format-dropdown')),
    );
    expect(dropdown.initialValue, 'pioneer');
    expect(
      tester.takeException(),
      isNull,
      reason: 'overflow while showing the format step',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('onboarding-complete-action')),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('onboarding-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('onboarding-complete-action')), findsOneWidget);
    expect(
      tracker.events.where((event) => event == 'core_flow_started'),
      hasLength(1),
    );
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: exception is FlutterError ? exception.toStringDeep() : null,
    );
  });

  testWidgets('write failure blocks navigation and keeps onboarding pending', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository()..failWrites = true;
    final tracker = _FakeEventTracker();
    late GoRouter router;
    await tester.pumpWidget(
      _subject(
        repository: repository,
        tracker: tracker,
        onRouter: (value) => router = value,
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('onboarding-skip-action')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('onboarding-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('onboarding-skip-action')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding-persistence-error')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-destination')), findsNothing);
    expect(repository.settlements, isEmpty);
    expect(tracker.events, isNot(contains('onboarding_skipped')));
  });

  testWidgets(
    'skip persists before navigation and emits one semantic outcome',
    (tester) async {
      final repository = _FakeOnboardingRepository();
      final tracker = _FakeEventTracker();
      var settledCalls = 0;
      late GoRouter router;
      await tester.pumpWidget(
        _subject(
          repository: repository,
          tracker: tracker,
          onSettled: () => settledCalls += 1,
          onRouter: (value) => router = value,
        ),
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('onboarding-skip-action')),
        240,
        scrollable: find.descendant(
          of: find.byKey(const Key('onboarding-scroll-view')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const Key('onboarding-skip-action')));
      await tester.pumpAndSettle();

      expect(repository.settlements, [OnboardingDisposition.skipped]);
      expect(settledCalls, 1);
      expect(
        tracker.events.where((event) => event == 'onboarding_skipped'),
        hasLength(1),
      );
      expect(find.byKey(const Key('home-destination')), findsOneWidget);
    },
  );

  testWidgets('base choice saves the resumed format before deep navigation', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository();
    final tracker = _FakeEventTracker();
    late GoRouter router;
    await tester.pumpWidget(
      _subject(
        repository: repository,
        tracker: tracker,
        onRouter: (value) => router = value,
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('onboarding-format-dropdown')),
    );
    dropdown.onChanged?.call('modern');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-import-action')),
    );
    await tester.tap(find.byKey(const Key('onboarding-import-action')));
    await tester.pumpAndSettle();

    expect(repository.savedFormats, ['modern', 'modern']);
    expect(
      tracker.events,
      containsAll(['format_selected', 'base_choice_import']),
    );
    expect(find.byKey(const Key('import-destination')), findsOneWidget);
  });

  testWidgets('load failure exposes retry without inferring completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeOnboardingRepository()..failLoad = true;
    final tracker = _FakeEventTracker();
    late GoRouter router;
    await tester.pumpWidget(
      _subject(
        repository: repository,
        tracker: tracker,
        textScale: 2,
        onRouter: (value) => router = value,
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('onboarding-persistence-error')),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('onboarding-scroll-view')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(
      find.byKey(const Key('onboarding-persistence-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('onboarding-persistence-retry')),
      findsOneWidget,
    );
    expect(repository.state.isSettled, isFalse);
    expect(tester.takeException(), isNull);

    repository.failLoad = false;
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-persistence-retry')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-persistence-retry')));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.byKey(const Key('onboarding-persistence-error')), findsNothing);
  });

  testWidgets('keyboard reaches format and primary actions in visual order', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository();
    final tracker = _FakeEventTracker();
    late GoRouter router;
    await tester.pumpWidget(
      _subject(
        repository: repository,
        tracker: tracker,
        onRouter: (value) => router = value,
      ),
    );
    addTearDown(router.dispose);
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    for (var index = 0; index < 3; index += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(
      _primaryFocusIsInside(
        find.byKey(const Key('onboarding-format-dropdown')),
      ),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _primaryFocusIsInside(
        find.byKey(const Key('onboarding-generate-action')),
      ),
      isTrue,
    );
  });
}

bool _primaryFocusIsInside(Finder ancestorFinder) {
  final primaryContext = FocusManager.instance.primaryFocus?.context;
  if (primaryContext is! Element) return false;
  final ancestors = ancestorFinder.evaluate();
  if (ancestors.length != 1) return false;
  final ancestor = ancestors.single;
  if (primaryContext == ancestor) return true;
  var found = false;
  primaryContext.visitAncestorElements((element) {
    if (element == ancestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
