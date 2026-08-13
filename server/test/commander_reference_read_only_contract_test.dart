import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String route;

  setUpAll(() {
    route = File('routes/ai/commander-reference/index.dart').readAsStringSync();
  });

  test('GET commander reference contains no PostgreSQL mutation statement', () {
    final mutations = RegExp(
      r'\b(?:INSERT|UPDATE|DELETE|MERGE)\b',
      caseSensitive: false,
    ).allMatches(route);

    expect(
      mutations,
      isEmpty,
      reason:
          'GET /ai/commander-reference must remain read-only over PostgreSQL.',
    );
    expect(route, isNot(contains('_buildAndPersistEdhrecProfile')));
    expect(route, isNot(contains('_refreshCommanderFromMtgTop8')));
  });

  test('cache miss and cache upgrade build a transient EDHREC profile', () {
    final decisionStart = route.indexOf('final needsCacheUpgrade');
    final decisionEnd = route.indexOf('if (edhrecProfile != null)');
    final decision = route.substring(decisionStart, decisionEnd);

    expect(decisionStart, isNonNegative);
    expect(decisionEnd, greaterThan(decisionStart));
    expect(decision, contains('cachedProfile == null'));
    expect(decision, contains('needsCacheUpgrade'));
    expect(decision, contains('_buildEdhrecProfile(commander: commander)'));
    expect(route, contains("'persistence': false"));
    expect(route, contains("'provider': 'edhrec'"));
  });

  test('admin refresh is an external read-only preview', () {
    final adminGuard = route.indexOf('await isConfiguredAdminUser(');
    final previewCall = route.indexOf(
      'refreshSummary = await _buildCommanderMtgTop8RefreshPreview',
    );

    expect(adminGuard, isNonNegative);
    expect(previewCall, greaterThan(adminGuard));
    expect(route, contains("'mode': 'read_only_preview'"));
    expect(route, contains("'imported': 0"));
    expect(route, contains("'candidates_found': candidatesFound"));
  });

  test('removed invalid common_commanders fallback from request path', () {
    expect(route, isNot(contains('common_commanders')));
    expect(route, isNot(contains('generated_from_card_meta_insights')));
  });
}
