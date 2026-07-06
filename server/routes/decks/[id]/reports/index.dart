import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/http_responses.dart';
import '../../../../lib/reports/shareable_report_service.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final service = ShareableReportService(context.read<Pool>());

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    body = const <String, dynamic>{};
  }

  try {
    final report = await service.createForDeck(
      userId: userId,
      deckId: deckId,
      body: body,
    );
    if (report == null) return notFound('Deck nao encontrado.');

    final publicUrl = _publicReportUrl(report['id']?.toString() ?? '');
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'report': report,
        'public_url': publicUrl,
      },
    );
  } catch (error) {
    return internalServerError(
      'Falha ao criar relatorio compartilhavel',
      details: error,
    );
  }
}

String _publicReportUrl(String reportId) {
  final base = (Platform.environment['MANALOOM_PUBLIC_SITE_URL'] ??
          Platform.environment['NEXT_PUBLIC_SITE_URL'] ??
          'https://manaloom.com')
      .trim()
      .replaceFirst(RegExp(r'/+$'), '');
  return '$base/reports/$reportId';
}
