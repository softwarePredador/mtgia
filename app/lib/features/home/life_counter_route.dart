import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const String lifeCounterRoutePath = '/life-counter';
const String lifeCounterFallbackRoutePath = '/home';

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

Future<T?> openLifeCounterRoute<T extends Object?>(BuildContext context) {
  return context.push<T>(lifeCounterRoutePath);
}

void closeLifeCounterRoute(
  BuildContext context, {
  String fallbackRoutePath = lifeCounterFallbackRoutePath,
}) {
  final router = maybeLifeCounterRouter(context);
  if (router != null) {
    if (router.canPop()) {
      context.pop();
      return;
    }

    context.go(fallbackRoutePath);
    return;
  }

  Navigator.of(context).maybePop();
}
