import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'logger.dart';
import 'public_error_contract.dart';

/// Erro público. `details` só sai quando é estruturado (mapa ou lista que a
/// rota montou para o cliente); exceção, erro ou texto livre nunca vão para o
/// cliente (BT-AUTH-001): ficam no log, só com o tipo.
Response apiError(
  int statusCode,
  String message, {
  Object? details,
}) {
  final body = <String, dynamic>{'error': message};
  if (details is Map || details is List) {
    body['details'] = details;
  } else if (details != null) {
    Log.w(
      '[http_error] status=$statusCode detail_omitted '
      'type=${details.runtimeType}',
    );
  }
  return Response.json(statusCode: statusCode, body: body);
}

Response badRequest(
  String message, {
  Object? details,
}) =>
    apiError(HttpStatus.badRequest, message, details: details);

Response notFound(
  String message, {
  Object? details,
}) =>
    apiError(HttpStatus.notFound, message, details: details);

Response unauthorized(
  String message, {
  Object? details,
}) =>
    apiError(HttpStatus.unauthorized, message, details: details);

/// 500 tipado (D-21): código estável e a frase da rota. A causa vai para o
/// log do servidor, nunca para o corpo.
Response internalServerError(
  String message, {
  Object? details,
}) {
  if (details != null) {
    Log.e(
      '[http_error] status=500 message=$message '
      'type=${details.runtimeType} cause=$details',
    );
  }
  return Response.json(
    statusCode: HttpStatus.internalServerError,
    body: {'error': serverInternalErrorCode, 'message': message},
  );
}

Response methodNotAllowed([
  String message = 'Method not allowed',
]) =>
    apiError(HttpStatus.methodNotAllowed, message);
