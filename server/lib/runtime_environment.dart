import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Loads local defaults first and lets process-level configuration win.
///
/// Container and one-off runtime overrides must not be replaced by a checked
/// out `.env` file. Keeping the precedence here avoids each route implementing
/// a subtly different environment contract.
DotEnv loadRuntimeEnvironment({
  Iterable<String> filenames = const ['.env'],
  Map<String, String>? processEnvironment,
  bool quiet = true,
}) {
  final env = DotEnv(quiet: quiet)..load(filenames);
  env.addAll(processEnvironment ?? Platform.environment);
  return env;
}
