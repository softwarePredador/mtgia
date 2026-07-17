import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/community_engagement_service.dart';
import '../../../lib/community_request_auth.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = await readAuthenticatedUserId(context);
  if (userId == null) return authenticationRequired();

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '40') ?? 40;
  final deckId = params['deck_id']?.trim();

  try {
    final service = CommunityEngagementService(context.read<Pool>());
    final payload = await service.findTradeMatches(
      userId: userId,
      deckId: deckId == null || deckId.isEmpty ? null : deckId,
      limit: limit,
    );
    return Response.json(body: payload);
  } catch (error) {
    return internalServerError(
      'Falha ao buscar matches de trade',
      details: error,
    );
  }
}
