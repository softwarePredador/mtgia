import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json();
  final email = body['email'] as String?;
  final password = body['password'] as String?;

  if (email == null || password == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Email and password are required.'},
    );
  }

  final conn = context.read<Connection>();

  try {
    // 1. Buscar o usuário pelo email
    final result = await conn.execute(
      Sql.named('SELECT id, password_hash FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'User not found.'},
      );
    }

    final user = result.first.toColumnMap();
    final hashedPassword = user['password_hash'] as String;
    final userId = user['id'] as String;

    // 2. Verificar a senha
    if (!BCrypt.checkpw(password, hashedPassword)) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid credentials.'},
      );
    }

    // 3. Gerar o JWT
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final jwtSecret = env['JWT_SECRET'];

    if (jwtSecret == null) {
      throw Exception('JWT_SECRET not found in .env file.');
    }

    final jwt = JWT({'id': userId});
    final token = jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(days: 7));

    return Response.json(body: {'token': token});
    
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'An unexpected error occurred: $e'},
    );
  }
}
