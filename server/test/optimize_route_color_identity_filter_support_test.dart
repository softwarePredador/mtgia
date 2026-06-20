import 'package:server/ai/optimize_route_color_identity_filter_support.dart';
import 'package:test/test.dart';

void main() {
  test('filters additions outside commander identity preserving order', () {
    final result = filterOptimizeAdditionsByCommanderIdentity(
      validAdditions: const [
        'Swords to Plowshares',
        'Counterspell',
        'Arcane Signet',
      ],
      identityByName: const {
        'swords to plowshares': ['W'],
        'counterspell': ['U'],
        'arcane signet': [],
      },
      commanderColorIdentity: const {'W'},
    );

    expect(result.additions, ['Swords to Plowshares', 'Arcane Signet']);
    expect(result.filteredByColorIdentity, ['Counterspell']);
  });

  test('colorless commander only allows colorless additions', () {
    final result = filterOptimizeAdditionsByCommanderIdentity(
      validAdditions: const ['Wastes', 'Sol Ring', 'Swan Song'],
      identityByName: const {
        'wastes': [],
        'sol ring': [],
        'swan song': ['U'],
      },
      commanderColorIdentity: const {},
    );

    expect(result.additions, ['Wastes', 'Sol Ring']);
    expect(result.filteredByColorIdentity, ['Swan Song']);
  });

  test(
      'missing identity data is blocked instead of treated as proven colorless',
      () {
    final result = filterOptimizeAdditionsByCommanderIdentity(
      validAdditions: const ['Unknown Card', 'Sol Ring'],
      identityByName: const {
        'sol ring': [],
      },
      commanderColorIdentity: const {'R'},
    );

    expect(result.additions, ['Sol Ring']);
    expect(result.filteredByColorIdentity, isEmpty);
    expect(result.filteredByMissingIdentity, ['Unknown Card']);
  });
}
