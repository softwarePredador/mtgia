import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/ai/battle_engine_config.dart';
import '../../../../../../lib/battle/battle_job_contract.dart';
import '../../../../../../lib/battle/battle_live_cursor_contract.dart';
import '../../../../../../lib/battle/battle_live_service.dart';
import '../../../../../../lib/battle/battle_live_source_client.dart';
import '../../../../../../lib/battle/battle_live_store.dart';
import '../../../../../../lib/http_responses.dart';
import '../../../../../../lib/logger.dart';
import '../../../../../../lib/observability.dart';

const _noStoreHeaders = <String, String>{'Cache-Control': 'no-store'};

bool battleLiveSpectatorEnabled(Map<String, String> environment) =>
    battleLiveSpectatorEnabledValue(
      environment[battleLiveSpectatorEnabledEnvironment],
    );

Future<Response> onRequest(RequestContext context, String id) async {
  if (!battleLiveSpectatorEnabled(Platform.environment)) {
    return _notFound();
  }
  if (context.request.method != HttpMethod.get) return methodNotAllowed();
  if (!battleJobUuidPattern.hasMatch(id)) return _notFound();

  late final BattleLiveQuery query;
  try {
    query = BattleLiveQuery.parse(context.request.uri.queryParameters);
  } on BattleLiveValidationException catch (error) {
    return _badRequest(error.code);
  }

  late final BattleLiveService service;
  try {
    service = _service(context, Platform.environment);
  } on Object {
    return _unavailable();
  }

  try {
    final page = await service.read(
      userId: context.read<String>(),
      jobId: id.toLowerCase(),
      query: query,
    );
    return Response.json(headers: _noStoreHeaders, body: page.toJson());
  } on BattleLiveNotFoundException {
    // Missing, malformed, and other-owner job identifiers deliberately share
    // the same response to prevent IDOR enumeration.
    return _notFound();
  } on BattleLiveValidationException catch (error) {
    return _badRequest(error.code);
  } on BattleLiveConflictException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      headers: _noStoreHeaders,
      body: {
        'error': error.code,
        'message': 'Live Spectator indisponivel para este Battle job.',
      },
    );
  } on BattleLiveUnavailableException {
    return _unavailable();
  } on BattleLiveStoreException {
    return _unavailable();
  } on ServerException {
    return _unavailable();
  } catch (error, stackTrace) {
    Log.e('[battle-live] polling failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle Live polling failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'ai_battle_job_live',
        'error_type': '${error.runtimeType}',
      },
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      headers: _noStoreHeaders,
      body: {
        'error': 'internal_error',
        'message': 'Falha ao consultar Live Spectator.',
      },
    );
  } finally {
    service.close();
  }
}

BattleLiveService _service(
  RequestContext context,
  Map<String, String> environment,
) {
  final cursorContract = BattleLiveCursorContract(
    cursorSigningKey: deriveBattleLiveCursorSigningKey(
      environment['JWT_SECRET'] ?? '',
    ),
  );
  final sourceUrl = environment['XMAGE_SIDECAR_URL']?.trim() ?? '';
  final expectedCommit =
      environment['XMAGE_EXPECTED_COMMIT']?.trim().toLowerCase() ??
      pinnedXmageCommit;
  final expectedVersion =
      environment['XMAGE_EXPECTED_VERSION']?.trim() ?? pinnedXmageVersion;
  BattleLiveSource? source;
  if (sourceUrl.isNotEmpty &&
      RegExp(r'^[0-9a-f]{40}$').hasMatch(expectedCommit) &&
      expectedVersion.isNotEmpty &&
      expectedVersion.length <= 80) {
    source = XmageBattleLiveSource(
      baseUrl: sourceUrl,
      expectedIdentity: ExternalBattleEngineIdentity(
        engine: 'xmage',
        version: expectedVersion,
        commit: expectedCommit,
        aiProfile: 'computer_mad',
        telemetryField: 'normalizer_version',
        telemetryVersion: 'xmage_replay_normalizer_v2',
        seedSemantics: 'request_correlation_only_server_rng_uncontrolled',
        deterministic: false,
      ),
      timeout: Duration(milliseconds: _sourceTimeoutMilliseconds(environment)),
    );
  }
  return BattleLiveService(
    store: BattleLiveStore(context.read<Pool>()),
    cursorContract: cursorContract,
    source: source,
  );
}

int _sourceTimeoutMilliseconds(Map<String, String> environment) {
  final parsed = int.tryParse(
    environment['BATTLE_LIVE_SOURCE_TIMEOUT_MS']?.trim() ?? '',
  );
  if (parsed == null || parsed < 250 || parsed > 5000) return 2000;
  return parsed;
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  headers: _noStoreHeaders,
  body: {'error': 'not_found', 'message': 'Battle job nao encontrado.'},
);

Response _badRequest(String code) => Response.json(
  statusCode: HttpStatus.badRequest,
  headers: _noStoreHeaders,
  body: {
    'error': 'battle_live_$code',
    'message': 'Parametros do Live Spectator invalidos.',
  },
);

Response _unavailable() => Response.json(
  statusCode: HttpStatus.serviceUnavailable,
  headers: {..._noStoreHeaders, 'Retry-After': '2'},
  body: {
    'error': 'battle_live_source_unavailable',
    'message': 'Live Spectator temporariamente indisponivel.',
    'retry_after_seconds': 2,
  },
);
