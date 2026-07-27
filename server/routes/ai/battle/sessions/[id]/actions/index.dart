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

  final text = await context.request.body();
  if (utf8.encode(text).length > interactiveBattleMaximumBodyBytes) {
    return Response.json(
      statusCode: HttpStatus.requestEntityTooLarge,
      headers: _noStore,
      body: {'error': 'interactive_battle_body_too_large'},
    );
  }
  late final Map<String, dynamic> body;
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException();
    body = decoded.map((key, value) => MapEntry(key.toString(), value));
  } on FormatException {
    return _unprocessable(
      const InteractiveBattleValidationException(
        'interactive_battle_json_invalid',
        'O corpo precisa ser um objeto JSON válido.',
      ),
    );
  }
  final scope = InteractiveBattleRequestScope.open(
    context.read<Pool>(),
    Platform.environment,
  );
  try {
    final action = InteractiveBattleActionInput.parse(
      body,
      headerIdempotencyKey: _header(context.request.headers, 'idempotency-key'),
    );
    final session = await scope.service.respond(
      userId: context.read<String>(),
      id: id.toLowerCase(),
      action: action,
    );
    return Response.json(
      headers: _noStore,
      body: {'accepted': true, 'session': session.toPrivateJson()},
    );
  } on InteractiveBattleValidationException catch (error) {
    return _unprocessable(error);
  } on InteractiveBattleNotFoundException {
    return _notFound();
  } on InteractiveBattleIdempotencyConflictException {
    return _conflict('interactive_battle_idempotency_conflict');
  } on InteractiveBattleStaleActionException catch (error) {
    return _conflict(error.code);
  } on InteractiveBattleTerminalException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      headers: _noStore,
      body: {
        'error': 'interactive_battle_already_terminal',
        'session': error.session.toPrivateJson(),
      },
    );
  } on InteractiveBattleRuntimeException catch (error) {
    return Response.json(
      statusCode:
          error.statusCode == HttpStatus.conflict
              ? HttpStatus.conflict
              : HttpStatus.serviceUnavailable,
      headers: {..._noStore, if (error.retryable) 'Retry-After': '2'},
      body: {'error': error.code},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      StateError('Interactive battle action failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'interactive_battle_action',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao responder à sessão interativa.');
  } finally {
    scope.close();
  }
}

Response _unprocessable(InteractiveBattleValidationException error) =>
    Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      headers: _noStore,
      body: {'error': error.code, 'message': error.message},
    );

Response _conflict(String code) => Response.json(
  statusCode: HttpStatus.conflict,
  headers: _noStore,
  body: {'error': code},
);

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  headers: _noStore,
  body: {'error': 'interactive_battle_not_found'},
);

String? _header(Map<String, String> headers, String name) {
  final normalized = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value.trim();
  }
  return null;
}
