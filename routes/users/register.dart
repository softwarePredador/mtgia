import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json();
  final username = body['username'] as String?;
  final email = body['email'] as String?;
  final password = body['password'] as String?;

  if (username == null || email == null || password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Username, email, and password are required.'},
    );
  }

  final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
  final conn = context.read<Connection>();

  try {
    await conn.execute(
      Sql.named(
        'INSERT INTO users (username, email, password_hash) VALUES (@username, @email, @password_hash)',
      ),
      parameters: {
        'username': username,
        'email': email,
        'password_hash': hashedPassword,
      },
    );

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'message': 'User created successfully.'},
    );
  } on ServerException catch (e) {
    if (e.message.contains('users_username_key') || e.message.contains('users_email_key')) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'Username or email already exists.'},
      );
    }
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Database error: ${e.message}'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'An unexpected error occurred: $e'},
    );
  }
}
