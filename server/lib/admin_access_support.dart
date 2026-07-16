import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

import 'auth_middleware.dart';
import 'runtime_environment.dart';

const manaloomOpsApiKeyHeader = 'x-manaloom-ops-key';

bool isPublicHealthPath(String path) =>
    path == '/health' || path == '/health/live' || path == '/health/ready';

bool isConfiguredOpsRequestKey({
  required Map<String, String> headers,
  required DotEnv env,
}) {
  final expected = (env['MANALOOM_OPS_API_KEY'] ?? '').trim();
  if (expected.length < 32) return false;

  String supplied = '';
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == manaloomOpsApiKeyHeader) {
      supplied = entry.value.trim();
      break;
    }
  }
  if (supplied.isEmpty) return false;

  final expectedDigest = sha256.convert(utf8.encode(expected)).bytes;
  final suppliedDigest = sha256.convert(utf8.encode(supplied)).bytes;
  var difference = 0;
  for (var index = 0; index < expectedDigest.length; index++) {
    difference |= expectedDigest[index] ^ suppliedDigest[index];
  }
  return difference == 0;
}

Set<String> _configuredValues(DotEnv env, List<String> keys) {
  return keys
      .expand((key) => (env[key] ?? '').split(','))
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
}

bool isConfiguredAdminUserId({required String userId, required DotEnv env}) {
  final ids = _configuredValues(env, const [
    'MANALOOM_ADMIN_USER_IDS',
    'TELEMETRY_ADMIN_USER_IDS',
  ]);
  return ids.contains(userId.trim().toLowerCase());
}

Future<bool> isConfiguredAdminUser({
  required Pool pool,
  required String userId,
  required DotEnv env,
}) async {
  if (isConfiguredAdminUserId(userId: userId, env: env)) return true;

  final emails = _configuredValues(env, const [
    'MANALOOM_ADMIN_EMAILS',
    'TELEMETRY_ADMIN_EMAILS',
  ]);
  if (emails.isEmpty) return false;

  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT LOWER(email) AS email
        FROM users
        WHERE id = CAST(@user_id AS uuid)
        LIMIT 1
      '''),
      parameters: {'user_id': userId},
    );
    if (result.isEmpty) return false;
    final email =
        (result.first.toColumnMap()['email']?.toString() ?? '')
            .trim()
            .toLowerCase();
    return email.isNotEmpty && emails.contains(email);
  } catch (_) {
    return false;
  }
}

Middleware operationalAdminMiddleware() {
  return (handler) {
    final Handler authenticatedAdminHandler = ((context) async {
      final env = loadRuntimeEnvironment();
      final authorized = await isConfiguredAdminUser(
        pool: context.read<Pool>(),
        userId: context.read<String>(),
        env: env,
      );
      if (!authorized) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Acesso operacional não autorizado'},
        );
      }
      return handler(context);
    }).use(authMiddleware());

    return (context) {
      final env = loadRuntimeEnvironment();
      if (isConfiguredOpsRequestKey(
        headers: context.request.headers,
        env: env,
      )) {
        return handler(context);
      }
      return authenticatedAdminHandler(context);
    };
  };
}
