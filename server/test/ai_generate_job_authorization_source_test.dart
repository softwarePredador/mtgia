import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AI generate job authorization source guards', () {
    test('async job creation requires an authenticated owner', () {
      final routeSource =
          File('routes/ai/generate/index.dart').readAsStringSync();
      final storeSource = File('lib/ai_generate_job.dart').readAsStringSync();

      expect(
        routeSource,
        contains("return unauthorized('Authentication required')"),
      );
      expect(routeSource, contains('userId: authenticatedUserId'));
      expect(storeSource, contains('required String userId'));
      expect(storeSource, isNot(contains('String? userId,')));
    });

    test(
      'jobs without persisted owner are not readable by arbitrary users',
      () {
        final routeSource =
            File('routes/ai/generate/jobs/[id].dart').readAsStringSync();
        final storeSource = File('lib/ai_generate_job.dart').readAsStringSync();

        expect(
          routeSource,
          contains('job.userId.isEmpty || job.userId != userId'),
        );
        expect(
          routeSource,
          isNot(contains('job.userId != null && job.userId != userId')),
        );
        expect(
          storeSource,
          contains("userId: row['user_id'] as String? ?? ''"),
        );
      },
    );

    test(
      'accepted jobs publish a polling timeout matching the worker budget',
      () {
        final routeSource =
            File('routes/ai/generate/index.dart').readAsStringSync();

        expect(
          routeSource,
          contains(
            "'job_timeout_ms': "
            'AiGenerateJobStore.executionTimeout.inMilliseconds',
          ),
        );
        expect(
          routeSource,
          contains('.timeout(AiGenerateJobStore.executionTimeout)'),
        );
      },
    );
  });
}
