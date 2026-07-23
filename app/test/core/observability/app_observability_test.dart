import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/observability/app_observability.dart';
import 'package:manaloom/features/auth/models/user.dart';

void main() {
  group('AppObservability', () {
    testWidgets('runs app runner without waiting for Sentry startup', (
      tester,
    ) async {
      var runnerCalled = false;

      await AppObservability.instance.bootstrap(() {
        runnerCalled = true;
      });

      expect(runnerCalled, isTrue);
    });

    test('attaches only the opaque user id to Sentry context', () {
      final sentryUser = AppObservability.instance.sentryUserFor(
        User(
          id: 'user-1',
          username: 'qa_user',
          email: 'qa@example.com',
          displayName: 'QA User',
        ),
      );

      expect(sentryUser.id, equals('user-1'));
      expect(sentryUser.username, isNull);
      expect(sentryUser.email, isNull);
      expect(sentryUser.name, isNull);
    });
  });
}
