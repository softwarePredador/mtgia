import 'dart:io';

import 'package:server/ai_plan_reservation_handle.dart';
import 'package:test/test.dart';

void main() {
  test('reservation handle defers settlement explicitly', () {
    final handle = AiPlanReservationHandle(
      userId: 'user-1',
      reservationId: 'reservation-1',
    );

    expect(handle.settlementDeferred, isFalse);
    handle.deferSettlement();
    expect(handle.settlementDeferred, isTrue);
    expect(handle.elapsedMilliseconds, greaterThanOrEqualTo(0));
  });

  test('async routes settle quota only after their terminal result', () {
    final middleware = File('lib/plan_middleware.dart').readAsStringSync();
    final generate = File('routes/ai/generate/index.dart').readAsStringSync();
    final optimize =
        File('lib/ai/optimize_route_async_support.dart').readAsStringSync();

    expect(middleware, contains('provide<AiPlanReservationHandle>'));
    expect(middleware, contains('reservationHandle.settlementDeferred'));
    expect(middleware, contains('response.statusCode == HttpStatus.accepted'));
    expect(generate, contains('deferAiPlanReservationIfAvailable(context)'));
    expect(generate, contains('return response.statusCode == HttpStatus.ok'));
    expect(generate, contains('settleDeferredAiPlanReservation('));
    expect(optimize, contains("successful: job?.status == 'completed'"));
    expect(optimize, contains('_failOptimizeJobAndReleaseQuota('));
  });
}
