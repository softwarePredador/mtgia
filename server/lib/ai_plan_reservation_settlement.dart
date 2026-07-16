import 'package:postgres/postgres.dart';

import 'ai_plan_reservation_handle.dart';
import 'plan_service.dart';

Future<bool> settleDeferredAiPlanReservation({
  required Pool pool,
  required AiPlanReservationHandle handle,
  required bool successful,
}) {
  final planService = PlanService(pool);
  if (successful) {
    return planService.finalizeAiActionReservation(
      userId: handle.userId,
      reservationId: handle.reservationId,
      latencyMs: handle.elapsedMilliseconds,
    );
  }
  return planService.releaseAiActionReservation(
    userId: handle.userId,
    reservationId: handle.reservationId,
  );
}
