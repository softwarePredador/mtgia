import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/ai/ai_generate_materialize_support.dart';
import '../../../../../lib/decks/deck_review_artifact.dart';
import '../../../../../lib/logger.dart';
import '../../../../../lib/verified_email_middleware.dart';

/// POST /ai/generate/requests/:id/materialize
///
/// Cria no servidor o deck do resultado de um Generate (DCK-P0-04). Body:
/// `{review_artifact, name?}`. O app não manda cartas nem controles: o deck
/// nasce do resultado e dos controles gravados no pedido, privado e sem o
/// prompt na descrição (D-29). Repetir devolve o mesmo deck (`replayed`).
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: const {'error': 'Method not allowed'},
    );
  }
  // Criar deck exige e-mail verificado, como no POST /decks (BT-AUTH-010).
  final blocked = await verifiedEmailRequiredResponse(context.request);
  if (blocked != null) return blocked;
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  String? token;
  String? name;
  try {
    final decoded = await context.request.json();
    if (decoded is! Map) throw const FormatException();
    final artifact = decoded['review_artifact'];
    token = switch (artifact) {
      final String value => value,
      final Map<dynamic, dynamic> value when value['token'] is String =>
        value['token'] as String,
      _ => null,
    };
    final rawName = decoded['name'];
    if (rawName != null && rawName is! String) throw const FormatException();
    name = rawName as String?;
    if (name != null &&
        name.trim().length > aiGenerateMaterializeMaxNameLength) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: const {
          'error': 'O nome do deck pode ter até 100 caracteres.',
          'error_code': 'generate_materialize_name_invalid',
        },
      );
    }
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: const {
        'error': 'JSON inválido.',
        'error_code': 'generate_materialize_body_invalid',
      },
    );
  }
  if (!_uuid.hasMatch(id)) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: const {
        'error': 'Pedido de geração não encontrado.',
        'error_code': 'generate_request_not_found',
      },
    );
  }

  try {
    final signingSecret = resolveDeckReviewSigningSecret();
    final result = await pool.runTx(
      (session) => materializeAiGenerateRequest(
        session,
        userId: userId,
        requestId: id,
        token: token,
        name: name,
        signingSecret: signingSecret,
      ),
    );
    return Response.json(
      statusCode:
          result['replayed'] == true ? HttpStatus.ok : HttpStatus.created,
      body: {'ok': true, 'generate_request_id': id, ...result},
    );
  } on AiGenerateMaterializeRefusal catch (refusal) {
    return Response.json(
      statusCode: refusal.statusCode,
      body: refusal.responseBody,
    );
  } catch (error) {
    Log.e('[ai-generate-request] materialize failed type=${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'error': 'Não foi possível criar o deck agora.',
        'error_code': 'generate_materialize_failed',
      },
    );
  }
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);
