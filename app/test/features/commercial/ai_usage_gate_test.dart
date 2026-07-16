import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/commercial/models/manaloom_plan.dart';
import 'package:manaloom/features/commercial/providers/commercial_provider.dart';
import 'package:manaloom/features/commercial/widgets/ai_usage_gate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting();
  });

  tearDown(ApiClient.resetForTesting);

  for (final kind in AiUsageKind.values) {
    testWidgets('shows paywall when ${kind.name} quota is exhausted', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));
      await provider.load();
      for (var i = 0; i < ManaLoomPlan.free.monthlyAiLimit; i += 1) {
        expect(
          await provider.consumeAiAction(AiUsageKind.deckGeneration),
          true,
        );
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<CommercialProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () =>
                              reserveAiActionOrShowPaywall(context, kind: kind),
                      child: const Text('run'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai-paywall-dialog')), findsOneWidget);
      expect(find.text('${kind.label} precisa do Pro'), findsOneWidget);
      expect(
        find.byKey(const Key('ai-paywall-upgrade-button')),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'authenticated actions use server quota without optimistic local debit',
    (tester) async {
      var remoteUsed = 119;
      var allowed = false;
      var usedImmediatelyAfterReservation = -1;
      ApiClient.resetForTesting(
        token: 'authenticated-token',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/users/me/plan');
          return http.Response(
            jsonEncode({
              'plan': {
                'plan_name': 'free',
                'status': 'active',
                'ai_monthly_limit': 120,
                'ai_requests_used': remoteUsed,
                'ai_requests_remaining': 120 - remoteUsed,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final provider = CommercialProvider(now: () => DateTime(2026, 7, 1));

      await tester.pumpWidget(
        ChangeNotifierProvider<CommercialProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        allowed = await reserveAiActionOrShowPaywall(
                          context,
                          kind: AiUsageKind.deckGeneration,
                        );
                        usedImmediatelyAfterReservation =
                            provider.usedAiActions;
                        remoteUsed = 120;
                        await refreshAiUsageAfterAction(context);
                      },
                      child: const Text('run'),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();

      expect(allowed, isTrue);
      expect(usedImmediatelyAfterReservation, 119);
      expect(provider.usedAiActions, 120);
      expect(provider.remainingAiActions, 0);
      expect(find.byKey(const Key('ai-paywall-dialog')), findsNothing);
    },
  );
}
