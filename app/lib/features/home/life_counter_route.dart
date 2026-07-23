import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const String lifeCounterRoutePath = '/life-counter';
const String lifeCounterFallbackRoutePath = '/home';

class LifeCounterExitResult {
  const LifeCounterExitResult({
    required this.hadGameActivity,
    required this.storageFlushed,
    required this.endedAtEpochMs,
    this.playSessionId,
    this.deckId,
    this.deckSnapshotHash,
    this.deckVersionAtEpochMs,
    this.startedAtEpochMs,
  });

  final bool hadGameActivity;
  final bool storageFlushed;
  final String? playSessionId;
  final String? deckId;
  final String? deckSnapshotHash;
  final int? deckVersionAtEpochMs;
  final int? startedAtEpochMs;
  final int endedAtEpochMs;

  Duration? get duration {
    final startedAt = startedAtEpochMs;
    if (startedAt == null || endedAtEpochMs < startedAt) return null;
    return Duration(milliseconds: endedAtEpochMs - startedAt);
  }
}

String lifeCounterRouteLocation({
  String? deckId,
  String? deckName,
  String? deckSnapshotHash,
  int? deckVersionAtEpochMs,
}) {
  final normalizedDeckId = deckId?.trim();
  final normalizedDeckName = deckName?.trim();
  final normalizedDeckSnapshotHash = deckSnapshotHash?.trim().toLowerCase();
  final hasCompleteDeckVersion =
      normalizedDeckSnapshotHash != null &&
      RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedDeckSnapshotHash) &&
      deckVersionAtEpochMs != null &&
      deckVersionAtEpochMs >= 0;
  final queryParameters = <String, String>{
    if (normalizedDeckId != null && normalizedDeckId.isNotEmpty)
      'deckId': normalizedDeckId,
    if (normalizedDeckName != null && normalizedDeckName.isNotEmpty)
      'deckName': normalizedDeckName,
    if (hasCompleteDeckVersion) 'deckSnapshotHash': normalizedDeckSnapshotHash,
    if (hasCompleteDeckVersion)
      'deckVersionAt': deckVersionAtEpochMs.toString(),
  };

  return Uri(
    path: lifeCounterRoutePath,
    queryParameters: queryParameters.isEmpty ? null : queryParameters,
  ).toString();
}

GoRouter? maybeLifeCounterRouter(BuildContext context) {
  try {
    return GoRouter.of(context);
  } catch (_) {
    return null;
  }
}

bool canPopLifeCounterRoute(BuildContext context) {
  final router = maybeLifeCounterRouter(context);
  if (router != null) {
    return router.canPop();
  }

  return Navigator.of(context).canPop();
}

Future<T?> openLifeCounterRoute<T extends Object?>(
  BuildContext context, {
  String? deckId,
  String? deckName,
  String? deckSnapshotHash,
  int? deckVersionAtEpochMs,
}) {
  return context.push<T>(
    lifeCounterRouteLocation(
      deckId: deckId,
      deckName: deckName,
      deckSnapshotHash: deckSnapshotHash,
      deckVersionAtEpochMs: deckVersionAtEpochMs,
    ),
  );
}

void closeLifeCounterRoute<T extends Object?>(
  BuildContext context, {
  String fallbackRoutePath = lifeCounterFallbackRoutePath,
  T? result,
}) {
  final router = maybeLifeCounterRouter(context);
  if (router != null) {
    if (router.canPop()) {
      context.pop<T>(result);
      return;
    }

    context.go(fallbackRoutePath);
    return;
  }

  Navigator.of(context).maybePop<T>(result);
}
