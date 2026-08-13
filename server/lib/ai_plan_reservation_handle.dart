import 'package:dart_frog/dart_frog.dart';

enum AiPlanReservationSettlementState { pending, deferred, waivedReused }

class AiPlanReservationHandle {
  AiPlanReservationHandle({required this.userId, required this.reservationId});

  final String userId;
  final String reservationId;
  final Stopwatch _stopwatch = Stopwatch()..start();

  AiPlanReservationSettlementState _settlementState =
      AiPlanReservationSettlementState.pending;

  AiPlanReservationSettlementState get settlementState => _settlementState;
  bool get settlementDeferred =>
      _settlementState == AiPlanReservationSettlementState.deferred;
  bool get waivedForReusedJob =>
      _settlementState == AiPlanReservationSettlementState.waivedReused;
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  void deferSettlement() {
    if (waivedForReusedJob) {
      throw StateError('A reused-job reservation cannot be deferred.');
    }
    _settlementState = AiPlanReservationSettlementState.deferred;
  }

  void waiveForReusedJob() {
    if (settlementDeferred) {
      throw StateError('A deferred reservation cannot be waived as reused.');
    }
    _settlementState = AiPlanReservationSettlementState.waivedReused;
  }
}

AiPlanReservationHandle? deferAiPlanReservationIfAvailable(
  RequestContext context,
) {
  AiPlanReservationHandle handle;
  try {
    handle = context.read<AiPlanReservationHandle>();
  } catch (_) {
    return null;
  }
  handle.deferSettlement();
  return handle;
}

AiPlanReservationHandle? waiveAiPlanReservationForReusedJobIfAvailable(
  RequestContext context,
) {
  AiPlanReservationHandle handle;
  try {
    handle = context.read<AiPlanReservationHandle>();
  } catch (_) {
    return null;
  }
  handle.waiveForReusedJob();
  return handle;
}
