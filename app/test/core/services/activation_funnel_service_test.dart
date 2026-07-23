import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/services/activation_funnel_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  tearDown(ApiClient.resetForTesting);

  test('does not contact production without an authentication token', () async {
    var requestCount = 0;
    ApiClient.resetForTesting(
      httpClient: MockClient((request) async {
        requestCount += 1;
        return http.Response('{}', 201);
      }),
    );

    await ActivationFunnelService.instance.track('core_flow_started');

    expect(requestCount, 0);
  });

  test(
    'sends authenticated activation events through the API client',
    () async {
      late http.Request capturedRequest;
      ApiClient.resetForTesting(
        token: 'test-token',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response('{"ok":true}', 201);
        }),
      );

      await ActivationFunnelService.instance.track(
        'deck_generated',
        format: 'commander',
        deckId: 'deck-1',
        source: 'test',
      );

      expect(capturedRequest.url.path, '/users/me/activation-events');
      expect(capturedRequest.headers['authorization'], 'Bearer test-token');
      expect(capturedRequest.body, contains('deck_generated'));
    },
  );

  test(
    'trackOnce coalesces concurrent and repeated analytics events',
    () async {
      var requestCount = 0;
      late Map<String, dynamic> capturedBody;
      ApiClient.resetForTesting(
        token: 'test-token',
        httpClient: MockClient((request) async {
          requestCount += 1;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"ok":true}', 201);
        }),
      );
      const dedupeKey = 'onboarding:v1:user-test:completed-test';

      await Future.wait([
        ActivationFunnelService.instance.trackOnce(
          dedupeKey,
          'onboarding_completed',
          source: 'test',
        ),
        ActivationFunnelService.instance.trackOnce(
          dedupeKey,
          'onboarding_completed',
          source: 'test',
        ),
      ]);
      await ActivationFunnelService.instance.trackOnce(
        dedupeKey,
        'onboarding_completed',
        source: 'test',
      );

      expect(requestCount, 1);
      expect((capturedBody['metadata'] as Map)['idempotency_key'], dedupeKey);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(
          'manaloom.analytics.receipt.v1.'
          '${Uri.encodeComponent(dedupeKey)}',
        ),
        isTrue,
      );
    },
  );
}
