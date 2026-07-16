import 'package:dart_frog/dart_frog.dart';

class AiPlanReservationHandle {
  AiPlanReservationHandle({required this.userId, required this.reservationId});

  final String userId;
  final String reservationId;
  final Stopwatch _stopwatch = Stopwatch()..start();

  bool _settlementDeferred = false;

  bool get settlementDeferred => _settlementDeferred;
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  void deferSettlement() {
    _settlementDeferred = true;
  }
}

AiPlanReservationHandle? deferAiPlanReservationIfAvailable(
  RequestContext context,
) {
  try {
    final handle = context.read<AiPlanReservationHandle>();
    handle.deferSettlement();
    return handle;
  } catch (_) {
    return null;
  }
}
