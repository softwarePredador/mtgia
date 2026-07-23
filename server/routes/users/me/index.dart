import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/auth_middleware.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';
import '../../../lib/user_data_privacy_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.get) {
    return _getMe(context);
  }
  if (method == HttpMethod.patch) {
    return _patchMe(context);
  }
  if (method == HttpMethod.delete) {
    return _deleteMe(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _getMe(RequestContext context) async {
  final userId = getUserId(context);
  final pool = context.read<Pool>();

  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT id, username, email, display_name, avatar_url,
               location_state, location_city, trade_notes,
               profile_visibility, binder_visibility, location_visibility,
               message_visibility, trade_visibility, trade_notes_visibility,
               created_at, updated_at, email_verified_at
        FROM users
        WHERE id = @id
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'id': userId},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Usuário não encontrado'},
      );
    }

    final map = result.first.toColumnMap();
    return Response.json(
      body: {
        'user': {
          'id': map['id'],
          'username': map['username'],
          'email': map['email'],
          'display_name': map['display_name'],
          'avatar_url': map['avatar_url'],
          'location_state': map['location_state'],
          'location_city': map['location_city'],
          'trade_notes': map['trade_notes'],
          'profile_visibility': map['profile_visibility'],
          'binder_visibility': map['binder_visibility'],
          'location_visibility': map['location_visibility'],
          'message_visibility': map['message_visibility'],
          'trade_visibility': map['trade_visibility'],
          'trade_notes_visibility': map['trade_notes_visibility'],
          'email_verified': map['email_verified_at'] != null,
          'created_at': (map['created_at'] as DateTime?)?.toIso8601String(),
          'updated_at': (map['updated_at'] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'users_me_route',
      extras: {'operation': 'get_me'},
    );
    Log.e('[profile_route] server_error endpoint=GET /users/me error=$e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Falha ao buscar perfil'},
    );
  }
}

Future<Response> _patchMe(RequestContext context) async {
  final userId = getUserId(context);
  final pool = context.read<Pool>();

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    Log.w(
      '[profile_route] invalid_payload endpoint=PATCH /users/me reason=invalid_json',
    );
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'JSON inválido'},
    );
  }

  final updateFields = <String>[];
  final params = <String, dynamic>{'id': userId};

  if (body.containsKey('display_name')) {
    final raw = body['display_name'];
    final value = raw == null ? null : raw.toString().trim();
    if (value != null && value.length > 50) {
      Log.w(
        '[profile_route] invalid_payload endpoint=PATCH /users/me field=display_name reason=max_length',
      );
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'display_name muito longo (max 50)'},
      );
    }
    updateFields.add('display_name = @display_name');
    params['display_name'] = (value == null || value.isEmpty) ? null : value;
  }

  if (body.containsKey('avatar_url')) {
    final raw = body['avatar_url'];
    final value = raw == null ? null : raw.toString().trim();
    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      final isValid =
          uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
      if (!isValid) {
        Log.w(
          '[profile_route] invalid_payload endpoint=PATCH /users/me field=avatar_url reason=invalid_url',
        );
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'avatar_url inválida (http/https)'},
        );
      }
      if (value.length > 500) {
        Log.w(
          '[profile_route] invalid_payload endpoint=PATCH /users/me field=avatar_url reason=max_length',
        );
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'avatar_url muito longa (max 500)'},
        );
      }
    }
    updateFields.add('avatar_url = @avatar_url');
    params['avatar_url'] = (value == null || value.isEmpty) ? null : value;
  }

  // Location state (UF)
  if (body.containsKey('location_state')) {
    final raw = body['location_state'];
    final value = raw == null ? null : raw.toString().trim().toUpperCase();
    if (value != null && value.isNotEmpty && value.length != 2) {
      Log.w(
        '[profile_route] invalid_payload endpoint=PATCH /users/me field=location_state reason=invalid_uf',
      );
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'location_state deve ter 2 caracteres (UF)'},
      );
    }
    updateFields.add('location_state = @location_state');
    params['location_state'] = (value == null || value.isEmpty) ? null : value;
  }

  // Location city
  if (body.containsKey('location_city')) {
    final raw = body['location_city'];
    final value = raw == null ? null : raw.toString().trim();
    if (value != null && value.length > 100) {
      Log.w(
        '[profile_route] invalid_payload endpoint=PATCH /users/me field=location_city reason=max_length',
      );
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'location_city muito longa (max 100)'},
      );
    }
    updateFields.add('location_city = @location_city');
    params['location_city'] = (value == null || value.isEmpty) ? null : value;
  }

  // Trade notes
  if (body.containsKey('trade_notes')) {
    final raw = body['trade_notes'];
    final value = raw == null ? null : raw.toString().trim();
    if (value != null && value.length > 500) {
      Log.w(
        '[profile_route] invalid_payload endpoint=PATCH /users/me field=trade_notes reason=max_length',
      );
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'trade_notes muito longa (max 500)'},
      );
    }
    updateFields.add('trade_notes = @trade_notes');
    params['trade_notes'] = (value == null || value.isEmpty) ? null : value;
  }

  const visibilityFields = <String, Set<String>>{
    'profile_visibility': {'public', 'private'},
    'binder_visibility': {'public', 'private'},
    'location_visibility': {'public', 'trade_only', 'private'},
    'message_visibility': {'everyone', 'followers', 'none'},
    'trade_visibility': {'everyone', 'followers', 'none'},
    'trade_notes_visibility': {'trade_only', 'private'},
  };
  for (final entry in visibilityFields.entries) {
    if (!body.containsKey(entry.key)) continue;
    final value = body[entry.key]?.toString().trim().toLowerCase() ?? '';
    if (!entry.value.contains(value)) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'error': '${entry.key} invalido',
          'allowed_values': entry.value.toList(growable: false),
        },
      );
    }
    updateFields.add('${entry.key} = @${entry.key}');
    params[entry.key] = value;
  }

  if (updateFields.isEmpty) {
    Log.w(
      '[profile_route] invalid_payload endpoint=PATCH /users/me reason=no_fields',
    );
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Nada para atualizar'},
    );
  }

  try {
    final result = await pool.execute(
      Sql.named('''
        UPDATE users
        SET ${updateFields.join(', ')},
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
          AND deleted_at IS NULL
        RETURNING id, username, email, display_name, avatar_url,
                  location_state, location_city, trade_notes,
                  profile_visibility, binder_visibility, location_visibility,
                  message_visibility, trade_visibility,
                  trade_notes_visibility,
                  created_at, updated_at, email_verified_at
      '''),
      parameters: params,
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Usuário não encontrado'},
      );
    }

    final map = result.first.toColumnMap();
    return Response.json(
      body: {
        'user': {
          'id': map['id'],
          'username': map['username'],
          'email': map['email'],
          'display_name': map['display_name'],
          'avatar_url': map['avatar_url'],
          'location_state': map['location_state'],
          'location_city': map['location_city'],
          'trade_notes': map['trade_notes'],
          'profile_visibility': map['profile_visibility'],
          'binder_visibility': map['binder_visibility'],
          'location_visibility': map['location_visibility'],
          'message_visibility': map['message_visibility'],
          'trade_visibility': map['trade_visibility'],
          'trade_notes_visibility': map['trade_notes_visibility'],
          'email_verified': map['email_verified_at'] != null,
          'created_at': (map['created_at'] as DateTime?)?.toIso8601String(),
          'updated_at': (map['updated_at'] as DateTime?)?.toIso8601String(),
        },
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'users_me_route',
      extras: {'operation': 'patch_me'},
    );
    Log.e('[profile_route] server_error endpoint=PATCH /users/me error=$e');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Falha ao atualizar perfil'},
    );
  }
}

Future<Response> _deleteMe(RequestContext context) async {
  final userId = getUserId(context);
  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'JSON inválido'},
    );
  }

  final confirmation = body['confirmation']?.toString().trim() ?? '';
  final password = body['password']?.toString() ?? '';
  if (confirmation != accountDeletionConfirmation) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': 'invalid_deletion_confirmation',
        'message':
            'Digite exatamente "$accountDeletionConfirmation" para confirmar.',
      },
    );
  }
  if (password.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'password_required', 'message': 'Senha obrigatória.'},
    );
  }

  try {
    final result = await UserDataPrivacyService(
      context.read<Pool>(),
    ).deleteAndAnonymizeAccount(userId: userId, password: password);
    return Response.json(
      body: result,
      headers: const {'Cache-Control': 'no-store, max-age=0'},
    );
  } on InvalidAccountPasswordException {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'invalid_password', 'message': 'Senha atual inválida.'},
    );
  } on UserDataNotFoundException {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Conta não encontrada'},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      source: 'users_me_route',
      extras: {'operation': 'delete_me'},
    );
    Log.e('[profile_route] server_error endpoint=DELETE /users/me');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Falha ao excluir a conta'},
    );
  }
}
