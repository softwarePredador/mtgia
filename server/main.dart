import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/auth_runtime_policy.dart';
import 'lib/runtime_environment.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final environment = loadRuntimeEnvironment();
  validateAuthRuntimeEnvironment(
    authRuntimeEnvironmentValues((key) => environment[key]),
  );
  return serve(handler, ip, port, poweredByHeader: null);
}
