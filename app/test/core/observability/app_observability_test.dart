import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/observability/app_observability.dart';
import 'package:manaloom/features/auth/models/user.dart';

void main() {
  group('AppObservability', () {
    test('does not attach email to Sentry user context', () {
      final sentryUser = AppObservability.instance.sentryUserFor(
        User(
          id: 'user-1',
          username: 'qa_user',
          email: 'qa@example.com',
          displayName: 'QA User',
        ),
      );

      expect(sentryUser.id, equals('user-1'));
      expect(sentryUser.username, equals('QA User'));
      expect(sentryUser.email, isNull);
    });
  });
}
