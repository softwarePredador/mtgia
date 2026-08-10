import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/binder/models/binder_import_models.dart';
import 'package:manaloom/features/binder/providers/binder_import_provider.dart';
import 'package:manaloom/features/binder/screens/binder_import_screen.dart';
import 'package:manaloom/features/binder/services/binder_import_draft_store.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';
import 'visual_capture_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
  defaultValue: true,
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _ringImageUrl = String.fromEnvironment('MANALOOM_VISUAL_RING_IMAGE_URL');
const _studyImageUrl = String.fromEnvironment(
  'MANALOOM_VISUAL_STUDY_IMAGE_URL',
);
const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 390,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 844,
);

const _requiredCheckpoints = <String>[
  'binder_import_00_source',
  'binder_import_01_review_duplicates',
  'binder_import_02_plan',
  'binder_import_03_confirmation',
  'binder_import_04_partial_failure',
  'binder_import_05_retry_success',
  'binder_import_06_history',
];

class _RuntimeBinderImportApi extends ApiClient {
  int applyCalls = 0;

  Map<String, dynamic> get _solRing => <String, dynamic>{
    'id': '10000000-0000-4000-8000-000000000001',
    'name': 'Sol Ring',
    'set_code': 'CMM',
    'set_name': 'Commander Masters',
    'collector_number': '396',
    'rarity': 'uncommon',
    'foil': true,
    if (_ringImageUrl.isNotEmpty) 'image_url': _ringImageUrl,
  };

  Map<String, dynamic> get _rhysticStudyWot => <String, dynamic>{
    'id': '20000000-0000-4000-8000-000000000001',
    'name': 'Rhystic Study',
    'set_code': 'WOT',
    'set_name': 'Wilds of Eldraine: Enchanting Tales',
    'collector_number': '25',
    'rarity': 'rare',
    'foil': true,
    if (_studyImageUrl.isNotEmpty) 'image_url': _studyImageUrl,
  };

  Map<String, dynamic> get _rhysticStudyJmp => <String, dynamic>{
    'id': '20000000-0000-4000-8000-000000000002',
    'name': 'Rhystic Study',
    'set_code': 'JMP',
    'set_name': 'Jumpstart',
    'collector_number': '169',
    'rarity': 'rare',
    'foil': false,
    if (_studyImageUrl.isNotEmpty) 'image_url': _studyImageUrl,
  };

  @override
  Future<ApiResponse> get(String endpoint) async {
    final cardName = Uri.parse(endpoint).queryParameters['name'];
    if (cardName == 'Sol Ring') {
      return ApiResponse(200, <String, dynamic>{
        'data': [_solRing],
      });
    }
    if (cardName == 'Rhystic Study') {
      return ApiResponse(200, <String, dynamic>{
        'data': [_rhysticStudyWot, _rhysticStudyJmp],
      });
    }
    throw StateError('Unexpected runtime GET $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/cards/resolve/batch') {
      return ApiResponse(200, <String, dynamic>{
        'data': const [
          {
            'input_name': 'Sol Ring',
            'card_id': '10000000-0000-4000-8000-000000000001',
            'matched_name': 'Sol Ring',
            'strategy': 'exact',
          },
          {
            'input_name': 'Rhystic Study',
            'card_id': '20000000-0000-4000-8000-000000000001',
            'matched_name': 'Rhystic Study',
            'strategy': 'exact',
          },
        ],
        'ambiguous': const [],
        'unresolved': const [],
      });
    }
    if (endpoint == '/binder/import/preview') {
      final items = (body['items'] as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
      return ApiResponse(200, <String, dynamic>{
        'data': items
            .map((item) {
              final isSolRing = item['card_id'] == _solRing['id'];
              final baseline = isSolRing ? 2 : 0;
              final quantity = item['quantity'] as int;
              return <String, dynamic>{
                ...item,
                'status': 'ready',
                'action': isSolRing ? 'update' : 'create',
                'card': isSolRing ? _solRing : _rhysticStudyWot,
                if (isSolRing) 'existing_id': 'binder-runtime-sol-ring',
                'baseline_quantity': baseline,
                'target_quantity': baseline + quantity,
                'availability': <String, dynamic>{
                  'owned_quantity': baseline,
                  'allocated_quantity': isSolRing ? 1 : 0,
                  'committed_trade_quantity': 0,
                  'free_quantity': isSolRing ? 1 : 0,
                  'missing_quantity': isSolRing ? 0 : quantity,
                },
              };
            })
            .toList(growable: false),
        'summary': const {
          'owned_quantity': 2,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': 1,
          'missing_quantity': 1,
        },
      });
    }
    if (endpoint == '/binder/import/apply') {
      applyCalls++;
      final items = (body['items'] as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false);
      final firstAttempt = applyCalls == 1;
      final results = items
          .map((item) {
            final isSolRing = item['card_id'] == _solRing['id'];
            if (firstAttempt && !isSolRing) {
              return <String, dynamic>{
                'input_id': item['input_id'],
                'status': 'failed',
                'code': 'binder_import_inventory_changed',
                'message': 'A quantidade mudou desde a revisão.',
              };
            }
            return <String, dynamic>{
              'input_id': item['input_id'],
              'status': isSolRing ? 'updated' : 'created',
            };
          })
          .toList(growable: false);
      return ApiResponse(200, <String, dynamic>{
        'batch_id': body['batch_id'],
        'data': results,
        'total_applied': results
            .where((result) => result['status'] != 'failed')
            .length,
        'total_failed': results
            .where((result) => result['status'] == 'failed')
            .length,
        'summary': <String, dynamic>{
          'owned_quantity': firstAttempt ? 5 : 6,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': firstAttempt ? 4 : 5,
          'missing_quantity': firstAttempt ? 1 : 0,
        },
      });
    }
    throw StateError('Unexpected runtime POST $endpoint');
  }
}

class _RuntimeDraftStore extends BinderImportDraftStore {
  BinderImportDraft? draft;
  List<BinderImportBatchHistory> history = <BinderImportBatchHistory>[];

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
      candidates: candidates
          .map(
            (candidate) => BinderImportCandidate.fromJson(candidate.toJson()),
          )
          .toList(growable: false),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> clearDraft(String ownerId) async => draft = null;

  @override
  Future<void> addHistory(
    String ownerId,
    BinderImportBatchHistory entry,
  ) async {
    history = <BinderImportBatchHistory>[entry, ...history];
  }
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String checkpoint,
) async {
  if (!_captureRuntimeProof) return;
  await captureVisualProof(binding, tester, checkpoint);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 350));
}

Finder _proofKey(String value) {
  return find.byKey(Key(value), skipOffstage: false);
}

void _invokeFilledButton(WidgetTester tester, String key) {
  final callback = tester.widget<FilledButton>(_proofKey(key)).onPressed;
  expect(callback, isNotNull, reason: '$key must be enabled');
  callback!();
}

Future<void> _revealMobileTarget(
  WidgetTester tester,
  Finder target, {
  required bool forward,
}) async {
  if (target.evaluate().isEmpty) {
    final mobileScroll = _proofKey('binder-import-mobile-scroll');
    expect(mobileScroll, findsOneWidget);
    final scrollable = find.descendant(
      of: mobileScroll,
      matching: find.byType(Scrollable),
    );
    final state = tester.state<ScrollableState>(scrollable);
    for (
      var attempt = 0;
      attempt < 30 && target.evaluate().isEmpty;
      attempt++
    ) {
      final rawNext = state.position.pixels + (forward ? 320 : -320);
      final next = rawNext.clamp(
        state.position.minScrollExtent,
        state.position.maxScrollExtent,
      );
      state.position.jumpTo(next);
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  expect(target, findsOneWidget);
  await _reveal(tester, target);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'real Web surface proves binder import review, cancel, partial retry and history',
    (tester) async {
      if (_captureRuntimeProof) {
        expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(_uiProofProfile, isNotEmpty);
        expect(_uiProofTarget, 'web_real_build');
        expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
        expect(_ringImageUrl, startsWith('http://127.0.0.1:'));
        expect(_studyImageUrl, startsWith('http://127.0.0.1:'));
        // Consumed by tool/ui_runtime_evidence.dart. The host capture script
        // rewrites this marker once so release-mode print elision cannot make
        // an otherwise valid capture unbound.
        // ignore: avoid_print
        print(
          'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': 'binder_import', 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': _requiredCheckpoints})}',
        );
      }

      await binding.setSurfaceSize(
        Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
      );
      addTearDown(() => binding.setSurfaceSize(null));

      final api = _RuntimeBinderImportApi();
      final draftStore = _RuntimeDraftStore();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: BinderImportScreen(
            ownerId: 'runtime-user',
            apiClient: api,
            draftStore: draftStore,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('binder-import-screen')), findsOneWidget);
      final provider = Provider.of<BinderImportProvider>(
        tester.element(find.byKey(const Key('binder-import-screen'))),
        listen: false,
      );
      await pumpUntil(
        tester,
        () => !provider.isLoadingDraft,
        description: 'the controlled Binder Import draft to initialize',
        attempts: 20,
        step: const Duration(milliseconds: 100),
      );
      await pumpUntilFound(tester, _proofKey('binder-import-source-field'));
      final sourceController = tester
          .widget<TextField>(_proofKey('binder-import-source-field'))
          .controller!;
      const source =
          '1 Sol Ring (CMM) 396\n'
          '2 Sol Ring (CMM) 396\n'
          '1 Rhystic Study\n'
          'linha sem quantidade';
      sourceController.text = source;
      await tester.pump(const Duration(milliseconds: 500));
      await _capture(binding, tester, 'binder_import_00_source');

      await provider.reviewSource(source, listType: 'have');
      await tester.pumpAndSettle();
      await _revealMobileTarget(
        tester,
        _proofKey('binder-import-candidate-line-3'),
        forward: true,
      );

      expect(provider.candidates, hasLength(2));
      expect(provider.candidates.first.quantity, 3);
      expect(provider.candidates.first.hasDuplicateSources, isTrue);
      expect(provider.invalidLines, <String>['linha sem quantidade']);
      expect(find.text('2 linhas', skipOffstage: false), findsOneWidget);
      await _reveal(tester, _proofKey('binder-import-candidate-line-1'));
      await _capture(binding, tester, 'binder_import_01_review_duplicates');

      final study = provider.candidates.singleWhere(
        (candidate) => candidate.id == 'line-3',
      );
      expect(study.status, BinderImportCandidateStatus.needsPrinting);
      await provider.selectPrinting(study.id, study.printings.first);
      await tester.pumpAndSettle();
      expect(provider.readyCount, 2);
      await provider.previewBatch();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, _proofKey('binder-import-plan-summary'));
      expect(provider.plans, hasLength(2));
      expect(api.applyCalls, 0);
      await _reveal(tester, _proofKey('binder-import-plan-summary'));
      await _capture(binding, tester, 'binder_import_02_plan');

      _invokeFilledButton(tester, 'binder-import-apply-button');
      await pumpUntilFound(
        tester,
        _proofKey('binder-import-apply-confirmation'),
      );
      await _capture(binding, tester, 'binder_import_03_confirmation');
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Voltar à revisão'),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(api.applyCalls, 0, reason: 'Cancel must never persist the plan.');

      _invokeFilledButton(tester, 'binder-import-apply-button');
      await pumpUntilFound(
        tester,
        _proofKey('binder-import-confirm-apply-button'),
      );
      _invokeFilledButton(tester, 'binder-import-confirm-apply-button');
      await pumpUntilFound(tester, _proofKey('binder-import-retry-button'));
      expect(api.applyCalls, 1);
      expect(
        provider.candidates
            .singleWhere((candidate) => candidate.id == 'line-1')
            .status,
        BinderImportCandidateStatus.applied,
      );
      expect(
        provider.candidates
            .singleWhere((candidate) => candidate.id == 'line-3')
            .status,
        BinderImportCandidateStatus.failed,
      );
      await _reveal(tester, _proofKey('binder-import-candidate-line-3'));
      await _capture(binding, tester, 'binder_import_04_partial_failure');

      await provider.retryFailed();
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, _proofKey('binder-import-apply-button'));
      expect(provider.plans, hasLength(1));
      _invokeFilledButton(tester, 'binder-import-apply-button');
      await pumpUntilFound(
        tester,
        _proofKey('binder-import-confirm-apply-button'),
      );
      _invokeFilledButton(tester, 'binder-import-confirm-apply-button');
      await pumpUntilFound(tester, _proofKey('binder-import-finish-button'));
      expect(api.applyCalls, 2);
      expect(
        provider.candidates,
        everyElement(
          isA<BinderImportCandidate>().having(
            (candidate) => candidate.status,
            'status',
            BinderImportCandidateStatus.applied,
          ),
        ),
      );
      expect(draftStore.history, hasLength(2));
      await _reveal(tester, _proofKey('binder-import-candidate-line-3'));
      await _capture(binding, tester, 'binder_import_05_retry_success');

      await _revealMobileTarget(
        tester,
        _proofKey('binder-import-history'),
        forward: false,
      );
      await tester.tap(_proofKey('binder-import-history'));
      await tester.pumpAndSettle();
      expect(
        find.text('1 aplicada(s) • 1 falha(s)', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('1 aplicada(s) • 0 falha(s)', skipOffstage: false),
        findsOneWidget,
      );
      await _capture(binding, tester, 'binder_import_06_history');
      expect(tester.takeException(), isNull);
    },
  );
}
