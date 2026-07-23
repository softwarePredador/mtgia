import 'dart:io';

import 'package:server/auth_runtime_policy.dart';

void main() {
  try {
    validateAuthRuntimeEnvironment(
      Platform.environment,
      requireProduction: true,
    );
    stdout.writeln(
      'auth_runtime_preflight=ready jwt_secret=validated proxy_contract=validated account_email_delivery=validated',
    );
  } on StateError catch (error) {
    stderr.writeln('auth_runtime_preflight=refused reason=${error.message}');
    exitCode = 2;
  }
}
