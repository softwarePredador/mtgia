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
  String? exportedEndpoint;
  Map<String, dynamic>? exportedBody;

  @override
  Future<ApiResponse> get(String endpoint) async {
    // BT-AUTH-004: a exportacao deixou de aceitar GET. Se o app voltar a usar
    // GET, este fake falha aqui em vez de deixar passar um 405 silencioso.
    fail('exportacao nao pode usar GET: $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    exportedEndpoint = endpoint;
    exportedBody = Map<String, dynamic>.from(body);
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

    final exported = await service.exportPortableData(
      password: 'TestPassword123!',
    );
    final decoded = jsonDecode(exported) as Map<String, dynamic>;

    expect(api.exportedEndpoint, '/users/me/export');
    expect(api.exportedBody, {'password': 'TestPassword123!'});
    expect(exported, contains('\n  "schema_version"'));
    expect(decoded['schema_version'], 1);
    expect((decoded['account'] as Map)['email'], 'player@example.com');
  });

  test('cada recusa da exportacao tem mensagem propria', () async {
    // Sem isto, senha errada e excesso de tentativas caem na mesma frase, e
    // quem errou a senha nao sabe que basta tentar de novo.
    for (final (code, trecho) in const [
      (400, 'Informe sua senha'),
      (401, 'Senha incorreta'),
      (429, 'Muitas tentativas'),
    ]) {
      final api = _PrivacyApiClient()..exportResponse = ApiResponse(code, {});
      final service = AccountPrivacyService(apiClient: api);
      await expectLater(
        () => service.exportPortableData(password: 'x'),
        throwsA(
          isA<AccountPrivacyException>().having(
            (e) => e.message,
            'message ($code)',
            contains(trecho),
          ),
        ),
      );
    }
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
    final api = _PrivacyApiClient()
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
    final api = _PrivacyApiClient()
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
