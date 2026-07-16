import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI optimize authorization source guards', () {
    test('deck context loader scopes deck access by authenticated owner', () {
      final source =
          File('lib/ai/optimize_request_support.dart').readAsStringSync();

      expect(source, contains('required String userId'));
      expect(source, contains('AND user_id = CAST(@user_id AS uuid)'));
      expect(source, contains('verifyOptimizeDeckAccess'));
      expect(source, contains('card_intelligence_snapshot'));
      expect(source, contains('function_tag_details'));
      expect(source, contains('semantic_tags_v2'));
      expect(source,
          isNot(contains('SELECT name, format FROM decks WHERE id = @id')));
    });

    test('route verifies deck access before creating async optimize job', () {
      final source = File('routes/ai/optimize/index.dart').readAsStringSync();
      final accessCheck = source.indexOf('verifyOptimizeDeckAccess');
      final jobCreate = source.indexOf('createOptimizeAsyncJob');

      expect(
          source, contains("return unauthorized('Authentication required')"));
      expect(accessCheck, greaterThanOrEqualTo(0));
      expect(jobCreate, greaterThan(accessCheck));
      expect(source, contains('userId: authenticatedUserId'));
    });

    test('provider calls retain owner and deck provenance for E2E evidence', () {
      final source = File('routes/ai/optimize/index.dart').readAsStringSync();
      final callStart = source.indexOf('() => optimizer.optimizeDeck(');
      final callEnd = source.indexOf('\n          ),', callStart);

      expect(callStart, greaterThanOrEqualTo(0));
      expect(callEnd, greaterThan(callStart));
      final call = source.substring(callStart, callEnd);
      expect(call, contains('userId: authenticatedUserId'));
      expect(call, contains('deckId: deckId'));
    });

    test('optimize jobs without owner are not readable by arbitrary users', () {
      final routeSource =
          File('routes/ai/optimize/jobs/[id].dart').readAsStringSync();
      final storeSource = File('lib/ai/optimize_job.dart').readAsStringSync();

      expect(
          routeSource, contains('job.userId.isEmpty || job.userId != userId'));
      expect(storeSource, contains('required String userId'));
      expect(storeSource, isNot(contains('String? userId,')));
    });
  });
}
