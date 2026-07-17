import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'ai_plan_reservation_handle.dart';
import 'internal_ai_request_token.dart';
import 'logger.dart';
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
      final planService = PlanService(pool);
      final actionEndpoint =
          'plan:${context.request.method.name.toLowerCase()}:${context.request.uri.path}';
      AiPlanReservationDecision decision;
      try {
        decision = await planService.reserveAiAction(
          userId,
          actionEndpoint: actionEndpoint,
        );
      } catch (error) {
        Log.w('AI plan reservation failed type=${error.runtimeType}');
        return Response.json(
          statusCode: HttpStatus.serviceUnavailable,
          body: {
            'error': 'Plano temporariamente indisponível',
            'message':
                'Não foi possível confirmar sua cota de IA agora. Tente novamente em instantes.',
          },
        );
      }
      final snapshot = decision.snapshot;

      if (snapshot.status != 'active') {
        return Response.json(
          statusCode: HttpStatus.paymentRequired,
          body: {
            'error': 'Plano inativo',
            'message':
                'Seu acesso de IA está inativo. Entre em contato com o suporte para revisão.',
            'beta_mode': true,
            'billing_enabled': false,
            'plan_name': snapshot.planName,
            'status': snapshot.status,
          },
        );
      }

      if (!decision.isAllowed) {
        return Response.json(
          statusCode: HttpStatus.paymentRequired,
          body: {
            'error': 'Limite do plano atingido',
            'message':
                'Você atingiu o limite de IA da beta gratuita. O acesso volta no próximo período de uso.',
            'beta_mode': true,
            'billing_enabled': false,
            'purchase_available': false,
            'plan_name': snapshot.planName,
            'ai_monthly_limit': snapshot.aiMonthlyLimit,
            'ai_requests_used': snapshot.aiRequestsUsed,
            'ai_requests_remaining': snapshot.aiRequestsRemaining,
          },
          headers: {
            'X-Plan-Name': snapshot.planName,
            'X-Plan-Limit': snapshot.aiMonthlyLimit.toString(),
            'X-Plan-Used': snapshot.aiRequestsUsed.toString(),
          },
        );
      }

      final reservationId = decision.reservationId!;
      final reservationHandle = AiPlanReservationHandle(
        userId: userId,
        reservationId: reservationId,
      );
      final stopwatch = Stopwatch()..start();
      Response response;
      try {
        response = await handler(
          context.provide<AiPlanReservationHandle>(() => reservationHandle),
        );
      } catch (_) {
        try {
          await planService.releaseAiActionReservation(
            userId: userId,
            reservationId: reservationId,
          );
        } catch (error) {
          Log.w('AI plan reservation release failed type=${error.runtimeType}');
        }
        rethrow;
      }

      final succeeded = isSuccessfulAiPlanActionStatus(response.statusCode);
      final deferredAccepted =
          reservationHandle.settlementDeferred &&
          response.statusCode == HttpStatus.accepted;
      if (!deferredAccepted) {
        try {
          if (succeeded) {
            await planService.finalizeAiActionReservation(
              userId: userId,
              reservationId: reservationId,
              latencyMs: stopwatch.elapsedMilliseconds,
            );
          } else {
            await planService.releaseAiActionReservation(
              userId: userId,
              reservationId: reservationId,
            );
          }
        } catch (error) {
          Log.w(
            'AI plan reservation settlement failed type=${error.runtimeType}',
          );
        }
      }

      final usedAfterRequest = snapshot.aiRequestsUsed + (succeeded ? 1 : 0);
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
