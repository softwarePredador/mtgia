import 'dart:io';

import 'package:server/ai_plan_reservation_handle.dart';
import 'package:server/plan_middleware.dart';
import 'package:test/test.dart';

void main() {
  test('reservation handle defers settlement explicitly', () {
    final handle = AiPlanReservationHandle(
      userId: 'user-1',
      reservationId: 'reservation-1',
    );

    expect(handle.settlementDeferred, isFalse);
    expect(handle.waivedForReusedJob, isFalse);
    expect(handle.settlementState, AiPlanReservationSettlementState.pending);
    handle.deferSettlement();
    expect(handle.settlementDeferred, isTrue);
    expect(handle.settlementState, AiPlanReservationSettlementState.deferred);
    expect(handle.waiveForReusedJob, throwsStateError);
    expect(handle.elapsedMilliseconds, greaterThanOrEqualTo(0));
  });

  test('reused job explicitly waives only the current reservation', () {
    final handle = AiPlanReservationHandle(
      userId: 'user-1',
      reservationId: 'retry-reservation',
    );

    handle.waiveForReusedJob();

    expect(handle.settlementDeferred, isFalse);
    expect(handle.waivedForReusedJob, isTrue);
    expect(
      handle.settlementState,
      AiPlanReservationSettlementState.waivedReused,
    );
    expect(handle.deferSettlement, throwsStateError);
  });

  test(
    'middleware releases reused retries and leaves X-Plan-Used unchanged',
    () {
      final reused = AiPlanReservationHandle(
        userId: 'user-1',
        reservationId: 'retry-reservation',
      )..waiveForReusedJob();
      final newJob = AiPlanReservationHandle(
        userId: 'user-1',
        reservationId: 'new-job-reservation',
      )..deferSettlement();

      expect(
        aiPlanReservationSettlementDirective(
          handle: reused,
          responseStatusCode: HttpStatus.accepted,
        ),
        AiPlanReservationSettlementDirective.release,
      );
      expect(
        aiPlanUsedAfterRequest(
          usedBeforeRequest: 17,
          responseStatusCode: HttpStatus.accepted,
          handle: reused,
        ),
        17,
      );
      expect(
        aiPlanReservationSettlementDirective(
          handle: newJob,
          responseStatusCode: HttpStatus.accepted,
        ),
        AiPlanReservationSettlementDirective.deferred,
      );
      expect(
        aiPlanUsedAfterRequest(
          usedBeforeRequest: 17,
          responseStatusCode: HttpStatus.accepted,
          handle: newJob,
        ),
        18,
      );
    },
  );

  test('async routes settle quota only after their terminal result', () {
    final middleware = File('lib/plan_middleware.dart').readAsStringSync();
    final generate = File('routes/ai/generate/index.dart').readAsStringSync();
    final optimizeRoute =
        File('routes/ai/optimize/index.dart').readAsStringSync();
    final optimize =
        File('lib/ai/optimize_route_async_support.dart').readAsStringSync();

    expect(middleware, contains('provide<AiPlanReservationHandle>'));
    expect(middleware, contains('aiPlanReservationSettlementDirective('));
    expect(middleware, contains('aiPlanUsedAfterRequest('));
    expect(middleware, contains('responseStatusCode == HttpStatus.accepted'));
    expect(generate, contains('deferAiPlanReservationIfAvailable(context)'));
    expect(
      generate,
      contains('return completed && response.statusCode == HttpStatus.ok'),
    );
    expect(generate, contains('settleDeferredAiPlanReservation('));
    expect(optimize, contains("successful: job?.status == 'completed'"));
    expect(optimize, contains('_failOptimizeJobAndReleaseQuota('));
    expect(
      RegExp(
        r'waiveAiPlanReservationForReusedJobIfAvailable\(context\)',
      ).allMatches(generate).length,
      1,
    );
    expect(
      RegExp(
        r'waiveAiPlanReservationForReusedJobIfAvailable\(context\)',
      ).allMatches(optimizeRoute).length,
      2,
      reason: 'Optimize and Complete must both waive idempotent retries.',
    );
  });
}
