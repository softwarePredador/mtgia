import 'dart:convert';

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
    final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
    await provider.load();
    await provider.setPlan(ManaLoomPlanTier.pro);

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
    expect(provider.remainingAiActions, 1);
    expect(
      await provider.consumeAiAction(AiUsageKind.deckOptimization),
      isTrue,
    );
    expect(
      provider.usedAiActions,
      2499,
      reason: 'remote-backed usage is consumed by the backend route',
    );
  });

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
            'message': 'Checkout real ainda nao esta configurado.',
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
    expect(result.message, contains('Checkout real'));
  });
}
