import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/billing/payment_provider.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final pool = context.read<Pool>();
  final rawBody = await context.request.body();
  final result = ManaLoomPaymentProvider(pool: pool).verifyWebhook(
    rawBody: rawBody,
    headers: context.request.headers,
  );

  return Response.json(statusCode: result.statusCode, body: result.body);
}
