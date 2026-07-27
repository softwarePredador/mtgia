import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/battle/interactive_battle_contract.dart';
import '../../../../../../lib/battle/interactive_battle_request_scope.dart';
import '../../../../../../lib/battle/interactive_battle_runtime_client.dart';
import '../../../../../../lib/http_responses.dart';
import '../../../../../../lib/observability.dart';

const _noStore = <String, String>{'Cache-Control': 'no-store'};

Future<Response> onRequest(RequestContext context, String id) async {
  if (!interactiveBattleFeatureEnabled(Platform.environment) ||
      !interactiveBattleUuidPattern.hasMatch(id)) {
    return _notFound();
  }
  if (context.request.method != HttpMethod.post) return methodNotAllowed();
  final bodyText = await context.request.body();
  if (utf8.encode(bodyText).length > interactiveBattleMaximumBodyBytes) {
    return Response.json(
      statusCode: HttpStatus.requestEntityTooLarge,
      headers: _noStore,
      body: {'error': 'interactive_battle_body_too_large'},
    );
  }
  final headerKey = _header(context.request.headers, 'idempotency-key');
  String? bodyKey;
  if (bodyText.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is! Map ||
          decoded.keys.any((key) => key.toString() != 'idempotency_key')) {
        throw const FormatException();
      }
      bodyKey = decoded['idempotency_key']?.toString().trim();
    } on FormatException {
      return _unprocessable(
        'interactive_battle_concede_json_invalid',
        'O corpo da concessão precisa conter apenas idempotency_key.',
      );
    }
  }
  if (headerKey != null && bodyKey != null && headerKey != bodyKey) {
    return _unprocessable(
      'interactive_battle_idempotency_mismatch',
      'As chaves de idempotência não coincidem.',
    );
  }
  final idempotencyKey = headerKey ?? bodyKey ?? '';
  if (!interactiveBattleIdempotencyPattern.hasMatch(idempotencyKey)) {
    return _unprocessable(
      'interactive_battle_idempotency_invalid',
      'Idempotency-Key é obrigatório e inválido.',
    );
  }
  final scope = InteractiveBattleRequestScope.open(
    context.read<Pool>(),
    Platform.environment,
  );
  try {
    final session = await scope.service.concede(
      userId: context.read<String>(),
      id: id.toLowerCase(),
      idempotencyKey: idempotencyKey,
    );
    return Response.json(
      headers: _noStore,
      body: {'accepted': true, 'session': session.toPrivateJson()},
    );
  } on InteractiveBattleValidationException catch (error) {
    return Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      headers: _noStore,
      body: {'error': error.code, 'message': error.message},
    );
  } on InteractiveBattleNotFoundException {
    return _notFound();
  } on InteractiveBattleIdempotencyConflictException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      headers: _noStore,
      body: {'error': 'interactive_battle_idempotency_conflict'},
    );
  } on InteractiveBattleRuntimeException catch (error) {
    return Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      headers: {..._noStore, if (error.retryable) 'Retry-After': '2'},
      body: {'error': error.code},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      StateError('Interactive battle concede failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'interactive_battle_concede',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao conceder a sessão interativa.');
  } finally {
    scope.close();
  }
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  headers: _noStore,
  body: {'error': 'interactive_battle_not_found'},
);

Response _unprocessable(String code, String message) => Response.json(
  statusCode: HttpStatus.unprocessableEntity,
  headers: _noStore,
  body: {'error': code, 'message': message},
);

String? _header(Map<String, String> headers, String name) {
  final normalized = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value.trim();
  }
  return null;
}
