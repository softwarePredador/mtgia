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
    this.startedAtEpochMs,
  });

  final bool hadGameActivity;
  final bool storageFlushed;
  final String? playSessionId;
  final String? deckId;
  final int? startedAtEpochMs;
  final int endedAtEpochMs;

  Duration? get duration {
    final startedAt = startedAtEpochMs;
    if (startedAt == null || endedAtEpochMs < startedAt) return null;
    return Duration(milliseconds: endedAtEpochMs - startedAt);
  }
}

String lifeCounterRouteLocation({String? deckId, String? deckName}) {
  final normalizedDeckId = deckId?.trim();
  final normalizedDeckName = deckName?.trim();
  final queryParameters = <String, String>{
    if (normalizedDeckId != null && normalizedDeckId.isNotEmpty)
      'deckId': normalizedDeckId,
    if (normalizedDeckName != null && normalizedDeckName.isNotEmpty)
      'deckName': normalizedDeckName,
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
}) {
  return context.push<T>(
    lifeCounterRouteLocation(deckId: deckId, deckName: deckName),
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
