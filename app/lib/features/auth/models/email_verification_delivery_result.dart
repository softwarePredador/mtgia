enum EmailVerificationDeliveryStatus { sent, unavailable, unknown }

class EmailVerificationDeliveryResult {
  const EmailVerificationDeliveryResult({
    required this.status,
    required this.message,
    this.alreadyVerified = false,
  });

  factory EmailVerificationDeliveryResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final rawSent = json['verification_sent'];
    final status = switch (rawSent) {
      true => EmailVerificationDeliveryStatus.sent,
      false => EmailVerificationDeliveryStatus.unavailable,
      _ => EmailVerificationDeliveryStatus.unknown,
    };
    final rawMessage = json['message'];
    final message = rawMessage is String && rawMessage.trim().isNotEmpty
        ? rawMessage.trim()
        : fallbackMessage;
    return EmailVerificationDeliveryResult(
      status: status,
      message: message,
      alreadyVerified: json['already_verified'] == true,
    );
  }

  final EmailVerificationDeliveryStatus status;
  final String message;
  final bool alreadyVerified;
}
