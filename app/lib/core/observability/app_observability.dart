import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../features/auth/models/user.dart';

class AppObservability {
  AppObservability._();

  static final AppObservability instance = AppObservability._();

  static const String _dsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static const String _environment =
      String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: '');
  static const String _release =
      String.fromEnvironment('SENTRY_RELEASE', defaultValue: '');
  static const String _tracesSampleRateRaw = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0',
  );

  bool get isEnabled => _dsn.trim().isNotEmpty;

  double get _tracesSampleRate {
    final parsed = double.tryParse(_tracesSampleRateRaw);
    if (parsed == null || parsed.isNaN || parsed < 0 || parsed > 1) {
      return 0;
    }
    return parsed;
  }

  Future<void> bootstrap(FutureOr<void> Function() appRunner) async {
    if (!isEnabled) {
      _attachGlobalHandlers();
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn.trim();
        options.environment = _environment.trim().isNotEmpty
            ? _environment.trim()
            : (kReleaseMode ? 'production' : 'development');
        if (_release.trim().isNotEmpty) {
          options.release = _release.trim();
        }
        options.sendDefaultPii = false;
        options.enableLogs = !kReleaseMode;
        options.tracesSampleRate = _tracesSampleRate;
      },
      appRunner: () async {
        _attachGlobalHandlers();
        await appRunner();
      },
    );
  }

  void _attachGlobalHandlers() {
    final previousFlutterErrorHandler = FlutterError.onError;

    FlutterError.onError = (details) {
      previousFlutterErrorHandler?.call(details);
      unawaited(
        captureException(
          details.exception,
          stackTrace: details.stack,
          tags: const {'source': 'flutter_error'},
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        captureException(
          error,
          stackTrace: stackTrace,
          tags: const {'source': 'platform_dispatcher'},
        ),
      );
      return true;
    };
  }

  Future<void> setCurrentRoute(String route) async {
    if (!isEnabled) {
      return;
    }

    await Sentry.configureScope((scope) {
      scope.setTag('route', route);
    });
  }

  Future<void> setUserContext(User? user) async {
    if (!isEnabled) {
      return;
    }

    await Sentry.configureScope((scope) {
      if (user == null) {
        scope.setUser(null);
        return;
      }

      scope.setUser(
        SentryUser(
          id: user.id,
          username: user.displayName?.trim().isNotEmpty == true
              ? user.displayName
              : user.username,
          email: user.email,
        ),
      );
    });
  }

  Future<void> clearUserContext() => setUserContext(null);

  Future<SentryId?> captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
    Map<String, Object?>? extras,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!isEnabled) {
      return null;
    }

    return Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;

        if (tags != null) {
          for (final entry in tags.entries) {
            scope.setTag(entry.key, entry.value);
          }
        }

        if (extras != null && extras.isNotEmpty) {
          scope.setContexts('observability', extras);
        }
      },
    );
  }
}

class AppObservabilityNavigatorObserver extends NavigatorObserver {
  void _report(Route<dynamic>? route) {
    if (route == null) {
      return;
    }

    final routeName = route.settings.name?.trim();
    final resolvedName =
        routeName != null && routeName.isNotEmpty ? routeName : route.toString();
    unawaited(AppObservability.instance.setCurrentRoute(resolvedName));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _report(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _report(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _report(newRoute);
  }
}
