import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/auth_runtime_policy.dart';
import 'lib/runtime_environment.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final environment = loadRuntimeEnvironment();
  validateAuthRuntimeEnvironment({
    'ENVIRONMENT': environment['ENVIRONMENT'] ?? 'development',
    if (environment['JWT_SECRET'] case final String value) 'JWT_SECRET': value,
    if (environment[trustedProxyHopsEnvironmentKey] case final String value)
      trustedProxyHopsEnvironmentKey: value,
    if (environment[trustedProxyPeersEnvironmentKey] case final String value)
      trustedProxyPeersEnvironmentKey: value,
  });
  return serve(handler, ip, port, poweredByHeader: null);
}
