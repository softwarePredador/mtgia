import 'package:dart_frog/dart_frog.dart';

import '../../../lib/billing/payment_provider.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final result = const ManaLoomPaymentProvider().verifyWebhook();

  return Response.json(statusCode: result.statusCode, body: result.body);
}
