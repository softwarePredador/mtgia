import 'dart:convert';

import '../../core/api/api_client.dart';

class AccountPrivacyException implements Exception {
  const AccountPrivacyException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AccountDeletionReceipt {
  const AccountDeletionReceipt({
    required this.deletedAt,
    required this.deletionMode,
  });

  final String? deletedAt;
  final String deletionMode;
}

/// Owns the authenticated portability and account-deletion contracts.
///
/// Keeping this outside the widget makes the destructive flow independently
/// testable and prevents accidental logging of the exported payload/password.
class AccountPrivacyService {
  AccountPrivacyService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Exporta os dados portáveis da conta.
  ///
  /// BT-AUTH-004: exportar os próprios dados passou a exigir reverificação de
  /// senha, como a exclusão de conta já exigia. O endpoint deixou de aceitar
  /// `GET` — quem mandar GET recebe 405 e a exportação simplesmente para de
  /// funcionar, sem mensagem útil.
  Future<String> exportPortableData({required String password}) async {
    final response = await _apiClient.post('/users/me/export', {
      'password': password,
    });
    if (response.statusCode != 200 || response.data is! Map) {
      throw AccountPrivacyException(
        _messageFor(response, fallback: _exportFallbackFor(response)),
        statusCode: response.statusCode,
      );
    }

    return const JsonEncoder.withIndent('  ').convert(response.data);
  }

  /// Traduz os três motivos que o servidor distingue nesta rota.
  ///
  /// Sem isto, senha errada e excesso de tentativas caíam na mesma frase
  /// genérica, e quem errou a senha não saberia que basta tentar de novo.
  String _exportFallbackFor(ApiResponse response) =>
      switch (response.statusCode) {
        400 => 'Informe sua senha para exportar seus dados.',
        401 => 'Senha incorreta. Tente novamente.',
        429 =>
          'Muitas tentativas. Aguarde um momento antes de exportar de novo.',
        _ => 'Não foi possível exportar seus dados.',
      };

  Future<AccountDeletionReceipt> deleteAccount({
    required String confirmation,
    required String password,
  }) async {
    final response = await _apiClient.delete(
      '/users/me',
      body: {'confirmation': confirmation, 'password': password},
    );

    if (response.statusCode != 200 || response.data is! Map) {
      throw AccountPrivacyException(
        _messageFor(
          response,
          fallback: switch (response.statusCode) {
            400 => 'Digite a frase de confirmação exatamente como exibida.',
            401 => 'Senha incorreta. Sua conta não foi alterada.',
            _ => 'Não foi possível excluir sua conta. Tente novamente.',
          },
        ),
        statusCode: response.statusCode,
      );
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['account_deleted'] != true) {
      throw const AccountPrivacyException(
        'O servidor não confirmou a exclusão. Sua sessão foi mantida.',
      );
    }

    return AccountDeletionReceipt(
      deletedAt: data['deleted_at'] as String?,
      deletionMode: data['deletion_mode'] as String? ?? 'anonymized',
    );
  }

  String _messageFor(ApiResponse response, {required String fallback}) {
    final data = response.data;
    if (data is Map) {
      for (final key in const ['message', 'error_description']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return fallback;
  }
}
