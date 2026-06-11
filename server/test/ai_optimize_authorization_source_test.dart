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
