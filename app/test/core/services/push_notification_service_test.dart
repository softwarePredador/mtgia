import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/push_notification_service.dart';

void main() {
  test('registers silently only for granted notification authorization', () {
    expect(
      PushNotificationService.authorizationAllowsRegistration(
        AuthorizationStatus.authorized,
      ),
      isTrue,
    );
    expect(
      PushNotificationService.authorizationAllowsRegistration(
        AuthorizationStatus.provisional,
      ),
      isTrue,
    );
    expect(
      PushNotificationService.authorizationAllowsRegistration(
        AuthorizationStatus.notDetermined,
      ),
      isFalse,
    );
    expect(
      PushNotificationService.authorizationAllowsRegistration(
        AuthorizationStatus.denied,
      ),
      isFalse,
    );
  });
}
