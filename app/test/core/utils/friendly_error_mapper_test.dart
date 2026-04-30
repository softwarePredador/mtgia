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
}
