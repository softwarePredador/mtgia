import 'log_sanitizer.dart';
import 'runtime_environment.dart';

class Log {
  static final _env = loadRuntimeEnvironment();

  static bool get _isProd {
    final v = (_env['ENVIRONMENT'] ?? 'development').trim().toLowerCase();
    return v == 'production';
  }

  static void d(String message) {
    if (_isProd) return;
    // ignore: avoid_print
    print(sanitizeLogMessage(message));
  }

  static void i(String message) {
    // ignore: avoid_print
    print(sanitizeLogMessage(message));
  }

  static void w(String message) {
    // ignore: avoid_print
    print(sanitizeLogMessage(message));
  }

  static void e(String message) {
    // ignore: avoid_print
    print(sanitizeLogMessage(message));
  }
}
