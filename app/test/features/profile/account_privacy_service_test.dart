import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/profile/account_privacy_service.dart';

class _PrivacyApiClient extends ApiClient {
  ApiResponse exportResponse = ApiResponse(200, {
    'schema_version': 1,
    'account': {'id': 'user-1', 'email': 'player@example.com'},
    'data': {'decks': <Object>[]},
  });
  ApiResponse deletionResponse = ApiResponse(200, {
    'account_deleted': true,
    'deletion_mode': 'anonymized',
    'deleted_at': '2026-07-16T12:00:00Z',
  });

  String? deletedEndpoint;
  Map<String, dynamic>? deletedBody;

  @override
  Future<ApiResponse> get(String endpoint) async {
    expect(endpoint, '/users/me/export');
    return exportResponse;
  }

  @override
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    deletedEndpoint = endpoint;
    deletedBody = body;
    return deletionResponse;
  }
}

void main() {
  test('exporta JSON portátil e legível sem transformar o envelope', () async {
    final api = _PrivacyApiClient();
    final service = AccountPrivacyService(apiClient: api);

    final exported = await service.exportPortableData();
    final decoded = jsonDecode(exported) as Map<String, dynamic>;

    expect(exported, contains('\n  "schema_version"'));
    expect(decoded['schema_version'], 1);
    expect((decoded['account'] as Map)['email'], 'player@example.com');
  });

  test('exclusão envia frase e senha somente no corpo autenticado', () async {
    final api = _PrivacyApiClient();
    final service = AccountPrivacyService(apiClient: api);

    final receipt = await service.deleteAccount(
      confirmation: 'EXCLUIR MINHA CONTA',
      password: 'TestPassword123!',
    );

    expect(api.deletedEndpoint, '/users/me');
    expect(api.deletedBody, {
      'confirmation': 'EXCLUIR MINHA CONTA',
      'password': 'TestPassword123!',
    });
    expect(receipt.deletionMode, 'anonymized');
    expect(receipt.deletedAt, '2026-07-16T12:00:00Z');
  });

  test('não encerra a sessão sem confirmação positiva do servidor', () async {
    final api =
        _PrivacyApiClient()
          ..deletionResponse = ApiResponse(200, {'account_deleted': false});
    final service = AccountPrivacyService(apiClient: api);

    await expectLater(
      service.deleteAccount(
        confirmation: 'EXCLUIR MINHA CONTA',
        password: 'TestPassword123!',
      ),
      throwsA(
        isA<AccountPrivacyException>().having(
          (error) => error.message,
          'message',
          contains('não confirmou'),
        ),
      ),
    );
  });

  test('senha inválida recebe mensagem segura e orientada', () async {
    final api =
        _PrivacyApiClient()
          ..deletionResponse = ApiResponse(401, {'error': 'invalid_password'});
    final service = AccountPrivacyService(apiClient: api);

    await expectLater(
      service.deleteAccount(
        confirmation: 'EXCLUIR MINHA CONTA',
        password: 'wrong',
      ),
      throwsA(
        isA<AccountPrivacyException>()
            .having((error) => error.statusCode, 'status', 401)
            .having(
              (error) => error.message,
              'message',
              'Senha incorreta. Sua conta não foi alterada.',
            ),
      ),
    );
  });
}
