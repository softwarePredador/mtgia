import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/interactive_battle_contract.dart';
import '../../../../lib/battle/interactive_battle_request_scope.dart';
import '../../../../lib/battle/interactive_battle_runtime_client.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/observability.dart';

const _noStore = <String, String>{'Cache-Control': 'no-store'};

Future<Response> onRequest(RequestContext context, String id) async {
  if (!interactiveBattleFeatureEnabled(Platform.environment) ||
      context.request.method != HttpMethod.get ||
      !interactiveBattleUuidPattern.hasMatch(id)) {
    return _notFound();
  }
  final scope = InteractiveBattleRequestScope.open(
    context.read<Pool>(),
    Platform.environment,
  );
  try {
    final session = await scope.service.get(
      context.read<String>(),
      id.toLowerCase(),
    );
    return Response.json(headers: _noStore, body: session.toPrivateJson());
  } on InteractiveBattleNotFoundException {
    return _notFound();
  } on InteractiveBattleRuntimeException catch (error) {
    return Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      headers: {..._noStore, if (error.retryable) 'Retry-After': '2'},
      body: {'error': error.code},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      StateError('Interactive battle read failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'interactive_battle_session',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao consultar sessão interativa.');
  } finally {
    scope.close();
  }
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  headers: _noStore,
  body: {'error': 'interactive_battle_not_found'},
);
