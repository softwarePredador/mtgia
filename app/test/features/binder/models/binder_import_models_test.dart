import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/binder/models/binder_import_models.dart';

void main() {
  group('collection import parser', () {
    test('parses plain and printing-qualified lines and groups duplicates', () {
      final result = parseBinderImportText('''
4 Lightning Bolt
1 Sol Ring (CMM) 396
2 Sol Ring [CMM] 396
# comment
invalid line
''');

      expect(result.candidates, hasLength(2));
      expect(result.invalidLines, ['invalid line']);
      final solRing = result.candidates.singleWhere(
        (candidate) => candidate.requestedName == 'Sol Ring',
      );
      expect(solRing.quantity, 3);
      expect(solRing.requestedSetCode, 'CMM');
      expect(solRing.requestedCollectorNumber, '396');
      expect(solRing.sourceLines, hasLength(2));
      expect(solRing.hasDuplicateSources, isTrue);
    });

    test('keeps have and want as explicit physical list identities', () {
      final have = parseBinderImportText('1 Sol Ring').candidates.single;
      final want = parseBinderImportText(
        '1 Sol Ring',
        listType: 'want',
      ).candidates.single;

      expect(have.listType, 'have');
      expect(want.listType, 'want');
      expect(have.physicalIdentityKey, isNot(want.physicalIdentityKey));
    });
  });

  test(
    'review plans aggregate only identical selected physical identities',
    () {
      BinderImportCandidate candidate(
        String id, {
        String condition = 'NM',
        int quantity = 1,
      }) {
        return BinderImportCandidate(
          id: id,
          requestedName: 'Sol Ring',
          quantity: quantity,
          sourceLines: ['1 Sol Ring'],
          selectedPrinting: const {
            'id': 'printing-1',
            'name': 'Sol Ring',
            'set_code': 'CMM',
            'collector_number': '396',
          },
          condition: condition,
          status: BinderImportCandidateStatus.ready,
        );
      }

      final plans = buildBinderImportPlans([
        candidate('a', quantity: 2),
        candidate('b', quantity: 3),
        candidate('c', condition: 'LP'),
      ]);

      expect(plans, hasLength(2));
      final nearMint = plans.singleWhere((plan) => plan.condition == 'NM');
      expect(nearMint.quantity, 5);
      expect(nearMint.candidateIds, ['a', 'b']);
      expect(nearMint.toPreviewJson()['card_id'], 'printing-1');
    },
  );

  test('draft JSON preserves selected printing and retry state', () {
    final original = BinderImportCandidate(
      id: 'line-1',
      requestedName: 'Sol Ring',
      quantity: 2,
      sourceLines: const ['2 Sol Ring'],
      selectedPrinting: const {'id': 'printing-1', 'name': 'Sol Ring'},
      status: BinderImportCandidateStatus.failed,
      error: 'retry',
      condition: 'LP',
      language: 'pt-br',
      isFoil: true,
    );

    final restored = BinderImportCandidate.fromJson(original.toJson());
    expect(restored.selectedPrinting?['id'], 'printing-1');
    expect(restored.status, BinderImportCandidateStatus.failed);
    expect(restored.condition, 'LP');
    expect(restored.language, 'pt-br');
    expect(restored.isFoil, isTrue);
  });
}
