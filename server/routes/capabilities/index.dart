import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/http_responses.dart';
import '../../lib/release_capability_policy.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  return capabilityPolicyResponse(context.read<ReleaseCapabilityPolicy>());
}

Response capabilityPolicyResponse(ReleaseCapabilityPolicy policy) {
  return Response.json(
    statusCode: policy.isValid ? HttpStatus.ok : HttpStatus.serviceUnavailable,
    headers: const {'Cache-Control': 'no-store'},
    body: policy.toPublicJson(),
  );
}
