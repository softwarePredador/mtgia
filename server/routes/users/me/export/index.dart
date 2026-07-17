import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/auth_middleware.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/user_data_privacy_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) return methodNotAllowed();

  final userId = getUserId(context);
  try {
    final payload = await UserDataPrivacyService(
      context.read<Pool>(),
    ).exportUserData(userId);
    return Response.json(
      body: payload,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
        'Pragma': 'no-cache',
        'Content-Disposition':
            'attachment; filename="manaloom-user-data-$userId.json"',
      },
    );
  } on UserDataNotFoundException {
    return notFound('Conta não encontrada.');
  } catch (_) {
    return internalServerError('Falha ao exportar os dados da conta.');
  }
}
