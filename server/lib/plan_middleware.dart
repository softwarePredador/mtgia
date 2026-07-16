import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'ai_log_service.dart';
import 'internal_ai_request_token.dart';
import 'plan_service.dart';

bool isSuccessfulAiPlanActionStatus(int statusCode) =>
    statusCode >= HttpStatus.ok && statusCode < HttpStatus.multipleChoices;

Middleware aiPlanLimitMiddleware() {
  return (handler) {
    return (context) async {
      if (InternalAiRequestToken.matches(context.request.headers)) {
        return handler(context);
      }

      String? userId;
      try {
        userId = context.read<String>();
      } catch (_) {
        // Se o usuário ainda não foi injetado (ou rota pública),
        // não aplica limite de plano aqui e deixa o próximo middleware decidir.
        return handler(context);
      }

      final pool = context.read<Pool>();
      final snapshot = await PlanService(pool).getSnapshot(userId);

      if (snapshot.status != 'active') {
        return Response.json(
          statusCode: HttpStatus.paymentRequired,
          body: {
            'error': 'Plano inativo',
            'message':
                'Seu plano está inativo. Reative para continuar usando IA.',
            'plan_name': snapshot.planName,
            'status': snapshot.status,
          },
        );
      }

      if (snapshot.aiRequestsRemaining <= 0) {
        return Response.json(
          statusCode: HttpStatus.paymentRequired,
          body: {
            'error': 'Limite do plano atingido',
            'message':
                'Você atingiu o limite de requisições de IA do seu plano atual. Faça upgrade para continuar.',
            'plan_name': snapshot.planName,
            'ai_monthly_limit': snapshot.aiMonthlyLimit,
            'ai_requests_used': snapshot.aiRequestsUsed,
            'ai_requests_remaining': snapshot.aiRequestsRemaining,
            'upgrade_hint': 'Plano Pro libera mais capacidade de otimização.',
          },
          headers: {
            'X-Plan-Name': snapshot.planName,
            'X-Plan-Limit': snapshot.aiMonthlyLimit.toString(),
            'X-Plan-Used': snapshot.aiRequestsUsed.toString(),
          },
        );
      }

      final stopwatch = Stopwatch()..start();
      final response = await handler(context);
      var usageRecorded = false;
      if (isSuccessfulAiPlanActionStatus(response.statusCode)) {
        usageRecorded = await AiLogService(pool).log(
          userId: userId,
          endpoint:
              'plan:${context.request.method.name.toLowerCase()}:${context.request.uri.path}',
          model: 'application_action',
          latencyMs: stopwatch.elapsedMilliseconds,
          success: true,
        );
      }
      final usedAfterRequest =
          snapshot.aiRequestsUsed + (usageRecorded ? 1 : 0);
      return response.copyWith(
        headers: {
          ...response.headers,
          'X-Plan-Name': snapshot.planName,
          'X-Plan-Limit': snapshot.aiMonthlyLimit.toString(),
          'X-Plan-Used': usedAfterRequest.toString(),
        },
      );
    };
  };
}
