import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/models/binder_import_models.dart';
import 'package:manaloom/features/binder/providers/binder_import_provider.dart';
import 'package:manaloom/features/binder/screens/binder_import_screen.dart';
import 'package:manaloom/features/binder/services/binder_import_draft_store.dart';
import 'package:provider/provider.dart';

class _ScreenImportApi extends ApiClient {
  int applyCalls = 0;
  bool failApply = false;

  @override
  Future<ApiResponse> get(String endpoint) async => ApiResponse(200, {
    'data': const [
      {
        'id': '00000000-0000-4000-8000-000000000001',
        'name': 'Sol Ring',
        'set_code': 'CMM',
        'set_name': 'Commander Masters',
        'collector_number': '396',
        'rarity': 'uncommon',
        'foil': true,
      },
    ],
  });

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/cards/resolve/batch') {
      return ApiResponse(200, {
        'data': const [
          {
            'input_name': 'Sol Ring',
            'card_id': '00000000-0000-4000-8000-000000000001',
            'matched_name': 'Sol Ring',
          },
        ],
        'ambiguous': const [],
        'unresolved': const [],
      });
    }
    if (endpoint == '/binder/import/preview') {
      final item = ((body['items'] as List).single as Map)
          .cast<String, dynamic>();
      return ApiResponse(200, {
        'data': [
          {
            ...item,
            'status': 'ready',
            'action': 'create',
            'card': const {
              'id': '00000000-0000-4000-8000-000000000001',
              'name': 'Sol Ring',
              'set_code': 'CMM',
              'set_name': 'Commander Masters',
              'collector_number': '396',
            },
            'baseline_quantity': 0,
            'target_quantity': 2,
            'availability': const {
              'owned_quantity': 0,
              'allocated_quantity': 1,
              'committed_trade_quantity': 0,
              'free_quantity': 0,
              'missing_quantity': 1,
            },
          },
        ],
        'summary': const {
          'owned_quantity': 0,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': 0,
          'missing_quantity': 1,
        },
      });
    }
    if (endpoint == '/binder/import/apply') {
      applyCalls++;
      final item = ((body['items'] as List).single as Map)
          .cast<String, dynamic>();
      return ApiResponse(200, {
        'batch_id': body['batch_id'],
        'data': [
          {
            'input_id': item['input_id'],
            'status': failApply ? 'failed' : 'created',
            if (failApply) 'code': 'binder_import_inventory_changed',
            if (failApply) 'message': 'A quantidade mudou desde a revisão.',
          },
        ],
        'total_applied': failApply ? 0 : 1,
        'total_failed': failApply ? 1 : 0,
        'summary': const {
          'owned_quantity': 2,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': 1,
          'missing_quantity': 0,
        },
      });
    }
    throw StateError(endpoint);
  }
}

class _ScreenDraftStore extends BinderImportDraftStore {
  BinderImportDraft? draft;
  List<BinderImportBatchHistory> history = [];

  @override
  Future<BinderImportDraft?> loadDraft(String ownerId) async => draft;

  @override
  Future<List<BinderImportBatchHistory>> loadHistory(String ownerId) async =>
      history;

  @override
  Future<void> saveDraft(
    String ownerId, {
    required String sourceText,
    required List<BinderImportCandidate> candidates,
  }) async {
    draft = BinderImportDraft(
      sourceText: sourceText,
      candidates: candidates,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clearDraft(String ownerId) async => draft = null;

  @override
  Future<void> addHistory(
    String ownerId,
    BinderImportBatchHistory entry,
  ) async {
    history = [entry, ...history];
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _ScreenImportApi api,
  required _ScreenDraftStore store,
  Size size = const Size(390, 844),
  Future<bool> Function()? onOnboardingTaskCompleted,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final screen = BinderImportScreen(
    ownerId: 'user-1',
    apiClient: api,
    draftStore: store,
    onOnboardingTaskCompleted: onOnboardingTaskCompleted,
  );
  if (onOnboardingTaskCompleted == null) {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: screen),
    );
  } else {
    final router = GoRouter(
      initialLocation: '/collection/import',
      routes: [
        GoRoute(path: '/collection/import', builder: (_, __) => screen),
        GoRoute(
          path: '/home',
          builder: (_, __) =>
              const SizedBox(key: Key('onboarding-completed-home')),
        ),
        GoRoute(
          path: '/onboarding/core-flow',
          builder: (_, __) =>
              const SizedBox(key: Key('onboarding-storage-recovery')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.darkTheme, routerConfig: router),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'builds a mobile review queue without persisting before confirm',
    (tester) async {
      final api = _ScreenImportApi();
      await _pumpScreen(tester, api: api, store: _ScreenDraftStore());

      final screen = find.byKey(const Key('binder-import-screen'));
      expect(screen, findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('binder-import-action-bar')))
            .height,
        lessThan(100),
        reason: 'The fixed action bar must not cover the import workspace.',
      );
      expect(
        find.text('Traga sua caixa para o Fichário').hitTestable(),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('binder-import-source-field')),
            )
            .decoration
            ?.helperMaxLines,
        2,
      );
      final provider = Provider.of<BinderImportProvider>(
        tester.element(screen),
        listen: false,
      );
      await provider.reviewSource('2 Sol Ring (CMM) 396', listType: 'have');
      await tester.pumpAndSettle();

      expect(api.applyCalls, 0);

      tester
          .widget<FilledButton>(
            find.byKey(const Key('binder-import-preview-button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(provider.plans, hasLength(1));
      expect(provider.plans.single.baselineQuantity, 0);
      expect(provider.plans.single.targetQuantity, 2);

      tester
          .widget<FilledButton>(
            find.byKey(const Key('binder-import-apply-button')),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('binder-import-apply-confirmation')),
        findsOneWidget,
      );
      expect(api.applyCalls, 0);

      await tester.tap(find.text('Voltar à revisão'));
      await tester.pumpAndSettle();
      expect(api.applyCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('applies after confirmation and exposes reconciled summary', (
    tester,
  ) async {
    final api = _ScreenImportApi();
    final store = _ScreenDraftStore();
    var onboardingCompletions = 0;
    await _pumpScreen(
      tester,
      api: api,
      store: store,
      size: const Size(1180, 900),
      onOnboardingTaskCompleted: () async {
        onboardingCompletions += 1;
        return true;
      },
    );

    final screen = find.byKey(const Key('binder-import-screen'));
    final provider = Provider.of<BinderImportProvider>(
      tester.element(screen),
      listen: false,
    );
    await provider.reviewSource('2 Sol Ring (CMM) 396', listType: 'have');
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('binder-import-preview-button')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('binder-import-apply-button')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('binder-import-confirm-apply-button')),
    );
    await tester.pumpAndSettle();

    expect(api.applyCalls, 1);
    expect(find.text('Criada'), findsOneWidget);
    expect(
      find.byKey(const Key('binder-import-finish-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('binder-import-availability-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('2 Tenho'), findsOneWidget);
    expect(store.history, hasLength(1));
    await tester.tap(find.byKey(const Key('binder-import-finish-button')));
    await tester.pumpAndSettle();

    expect(onboardingCompletions, 1);
    expect(find.byKey(const Key('onboarding-completed-home')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
