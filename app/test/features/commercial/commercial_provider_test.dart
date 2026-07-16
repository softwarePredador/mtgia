import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting(token: 'test-token');
  });

  test('Free plan blocks AI after monthly limit', () async {
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();

    expect(provider.tier, ManaLoomPlanTier.free);
    expect(provider.monthlyAiLimit, 120);

    for (var i = 0; i < 120; i++) {
      expect(
        await provider.consumeAiAction(AiUsageKind.deckGeneration),
        isTrue,
      );
    }

    expect(provider.remainingAiActions, 0);
    expect(
      await provider.consumeAiAction(AiUsageKind.deckOptimization),
      isFalse,
    );
  });

  test('Pro plan raises AI usage limit and persists tier', () async {
    SharedPreferences.setMockInitialValues({'manaloom.commercial.plan': 'pro'});
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();

    expect(provider.tier, ManaLoomPlanTier.pro);
    expect(provider.monthlyAiLimit, 2500);
    expect(
      await provider.consumeAiAction(AiUsageKind.deckOptimization),
      isTrue,
    );

    final reloaded = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await reloaded.load();
    expect(reloaded.tier, ManaLoomPlanTier.pro);
    expect(reloaded.usedAiActions, 1);
  });

  test('monthly usage rolls over into a new period', () async {
    var currentDate = DateTime(2026, 7, 31);
    final provider = CommercialProvider(now: () => currentDate);
    await provider.load();
    expect(await provider.consumeAiAction(AiUsageKind.deckGeneration), isTrue);
    expect(provider.usedAiActions, 1);

    currentDate = DateTime(2026, 8, 1);
    expect(await provider.consumeAiAction(AiUsageKind.deckGeneration), isTrue);

    expect(provider.periodKey, '2026-08');
    expect(provider.usedAiActions, 1);
    expect(provider.remainingAiActions, 119);
  });

  test('remote plan snapshot becomes the source for AI usage limits', () async {
    ApiClient.resetForTesting(
      token: 'test-token',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/users/me/plan');
        return http.Response(
          jsonEncode({
            'plan': {
              'plan_name': 'pro',
              'status': 'active',
              'ai_monthly_limit': 2500,
              'ai_requests_used': 2499,
              'ai_requests_remaining': 1,
              'usage_period_start': '2026-06-01T00:00:00.000Z',
              'usage_period_end': '2026-07-01T00:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.refreshFromServer();

    expect(provider.isRemoteSynced, isTrue);
    expect(provider.tier, ManaLoomPlanTier.pro);
    expect(provider.monthlyAiLimit, 2500);
    expect(provider.usedAiActions, 2499);
    expect(provider.periodKey, '2026-06');
    expect(provider.remainingAiActions, 1);
  });

  test('concurrent remote refreshes share one authoritative request', () async {
    final release = Completer<void>();
    var requestCount = 0;
    ApiClient.resetForTesting(
      token: 'test-token',
      httpClient: MockClient((request) async {
        requestCount += 1;
        await release.future;
        return http.Response(
          jsonEncode({
            'plan': {
              'plan_name': 'free',
              'status': 'active',
              'ai_monthly_limit': 120,
              'ai_requests_used': 7,
              'ai_requests_remaining': 113,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));

    final first = provider.refreshFromServer();
    final second = provider.refreshFromServer();
    release.complete();
    await Future.wait([first, second]);

    expect(requestCount, 1);
    expect(provider.isRemoteSynced, isTrue);
    expect(provider.usedAiActions, 7);
  });

  test(
    'malformed remote plan invalidates a previously synced snapshot',
    () async {
      var requestCount = 0;
      ApiClient.resetForTesting(
        token: 'test-token',
        httpClient: MockClient((request) async {
          requestCount += 1;
          return http.Response(
            jsonEncode(
              requestCount == 1
                  ? {
                    'plan': {
                      'plan_name': 'pro',
                      'ai_monthly_limit': 2500,
                      'ai_requests_used': 8,
                    },
                  }
                  : {'plan': 'invalid'},
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));

      await provider.refreshFromServer();
      expect(provider.isRemoteSynced, isTrue);
      await provider.refreshFromServer();

      expect(provider.isRemoteSynced, isFalse);
      expect(provider.lastRemoteError, contains('plano inválido'));
      expect(provider.usedAiActions, 8);
    },
  );

  test('session reset discards an in-flight remote plan response', () async {
    final release = Completer<void>();
    ApiClient.resetForTesting(
      token: 'test-token',
      httpClient: MockClient((request) async {
        await release.future;
        return http.Response(
          jsonEncode({
            'plan': {
              'plan_name': 'pro',
              'status': 'active',
              'ai_monthly_limit': 2500,
              'ai_requests_used': 15,
              'ai_requests_remaining': 2485,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));

    final refresh = provider.refreshFromServer();
    await provider.clearRemoteSnapshot();
    release.complete();
    await refresh;

    expect(provider.isRemoteSynced, isFalse);
    expect(provider.tier, ManaLoomPlanTier.free);
    expect(provider.usedAiActions, 0);
  });

  test('refresh started during session reset uses the new session', () async {
    var requestCount = 0;
    ApiClient.resetForTesting(
      token: 'new-session-token',
      httpClient: MockClient((request) async {
        requestCount += 1;
        return http.Response(
          jsonEncode({
            'plan': {
              'plan_name': 'pro',
              'status': 'active',
              'ai_monthly_limit': 2500,
              'ai_requests_used': 21,
              'ai_requests_remaining': 2479,
              'usage_period_start': '2026-07-01T00:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();

    final reset = provider.clearRemoteSnapshot();
    final refresh = provider.refreshFromServer();
    await Future.wait([reset, refresh]);

    expect(requestCount, 1);
    expect(provider.isRemoteSynced, isTrue);
    expect(provider.tier, ManaLoomPlanTier.pro);
    expect(provider.usedAiActions, 21);
  });

  test(
    'session reset removes the previous user plan and usage snapshot',
    () async {
      ApiClient.resetForTesting(
        token: 'test-token',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'plan': {
                'plan_name': 'pro',
                'status': 'active',
                'ai_monthly_limit': 2500,
                'ai_requests_used': 37,
                'ai_requests_remaining': 2463,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
      await provider.refreshFromServer();
      expect(provider.tier, ManaLoomPlanTier.pro);
      expect(provider.usedAiActions, 37);

      await provider.clearRemoteSnapshot();

      expect(provider.tier, ManaLoomPlanTier.free);
      expect(provider.usedAiActions, 0);
      expect(provider.monthlyAiLimit, ManaLoomPlan.free.monthlyAiLimit);

      final reloaded = CommercialProvider(now: () => DateTime(2026, 7, 1));
      await reloaded.load();
      expect(reloaded.tier, ManaLoomPlanTier.free);
      expect(reloaded.usedAiActions, 0);
    },
  );

  test(
    'backend checkout activation refreshes the local plan snapshot',
    () async {
      ApiClient.resetForTesting(
        token: 'test-token',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/users/me/plan/checkout');
          return http.Response(
            jsonEncode({
              'checkout_status': 'activated',
              'message': 'Plano Pro ativado.',
              'plan': {
                'plan_name': 'pro',
                'status': 'active',
                'ai_monthly_limit': 2500,
                'ai_requests_used': 0,
                'ai_requests_remaining': 2500,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
      final result = await provider.startProCheckout();

      expect(result.activated, isTrue);
      expect(result.requiresExternalPayment, isFalse);
      expect(provider.isRemoteSynced, isTrue);
      expect(provider.tier, ManaLoomPlanTier.pro);
      expect(provider.remainingAiActions, 2500);
    },
  );

  test('checkout reports payment configuration requirements', () async {
    ApiClient.resetForTesting(
      token: 'test-token',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'checkout_status': 'payment_provider_not_configured',
            'message':
                'O ManaLoom Pro ainda não está disponível para contratação.',
          }),
          501,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    final result = await provider.startProCheckout();

    expect(result.activated, isFalse);
    expect(result.requiresExternalPayment, isTrue);
    expect(result.message, contains('ainda não está disponível'));
  });
}
