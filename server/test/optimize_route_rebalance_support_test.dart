import 'package:server/ai/optimize_route_rebalance_support.dart';
import 'package:test/test.dart';

void main() {
  test('builds replacement plan when removals exceed additions', () {
    final plan = buildOptimizeRebalancePlan(
      removals: const ['Weak One', 'Weak Two', 'Weak Three'],
      additions: const ['Strong One'],
      deckNamesLower: const {'sol ring'},
      filteredByColorIdentity: const ['Off Color Card'],
    );

    expect(plan.needsRebalance, isTrue);
    expect(plan.needsReplacements, isTrue);
    expect(plan.missingCount, 2);
    expect(plan.removedButUnmatched, ['Weak Two', 'Weak Three']);
    expect(plan.excludeNames,
        containsAll(['sol ring', 'strong one', 'off color card']));
  });

  test('builds no-op plan when counts are already balanced', () {
    final plan = buildOptimizeRebalancePlan(
      removals: const ['Weak One'],
      additions: const ['Strong One'],
      deckNamesLower: const {'sol ring'},
      filteredByColorIdentity: const ['Off Color Card'],
    );

    expect(plan.needsRebalance, isFalse);
    expect(plan.needsReplacements, isFalse);
    expect(plan.missingCount, 0);
    expect(plan.removedButUnmatched, isEmpty);
    expect(plan.excludeNames, isEmpty);
  });

  test('applies valid replacement rows and returns card lookup updates', () {
    final result = applyOptimizeRebalanceReplacements(
      additions: const ['Strong One'],
      replacements: const [
        {'name': 'Replacement A', 'id': 'card-a'},
        {'name': 'Replacement B', 'id': 'card-b'},
      ],
    );

    expect(result.additions, ['Strong One', 'Replacement A', 'Replacement B']);
    expect(result.addedCount, 2);
    expect(result.validByNameLowerUpdates, {
      'replacement a': {'id': 'card-a', 'name': 'Replacement A'},
      'replacement b': {'id': 'card-b', 'name': 'Replacement B'},
    });
  });

  test('skips replacement rows without usable card id or name', () {
    final result = applyOptimizeRebalanceReplacements(
      additions: const ['Strong One'],
      replacements: const [
        {'name': 'No Id'},
        {'id': 'missing-name'},
        {'name': '', 'id': 'blank-name'},
      ],
    );

    expect(result.additions, ['Strong One']);
    expect(result.addedCount, 0);
    expect(result.validByNameLowerUpdates, isEmpty);
  });

  test('trims removals when replacements cannot fill all missing additions',
      () {
    final result = trimOptimizeRebalanceToPairs(
      removals: const ['Weak One', 'Weak Two', 'Weak Three'],
      additions: const ['Strong One'],
    );

    expect(result.removals, ['Weak One']);
    expect(result.additions, ['Strong One']);
    expect(result.truncatedRemovalsCount, 2);
    expect(result.truncatedAdditionsCount, 0);
  });

  test('trims additions when additions exceed removals', () {
    final result = trimOptimizeRebalanceToPairs(
      removals: const ['Weak One'],
      additions: const ['Strong One', 'Strong Two'],
    );

    expect(result.removals, ['Weak One']);
    expect(result.additions, ['Strong One']);
    expect(result.truncatedRemovalsCount, 0);
    expect(result.truncatedAdditionsCount, 1);
  });
}
