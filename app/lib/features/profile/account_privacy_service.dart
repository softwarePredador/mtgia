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

  Future<String> exportPortableData() async {
    final response = await _apiClient.get('/users/me/export');
    if (response.statusCode != 200 || response.data is! Map) {
      throw AccountPrivacyException(
        _messageFor(
          response,
          fallback: 'Não foi possível exportar seus dados.',
        ),
        statusCode: response.statusCode,
      );
    }

    return const JsonEncoder.withIndent('  ').convert(response.data);
  }

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
