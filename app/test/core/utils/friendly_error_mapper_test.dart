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

  group('server error bodies (BT-UX-ERR-001)', () {
    test('capability denial without message becomes Portuguese copy', () {
      final message = FriendlyErrorMapper.fromApiResponse(
        ApiResponse(404, {
          'error': 'capability_unavailable',
          'capability': 'trades',
          'release_capability': 'off',
          'request_id': 'req-1',
        }),
        context: FriendlyErrorContext.tradeCreate,
      );

      expect(message, 'Este recurso não está disponível nesta versão da beta.');
    });

    test('prefers the server phrase in message over the code in error', () {
      final message = FriendlyErrorMapper.fromApiResponse(
        ApiResponse(409, {
          'error': 'deck_revision_conflict',
          'message': 'Este deck mudou em outra aba. Recarregue para continuar.',
        }),
        context: FriendlyErrorContext.deckSave,
      );

      expect(
        message,
        'Este deck mudou em outra aba. Recarregue para continuar.',
      );
    });

    test('keeps a Portuguese phrase that the route put in error', () {
      final message = FriendlyErrorMapper.fromApiResponse(
        ApiResponse(400, {
          'error': 'Nome do deck é obrigatório.',
          'code': 'request_invalid',
        }),
        context: FriendlyErrorContext.deckSave,
      );

      expect(message, 'Nome do deck é obrigatório.');
    });

    for (final code in const [
      'capability_unavailable',
      'interaction_blocked',
      'trades_not_allowed',
      'idempotency_conflict',
      'deck_revision_conflict',
      'resource_not_found',
      'legal_acceptance_required',
    ]) {
      test('never shows the raw code $code', () {
        for (final status in const [400, 403, 404, 409, 422]) {
          final fromResponse = FriendlyErrorMapper.fromApiResponse(
            ApiResponse(status, {'error': code}),
          );
          expect(fromResponse, isNot(contains(code)));
          expect(fromResponse, isNot(contains('_')));
        }
        final fromException = FriendlyErrorMapper.fromException(
          Exception(code),
        );
        expect(fromException, isNot(contains(code)));
        expect(
          FriendlyErrorMapper.serverMessageFromBody({'error': code}),
          anyOf(isNull, isNot(contains('_'))),
        );
      });
    }

    test('never shows the single-word code forbidden from a server body', () {
      for (final status in const [400, 403, 404, 409, 422]) {
        final message = FriendlyErrorMapper.fromApiResponse(
          ApiResponse(status, {'error': 'forbidden'}),
        );
        expect(message, isNot(contains('forbidden')));
      }
      expect(
        FriendlyErrorMapper.serverMessageFromBody({'error': 'forbidden'}),
        isNull,
      );
    });

    test('keeps a one-word exception message as the thrower wrote it', () {
      expect(
        FriendlyErrorMapper.fromException(Exception('offline')),
        isNotEmpty,
      );
      expect(
        FriendlyErrorMapper.fromException(Exception('offline')),
        contains('offline'),
      );
    });

    group('403 (BT-AUTH-010)', () {
      const permission = 'Você não tem permissão para realizar esta ação.';

      test('single-word code forbidden shows the permission phrase', () {
        final message = FriendlyErrorMapper.fromApiResponse(
          ApiResponse(403, {'error': 'forbidden'}),
        );

        expect(message, permission);
        expect(message, isNot(contains('forbidden')));
      });

      test('email_verification_required is not a permission denial', () {
        final withoutMessage = FriendlyErrorMapper.fromApiResponse(
          ApiResponse(403, {'error': 'email_verification_required'}),
        );
        final withMessage = FriendlyErrorMapper.fromApiResponse(
          ApiResponse(403, {
            'error': 'email_verification_required',
            'message': 'Confirme seu email para continuar.',
          }),
        );

        expect(withoutMessage, isNot(contains('não tem permissão')));
        expect(withoutMessage, contains('Confirme seu email'));
        expect(withMessage, 'Confirme seu email para continuar.');
        expect(withMessage, isNot(contains('não tem permissão')));
      });

      test('403 without body or with access_forbidden shows permission', () {
        expect(
          FriendlyErrorMapper.fromApiResponse(ApiResponse(403, null)),
          permission,
        );
        expect(
          FriendlyErrorMapper.fromApiResponse(
            ApiResponse(403, {'error': 'access_forbidden'}),
          ),
          permission,
        );
      });
    });

    test('exposes the stable code for callers that branch on it', () {
      expect(
        FriendlyErrorMapper.errorCodeFromBody({
          'error': 'capability_unavailable',
        }),
        'capability_unavailable',
      );
      expect(
        FriendlyErrorMapper.errorCodeFromBody({
          'error': 'Frase em português.',
          'code': 'request_invalid',
        }),
        'request_invalid',
      );
      expect(FriendlyErrorMapper.errorCodeFromBody('nope'), isNull);
    });
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
}
