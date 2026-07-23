import 'dart:convert';

import 'package:server/push_notification_service.dart';
import 'package:test/test.dart';

void main() {
  group('FCM delivery classification', () {
    test('accepts successful delivery', () {
      expect(
        PushNotificationService.classifyDeliveryResponse(
          statusCode: 200,
          body: '{}',
        ),
        FcmDeliveryOutcome.delivered,
      );
    });

    test('invalidates an explicitly unregistered token', () {
      expect(
        PushNotificationService.classifyDeliveryResponse(
          statusCode: 404,
          body: jsonEncode({
            'error': {
              'status': 'UNREGISTERED',
              'details': [
                {
                  '@type':
                      'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                  'errorCode': 'UNREGISTERED',
                },
              ],
            },
          }),
        ),
        FcmDeliveryOutcome.invalidRegistration,
      );
    });

    test('invalidates only FCM-specific INVALID_ARGUMENT responses', () {
      final tokenError = PushNotificationService.classifyDeliveryResponse(
        statusCode: 400,
        body: jsonEncode({
          'error': {
            'status': 'INVALID_ARGUMENT',
            'details': [
              {
                '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                'errorCode': 'INVALID_ARGUMENT',
              },
            ],
          },
        }),
      );
      final payloadError = PushNotificationService.classifyDeliveryResponse(
        statusCode: 400,
        body: jsonEncode({
          'error': {
            'status': 'INVALID_ARGUMENT',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.BadRequest',
                'fieldViolations': [
                  {'field': 'message.data', 'description': 'invalid payload'},
                ],
              },
            ],
          },
        }),
      );

      expect(tokenError, FcmDeliveryOutcome.invalidRegistration);
      expect(payloadError, FcmDeliveryOutcome.failed);
    });

    test('fails closed for malformed provider responses', () {
      expect(
        PushNotificationService.classifyDeliveryResponse(
          statusCode: 503,
          body: '<html>unavailable</html>',
        ),
        FcmDeliveryOutcome.failed,
      );
    });
  });
}
