import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../lib/http_responses.dart';
import '../../lib/reports/shareable_report_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final service = ShareableReportService(context.read<Pool>());

  try {
    final report = await service.getPublicReport(id);
    if (report == null) return notFound('Relatorio nao encontrado.');
    return Response.json(body: report);
  } catch (error) {
    return internalServerError(
      'Falha ao carregar relatorio compartilhavel',
      details: error,
    );
  }
}
