import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/binder/models/binder_import_models.dart';
import 'package:manaloom/features/binder/providers/binder_import_provider.dart';
import 'package:manaloom/features/binder/services/binder_import_draft_store.dart';

class _ImportApiClient extends ApiClient {
  bool failApply = false;

  @override
  Future<ApiResponse> get(String endpoint) async {
    expect(endpoint, contains('/cards/printings'));
    return ApiResponse(200, {
      'data': [
        {
          'id': 'printing-cmm',
          'name': 'Sol Ring',
          'set_code': 'CMM',
          'collector_number': '396',
          'image_url': 'https://cards.scryfall.io/normal/front/a/a/card.jpg',
        },
        {
          'id': 'printing-ltc',
          'name': 'Sol Ring',
          'set_code': 'LTC',
          'collector_number': '284',
          'image_url': 'https://cards.scryfall.io/normal/front/b/b/card.jpg',
        },
      ],
    });
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/cards/resolve/batch') {
      return ApiResponse(200, {
        'data': [
          {
            'input_name': 'Sol Ring',
            'card_id': 'printing-cmm',
            'matched_name': 'Sol Ring',
            'strategy': 'exact',
          },
        ],
        'ambiguous': const [],
        'unresolved': const [],
      });
    }
    if (endpoint == '/binder/import/preview') {
      final items = body['items'] as List;
      final item = (items.single as Map).cast<String, dynamic>();
      return ApiResponse(200, {
        'data': [
          {
            ...item,
            'status': 'ready',
            'action': 'update',
            'card': {
              'id': item['card_id'],
              'name': 'Sol Ring',
              'set_code': 'LTC',
              'collector_number': '284',
            },
            'existing_id': 'binder-1',
            'baseline_quantity': 2,
            'target_quantity': 5,
            'availability': {
              'owned_quantity': 2,
              'allocated_quantity': 1,
              'committed_trade_quantity': 0,
              'free_quantity': 1,
              'missing_quantity': 0,
            },
          },
        ],
        'summary': {
          'owned_quantity': 2,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': 1,
          'missing_quantity': 0,
        },
      });
    }
    if (endpoint == '/binder/import/apply') {
      final item = ((body['items'] as List).single as Map)
          .cast<String, dynamic>();
      return ApiResponse(200, {
        'batch_id': body['batch_id'],
        'data': [
          {
            'input_id': item['input_id'],
            'status': failApply ? 'failed' : 'updated',
            if (failApply) 'code': 'binder_import_inventory_changed',
            if (failApply) 'message': 'A quantidade mudou desde a revisão.',
          },
        ],
        'total_applied': failApply ? 0 : 1,
        'total_failed': failApply ? 1 : 0,
        'summary': {
          'owned_quantity': failApply ? 2 : 5,
          'allocated_quantity': 1,
          'committed_trade_quantity': 0,
          'free_quantity': failApply ? 1 : 4,
          'missing_quantity': 0,
        },
      });
    }
    throw StateError('unexpected endpoint $endpoint');
  }
}

class _MemoryDraftStore extends BinderImportDraftStore {
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
      candidates: candidates
          .map(
            (candidate) => BinderImportCandidate.fromJson(candidate.toJson()),
          )
          .toList(growable: false),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> clearDraft(String ownerId) async {
    draft = null;
  }

  @override
  Future<void> addHistory(
    String ownerId,
    BinderImportBatchHistory entry,
  ) async {
    history = [entry, ...history];
  }
}

void main() {
  test(
    'scanner session appends exact printings and groups repeated scans',
    () async {
      final store = _MemoryDraftStore();
      final provider = BinderImportProvider(
        apiClient: _ImportApiClient(),
        draftStore: store,
      );
      addTearDown(provider.dispose);
      await provider.initialize(ownerId: 'user-1', listType: 'have');
      const card = {
        'id': 'printing-cmm',
        'name': 'Sol Ring',
        'set_code': 'CMM',
        'collector_number': '396',
      };

      await provider.addScannedCard(card, listType: 'have');
      await provider.addScannedCard(card, listType: 'have');

      expect(provider.candidates, hasLength(1));
      expect(provider.candidates.single.quantity, 2);
      expect(provider.candidates.single.cardId, 'printing-cmm');
      expect(
        provider.candidates.single.status,
        BinderImportCandidateStatus.ready,
      );
      expect(provider.candidates.single.sourceLines, hasLength(2));
      expect(store.draft?.candidates, hasLength(1));
    },
  );

  test(
    'requires explicit printing, previews baseline and applies once',
    () async {
      final api = _ImportApiClient();
      final store = _MemoryDraftStore();
      final provider = BinderImportProvider(apiClient: api, draftStore: store);
      addTearDown(provider.dispose);

      await provider.initialize(ownerId: 'user-1', listType: 'have');
      await provider.reviewSource('2 Sol Ring\n1 Sol Ring', listType: 'have');

      expect(provider.candidates, hasLength(1));
      expect(provider.candidates.single.quantity, 3);
      expect(
        provider.candidates.single.status,
        BinderImportCandidateStatus.needsPrinting,
      );
      expect(provider.canPreview, isFalse);

      await provider.selectPrinting(
        provider.candidates.single.id,
        provider.candidates.single.printings.last,
      );
      expect(provider.canPreview, isTrue);

      await provider.previewBatch();
      expect(provider.plans, hasLength(1));
      expect(provider.plans.single.action, 'update');
      expect(provider.plans.single.baselineQuantity, 2);
      expect(provider.plans.single.targetQuantity, 5);
      expect(provider.canApply, isTrue);

      await provider.applyBatch();
      expect(
        provider.candidates.single.status,
        BinderImportCandidateStatus.applied,
      );
      expect(provider.candidates.single.applicationStatus, 'updated');
      expect(provider.summary?.ownedQuantity, 5);
      expect(store.history, hasLength(1));
      expect(store.draft?.candidates, isEmpty);
    },
  );

  test(
    'partial item failure remains in the per-user draft for retry',
    () async {
      final api = _ImportApiClient()..failApply = true;
      final store = _MemoryDraftStore();
      final provider = BinderImportProvider(apiClient: api, draftStore: store);
      addTearDown(provider.dispose);

      await provider.initialize(ownerId: 'user-1', listType: 'have');
      await provider.reviewSource('3 Sol Ring (LTC) 284', listType: 'have');
      expect(
        provider.candidates.single.status,
        BinderImportCandidateStatus.ready,
      );
      await provider.previewBatch();
      await provider.applyBatch();

      expect(
        provider.candidates.single.status,
        BinderImportCandidateStatus.failed,
      );
      expect(provider.candidates.single.error, contains('quantidade mudou'));
      expect(store.draft?.candidates, hasLength(1));
      expect(store.history.single.totalFailed, 1);

      await provider.retryFailed();
      expect(provider.plans.single.baselineQuantity, 2);
      expect(provider.canApply, isTrue);
    },
  );
}
