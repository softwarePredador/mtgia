import 'dart:math';

class InternalAiRequestToken {
  InternalAiRequestToken._();

  static final String value = _generate();

  static bool matches(Map<String, String> headers) {
    final supplied = headers['x-internal-ai-request-token'] ??
        headers['X-Internal-AI-Request-Token'];
    return supplied != null && supplied == value;
  }

  static String _generate() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
