import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/utils/friendly_error_mapper.dart';

void main() {
  test('maps technical 500 body to friendly server message', () {
    final message = FriendlyErrorMapper.fromApiResponse(
      ApiResponse(500, {'error': 'DioException: RequestOptions /trades'}),
      context: FriendlyErrorContext.tradeCreate,
    );

    expect(
      message,
      'Servidor indisponível no momento. Tente novamente em instantes.',
    );
    expect(message, isNot(contains('DioException')));
    expect(message, isNot(contains('/trades')));
  });

  test('maps timeout exception without leaking exception type', () {
    final message = FriendlyErrorMapper.fromException(
      TimeoutException('RequestOptions timeout stackTrace'),
      context: FriendlyErrorContext.deckGenerate,
    );

    expect(
      message,
      'A conexão demorou mais que o esperado. Tente novamente em instantes.',
    );
    expect(message, isNot(contains('TimeoutException')));
    expect(message, isNot(contains('RequestOptions')));
  });

  test('maps auth conflict body to actionable account copy', () {
    final message = FriendlyErrorMapper.fromApiResponse(
      ApiResponse(409, {'message': 'email already exists'}),
      context: FriendlyErrorContext.authRegister,
    );

    expect(message, 'Este email já está em uso.');
  });

  test('maps raw status exception to contextual friendly copy', () {
    final message = FriendlyErrorMapper.fromException(
      Exception('Falha ao buscar coleção (500)'),
      context: FriendlyErrorContext.setsCatalog,
    );

    expect(
      message,
      'Servidor indisponível no momento. Tente novamente em instantes.',
    );
    expect(message, isNot(contains('500')));
  });

  test('network errors explain durable deck draft preservation', () {
    final message = FriendlyErrorMapper.fromException(
      Exception('ClientException: network is unreachable'),
      context: FriendlyErrorContext.deckGenerate,
    );

    expect(message, contains('rascunho continua salvo'));
    expect(message, contains('reconecte'));
    expect(message, isNot(contains('ClientException')));
  });

  test('every friendly context resolves to an offline contract', () {
    for (final context in FriendlyErrorContext.values) {
      final contract = FriendlyErrorMapper.offlineContractForContext(context);
      expect(contract.key, isNotEmpty, reason: context.name);
      expect(contract.disconnectedMessage, isNotEmpty, reason: context.name);
    }
  });

  group('403 com email_verification_required', () {
    test('recebe mensagem acionável, não a genérica de permissão', () {
      final msg = FriendlyErrorMapper.fromStatusCode(
        403,
        body: {'error': 'email_verification_required'},
      );
      expect(msg, contains('Confirme seu e-mail'));
      expect(msg, contains('Reenvie'));
      expect(msg, isNot(contains('não tem permissão')));
    });

    test('403 sem esse código mantém a mensagem de permissão', () {
      // Guarda contra alargar o ramo até engolir 403 de verdade.
      expect(
        FriendlyErrorMapper.fromStatusCode(403, body: {'error': 'forbidden'}),
        contains('não tem permissão'),
      );
      expect(
        FriendlyErrorMapper.fromStatusCode(403),
        contains('não tem permissão'),
      );
    });
  });
}