import '../../core/api/api_client.dart';

class AccountSecurityService {
  AccountSecurityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String> requestPasswordReset(String email) async {
    final response = await _apiClient.post('/auth/forgot-password', {
      'email': email.trim(),
    });
    final data = response.data;
    if (response.statusCode != 202 || data is! Map) {
      throw AccountSecurityUiException(
        _message(data, 'Não foi possível solicitar a recuperação agora.'),
      );
    }
    return _message(
      data,
      'Se o email estiver cadastrado, enviaremos as instruções.',
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiClient.post('/auth/reset-password', {
      'token': token.trim(),
      'new_password': newPassword,
    });
    if (response.statusCode != 200) {
      throw AccountSecurityUiException(
        _message(
          response.data,
          'Não foi possível alterar a senha. Solicite um novo link.',
        ),
      );
    }
  }

  Future<String> verifyEmail(String token) async {
    final response = await _apiClient.post('/auth/verify-email', {
      'token': token.trim(),
    });
    if (response.statusCode != 200) {
      throw AccountSecurityUiException(
        _message(
          response.data,
          'Não foi possível verificar o email. Solicite outro link.',
        ),
      );
    }
    return _message(response.data, 'Email verificado com sucesso.');
  }

  Future<String> resendEmailVerification() async {
    final response = await _apiClient.post(
      '/auth/resend-verification',
      const {},
    );
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw AccountSecurityUiException(
        _message(
          response.data,
          'Não foi possível reenviar a verificação agora.',
        ),
      );
    }
    return _message(response.data, 'Enviaremos um novo link de verificação.');
  }

  static String _message(Object? data, String fallback) {
    if (data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }
}

class AccountSecurityUiException implements Exception {
  const AccountSecurityUiException(this.message);

  final String message;
}
